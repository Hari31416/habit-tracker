import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/haptics_helper.dart';

/// A 4-segment passkey input widget for 'XXXX-XXXX-XXXX-XXXX' format passkeys.
class PasskeyInputWidget extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final String? errorText;

  const PasskeyInputWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = true,
    this.errorText,
  });

  @override
  State<PasskeyInputWidget> createState() => PasskeyInputWidgetState();
}

class PasskeyInputWidgetState extends State<PasskeyInputWidget> {
  late final List<TextEditingController> _segmentControllers;
  late final List<FocusNode> _focusNodes;
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _segmentControllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());

    if (widget.controller != null) {
      _syncFromExternalController();
      widget.controller!.addListener(_onExternalControllerChanged);
    }
  }

  @override
  void didUpdateWidget(covariant PasskeyInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onExternalControllerChanged);
      widget.controller?.addListener(_onExternalControllerChanged);
      _syncFromExternalController();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onExternalControllerChanged);
    for (final c in _segmentControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onExternalControllerChanged() {
    if (_isInternalUpdate) return;
    _syncFromExternalController();
  }

  void _syncFromExternalController() {
    final text = widget.controller?.text ?? '';
    setFullPasskey(text, notify: false);
  }

  void setFullPasskey(String rawText, {bool notify = true}) {
    final clean = rawText.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    _isInternalUpdate = true;

    for (var i = 0; i < 4; i++) {
      final start = i * 4;
      if (start < clean.length) {
        final end = (start + 4 <= clean.length) ? start + 4 : clean.length;
        _segmentControllers[i].text = clean.substring(start, end);
      } else {
        _segmentControllers[i].clear();
      }
    }

    _isInternalUpdate = false;
    if (notify) {
      _notifyChange();
    }
  }

  String get fullPasskey {
    final parts = _segmentControllers.map((c) => c.text.trim()).toList();
    if (parts.every((p) => p.isEmpty)) return '';
    return parts.join('-');
  }

  void _notifyChange() {
    final val = fullPasskey;
    if (widget.controller != null && widget.controller!.text != val) {
      _isInternalUpdate = true;
      widget.controller!.text = val;
      _isInternalUpdate = false;
    }
    widget.onChanged?.call(val);
  }

  void _handleSegmentChanged(int index, String value) {
    // Check if user pasted a longer string containing hyphens or >4 characters
    final clean = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length > 4) {
      setFullPasskey(clean);
      final lastIndex = (clean.length / 4).ceil().clamp(1, 4) - 1;
      _focusNodes[lastIndex].requestFocus();
      return;
    }

    final upper = value.toUpperCase();
    if (value != upper) {
      _segmentControllers[index].value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }

    _notifyChange();

    if (upper.length == 4 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setFullPasskey(data.text!);
      HapticsHelper.performLightHaptic();
      final text = fullPasskey.replaceAll('-', '');
      final targetIdx = (text.length / 4).ceil().clamp(1, 4) - 1;
      _focusNodes[targetIdx].requestFocus();
    }
  }

  void clear() {
    for (final c in _segmentControllers) {
      c.clear();
    }
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(7, (i) {
            if (i.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '-',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              );
            }

            final segIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _segmentControllers[segIdx].text.isEmpty &&
                        segIdx > 0) {
                      _focusNodes[segIdx - 1].requestFocus();
                    }
                  },
                  child: TextField(
                    controller: _segmentControllers[segIdx],
                    focusNode: _focusNodes[segIdx],
                    autofocus: widget.autofocus && segIdx == 0,
                    enabled: widget.enabled,
                    obscureText: widget.obscureText,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(4),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        letterSpacing: 2.0,
                      ),
                      filled: true,
                      fillColor: isError
                          ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isError ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isError ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                          width: isError ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    onChanged: (val) => _handleSegmentChanged(segIdx, val),
                  ),
                ),
              ),
            );
          }),
        ),
        if (isError) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

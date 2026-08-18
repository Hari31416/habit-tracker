import 'package:flutter/material.dart';

class DirectNumericInputDialog extends StatefulWidget {
  final String habitTitle;
  final double currentValue;
  final double targetValue;
  final String? unit;
  final VoidCallback onDismiss;
  final ValueChanged<double> onConfirm;

  const DirectNumericInputDialog({
    super.key,
    required this.habitTitle,
    required this.currentValue,
    required this.targetValue,
    this.unit,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<DirectNumericInputDialog> createState() =>
      _DirectNumericInputDialogState();
}

class _DirectNumericInputDialogState extends State<DirectNumericInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = widget.currentValue % 1.0 == 0.0
        ? widget.currentValue.toInt().toString()
        : widget.currentValue.toString();
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text.trim()) ?? 0.0;
    widget.onConfirm(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetText = widget.targetValue % 1.0 == 0.0
        ? widget.targetValue.toInt().toString()
        : widget.targetValue.toString();
    final unitText = widget.unit != null && widget.unit!.trim().isNotEmpty
        ? ' ${widget.unit!.trim()}'
        : '';

    return AlertDialog(
      title: Text(
        'Log ${widget.habitTitle}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target: $targetText$unitText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.unit != null && widget.unit!.isNotEmpty
                  ? 'Value (${widget.unit})'
                  : 'Value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onDismiss,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

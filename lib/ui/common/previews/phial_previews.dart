import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../theme/app_theme.dart';

/// MultiPreview annotation generating both Light and Dark mode preview variants for Phial.
final class PhialMultiBrightnessPreview extends MultiPreview {
  final String name;
  final String group;
  final Size? size;

  const PhialMultiBrightnessPreview({
    required this.name,
    this.group = 'Components',
    this.size,
  });

  @override
  List<Preview> get previews => [
        Preview(
          name: '$name (Light)',
          group: group,
          brightness: Brightness.light,
          size: size,
        ),
        Preview(
          name: '$name (Dark)',
          group: group,
          brightness: Brightness.dark,
          size: size,
        ),
      ];
}

/// Helper wrapper that ensures Material 3 AppTheme styling, background colors, and padding.
class PhialPreviewWrapper extends StatelessWidget {
  final Widget child;
  final Brightness brightness;
  final EdgeInsetsGeometry padding;

  const PhialPreviewWrapper({
    super.key,
    required this.child,
    this.brightness = Brightness.light,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = brightness == Brightness.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    return Theme(
      data: theme,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: padding,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}

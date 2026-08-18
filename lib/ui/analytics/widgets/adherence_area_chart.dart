import 'package:flutter/material.dart';
import '../controllers/analytics_controller.dart';

class AdherenceAreaChart extends StatelessWidget {
  final List<AdherenceDataPoint> dataPoints;
  final TrendRange selectedRange;
  final ValueChanged<TrendRange> onRangeSelected;

  const AdherenceAreaChart({
    super.key,
    required this.dataPoints,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final gridLineColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Header with Range Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adherence Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<TrendRange>(
              segments: TrendRange.values.map((range) {
                return ButtonSegment<TrendRange>(
                  value: range,
                  label: Text(
                    range.label,
                    style: theme.textTheme.labelSmall,
                  ),
                );
              }).toList(),
              selected: {selectedRange},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onRangeSelected(selection.first);
                }
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (dataPoints.isEmpty)
          SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'No adherence data available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          // Smooth Area Canvas
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _AreaChartPainter(
                dataPoints: dataPoints,
                primaryColor: primaryColor,
                gridLineColor: gridLineColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // X-Axis Labels (First, Middle, Last)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dataPoints.first.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (dataPoints.length > 2)
                Text(
                  dataPoints[dataPoints.length ~/ 2].label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              Text(
                dataPoints.last.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<AdherenceDataPoint> dataPoints;
  final Color primaryColor;
  final Color gridLineColor;

  _AreaChartPainter({
    required this.dataPoints,
    required this.primaryColor,
    required this.gridLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Horizontal grid lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final percent in [0.0, 0.5, 1.0]) {
      final y = height - (percent * height);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (dataPoints.length < 2) return;

    final stepX = width / (dataPoints.length - 1);
    final strokePath = Path();
    final fillPath = Path();

    for (int index = 0; index < dataPoints.length; index++) {
      final x = index * stepX;
      final normalizedY =
          (dataPoints[index].adherencePercent / 100.0).clamp(0.0, 1.0);
      final y = height - (normalizedY * height);

      if (index == 0) {
        strokePath.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (index - 1) * stepX;
        final prevNormY = (dataPoints[index - 1].adherencePercent / 100.0)
            .clamp(0.0, 1.0);
        final prevY = height - (prevNormY * height);

        final cx = (prevX + x) / 2;
        strokePath.cubicTo(cx, prevY, cx, y, x, y);
        fillPath.cubicTo(cx, prevY, cx, y, x, y);
      }
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw Area Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw Stroke Line
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(strokePath, strokePaint);

    // Draw Points
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (int index = 0; index < dataPoints.length; index++) {
      final x = index * stepX;
      final normalizedY =
          (dataPoints[index].adherencePercent / 100.0).clamp(0.0, 1.0);
      final y = height - (normalizedY * height);

      canvas.drawCircle(Offset(x, y), 4.0, whitePaint);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.gridLineColor != gridLineColor;
  }
}

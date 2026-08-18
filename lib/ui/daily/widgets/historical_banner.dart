import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoricalBanner extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onReturnToToday;

  const HistoricalBanner({
    super.key,
    required this.selectedDate,
    required this.onReturnToToday,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final isToday = currentSelected == today;
    final isPast = currentSelected.isBefore(today);

    if (isToday) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('EEE, MMM d, yyyy').format(selectedDate);
    final label = isPast
        ? 'Viewing Past: $formattedDate'
        : 'Viewing Future: $formattedDate';

    return Container(
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 18,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReturnToToday,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onTertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Return to Today',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../domain/gamification/gamification_models.dart';
import '../../common/haptics_helper.dart';

class LevelUpCelebrationDialog extends StatefulWidget {
  final LevelUpCelebration celebration;
  final VoidCallback onDismiss;

  const LevelUpCelebrationDialog({
    super.key,
    required this.celebration,
    required this.onDismiss,
  });

  @override
  State<LevelUpCelebrationDialog> createState() =>
      _LevelUpCelebrationDialogState();
}

class _LevelUpCelebrationDialogState extends State<LevelUpCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    HapticsHelper.performHeavyConfirmationHaptic();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Star / AutoAwesome Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'LEVEL UP',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Level ${widget.celebration.newLevel}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              // Title Promotion Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Text(
                          'Mastery Title',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          widget.celebration.title.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.celebration.title.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    widget.onDismiss();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Claim & Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

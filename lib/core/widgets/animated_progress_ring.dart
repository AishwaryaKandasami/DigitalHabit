import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// A circular progress ring whose arc and % label sweep smoothly to
/// [progress] (0..1) — on first build it fills from zero, and afterwards it
/// animates from the old value to the new one whenever progress changes.
///
/// Used for the daily task-progress rings on the dashboard and tasks screen.
class AnimatedProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final TextStyle? labelStyle;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 70,
    this.strokeWidth = 7,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          final complete = value >= 0.999;
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  complete ? AppColors.accentGreen : AppColors.primary,
                ),
              ),
              Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: labelStyle ?? AppTextStyles.heading3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

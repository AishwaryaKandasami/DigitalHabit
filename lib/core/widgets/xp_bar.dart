import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final int level;

  const XpBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level', style: AppTextStyles.label),
            // XP total ticks up smoothly when it changes.
            TweenAnimationBuilder<double>(
              tween: Tween(end: currentXp.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) => Text(
                '${value.round()} / $maxXp XP',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: AppColors.surfaceVariant),
                ),
                Positioned.fill(
                  // Bar fills smoothly toward the new XP level, with a soft
                  // shimmer sweeping across the filled part to feel "alive".
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1800.ms,
                        color: const Color(0x66FFFFFF),
                      )
                      .then(delay: 1600.ms),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CoinBadge extends StatelessWidget {
  final int coins;

  const CoinBadge({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The coin pops each time the total changes (keyed on [coins]).
          const Icon(Icons.monetization_on, color: AppColors.accent, size: 20)
              .animate(key: ValueKey(coins))
              .scaleXY(
                begin: 0.6,
                end: 1.0,
                duration: 450.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: 4),
          // The number counts up smoothly toward the new total.
          TweenAnimationBuilder<double>(
            tween: Tween(end: coins.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) =>
                Text('${value.round()}', style: AppTextStyles.bodyBold),
          ),
        ],
      ),
    );
  }
}

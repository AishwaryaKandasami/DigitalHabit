import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/game_constants.dart';

class MoodIndicator extends StatelessWidget {
  final int moodScore;
  final double size;

  const MoodIndicator({super.key, required this.moodScore, this.size = 24});

  String get _moodLabel {
    if (moodScore >= GameConstants.moodHappyThreshold) return 'Happy';
    if (moodScore >= GameConstants.moodNeutralThreshold) return 'Neutral';
    if (moodScore >= GameConstants.moodSadThreshold) return 'Sad';
    return 'Sick';
  }

  IconData get _moodIcon {
    if (moodScore >= GameConstants.moodHappyThreshold) {
      return Icons.sentiment_very_satisfied;
    }
    if (moodScore >= GameConstants.moodNeutralThreshold) {
      return Icons.sentiment_neutral;
    }
    if (moodScore >= GameConstants.moodSadThreshold) {
      return Icons.sentiment_dissatisfied;
    }
    return Icons.sick;
  }

  Color get _moodColor {
    if (moodScore >= GameConstants.moodHappyThreshold) {
      return AppColors.moodHappy;
    }
    if (moodScore >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral;
    }
    if (moodScore >= GameConstants.moodSadThreshold) return AppColors.moodSad;
    return AppColors.moodSick;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_moodIcon, color: _moodColor, size: size),
        const SizedBox(width: 4),
        Text(
          _moodLabel,
          style: TextStyle(
            color: _moodColor,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.6,
          ),
        ),
      ],
    );
  }
}

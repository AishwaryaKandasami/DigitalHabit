import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../domain/avatar_state.dart';

class AvatarDisplay extends StatelessWidget {
  final AvatarState avatarState;
  final double size;

  const AvatarDisplay({
    super.key,
    required this.avatarState,
    this.size = 200,
  });

  String get _stageEmoji {
    switch (avatarState.evolutionStage) {
      case 1:
        return '🥚';
      case 2:
        return avatarState.creatureType.emoji;
      case 3:
        return avatarState.creatureType.emoji;
      case 4:
        return avatarState.creatureType.emoji;
      case 5:
        return '✨${avatarState.creatureType.emoji}✨';
      default:
        return '🥚';
    }
  }

  double get _emojiSize {
    switch (avatarState.evolutionStage) {
      case 1:
        return size * 0.3;
      case 2:
        return size * 0.35;
      case 3:
        return size * 0.45;
      case 4:
        return size * 0.55;
      case 5:
        return size * 0.6;
      default:
        return size * 0.3;
    }
  }

  Color get _glowColor {
    if (avatarState.moodScore >= GameConstants.moodHappyThreshold) {
      return AppColors.moodHappy;
    }
    if (avatarState.moodScore >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral;
    }
    if (avatarState.moodScore >= GameConstants.moodSadThreshold) {
      return AppColors.moodSad;
    }
    return AppColors.moodSick;
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarState.creatureType.color.withAlpha(30),
        border: Border.all(color: _glowColor.withAlpha(100), width: 3),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withAlpha(40),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _stageEmoji,
            style: TextStyle(fontSize: _emojiSize),
          ),
          if (avatarState.evolutionStage > 1) ...[
            const SizedBox(height: 4),
            Text(
              avatarState.moodLabel,
              style: TextStyle(
                fontSize: size * 0.07,
                color: _glowColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );

    // Add animation based on mood
    if (avatarState.moodScore >= GameConstants.moodHappyThreshold) {
      avatar = avatar
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.05, duration: 1500.ms)
          .then()
          .scaleXY(end: 1.0, duration: 1500.ms);
    } else if (avatarState.moodScore < GameConstants.moodSadThreshold) {
      avatar = avatar
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 3, duration: 2000.ms);
    }

    return avatar;
  }
}

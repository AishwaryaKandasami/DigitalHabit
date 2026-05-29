import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/game_constants.dart';
import '../../domain/avatar_state.dart';

class AvatarDisplay extends StatelessWidget {
  final AvatarState avatarState;
  final double size;

  /// Whether to show a mood-based chat-bubble above the avatar. Auto-hides
  /// for small (<120) renderings to keep badges on nav / header clean.
  final bool showMoodNote;

  /// Optional override text for the speech bubble. When provided (e.g. an
  /// unread parent message), the bubble shows this with a "From X" tag
  /// instead of the mood note. Tapping it fires [onMessageTap] (usually
  /// "mark as read"). Pass null to fall back to the mood note.
  final String? messageOverride;
  final String? messageFromName;
  final VoidCallback? onMessageTap;

  const AvatarDisplay({
    super.key,
    required this.avatarState,
    this.size = 200,
    this.showMoodNote = true,
    this.messageOverride,
    this.messageFromName,
    this.onMessageTap,
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

  /// Friendly one-liner the avatar "says", driven by mood (and egg stage).
  String get _moodNote {
    // Before the egg hatches, the creature can't "talk" much.
    if (avatarState.evolutionStage == 1) {
      return 'Keep me warm! 🥚';
    }
    final mood = avatarState.moodScore;
    if (mood >= GameConstants.moodHappyThreshold) {
      return "WOW! I'm happy today!";
    }
    if (mood >= GameConstants.moodNeutralThreshold) {
      return 'Feeling good.';
    }
    if (mood >= GameConstants.moodSadThreshold) {
      return 'I feel a bit sad…';
    }
    return "I'm tired today…";
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

    // Skip the chat bubble on small instances (used in nav/headers).
    if (!showMoodNote || size < 120) {
      return avatar;
    }

    final hasMessage =
        messageOverride != null && messageOverride!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMessage)
          _ParentMessageBubble(
            text: messageOverride!,
            fromName: messageFromName ?? 'Parent',
            onTap: onMessageTap,
          )
        else
          _MoodChatBubble(text: _moodNote, mood: avatarState.moodScore),
        const SizedBox(height: 8),
        avatar,
      ],
    );
  }
}

class _ParentMessageBubble extends StatelessWidget {
  final String text;
  final String fromName;
  final VoidCallback? onTap;

  const _ParentMessageBubble({
    required this.text,
    required this.fromName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(140)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'From $fromName',
                      style: AppTextStyles.caption.copyWith(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppTextStyles.bodyBold.copyWith(color: color),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tap to dismiss',
                    style: AppTextStyles.caption.copyWith(
                      color: color.withAlpha(180),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CustomPaint(
            size: const Size(14, 8),
            painter: _BubbleTailPainter(
              color: color.withAlpha(40),
              border: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChatBubble extends StatelessWidget {
  final String text;
  final int mood;

  const _MoodChatBubble({required this.text, required this.mood});

  Color get _bg {
    if (mood >= GameConstants.moodHappyThreshold) {
      return AppColors.moodHappy.withAlpha(40);
    }
    if (mood >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral.withAlpha(40);
    }
    if (mood >= GameConstants.moodSadThreshold) {
      return AppColors.moodSad.withAlpha(40);
    }
    return AppColors.moodSick.withAlpha(40);
  }

  Color get _border {
    if (mood >= GameConstants.moodHappyThreshold) return AppColors.moodHappy;
    if (mood >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral;
    }
    if (mood >= GameConstants.moodSadThreshold) return AppColors.moodSad;
    return AppColors.moodSick;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withAlpha(120)),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyBold.copyWith(color: _border),
          ),
        ),
        // Tiny tail triangle pointing down to the avatar.
        CustomPaint(
          size: const Size(14, 8),
          painter: _BubbleTailPainter(color: _bg, border: _border),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color border;
  _BubbleTailPainter({required this.color, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = border.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.border != border;
}

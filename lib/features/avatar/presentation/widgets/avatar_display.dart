import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../shop/domain/shop_item_model.dart';
import '../../domain/avatar_state.dart';

/// A living, interactive creature display.
///
/// - Idles with gentle breathing, bobbing and occasional blinks.
/// - Tapping it makes it pop + wiggle and puffs out floating hearts
///   (and fires [onTapPet] so the caller can give a small mood boost).
/// - Bumping [celebrateSignal] (an int the parent owns) plays a happy jump
///   + a sparkle burst — used for "task done" / "level up" moments.
/// - Keeps the speech bubble (mood note, or a parent-message override).
class AvatarDisplay extends StatefulWidget {
  final AvatarState avatarState;
  final double size;

  /// Whether to show the chat-bubble above the avatar. Auto-hides for small
  /// (<120) renderings used in nav / headers.
  final bool showMoodNote;

  /// Optional override text for the speech bubble (e.g. an unread parent
  /// message). Tapping the bubble fires [onMessageTap].
  final String? messageOverride;
  final String? messageFromName;
  final VoidCallback? onMessageTap;

  /// Increment this from the parent to trigger a one-shot celebration
  /// (happy jump + sparkles). Must be a value the parent owns locally so the
  /// change is detected in didUpdateWidget.
  final int celebrateSignal;

  /// Called when the kid taps (pets) the creature.
  final VoidCallback? onTapPet;

  const AvatarDisplay({
    super.key,
    required this.avatarState,
    this.size = 200,
    this.showMoodNote = true,
    this.messageOverride,
    this.messageFromName,
    this.onMessageTap,
    this.celebrateSignal = 0,
    this.onTapPet,
  });

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay> {
  int _tapKey = 0;
  int _celebrateKey = 0;
  int _burstSeq = 0;
  final List<_Burst> _bursts = [];

  AvatarState get _a => widget.avatarState;

  @override
  void didUpdateWidget(covariant AvatarDisplay old) {
    super.didUpdateWidget(old);
    if (widget.celebrateSignal != old.celebrateSignal) {
      _celebrate();
    }
  }

  void _onTap() {
    setState(() => _tapKey++);
    _spawnBurst(const ['💛', '❤️', '✨'], count: 4);
    widget.onTapPet?.call();
  }

  void _celebrate() {
    setState(() => _celebrateKey++);
    _spawnBurst(const ['✨', '🌟', '🎉', '⭐'], count: 6);
  }

  void _spawnBurst(List<String> emojis, {required int count}) {
    final id = _burstSeq++;
    final items = List.generate(count, (i) {
      return _BurstItem(
        emoji: emojis[i % emojis.length],
        dx: (i - (count - 1) / 2) * 16.0,
        delayMs: i * 55,
      );
    });
    setState(() => _bursts.add(_Burst(id: id, items: items)));
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() => _bursts.removeWhere((b) => b.id == id));
      }
    });
  }

  String get _stageEmoji {
    switch (_a.evolutionStage) {
      case 1:
        return '🥚';
      case 5:
        return '✨${_a.creatureType.emoji}✨';
      default:
        return _a.creatureType.emoji;
    }
  }

  double get _emojiSize {
    switch (_a.evolutionStage) {
      case 1:
        return widget.size * 0.3;
      case 2:
        return widget.size * 0.35;
      case 3:
        return widget.size * 0.45;
      case 4:
        return widget.size * 0.55;
      case 5:
        return widget.size * 0.6;
      default:
        return widget.size * 0.3;
    }
  }

  Color get _glowColor {
    if (_a.moodScore >= GameConstants.moodHappyThreshold) {
      return AppColors.moodHappy;
    }
    if (_a.moodScore >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral;
    }
    return AppColors.moodSad;
  }

  /// Emojis of equipped accessories (hat, glasses, etc.), in equip order.
  List<String> get _accessoryEmojis {
    final out = <String>[];
    for (final id in _a.accessories) {
      final item = ShopItemModel.byId(id);
      if (item != null && item.type == ShopItemType.accessory) {
        out.add(item.emoji);
      }
    }
    return out;
  }

  /// Emoji of the equipped background (only one shown), or null.
  String? get _backgroundEmoji {
    for (final id in _a.accessories) {
      final item = ShopItemModel.byId(id);
      if (item != null && item.type == ShopItemType.background) {
        return item.emoji;
      }
    }
    return null;
  }

  /// Warm one-liner the creature "says". Always positive — never guilt.
  String get _moodNote {
    if (_a.evolutionStage == 1) return 'Keep me warm! 🥚';
    final mood = _a.moodScore;
    if (mood >= GameConstants.moodHappyThreshold) return 'WOW! So happy! 💛';
    if (mood >= GameConstants.moodNeutralThreshold) return 'Feeling good!';
    return "Let's play! 💛";
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    final bgEmoji = _backgroundEmoji;
    final accessoryEmojis = _accessoryEmojis;

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _a.creatureType.color.withAlpha(30),
        border: Border.all(color: _glowColor.withAlpha(100), width: 3),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withAlpha(40),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background scene (faint), kept inside the circle.
          if (bgEmoji != null)
            ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Opacity(
                    opacity: 0.18,
                    child: Text(bgEmoji, style: TextStyle(fontSize: size * 0.72)),
                  ),
                ),
              ),
            ),
          // Creature + mood label.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_stageEmoji, style: TextStyle(fontSize: _emojiSize)),
              if (_a.evolutionStage > 1) ...[
                const SizedBox(height: 4),
                Text(
                  _a.moodLabel,
                  style: TextStyle(
                    fontSize: size * 0.07,
                    color: _glowColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          // Equipped accessories worn near the top of the creature.
          if (accessoryEmojis.isNotEmpty)
            Align(
              alignment: const Alignment(0, -0.75),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in accessoryEmojis)
                    Text(e, style: TextStyle(fontSize: size * 0.18)),
                ],
              ),
            ),
        ],
      ),
    );

    // Small / header instances stay static and non-interactive.
    if (!widget.showMoodNote || size < 120) {
      return circle;
    }

    // Layer the living animations on the circle.
    Widget creature = circle
        // Idle breathing + gentle bob (continuous, reversing).
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.04, duration: 2200.ms, curve: Curves.easeInOut)
        .moveY(begin: 0, end: -4, duration: 2600.ms, curve: Curves.easeInOut);

    // Occasional blink/squash on its own slow loop.
    creature = creature
        .animate(onPlay: (c) => c.repeat())
        .scaleY(begin: 1, end: 0.9, duration: 110.ms, curve: Curves.easeOut)
        .then()
        .scaleY(begin: 0.9, end: 1, duration: 110.ms)
        .then(delay: 3400.ms);

    // One-shot tap reaction (only after the first tap so nothing fires on load).
    if (_tapKey > 0) {
      creature = creature
          .animate(key: ValueKey('tap_$_tapKey'))
          .scaleXY(begin: 1, end: 1.16, duration: 130.ms, curve: Curves.easeOut)
          .then()
          .scaleXY(begin: 1.16, end: 1, duration: 220.ms, curve: Curves.elasticOut);
    }

    // One-shot celebration jump.
    if (_celebrateKey > 0) {
      creature = creature
          .animate(key: ValueKey('celebrate_$_celebrateKey'))
          .moveY(begin: 0, end: -22, duration: 260.ms, curve: Curves.easeOut)
          .then()
          .moveY(begin: -22, end: 0, duration: 430.ms, curve: Curves.bounceOut);
    }

    final interactive = GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            creature,
            for (final burst in _bursts)
              for (var i = 0; i < burst.items.length; i++)
                _BurstParticle(
                  key: ValueKey('burst_${burst.id}_$i'),
                  item: burst.items[i],
                  fontSize: size * 0.13,
                ),
          ],
        ),
      ),
    );

    final hasMessage =
        widget.messageOverride != null &&
            widget.messageOverride!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMessage)
          _ParentMessageBubble(
            text: widget.messageOverride!,
            fromName: widget.messageFromName ?? 'Parent',
            onTap: widget.onMessageTap,
          )
        else
          _MoodChatBubble(text: _moodNote, mood: _a.moodScore),
        const SizedBox(height: 8),
        interactive,
      ],
    );
  }
}

class _Burst {
  final int id;
  final List<_BurstItem> items;
  _Burst({required this.id, required this.items});
}

class _BurstItem {
  final String emoji;
  final double dx;
  final int delayMs;
  _BurstItem({required this.emoji, required this.dx, required this.delayMs});
}

class _BurstParticle extends StatelessWidget {
  final _BurstItem item;
  final double fontSize;

  const _BurstParticle({
    super.key,
    required this.item,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(item.emoji, style: TextStyle(fontSize: fontSize))
        .animate()
        .moveY(
          begin: 0,
          end: -90,
          duration: 950.ms,
          delay: item.delayMs.ms,
          curve: Curves.easeOut,
        )
        .moveX(begin: 0, end: item.dx, duration: 950.ms, delay: item.delayMs.ms)
        .scaleXY(begin: 0.6, end: 1.2, duration: 300.ms, delay: item.delayMs.ms)
        .fadeIn(duration: 120.ms, delay: item.delayMs.ms)
        .then(delay: 350.ms)
        .fadeOut(duration: 380.ms);
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

  Color get _border {
    if (mood >= GameConstants.moodHappyThreshold) return AppColors.moodHappy;
    if (mood >= GameConstants.moodNeutralThreshold) {
      return AppColors.moodNeutral;
    }
    return AppColors.moodSad;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _border.withAlpha(40);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withAlpha(120)),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodyBold.copyWith(color: _border),
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _BubbleTailPainter(color: bg, border: _border),
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

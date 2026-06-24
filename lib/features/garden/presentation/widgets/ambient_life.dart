import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Gentle, non-interactive garden critters — butterflies, a bee, a ladybug and
/// a bird — drifting over the scene. Pure decoration (emoji + flutter_animate,
/// no assets). Meant to fill the garden's sky band, behind the creature.
class AmbientLife extends StatelessWidget {
  const AmbientLife({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
              left: 36,
              top: 28,
              child: _Critter('🦋', 18, 18, -12, 3200, flap: true)),
          Positioned(
              right: 60,
              top: 50,
              child: _Critter('🦋', 15, -14, -18, 3800,
                  flap: true, delayMs: 700)),
          Positioned(
              left: 118,
              top: 74,
              child: _Critter('🐝', 14, 24, -10, 2200, delayMs: 300)),
          Positioned(
              right: 116,
              top: 96,
              child: _Critter('🐞', 13, -12, -6, 4200)),
          Positioned(
              left: 6,
              top: 14,
              child: _Critter('🐦', 16, 44, -8, 5200, delayMs: 1200)),
        ],
      ),
    );
  }
}

class _Critter extends StatelessWidget {
  final String emoji;
  final double size;
  final double dx;
  final double dy;
  final int durationMs;
  final int delayMs;
  final bool flap;

  const _Critter(
    this.emoji,
    this.size,
    this.dx,
    this.dy,
    this.durationMs, {
    this.delayMs = 0,
    this.flap = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget critter = Text(emoji, style: TextStyle(fontSize: size));

    // Butterflies flap their wings (a quick horizontal squish).
    if (flap) {
      critter = critter
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleX(
              begin: 1.0, end: 0.55, duration: 260.ms, curve: Curves.easeInOut);
    }

    // Everyone drifts gently and returns (X and Y on different periods so the
    // path wanders rather than going straight back and forth).
    return critter
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
        .moveX(begin: 0, end: dx, duration: durationMs.ms, curve: Curves.easeInOut)
        .moveY(
          begin: 0,
          end: dy,
          duration: (durationMs * 0.6).round().ms,
          curve: Curves.easeInOut,
        );
  }
}

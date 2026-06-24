import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/garden_plant.dart';
import 'code_plant.dart';

/// Renders a single garden plant.
///
/// This is the swap seam for Rive. Today it draws with [CodePlant] — wrapped
/// in a grow-in + a gentle, continuous sway so the bed feels alive. Once
/// `.riv` assets exist this wrapper will load the species' Rive artboard and
/// feed `growth` into its state machine, falling back to [CodePlant] whenever
/// the asset (or the expected `growth` input) is missing. The rest of the app
/// only ever talks to `RivePlant(species, stage, growth)`.
class RivePlant extends StatelessWidget {
  final PlantSpecies species;
  final PlantStage stage;

  /// 0..1 lifecycle progress — reserved for the Rive `growth` input.
  final double growth;
  final double size;

  const RivePlant({
    super.key,
    required this.species,
    required this.stage,
    this.growth = 0,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final plant = CodePlant(species: species, stage: stage, size: size);

    // Younger plants sway a touch more than fully-grown ones.
    final sway = 0.010 + (1 - growth.clamp(0.0, 1.0)) * 0.010;

    return plant
        // Grows up out of the soil the first time it appears.
        .animate()
        .scaleY(
          begin: 0.0,
          end: 1.0,
          duration: 650.ms,
          curve: Curves.easeOutBack,
          alignment: Alignment.bottomCenter,
        )
        .fadeIn(duration: 400.ms)
        // ...then sways gently forever, pivoting at the base.
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .rotate(
          begin: -sway,
          end: sway,
          duration: 2600.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
        );
  }
}

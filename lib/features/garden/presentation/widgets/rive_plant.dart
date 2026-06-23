import 'package:flutter/material.dart';
import '../../domain/garden_plant.dart';
import 'code_plant.dart';

/// Renders a single garden plant.
///
/// This is the swap seam for Rive. Today it draws with [CodePlant]; once
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
    return CodePlant(species: species, stage: stage, size: size);
  }
}

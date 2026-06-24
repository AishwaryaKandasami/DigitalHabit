import 'package:flutter/services.dart';
import '../../domain/garden_plant.dart';

enum PlantAssetKind { lottie, image }

class PlantAsset {
  final PlantAssetKind kind;
  final String path;
  const PlantAsset(this.kind, this.path);
}

/// Resolves the best available art file for a given [PlantSpecies] / [PlantStage].
///
/// Priority: Lottie (.json) → image (.png/.webp/.jpg) → null (falls back to CodePlant).
/// One Lottie file per species covers all stages; images can be provided per-stage
/// with nearest-stage fallback (so even a single image upgrades the whole species).
///
/// The AssetManifest is loaded once and cached — all calls after the first are
/// synchronous against the cached key set.
class PlantAssets {
  PlantAssets._();

  static Future<Set<String>>? _future;

  static Future<Set<String>> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().toSet();
  }

  static Future<PlantAsset?> resolve(PlantSpecies species, PlantStage stage) async {
    final keys = await (_future ??= _load());
    return _pick(keys, species, stage);
  }

  static PlantAsset? _pick(Set<String> keys, PlantSpecies species, PlantStage stage) {
    final name = species.name;

    // Lottie for this species (one file = all stages, animated).
    final lottie = 'assets/animations/plant_$name.json';
    if (keys.contains(lottie)) return PlantAsset(PlantAssetKind.lottie, lottie);

    // Per-stage image, trying exact stage first then nearest neighbour outward.
    final stages = PlantStage.values;
    final idx = stages.indexOf(stage);
    for (final delta in [0, -1, 1, -2, 2, -3, 3, -4, 4]) {
      final i = idx + delta;
      if (i < 0 || i >= stages.length) continue;
      for (final ext in ['png', 'webp', 'jpg']) {
        final img = 'assets/images/plants/${name}_${stages[i].name}.$ext';
        if (keys.contains(img)) return PlantAsset(PlantAssetKind.image, img);
      }
    }

    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../domain/garden_plant.dart';
import 'code_plant.dart';
import 'plant_assets.dart';

/// Renders a single garden plant, upgrading automatically when art assets exist.
///
/// Resolution priority per species: Lottie → image → [CodePlant] fallback.
/// The rest of the app calls `RivePlant(species, stage, growth)` unchanged;
/// each species upgrades the moment its art file lands in assets/.
class RivePlant extends StatefulWidget {
  final PlantSpecies species;
  final PlantStage stage;

  /// 0..1 lifecycle progress. Younger plants sway more.
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
  State<RivePlant> createState() => _RivePlantState();
}

class _RivePlantState extends State<RivePlant> {
  PlantAsset? _asset;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(RivePlant old) {
    super.didUpdateWidget(old);
    if (old.species != widget.species || old.stage != widget.stage) {
      setState(() => _resolved = false);
      _resolve();
    }
  }

  void _resolve() {
    PlantAssets.resolve(widget.species, widget.stage).then((a) {
      if (mounted) setState(() { _asset = a; _resolved = true; });
    });
  }

  Widget _content() {
    if (!_resolved) {
      return CodePlant(species: widget.species, stage: widget.stage, size: widget.size);
    }
    final asset = _asset;
    if (asset == null) {
      return CodePlant(species: widget.species, stage: widget.stage, size: widget.size);
    }
    if (asset.kind == PlantAssetKind.lottie) {
      return Lottie.asset(
        asset.path,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        repeat: true,
      );
    }
    return Image.asset(
      asset.path,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sway = 0.010 + (1 - widget.growth.clamp(0.0, 1.0)) * 0.010;

    final plant = Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: -4,
          child: Container(
            width: widget.size * 0.55,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withAlpha(28),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: KeyedSubtree(
            key: ValueKey('${widget.species.name}_${widget.stage.name}_${_asset?.path ?? 'code'}'),
            child: _content(),
          ),
        ),
      ],
    );

    return plant
        .animate()
        .scaleY(
          begin: 0.0,
          end: 1.0,
          duration: 650.ms,
          curve: Curves.easeOutBack,
          alignment: Alignment.bottomCenter,
        )
        .fadeIn(duration: 400.ms)
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

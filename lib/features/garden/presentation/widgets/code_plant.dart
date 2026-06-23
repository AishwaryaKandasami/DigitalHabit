import 'package:flutter/material.dart';
import '../../domain/garden_plant.dart';

/// A code-drawn plant — the working renderer until Rive `.riv` art is added.
/// [RivePlant] uses this as its fallback. Anchored at bottom-centre, grows up.
class CodePlant extends StatelessWidget {
  final PlantSpecies species;
  final PlantStage stage;
  final double size;

  const CodePlant({
    super.key,
    required this.species,
    required this.stage,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlantPainter(species, stage)),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final PlantSpecies species;
  final PlantStage stage;

  _PlantPainter(this.species, this.stage);

  static const _stem = Color(0xFF3B6D11);
  static const _leaf = Color(0xFF639922);
  static const _leaf2 = Color(0xFF7DB13B);
  static const _soil = Color(0xFF8A5A1A);
  static const _trunk = Color(0xFF854F0B);
  static const _wood = Color(0xFFA86A18);
  static const _fruit = Color(0xFFE24B4A);
  static const _center = Color(0xFFEF9F27);
  static const _pink = Color(0xFFED93B1);

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height * 0.96);
    final u = size.height / 100;
    Offset p(double x, double y) => Offset(base.dx + x * u, base.dy - y * u);
    final fill = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    void blob(double x, double y, double r, Color c) {
      fill.color = c;
      canvas.drawCircle(p(x, y), r * u, fill);
    }

    void leaf(double x, double y, double w, Color c) {
      fill.color = c;
      canvas.drawOval(
          Rect.fromCenter(center: p(x, y), width: w * u, height: w * 0.5 * u),
          fill);
    }

    void bar(double x, double y, double w, double h, Color c) {
      fill.color = c;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: p(x, y), width: w * u, height: h * u),
              Radius.circular(1.2 * u)),
          fill);
    }

    void stem(double h, double w, [Color c = _stem]) {
      fill.color = c;
      final rect = Rect.fromLTRB(
          p(-w / 2, h).dx, p(0, h).dy, p(w / 2, 0).dx, p(0, 0).dy);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(w * u / 2)), fill);
    }

    void vine(List<Offset> pts, double w, Color c) {
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * u
        ..strokeCap = StrokeCap.round
        ..color = c
        ..isAntiAlias = true;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, pen);
    }

    // Soil mound under every plant.
    fill.color = _soil;
    canvas.drawOval(
        Rect.fromCenter(center: p(0, 1.5), width: 34 * u, height: 9 * u), fill);

    final si = PlantStage.values.indexOf(stage); // 0..4

    void sprout() {
      stem(si == 0 ? 7 : 13, 3);
      leaf(-5, si == 0 ? 6 : 10, 10, _leaf);
      if (si > 0) leaf(5, 12, 10, _leaf2);
    }

    void flowerHead(double ty, Color c0, Color c1) {
      blob(0, ty + 7, 6.5, c0);
      blob(-6, ty + 2, 6.5, c0);
      blob(6, ty + 2, 6.5, c1);
      blob(-3, ty - 3, 6.5, c1);
      blob(3, ty - 3, 6.5, c0);
      blob(0, ty + 2, 4.5, _center);
    }

    switch (species) {
      case PlantSpecies.tree:
        if (si <= 1) {
          sprout();
        } else if (si == 2) {
          stem(24, 6, _trunk);
          blob(0, 30, 13, _leaf);
          blob(-6, 34, 8, _leaf2);
          blob(7, 33, 7, _leaf2);
        } else {
          stem(38, 9, _trunk);
          blob(0, 46, 21, _leaf);
          blob(-12, 52, 12, _leaf2);
          blob(12, 49, 11, _leaf2);
          if (si == 4) {
            blob(-8, 44, 3.5, _fruit);
            blob(9, 50, 3.5, _fruit);
            blob(2, 56, 3.5, _fruit);
          }
        }
        break;

      case PlantSpecies.flower:
        {
          const heights = [6.0, 13.0, 26.0, 34.0, 40.0];
          final h = heights[si];
          stem(h, 3.4);
          if (si >= 1) leaf(-6, h * 0.5, 12, _leaf);
          if (si >= 2) leaf(6, h * 0.65, 13, _leaf2);
          if (si >= 3) leaf(-7, h * 0.82, 11, _leaf);
          if (si == 3) blob(0, h + 3, 6, _leaf);
          if (si == 4) {
            flowerHead(h + 4, const Color(0xFF378ADD), const Color(0xFF85B7EB));
          }
        }
        break;

      case PlantSpecies.tulips:
        if (si <= 1) {
          sprout();
        } else {
          leaf(-8, 6, 12, _leaf);
          leaf(8, 7, 12, _leaf2);
          leaf(0, 5, 12, _leaf);
          final hs = si == 2 ? 16.0 : (si == 3 ? 24.0 : 30.0);
          const cols = [
            Color(0xFFD4537E),
            Color(0xFFE0A11B),
            Color(0xFFD85A30)
          ];
          for (var k = 0; k < 3; k++) {
            final dx = (k - 1) * 7.0;
            vine([p(0, 0), p(dx, hs)], 2.4, _stem);
            if (si == 4) {
              fill.color = cols[k];
              canvas.drawOval(
                  Rect.fromCenter(
                      center: p(dx, hs + 3), width: 9 * u, height: 12 * u),
                  fill);
            } else if (si == 3) {
              blob(dx, hs, 3.5, _leaf);
            }
          }
        }
        break;

      case PlantSpecies.veggies:
        if (si <= 1) {
          sprout();
        } else {
          leaf(-8, 7, 18, _leaf);
          leaf(8, 7, 18, _leaf2);
          leaf(0, 12, 18, _leaf);
          if (si == 3) {
            blob(-6, 5, 3.5, _leaf2);
            blob(6, 6, 3.5, _leaf2);
          }
          if (si == 4) {
            blob(-6, 5, 4.5, _fruit);
            blob(7, 6, 4.5, _fruit);
            blob(1, 11, 4, _center);
          }
        }
        break;

      case PlantSpecies.bush:
        if (si <= 1) {
          sprout();
        } else {
          final r = si == 2 ? 14.0 : (si == 3 ? 17.0 : 20.0);
          blob(0, r * 0.7, r, _leaf);
          blob(-r * 0.6, r * 0.6, r * 0.7, _leaf2);
          blob(r * 0.6, r * 0.55, r * 0.65, _leaf2);
          if (si == 4) {
            blob(-6, r, 3, _pink);
            blob(6, r * 1.1, 3, _pink);
            blob(0, r * 1.3, 3, _pink);
            blob(-r * 0.4, r * 0.7, 3, _pink);
          }
        }
        break;

      case PlantSpecies.creeper:
        bar(-11, 23, 2.8, 46, _wood);
        bar(11, 23, 2.8, 46, _wood);
        bar(0, 36, 26, 2.4, _wood);
        bar(0, 20, 26, 2.4, _wood);
        final vh = si <= 1 ? 14.0 : (si == 2 ? 28.0 : 44.0);
        vine([
          p(0, 0),
          p(-4, vh * 0.4),
          p(2, vh * 0.7),
          p(0, vh),
        ], 2.6, _stem);
        leaf(-6, vh * 0.4, 9, _leaf);
        if (si >= 2) leaf(4, vh * 0.7, 9, _leaf2);
        if (si >= 4) {
          blob(-3, vh * 0.9, 4, const Color(0xFF7F77DD));
          blob(4, vh * 0.8, 4, const Color(0xFFAFA9EC));
          blob(-6, vh * 0.55, 3.6, const Color(0xFF7F77DD));
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) =>
      old.species != species || old.stage != stage;
}

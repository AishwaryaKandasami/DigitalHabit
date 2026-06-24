import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../family/providers/family_providers.dart';
import '../../../avatar/presentation/widgets/avatar_display.dart';
import '../../domain/garden_plant.dart';
import '../../domain/garden_state.dart';
import 'ambient_life.dart';
import 'rive_plant.dart';

/// The garden: a sky band with the sun (sized by streak) and the creature,
/// over a grass band where each habit's plant grows. Tapping the creature
/// opens its detail screen.
class GardenScene extends ConsumerWidget {
  final GardenState garden;
  const GardenScene({super.key, required this.garden});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 168,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6ABBE8), // deep sky
                Color(0xFFADD8F0), // mid sky
                Color(0xFFD5EFD4), // warm horizon
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 14,
                right: 18,
                child: _Sun(streak: garden.streakDays),
              ),
              const Positioned.fill(child: AmbientLife()),
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () => context.push('/kid/garden/creature'),
                  behavior: HitTestBehavior.opaque,
                  child: member == null
                      ? const SizedBox(height: 108)
                      : AvatarDisplay(
                          avatarState: member.avatarState,
                          size: 104,
                          showMoodNote: false,
                          showRing: false,
                        ),
                ),
              ),
            ],
          ),
        ),
        // Horizon divider
        Container(height: 3, color: const Color(0xFF8BC34A)),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF9ED160), // bright top grass
                Color(0xFF72A832), // richer mid
                Color(0xFF5A8C22), // shadowed bottom
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
          child: SizedBox(
            height: 156,
            child: garden.isEmpty
                ? const _EmptyBeds()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: garden.plants.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => _PlotTile(plant: garden.plants[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Sun extends StatelessWidget {
  final int streak;
  const _Sun({required this.streak});

  @override
  Widget build(BuildContext context) {
    final d = 26.0 + streak.clamp(0, 14) * 1.2;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFAC775),
        border: Border.all(color: const Color(0xFFEF9F27), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFAC775).withAlpha(150),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    )
        // Gentle breathing glow so the sky feels warm and alive.
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.08,
          duration: 2400.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _PlotTile extends StatelessWidget {
  final GardenPlant plant;
  const _PlotTile({required this.plant});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RivePlant(
            species: plant.species,
            stage: plant.stage,
            growth: plant.growth,
            size: 96,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(plant.category.icon,
                  size: 13, color: Colors.white),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  plant.category.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(
            '${plant.days} day${plant.days == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 10, color: Color(0xFFDCF5C0), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyBeds extends StatelessWidget {
  const _EmptyBeds();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 36, color: Colors.white70),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Finish your habits to plant your garden!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

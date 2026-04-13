import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../../core/widgets/mood_indicator.dart';
import '../../family/providers/family_providers.dart';
import 'widgets/avatar_display.dart';

class AvatarScreen extends ConsumerWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);
    if (member == null) {
      return const Scaffold(
        body: Center(child: Text('Loading...')),
      );
    }

    final avatar = member.avatarState;

    return Scaffold(
      appBar: AppBar(title: Text(avatar.creatureName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar display
            AvatarDisplay(avatarState: avatar, size: 200),
            const SizedBox(height: 24),

            // Name and stage
            Text(avatar.creatureName, style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              '${avatar.creatureType.displayName} - ${avatar.evolutionStageName}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),

            // XP bar
            XpBar(
              currentXp: avatar.xpForCurrentLevel,
              maxXp: avatar.xpToNextLevel,
              level: avatar.level,
            ),
            const SizedBox(height: 16),

            // Mood and Health
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Mood',
                    child: MoodIndicator(moodScore: avatar.moodScore),
                    value: '${avatar.moodScore}/${GameConstants.moodMax}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Health',
                    child: Icon(
                      Icons.favorite,
                      color: avatar.health > GameConstants.healthSickThreshold
                          ? Colors.red
                          : Colors.grey,
                    ),
                    value: '${avatar.health}/${GameConstants.healthMax}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Evolution timeline
            Text('Evolution Path', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _EvolutionTimeline(currentStage: avatar.evolutionStage),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Widget child;
  final String value;

  const _StatCard({
    required this.label,
    required this.child,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 8),
            child,
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

class _EvolutionTimeline extends StatelessWidget {
  final int currentStage;

  const _EvolutionTimeline({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final stage = i + 1;
        final isReached = stage <= currentStage;
        final isCurrent = stage == currentStage;
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReached
                    ? Theme.of(context).colorScheme.primary.withAlpha(isCurrent ? 255 : 100)
                    : Colors.grey.withAlpha(50),
                border: isCurrent
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3)
                    : null,
              ),
              child: Center(
                child: Text(
                  GameConstants.evolutionStageNames[i][0],
                  style: TextStyle(
                    color: isReached ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              GameConstants.evolutionStageNames[i],
              style: AppTextStyles.caption.copyWith(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

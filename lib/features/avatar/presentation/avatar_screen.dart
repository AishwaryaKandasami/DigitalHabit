import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../../core/widgets/mood_indicator.dart';
import '../../family/providers/family_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/evolution_calculator.dart';
import 'widgets/avatar_display.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  int _celebrateSignal = 0;
  DateTime? _lastPetWrite;

  Future<void> _petCreature() async {
    final now = DateTime.now();
    if (_lastPetWrite != null &&
        now.difference(_lastPetWrite!).inSeconds < 20) {
      return;
    }
    _lastPetWrite = now;
    final appUser = ref.read(appUserProvider).value;
    final member = ref.read(currentMemberProvider);
    if (appUser?.familyId == null ||
        appUser?.memberId == null ||
        member == null) {
      return;
    }
    try {
      final updated =
          EvolutionCalculator.applyMoodChange(member.avatarState, 1);
      await ref.read(familyRepositoryProvider).updateMember(
            appUser!.familyId!,
            appUser.memberId!,
            {'avatarState': updated.toMap()},
          );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _giveTreat() async {
    final appUser = ref.read(appUserProvider).value;
    if (appUser?.familyId == null || appUser?.memberId == null) return;
    try {
      final eaten = await ref.read(shopRepositoryProvider).giveDailyTreat(
            familyId: appUser!.familyId!,
            memberId: appUser.memberId!,
          );
      if (!mounted) return;
      if (eaten) {
        setState(() => _celebrateSignal++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yum! 🍎 Your creature feels great!'),
            backgroundColor: AppColors.accentGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already had a treat today! 💤'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Avatar display — tap to pet, celebrates on treat.
            AvatarDisplay(
              avatarState: avatar,
              size: 200,
              celebrateSignal: _celebrateSignal,
              onTapPet: _petCreature,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _giveTreat,
              icon: const Text('🍎', style: TextStyle(fontSize: 16)),
              label: const Text('Give a treat'),
            ),
            const SizedBox(height: 16),

            // Name and stage
            Text(avatar.creatureName, style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              '${avatar.creatureType.displayName} - ${avatar.evolutionStageName}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 8),

            // Egg-stage only: let kid change creature before it hatches
            if (avatar.evolutionStage == 1) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/choose-avatar'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Change my creature'),
              ),
              Text(
                'You can change your creature until your egg hatches.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            // Streak and total XP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniStat(
                  icon: Icons.local_fire_department,
                  color: AppColors.accent,
                  label: '${member.streakDays} day streak',
                ),
                const SizedBox(width: 20),
                _MiniStat(
                  icon: Icons.star,
                  color: AppColors.primary,
                  label: '${avatar.totalXp} total XP',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // XP bar
            XpBar(
              currentXp: avatar.xpForCurrentLevel,
              maxXp: avatar.xpToNextLevel > 0 ? avatar.xpToNextLevel : 1,
              level: avatar.level,
            ),
            if (avatar.evolutionStage < GameConstants.evolutionXpThresholds.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${GameConstants.evolutionXpThresholds[avatar.evolutionStage] - avatar.totalXp} XP to ${GameConstants.evolutionStageNames[avatar.evolutionStage]}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              ),
            const SizedBox(height: 20),

            // Mood and Health
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Mood',
                    child: MoodIndicator(moodScore: avatar.moodScore),
                    value: avatar.moodLabel,
                    subValue: '${avatar.moodScore}/${GameConstants.moodMax}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HealthCard(health: avatar.health),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Evolution timeline
            Text('Evolution Path', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _EvolutionTimeline(
              currentStage: avatar.evolutionStage,
              creatureEmoji: avatar.creatureType.emoji,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Widget child;
  final String value;
  final String? subValue;

  const _StatCard({
    required this.label,
    required this.child,
    required this.value,
    this.subValue,
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
            Text(value, style: AppTextStyles.bodyBold),
            if (subValue != null)
              Text(subValue!, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final int health;

  const _HealthCard({required this.health});

  Color get _healthColor {
    if (health > 70) return AppColors.accentGreen;
    if (health > 40) return AppColors.accent;
    if (health > GameConstants.healthSickThreshold) return AppColors.accentRed;
    return Colors.grey;
  }

  String get _healthLabel {
    if (health > 70) return 'Healthy';
    if (health > 40) return 'Okay';
    if (health > GameConstants.healthSickThreshold) return 'Weak';
    return 'Sick';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Health', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: health / GameConstants.healthMax,
                    strokeWidth: 5,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(_healthColor),
                  ),
                  Center(
                    child: Icon(Icons.favorite, color: _healthColor, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(_healthLabel, style: AppTextStyles.bodyBold),
            Text('$health/${GameConstants.healthMax}',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _EvolutionTimeline extends StatelessWidget {
  final int currentStage;
  final String creatureEmoji;

  const _EvolutionTimeline({
    required this.currentStage,
    required this.creatureEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final stage = i + 1;
        final isReached = stage <= currentStage;
        final isCurrent = stage == currentStage;
        final xpNeeded = GameConstants.evolutionXpThresholds[i];

        return Expanded(
          child: Column(
            children: [
              // Connector line (except first)
              if (i > 0)
                Container(
                  height: 2,
                  color: isReached
                      ? AppColors.primary.withAlpha(180)
                      : AppColors.surfaceVariant,
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isReached
                      ? AppColors.primary.withAlpha(isCurrent ? 255 : 100)
                      : AppColors.surfaceVariant,
                  border: isCurrent
                      ? Border.all(color: AppColors.accent, width: 3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    isCurrent ? creatureEmoji : GameConstants.evolutionStageNames[i][0],
                    style: TextStyle(
                      color: isReached ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: isCurrent ? 20 : 14,
                    ),
                  ),
                ),
              )
                  .animate(
                    target: isCurrent ? 1 : 0,
                  )
                  .scaleXY(end: 1.1, duration: 1000.ms, curve: Curves.easeInOut),
              const SizedBox(height: 4),
              Text(
                GameConstants.evolutionStageNames[i],
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
              Text(
                '${xpNeeded}XP',
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        );
      }),
    );
  }
}

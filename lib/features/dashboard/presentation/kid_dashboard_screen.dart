import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../family/providers/family_providers.dart';
import '../../avatar/presentation/widgets/avatar_display.dart';

class KidDashboardScreen extends ConsumerWidget {
  const KidDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);

    if (member == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatar = member.avatarState;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, ${member.displayName}!',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${member.streakDays} day streak',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                  CoinBadge(coins: member.wallet.coins),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar
              Center(
                child: AvatarDisplay(avatarState: avatar, size: 180),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${avatar.creatureName} the ${avatar.creatureType.displayName}',
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(height: 16),

              // XP bar
              XpBar(
                currentXp: avatar.xpForCurrentLevel,
                maxXp: avatar.xpToNextLevel > 0 ? avatar.xpToNextLevel : 1,
                level: avatar.level,
              ),
              const SizedBox(height: 24),

              // Today's Schedule placeholder
              Text("Today's Schedule", style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 48,
                            color: AppColors.textSecondary.withAlpha(100)),
                        const SizedBox(height: 12),
                        Text(
                          'No plan for today yet!',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Go to Planner to create your week.',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress ring placeholder
              Text('Daily Progress', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 0,
                              strokeWidth: 8,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accentGreen),
                            ),
                            Center(
                              child: Text('0%',
                                  style: AppTextStyles.heading3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('0 of 0 tasks done',
                                style: AppTextStyles.bodyBold),
                            const SizedBox(height: 4),
                            Text(
                              'Complete tasks to earn coins and grow your creature!',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

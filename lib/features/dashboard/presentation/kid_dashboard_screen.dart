import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../family/providers/family_providers.dart';
import '../../avatar/presentation/widgets/avatar_display.dart';
import '../../planner/domain/plan_model.dart';
import '../../planner/providers/planner_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/domain/reward_calculator.dart';
import '../../auth/providers/auth_providers.dart';

class KidDashboardScreen extends ConsumerWidget {
  const KidDashboardScreen({super.key});

  String _todayDayName() {
    final weekday = DateTime.now().weekday;
    return PlanModel.dayNames[weekday - 1];
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider);
    final planAsync = ref.watch(currentPlanProvider);
    final logsAsync = ref.watch(todayLogsProvider);

    // Apply mood decay retroactively on dashboard load
    ref.watch(applyMoodDecayProvider);

    if (member == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatar = member.avatarState;
    final plan = planAsync.value;
    final todayTasks = (plan?.status == PlanStatus.approved)
        ? (plan!.tasksForDay(_todayDayName())
          ..sort((a, b) => a.hour.compareTo(b.hour)))
        : [];
    final completedTaskIds =
        logsAsync.value?.map((l) => l.taskId).toSet() ?? {};
    final doneCount =
        todayTasks.where((t) => completedTaskIds.contains(t.taskId)).length;
    final totalCount = todayTasks.length;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

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
                child: AvatarDisplay(avatarState: avatar, size: 160),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${avatar.creatureName} the ${avatar.creatureType.displayName}',
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(height: 12),

              // XP bar
              XpBar(
                currentXp: avatar.xpForCurrentLevel,
                maxXp: avatar.xpToNextLevel > 0 ? avatar.xpToNextLevel : 1,
                level: avatar.level,
              ),
              const SizedBox(height: 24),

              // Daily Progress
              Text('Daily Progress', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 7,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(
                                progress >= 1.0
                                    ? AppColors.accentGreen
                                    : AppColors.primary,
                              ),
                            ),
                            Center(
                              child: Text('${(progress * 100).round()}%',
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
                            Text('$doneCount of $totalCount tasks done',
                                style: AppTextStyles.bodyBold),
                            const SizedBox(height: 4),
                            Text(
                              totalCount == 0
                                  ? 'No tasks planned for today.'
                                  : doneCount == totalCount
                                      ? 'All done! Your creature is happy!'
                                      : 'Complete tasks to earn coins!',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Tasks", style: AppTextStyles.heading3),
                  if (todayTasks.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/kid/tasks'),
                      child: const Text('See All'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (todayTasks.isEmpty && plan == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48,
                              color:
                                  AppColors.textSecondary.withAlpha(100)),
                          const SizedBox(height: 12),
                          Text('No plan for this week yet!',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Go to Planner to create your week.',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                )
              else if (todayTasks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('😎', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text('Free day! No tasks planned.',
                              style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Show up to 5 tasks inline
                ...todayTasks.take(5).map((task) {
                  final isDone = completedTaskIds.contains(task.taskId);
                  final timeStr =
                      '${task.hour.toString().padLeft(2, '0')}:00';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isDone
                        ? AppColors.accentGreen.withAlpha(15)
                        : null,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.accentGreen.withAlpha(30)
                              : task.category.color.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDone ? Icons.check : task.category.icon,
                          color: isDone
                              ? AppColors.accentGreen
                              : task.category.color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: AppTextStyles.bodyBold.copyWith(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? AppColors.textSecondary : null,
                        ),
                      ),
                      subtitle: Text('$timeStr  •  ${task.duration}min',
                          style: AppTextStyles.caption),
                      trailing: isDone
                          ? const Icon(Icons.check_circle,
                              color: AppColors.accentGreen, size: 24)
                          : _QuickDoneButton(
                              onPressed: () => _completeTask(
                                  context, ref, plan!, task),
                            ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeTask(
    BuildContext context,
    WidgetRef ref,
    PlanModel plan,
    dynamic task,
  ) async {
    final appUser = ref.read(appUserProvider).value;
    if (appUser == null) return;

    try {
      final repo = ref.read(taskLogRepositoryProvider);
      final result = await repo.completeTask(
        familyId: appUser.familyId!,
        memberId: appUser.memberId!,
        planId: plan.id,
        date: _todayDate(),
        task: task,
      );

      // Update streak
      await repo.updateStreak(
        familyId: appUser.familyId!,
        memberId: appUser.memberId!,
        todayDate: _todayDate(),
      );

      ref.invalidate(todayLogsProvider);

      if (context.mounted) {
        final reward =
            RewardCalculator.forTaskCompletion(isHealthy: task.isHealthy);
        final msg = result.leveledUp
            ? '${task.title} done! Your creature evolved! +${reward.coins} coins, +${reward.xp} XP'
            : '${task.title} done! +${reward.coins} coins, +${reward.xp} XP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: result.leveledUp
                ? AppColors.accent
                : AppColors.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _QuickDoneButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuickDoneButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 32,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
        ),
        child: const Text('Done!', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

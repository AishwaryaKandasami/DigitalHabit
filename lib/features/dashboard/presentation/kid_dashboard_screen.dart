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
import '../../tasks/domain/task_log_model.dart';
import '../../tasks/presentation/widgets/parent_feedback_chip.dart';
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
    final logsByTaskId = <String, TaskLogModel>{
      for (final l in (logsAsync.value ?? const <TaskLogModel>[]))
        l.taskId: l,
    };
    final unreadLogs = (logsAsync.value ?? const <TaskLogModel>[])
        .where((l) => l.hasUnreadFeedback)
        .toList();
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

              // New feedback banner (only when there's unread parent feedback)
              if (unreadLogs.isNotEmpty) ...[
                _FeedbackBanner(
                  count: unreadLogs.length,
                  onTap: () =>
                      _openFeedback(context, ref, unreadLogs),
                ),
                const SizedBox(height: 16),
              ],

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
                  final log = logsByTaskId[task.taskId];
                  final timeStr =
                      '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isDone
                        ? AppColors.accentGreen.withAlpha(15)
                        : null,
                    child: ListTile(
                      isThreeLine: log != null && log.verifiedByParent != null,
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$timeStr  •  ${task.duration}min',
                              style: AppTextStyles.caption),
                          if (log != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ParentFeedbackChip(log: log),
                            ),
                        ],
                      ),
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

  /// Mark all currently-unread feedback logs as seen and jump to the
  /// Today's Tasks screen so the kid actually sees the comments.
  Future<void> _openFeedback(
    BuildContext context,
    WidgetRef ref,
    List<TaskLogModel> unread,
  ) async {
    final appUser = ref.read(appUserProvider).value;
    if (appUser?.familyId == null || unread.isEmpty) return;
    try {
      await ref.read(taskLogRepositoryProvider).markFeedbackSeen(
            familyId: appUser!.familyId!,
            logIds: unread.map((l) => l.id).toList(),
          );
    } catch (_) {
      // Marking-seen is a nice-to-have; don't block navigation on failure.
    }
    if (!context.mounted) return;
    context.push('/kid/tasks');
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

class _FeedbackBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FeedbackBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.mark_email_unread,
                    color: AppColors.primary, size: 22),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 16),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? '1 new message from your parent'
                        : '$count new messages from your parent',
                    style:
                        AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('Tap to read them.', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
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

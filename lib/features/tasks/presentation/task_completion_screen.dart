import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../planner/domain/plan_model.dart';
import '../../planner/domain/task_model.dart';
import '../../planner/providers/planner_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/task_providers.dart';
import '../domain/reward_calculator.dart';
import '../data/task_log_repository.dart';
import '../../../core/constants/game_constants.dart';

class TaskCompletionScreen extends ConsumerWidget {
  const TaskCompletionScreen({super.key});

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
    final planAsync = ref.watch(currentPlanProvider);
    final logsAsync = ref.watch(todayLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Tasks")),
      body: planAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) {
          if (plan == null || plan.status != PlanStatus.approved) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy,
                      size: 64, color: AppColors.textSecondary.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text('No approved plan for this week',
                      style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text(
                    'Create and submit a plan first!',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            );
          }

          final dayName = _todayDayName();
          final todayTasks = plan.tasksForDay(dayName)
            ..sort((a, b) => a.hour.compareTo(b.hour));
          final completedTaskIds = logsAsync.value
                  ?.map((l) => l.taskId)
                  .toSet() ??
              {};

          if (todayTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text('No tasks planned for today!',
                      style: AppTextStyles.heading3),
                ],
              ),
            );
          }

          final doneCount =
              todayTasks.where((t) => completedTaskIds.contains(t.taskId)).length;
          final totalCount = todayTasks.length;
          final progress =
              totalCount > 0 ? doneCount / totalCount : 0.0;

          return Column(
            children: [
              // Progress header
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.primary.withAlpha(15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1.0
                                  ? AppColors.accentGreen
                                  : AppColors.primary,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: AppTextStyles.bodyBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$doneCount of $totalCount tasks done',
                              style: AppTextStyles.bodyBold),
                          if (doneCount == totalCount)
                            Text('All done! Great job!',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.accentGreen))
                          else
                            Text('Keep going!', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: todayTasks.length,
                  itemBuilder: (context, index) {
                    final task = todayTasks[index];
                    final isDone = completedTaskIds.contains(task.taskId);
                    return _TaskTile(
                      task: task,
                      isDone: isDone,
                      onComplete: isDone
                          ? null
                          : () => _completeTask(context, ref, plan, task),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeTask(
    BuildContext context,
    WidgetRef ref,
    PlanModel plan,
    TaskModel task,
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

      // Check full day bonus
      final dayName = _todayDayName();
      final totalTasksToday = plan.tasksForDay(dayName).length;
      final fullDayBonus = await repo.checkFullDayBonus(
        familyId: appUser.familyId!,
        memberId: appUser.memberId!,
        date: _todayDate(),
        totalTasksToday: totalTasksToday,
      );

      ref.invalidate(todayLogsProvider);

      if (context.mounted) {
        final reward =
            RewardCalculator.forTaskCompletion(isHealthy: task.isHealthy);

        if (result.leveledUp) {
          _showEvolutionDialog(context, result);
        } else {
          _showRewardToast(context, task.title, reward,
              fullDayBonus: fullDayBonus);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRewardToast(
    BuildContext context,
    String taskTitle,
    RewardResult reward, {
    RewardResult? fullDayBonus,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _RewardDialog(
        taskTitle: taskTitle,
        coins: reward.coins,
        xp: reward.xp,
        fullDayBonus: fullDayBonus,
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showEvolutionDialog(
      BuildContext context, TaskCompletionResult result) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _EvolutionDialog(
        previousStage: result.previousStage,
        newStage: result.newStage,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final bool isDone;
  final VoidCallback? onComplete;

  const _TaskTile({
    required this.task,
    required this.isDone,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${task.hour.toString().padLeft(2, '0')}:00';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDone ? AppColors.accentGreen.withAlpha(15) : null,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.accentGreen.withAlpha(30)
                : task.category.color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone ? Icons.check : task.category.icon,
            color: isDone ? AppColors.accentGreen : task.category.color,
          ),
        ),
        title: Text(
          task.title,
          style: AppTextStyles.bodyBold.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: Text(
          '$timeStr  •  ${task.duration}min  •  ${task.category.displayName}',
          style: AppTextStyles.caption,
        ),
        trailing: isDone
            ? const Icon(Icons.check_circle, color: AppColors.accentGreen)
            : FilledButton(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Done!',
                    style: TextStyle(fontSize: 13)),
              ),
      ),
    );
  }
}

class _RewardDialog extends StatelessWidget {
  final String taskTitle;
  final int coins;
  final int xp;
  final RewardResult? fullDayBonus;

  const _RewardDialog({
    required this.taskTitle,
    required this.coins,
    required this.xp,
    this.fullDayBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48))
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text('Task Complete!', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(taskTitle, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(
                  icon: Icons.monetization_on,
                  color: AppColors.accent,
                  label: '+$coins',
                ),
                const SizedBox(width: 16),
                _RewardChip(
                  icon: Icons.star,
                  color: AppColors.primary,
                  label: '+$xp XP',
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.3, duration: 400.ms),
            if (fullDayBonus != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('All Tasks Done!',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.accentGreen)),
                    const SizedBox(height: 4),
                    Text(
                      '+${fullDayBonus!.coins} bonus coins, +${fullDayBonus!.xp} bonus XP',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.3, duration: 400.ms),
            ],
          ],
        ),
      )
          .animate()
          .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms),
    );
  }
}

class _EvolutionDialog extends StatelessWidget {
  final int previousStage;
  final int newStage;

  const _EvolutionDialog({
    required this.previousStage,
    required this.newStage,
  });

  @override
  Widget build(BuildContext context) {
    final stageName = GameConstants.evolutionStageNames[newStage - 1];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withAlpha(100), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(40),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 56))
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 16),
            Text('EVOLUTION!', style: AppTextStyles.heading1)
                .animate()
                .fadeIn(delay: 300.ms)
                .shimmer(duration: 1500.ms, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(
              'Your creature evolved to $stageName!',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 500.ms),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  GameConstants.evolutionStageNames[previousStage - 1],
                  style: AppTextStyles.caption,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: AppColors.accent),
                ),
                Text(
                  stageName,
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.accent),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 700.ms)
                .slideX(begin: -0.2, duration: 400.ms),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            )
                .animate()
                .fadeIn(delay: 900.ms),
          ],
        ),
      )
          .animate()
          .scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(duration: 300.ms),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RewardChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodyBold.copyWith(color: color)),
        ],
      ),
    );
  }
}

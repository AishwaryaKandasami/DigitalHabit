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
      await repo.completeTask(
        familyId: appUser.familyId!,
        memberId: appUser.memberId!,
        planId: plan.id,
        date: _todayDate(),
        task: task,
      );

      ref.invalidate(todayLogsProvider);

      if (context.mounted) {
        final reward =
            RewardCalculator.forTaskCompletion(isHealthy: task.isHealthy);
        _showRewardToast(context, task.title, reward);
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
      BuildContext context, String taskTitle, RewardResult reward) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _RewardDialog(
        taskTitle: taskTitle,
        coins: reward.coins,
        xp: reward.xp,
      ),
    );
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
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

  const _RewardDialog({
    required this.taskTitle,
    required this.coins,
    required this.xp,
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
          ],
        ),
      )
          .animate()
          .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/plan_model.dart';
import '../domain/task_category.dart';
import '../providers/planner_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class PlanReviewScreen extends ConsumerWidget {
  const PlanReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPlansProvider);
    final members = ref.watch(familyMembersProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Reviews')),
      body: pendingAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.accentGreen.withAlpha(120)),
                  const SizedBox(height: 12),
                  Text('All caught up!', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text('No plans waiting for approval.',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final child = members
                  .where((m) => m.id == plan.memberId)
                  .firstOrNull;
              final childName = child?.displayName ?? 'Unknown';

              return _PlanReviewCard(
                plan: plan,
                childName: childName,
                onApprove: () => _approve(context, ref, plan),
                onRequestRevision: () =>
                    _requestRevision(context, ref, plan),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, PlanModel plan) async {
    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;
      await ref
          .read(planRepositoryProvider)
          .approvePlan(appUser.familyId!, plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan approved!'),
            backgroundColor: AppColors.accentGreen,
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

  Future<void> _requestRevision(
      BuildContext context, WidgetRef ref, PlanModel plan) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Changes'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'What should they change?',
            labelText: 'Note to child',
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
            child: const Text('Send Back'),
          ),
        ],
      ),
    );

    if (note == null || note.isEmpty) return;

    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;
      await ref
          .read(planRepositoryProvider)
          .requestRevision(appUser.familyId!, plan.id, note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision requested.')),
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

class _PlanReviewCard extends StatelessWidget {
  final PlanModel plan;
  final String childName;
  final VoidCallback onApprove;
  final VoidCallback onRequestRevision;

  const _PlanReviewCard({
    required this.plan,
    required this.childName,
    required this.onApprove,
    required this.onRequestRevision,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate category breakdown
    final categoryMinutes = <TaskCategory, int>{};
    for (final dayTasks in plan.days.values) {
      for (final task in dayTasks) {
        categoryMinutes[task.category] =
            (categoryMinutes[task.category] ?? 0) + task.duration;
      }
    }
    final totalMinutes =
        categoryMinutes.values.fold(0, (sum, m) => sum + m);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$childName's Plan",
                          style: AppTextStyles.heading3),
                      Text('Week of ${plan.weekStart}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${plan.totalTasks} tasks',
                      style: AppTextStyles.label),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category pie chart
            if (totalMinutes > 0) ...[
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: categoryMinutes.entries.map((e) {
                            final pct = e.value / totalMinutes * 100;
                            return PieChartSectionData(
                              color: e.key.color,
                              value: e.value.toDouble(),
                              title: '${pct.round()}%',
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 40,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categoryMinutes.entries.map((e) {
                          final hours =
                              (e.value / 60).toStringAsFixed(1);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: e.key.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${e.key.displayName}: ${hours}h',
                                    style: AppTextStyles.caption,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Daily breakdown row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = PlanModel.dayNames[i];
                final count = plan.tasksForDay(day).length;
                return Column(
                  children: [
                    Text(PlanModel.dayLabels[i],
                        style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: count > 0
                            ? AppColors.primary.withAlpha(count * 30 + 30)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            color: count > 0
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),

            // Health summary
            Row(
              children: [
                const Icon(Icons.eco,
                    size: 16, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text(
                  '${plan.totalHealthyTasks} healthy tasks',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accentGreen),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone_android,
                    size: 16, color: AppColors.accentRed),
                const SizedBox(width: 4),
                Text(
                  '${(plan.totalScreenTimeMinutes / 60).toStringAsFixed(1)}h screen time',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accentRed),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRequestRevision,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Request Changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: const BorderSide(color: AppColors.accentRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

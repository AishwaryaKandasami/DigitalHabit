import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/task_providers.dart';
import '../domain/task_log_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class TaskVerificationScreen extends ConsumerWidget {
  const TaskVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVerificationProvider);
    final members = ref.watch(familyMembersProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Tasks')),
      body: pendingAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified,
                      size: 64,
                      color: AppColors.accentGreen.withAlpha(120)),
                  const SizedBox(height: 12),
                  Text('All tasks verified!', style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text('No tasks waiting for your review.',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          }

          // Group by child
          final grouped = <String, List<TaskLogModel>>{};
          for (final log in logs) {
            grouped.putIfAbsent(log.memberId, () => []).add(log);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              final child = members
                  .where((m) => m.id == entry.key)
                  .firstOrNull;
              final childName = child?.displayName ?? 'Unknown';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        if (child != null)
                          Text(child.avatarState.creatureType.emoji,
                              style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(childName, style: AppTextStyles.heading3),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${entry.value.length} pending',
                              style: AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((log) => _VerificationCard(
                        log: log,
                        onReview: () => _openReviewDialog(context, ref, log),
                        onReject: () => _reject(context, ref, log),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _openReviewDialog(
    BuildContext context,
    WidgetRef ref,
    TaskLogModel log,
  ) async {
    final result = await showDialog<_ReviewResult>(
      context: context,
      builder: (_) => _ReviewDialog(log: log),
    );
    if (result == null) return; // Cancelled

    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;

      await ref.read(taskLogRepositoryProvider).verifyTask(
            familyId: appUser.familyId!,
            memberId: log.memberId,
            log: log,
            approved: true,
            feedback: result.feedback,
            comment: result.comment,
          );

      if (context.mounted) {
        final isNegative = result.feedback == ParentFeedback.negative;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNegative
                ? '${log.title}: gentle note sent 🌱'
                : '${log.title} verified! Bonus awarded.'),
            backgroundColor: isNegative
                ? AppColors.accent
                : AppColors.accentGreen,
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

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TaskLogModel log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject this task?'),
        content: Text(
          'Mark "${log.title}" as not completed. No coins or XP will be '
          'awarded. Use this when the task wasn\'t actually done.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;

      await ref.read(taskLogRepositoryProvider).verifyTask(
            familyId: appUser.familyId!,
            memberId: log.memberId,
            log: log,
            approved: false,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${log.title} rejected.'),
            backgroundColor: AppColors.textSecondary,
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

class _ReviewResult {
  final ParentFeedback? feedback;
  final String? comment;
  const _ReviewResult({this.feedback, this.comment});
}

class _ReviewDialog extends StatefulWidget {
  final TaskLogModel log;
  const _ReviewDialog({required this.log});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  ParentFeedback _feedback = ParentFeedback.positive;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = _feedback == ParentFeedback.negative;
    return AlertDialog(
      title: const Text('Review task'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.log.title, style: AppTextStyles.bodyBold),
              const SizedBox(height: 4),
              Text(widget.log.category.displayName,
                  style: AppTextStyles.caption),
              const SizedBox(height: 20),
              Text('How did they do?', style: AppTextStyles.label),
              const SizedBox(height: 8),
              SegmentedButton<ParentFeedback>(
                segments: const [
                  ButtonSegment(
                    value: ParentFeedback.positive,
                    icon: Icon(Icons.thumb_up),
                    label: Text('Great'),
                  ),
                  ButtonSegment(
                    value: ParentFeedback.negative,
                    icon: Icon(Icons.eco),
                    label: Text('Keep trying'),
                  ),
                ],
                selected: {_feedback},
                onSelectionChanged: (s) =>
                    setState(() => _feedback = s.first),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isNegative
                          ? AppColors.accent
                          : AppColors.accentGreen)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isNegative
                      ? "We'll gently encourage them to try again — no points lost. 🌱"
                      : 'Your kid gets a coin + XP bonus and their creature cheers up! 💛',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'e.g. "Great job finishing on time!"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                maxLength: 140,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ReviewResult(
              feedback: _feedback,
              comment: _commentController.text,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor:
                isNegative ? AppColors.accent : AppColors.accentGreen,
          ),
          child: Text(isNegative ? 'Send a note' : 'Approve'),
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final TaskLogModel log;
  final VoidCallback onReview;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.log,
    required this.onReview,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = log.completedAt.hour.toString().padLeft(2, '0');
    final minStr = log.completedAt.minute.toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: log.category.color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(log.category.icon,
                  color: log.category.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.title, style: AppTextStyles.bodyBold),
                  Text(
                    '${log.category.displayName}  •  Done at $timeStr:$minStr  •  ${log.date}',
                    style: AppTextStyles.caption,
                  ),
                  Row(
                    children: [
                      Icon(
                        log.isHealthy ? Icons.eco : Icons.phone_android,
                        size: 14,
                        color: log.isHealthy
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${log.coinsEarned} coins earned',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review),
                  color: AppColors.accentGreen,
                  tooltip: 'Review & approve',
                ),
                IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel),
                  color: AppColors.accentRed,
                  tooltip: 'Reject (not done)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

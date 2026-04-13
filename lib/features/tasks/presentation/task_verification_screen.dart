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
                        onVerify: () =>
                            _verify(context, ref, log, true),
                        onReject: () =>
                            _verify(context, ref, log, false),
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

  Future<void> _verify(
    BuildContext context,
    WidgetRef ref,
    TaskLogModel log,
    bool approved,
  ) async {
    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;

      await ref.read(taskLogRepositoryProvider).verifyTask(
            familyId: appUser.familyId!,
            memberId: log.memberId,
            log: log,
            approved: approved,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved
                ? '${log.title} verified! Bonus awarded.'
                : '${log.title} rejected.'),
            backgroundColor:
                approved ? AppColors.accentGreen : AppColors.textSecondary,
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

class _VerificationCard extends StatelessWidget {
  final TaskLogModel log;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.log,
    required this.onVerify,
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
                  onPressed: onVerify,
                  icon: const Icon(Icons.check_circle),
                  color: AppColors.accentGreen,
                  tooltip: 'Verify',
                ),
                IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel),
                  color: AppColors.accentRed,
                  tooltip: 'Reject',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

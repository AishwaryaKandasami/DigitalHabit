import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../family/providers/family_providers.dart';
import '../../family/domain/member_model.dart';
import '../../planner/providers/planner_providers.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final children = ref.watch(childMembersProvider);
    final pendingAsync = ref.watch(pendingPlansProvider);
    final pendingCount = pendingAsync.value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              familyAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => Text('Error: $e'),
                data: (family) => Text(
                  family?.name ?? 'My Family',
                  style: AppTextStyles.heading1,
                ),
              ),
              const SizedBox(height: 4),
              Text('Parent Dashboard', style: AppTextStyles.caption),
              const SizedBox(height: 24),

              // Pending approvals banner
              InkWell(
                onTap: pendingCount > 0
                    ? () => context.go('/parent/plans')
                    : null,
                child: Card(
                  color: pendingCount > 0
                      ? AppColors.accentRed.withAlpha(25)
                      : AppColors.accent.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: pendingCount > 0
                                  ? AppColors.accentRed
                                  : AppColors.accent,
                            ),
                            if (pendingCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$pendingCount',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pendingCount > 0
                                    ? '$pendingCount plan${pendingCount > 1 ? 's' : ''} waiting for approval'
                                    : 'No pending plans',
                                style: AppTextStyles.bodyBold,
                              ),
                              Text(
                                pendingCount > 0
                                    ? 'Tap to review'
                                    : 'Plans from your kids will appear here for approval.',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (pendingCount > 0)
                          const Icon(Icons.chevron_right,
                              color: AppColors.accentRed),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Children overview
              Text('Your Kids', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              if (children.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.child_care,
                              size: 48,
                              color: AppColors.textSecondary.withAlpha(100)),
                          const SizedBox(height: 12),
                          Text(
                            'No kids have joined yet',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your family invite code to get started!',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...children
                    .map((child) => _ChildSummaryCard(child: child))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildSummaryCard extends StatelessWidget {
  final MemberModel child;

  const _ChildSummaryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final avatar = child.avatarState;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar mini
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatar.creatureType.color.withAlpha(30),
              ),
              child: Center(
                child: Text(
                  avatar.creatureType.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.displayName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${avatar.level} ${avatar.creatureType.displayName}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text('${child.streakDays}d',
                          style: AppTextStyles.caption),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text('${child.wallet.coins}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            // Today's progress placeholder
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 0,
                    strokeWidth: 4,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accentGreen),
                  ),
                  Center(
                    child:
                        Text('0%', style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

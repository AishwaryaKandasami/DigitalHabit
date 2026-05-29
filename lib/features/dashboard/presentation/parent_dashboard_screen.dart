import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../family/providers/family_providers.dart';
import '../../family/domain/member_model.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../planner/providers/planner_providers.dart';
import '../../tasks/providers/task_providers.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final children = ref.watch(childMembersProvider);
    final pendingPlansAsync = ref.watch(pendingPlansProvider);
    final pendingPlansCount = pendingPlansAsync.value?.length ?? 0;
    final pendingVerifyAsync = ref.watch(pendingVerificationProvider);
    final pendingVerifyCount = pendingVerifyAsync.value?.length ?? 0;

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

              // Action banners row
              Row(
                children: [
                  Expanded(
                    child: _ActionBanner(
                      icon: Icons.pending_actions,
                      count: pendingPlansCount,
                      label: 'Plans to review',
                      emptyLabel: 'No pending plans',
                      color: AppColors.primary,
                      onTap: () => context.go('/parent/plans'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionBanner(
                      icon: Icons.verified_user,
                      count: pendingVerifyCount,
                      label: 'Tasks to verify',
                      emptyLabel: 'All verified',
                      color: AppColors.accentGreen,
                      onTap: () => context.go('/parent/verify'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Send a message — quick mid-day praise / nudge.
              _SendMessageBanner(
                onTap: children.isEmpty
                    ? null
                    : () => showDialog(
                          context: context,
                          builder: (_) => const SendMessageDialog(),
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
                ...children.map((child) => _ChildProgressCard(
                      child: child,
                      onSendMessage: () => showDialog(
                        context: context,
                        builder: (_) =>
                            SendMessageDialog(initialChild: child),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final String emptyLabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionBanner({
    required this.icon,
    required this.count,
    required this.label,
    required this.emptyLabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: hasItems ? color.withAlpha(20) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: hasItems ? color : AppColors.textSecondary),
                  if (hasItems)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
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
              const SizedBox(height: 8),
              Text(
                hasItems ? '$count $label' : emptyLabel,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  final MemberModel child;
  final VoidCallback? onSendMessage;

  const _ChildProgressCard({required this.child, this.onSendMessage});

  @override
  Widget build(BuildContext context) {
    final avatar = child.avatarState;
    final moodColor = avatar.moodScore >= GameConstants.moodHappyThreshold
        ? AppColors.moodHappy
        : avatar.moodScore >= GameConstants.moodNeutralThreshold
            ? AppColors.moodNeutral
            : avatar.moodScore >= GameConstants.moodSadThreshold
                ? AppColors.moodSad
                : AppColors.moodSick;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar mini
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatar.creatureType.color.withAlpha(30),
                    border: Border.all(
                      color: moodColor.withAlpha(100),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      avatar.evolutionStage == 1
                          ? '🥚'
                          : avatar.creatureType.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + stage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.displayName, style: AppTextStyles.bodyBold),
                      Text(
                        'Lv.${avatar.level} ${avatar.evolutionStageName} ${avatar.creatureType.displayName}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                // Coins
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('${child.wallet.coins}',
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (onSendMessage != null)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.primary),
                    tooltip: 'Send a message',
                    onPressed: onSendMessage,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                // Streak
                _SmallStat(
                  icon: Icons.local_fire_department,
                  color: AppColors.accent,
                  value: '${child.streakDays}',
                  label: 'Streak',
                ),
                _SmallStat(
                  icon: Icons.star,
                  color: AppColors.primary,
                  value: '${avatar.totalXp}',
                  label: 'XP',
                ),
                _SmallStat(
                  icon: Icons.emoji_emotions,
                  color: moodColor,
                  value: avatar.moodLabel,
                  label: 'Mood',
                ),
                _SmallStat(
                  icon: Icons.favorite,
                  color: avatar.health > 50
                      ? AppColors.accentGreen
                      : AppColors.accentRed,
                  value: '${avatar.health}%',
                  label: 'Health',
                ),
              ],
            ),

            // XP progress bar
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: avatar.xpToNextLevel > 0
                    ? (avatar.xpForCurrentLevel / avatar.xpToNextLevel)
                        .clamp(0.0, 1.0)
                    : 1.0,
                minHeight: 4,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendMessageBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const _SendMessageBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: enabled ? AppColors.primary.withAlpha(20) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.chat_bubble,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled
                          ? 'Send a message'
                          : 'Add a child to send messages',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Quick praise or a mid-day nudge.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SmallStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

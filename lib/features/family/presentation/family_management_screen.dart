import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/family_providers.dart';
import '../domain/member_model.dart';

class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: familyAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (family) {
          if (family == null) {
            return const Center(child: Text('No family found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Family name
                Text(family.name, style: AppTextStyles.heading2),
                const SizedBox(height: 24),

                // Invite code card
                Card(
                  color: AppColors.primaryLight.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite Code',
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 4),
                              Text(
                                family.inviteCode,
                                style: AppTextStyles.heading2.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: family.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code with your kids to join the family.',
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 32),

                // Members list
                Text('Family Members', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                membersAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Text('Error: $e'),
                  data: (members) => Column(
                    children: members
                        .map((m) => _MemberTile(
                              member: m,
                              onDelete: m.role.name == 'child'
                                  ? () => _deleteMember(context, ref, m)
                                  : null,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteMember(
    BuildContext context,
    WidgetRef ref,
    MemberModel member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Remove "${member.displayName}" from the family? '
          'This will delete their avatar, coins, and all progress. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser?.familyId == null) return;

      await ref
          .read(familyRepositoryProvider)
          .deleteMember(appUser!.familyId!, member.id);

      // Also delete their user profile if they have an authUid
      if (member.authUid != null) {
        await ref
            .read(authRepositoryProvider)
            .deleteUserProfile(member.authUid!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} removed'),
            backgroundColor: AppColors.accentRed,
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

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final VoidCallback? onDelete;

  const _MemberTile({required this.member, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isParent = member.role.name == 'parent';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isParent ? AppColors.primary : member.avatarState.creatureType.color,
          child: Text(
            isParent ? 'P' : member.avatarState.creatureType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyBold),
        subtitle: Text(
          isParent
              ? 'Parent'
              : 'Level ${member.avatarState.level} ${member.avatarState.creatureType.displayName}',
          style: AppTextStyles.caption,
        ),
        trailing: isParent
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${member.wallet.coins} coins',
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.accent),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.accentRed, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Remove member',
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

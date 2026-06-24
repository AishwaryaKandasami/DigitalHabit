import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/family_providers.dart';
import '../domain/member_model.dart';
import 'add_child_dialog.dart';

/// Manage kids (single-login model): children are profiles, not accounts.
/// Add / rename / remove them — no emails or passwords.
class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final children = ref.watch(childMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage kids')),
      floatingActionButton: familyAsync.maybeWhen(
        data: (family) => family == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AddChildDialog(familyId: family.id),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Add child'),
              ),
        orElse: () => null,
      ),
      body: familyAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (family) {
          if (family == null) {
            return const Center(child: Text('No family found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(family.name, style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Each kid is a profile. They pick theirs from "Who\'s playing?" '
                '— no passwords to remember.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 20),
              Text('Kids', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              if (children.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No kids yet. Tap "Add child".',
                        style: AppTextStyles.caption),
                  ),
                )
              else
                ...children.map((m) => _MemberTile(
                      member: m,
                      onDelete: () => _deleteMember(context, ref, m),
                    )),
              const SizedBox(height: 80),
            ],
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
        title: const Text('Remove kid?'),
        content: Text(
          'Remove "${member.displayName}"? This deletes their creature, coins '
          'and progress. This cannot be undone.',
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
  final VoidCallback onDelete;

  const _MemberTile({required this.member, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final avatar = member.avatarState;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatar.creatureType.color.withAlpha(40),
          child: Text(
            avatar.creatureType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyBold),
        subtitle: Text(
          'Lv.${avatar.level} ${avatar.creatureType.displayName}  •  '
          '${member.wallet.coins} coins  •  ${member.streakDays}-day streak',
          style: AppTextStyles.caption,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: AppColors.accentRed, size: 20),
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
      ),
    );
  }
}

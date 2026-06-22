import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../avatar/domain/avatar_state.dart';
import '../../avatar/domain/creature_type.dart';
import '../providers/family_providers.dart';
import '../domain/member_model.dart';

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
                  builder: (_) => _AddChildDialog(familyId: family.id),
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

class _AddChildDialog extends ConsumerStatefulWidget {
  final String familyId;
  const _AddChildDialog({required this.familyId});

  @override
  ConsumerState<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends ConsumerState<_AddChildDialog> {
  final _nameController = TextEditingController();
  CreatureType? _creature;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final avatar = _creature == null
          ? const AvatarState()
          : AvatarState(creatureType: _creature!);
      await ref.read(familyRepositoryProvider).addMember(
            familyId: widget.familyId,
            displayName: name,
            role: UserRole.child,
            avatarState: avatar,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added!')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a kid'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Kid's name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Text('Starter creature (optional)', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text('They can change it later while it\'s still an egg.',
                  style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Let kid pick'),
                    selected: _creature == null,
                    onSelected: (_) => setState(() => _creature = null),
                  ),
                  for (final type in CreatureType.values)
                    ChoiceChip(
                      avatar: Text(type.emoji,
                          style: const TextStyle(fontSize: 16)),
                      label: Text(type.displayName),
                      selected: _creature == type,
                      onSelected: (_) => setState(() => _creature = type),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.accentRed)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
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
            avatar.evolutionStage == 1 ? '🥚' : avatar.creatureType.emoji,
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

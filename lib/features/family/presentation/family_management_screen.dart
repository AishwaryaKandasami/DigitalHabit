import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      floatingActionButton: familyAsync.maybeWhen(
        data: (family) => family == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddChildDialog(context, ref, family.id),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Child'),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Family name
                Text(family.name, style: AppTextStyles.heading2),
                const SizedBox(height: 24),

                // Info card about new email/password flow
                Card(
                  color: AppColors.accent.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kids now log in with email and password. '
                            'Tap "Add Child" to create each kid an account. '
                            'If you previously added kids with the invite code, '
                            'remove them and add them back so they can log in '
                            'from any device.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invite code card (kept for reference, less prominent now)
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
                              Text('Family Invite Code',
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
                              onResetPassword:
                                  m.role.name == 'child' && m.email != null
                                      ? () =>
                                          _resetPassword(context, ref, m)
                                      : null,
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 80), // room under FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddChildDialog(
    BuildContext context,
    WidgetRef ref,
    String familyId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddChildDialog(familyId: familyId),
    );
  }

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
    MemberModel member,
  ) async {
    final email = member.email;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text(
          'Send a password reset link to "$email"? '
          'Firebase will email a reset link to that address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset email sent to $email')),
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

class _AddChildDialog extends ConsumerStatefulWidget {
  final String familyId;
  const _AddChildDialog({required this.familyId});

  @override
  ConsumerState<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends ConsumerState<_AddChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  CreatureType? _creature;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final familyRepo = ref.read(familyRepositoryProvider);

      // 1. Create the child's auth account (secondary app, parent stays signed in).
      final kidUser = await authRepo.createChildAccount(email, password);

      // 2. Create member doc in the family.
      final initialAvatar = _creature == null
          ? const AvatarState()
          : AvatarState(creatureType: _creature!);

      final member = await familyRepo.addMember(
        familyId: widget.familyId,
        displayName: name,
        role: UserRole.child,
        authUid: kidUser.uid,
        email: email,
        avatarState: initialAvatar,
      );

      // 3. Save userProfiles/{uid} mapping so login redirects correctly.
      await authRepo.saveUserProfile(AppUser(
        uid: kidUser.uid,
        email: email,
        familyId: widget.familyId,
        memberId: member.id,
        role: UserRole.child,
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name added. They can log in with $email.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered. Use a different email for this kid.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return e.message ?? e.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Child'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Give your kid their own login. Use a real email address you '
                  'control — password resets will be sent there.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kid\'s name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g. bella@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Starter creature (optional)',
                    style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  'Leave blank to let them pick on first login.',
                  style: AppTextStyles.caption,
                ),
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
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.accentRed),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Child'),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final VoidCallback? onDelete;
  final VoidCallback? onResetPassword;

  const _MemberTile({
    required this.member,
    this.onDelete,
    this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isParent = member.role.name == 'parent';
    final subtitle = isParent
        ? 'Parent'
        : [
            'Level ${member.avatarState.level} ${member.avatarState.creatureType.displayName}',
            if (member.email != null) member.email!,
          ].join('\n');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: !isParent && member.email != null,
        leading: CircleAvatar(
          backgroundColor:
              isParent ? AppColors.primary : member.avatarState.creatureType.color,
          child: Text(
            isParent ? 'P' : member.avatarState.creatureType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyBold),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
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
                  if (onResetPassword != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.lock_reset,
                          color: AppColors.primary, size: 20),
                      onPressed: onResetPassword,
                      tooltip: 'Send password reset email',
                    ),
                  ],
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.accentRed, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Remove member',
                    ),
                ],
              ),
      ),
    );
  }
}

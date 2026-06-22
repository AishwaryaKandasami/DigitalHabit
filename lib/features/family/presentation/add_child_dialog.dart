import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/domain/app_user.dart';
import '../../avatar/domain/avatar_state.dart';
import '../../avatar/domain/creature_type.dart';
import '../providers/family_providers.dart';

/// Add a child profile (single-login model: a profile, not an account).
/// Used from both the grown-up "Manage kids" screen and the profile picker.
class AddChildDialog extends ConsumerStatefulWidget {
  final String familyId;
  const AddChildDialog({super.key, required this.familyId});

  @override
  ConsumerState<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends ConsumerState<AddChildDialog> {
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
      final member = await ref.read(familyRepositoryProvider).addMember(
            familyId: widget.familyId,
            displayName: name,
            role: UserRole.child,
            avatarState: avatar,
          );
      if (mounted) {
        Navigator.pop(context, member.id);
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
                autofocus: true,
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

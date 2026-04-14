import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/avatar_state.dart';
import '../domain/creature_type.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class ChooseAvatarScreen extends ConsumerStatefulWidget {
  const ChooseAvatarScreen({super.key});

  @override
  ConsumerState<ChooseAvatarScreen> createState() =>
      _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends ConsumerState<ChooseAvatarScreen> {
  CreatureType? _selected;
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Prefill the form from the current member (edit-mode), if available.
  /// Runs on every build until it successfully hydrates once, because
  /// `currentMemberProvider` may be null on first frame while Firestore loads.
  void _maybePrefill() {
    if (_prefilled) return;
    final member = ref.read(currentMemberProvider);
    if (member == null) return;
    _selected = member.avatarState.creatureType;
    _nameController.text = member.avatarState.creatureName;
    _prefilled = true;
  }

  Future<void> _confirm() async {
    if (_selected == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a creature and give it a name!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Read directly from Firebase Auth + Firestore to avoid provider timing issues
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not signed in. Please go back and try again.')),
          );
        }
        return;
      }

      final authRepo = ref.read(authRepositoryProvider);
      final appUser = await authRepo.getUserProfile(firebaseUser.uid);
      if (appUser == null || appUser.familyId == null || appUser.memberId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile not ready. Please go back and try again.')),
          );
        }
        return;
      }

      final familyRepo = ref.read(familyRepositoryProvider);

      // Edit-mode safety: if the member already exists and has hatched past
      // the egg, refuse to overwrite. (Shouldn't normally reach here because
      // the entry button is hidden, but don't trust the client.)
      final currentMember = ref.read(currentMemberProvider);
      if (currentMember != null &&
          currentMember.avatarState.evolutionStage > 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your creature already hatched — it can\'t be changed now.'),
            ),
          );
        }
        return;
      }

      // Preserve XP / mood / health / accessories when editing. Fall back to
      // a fresh state when there's no existing member (first-login path).
      final AvatarState avatar = currentMember != null
          ? currentMember.avatarState.copyWith(
              creatureName: _nameController.text.trim(),
              creatureType: _selected!,
            )
          : AvatarState(
              creatureName: _nameController.text.trim(),
              creatureType: _selected!,
              moodScore: 75,
              health: 100,
              evolutionStage: 1,
              level: 1,
            );

      await familyRepo.updateMember(
        appUser.familyId!,
        appUser.memberId!,
        {'avatarState': avatar.toMap()},
      );

      ref.invalidate(familyMembersProvider);
      if (mounted) context.go('/kid');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the provider alive so changes during loading still hydrate the form.
    ref.watch(familyMembersProvider);
    _maybePrefill();

    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Hatching your creature...'),
      );
    }

    // If the kid has already hatched, block the edit flow with a friendly
    // message instead of allowing silent overwrite.
    final member = ref.watch(currentMemberProvider);
    final alreadyHatched =
        member != null && member.avatarState.evolutionStage > 1;
    if (alreadyHatched) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Your Creature')),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Your creature already hatched!',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can\'t change ${member.avatarState.creatureName} anymore — keep going and watch it grow.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/kid/avatar'),
                child: const Text('Back to my avatar'),
              ),
            ],
          ),
        ),
      );
    }

    final isEditMode =
        member != null && member.avatarState.creatureName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Change Your Creature' : 'Choose Your Creature'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditMode ? 'Pick a new look!' : 'Pick your companion!',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isEditMode
                  ? 'You can change your creature until it hatches. Your XP, coins and items stay the same.'
                  : 'Your creature will grow as you build healthy habits.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Creature grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: CreatureType.values
                  .map((type) => _CreatureCard(
                        type: type,
                        isSelected: _selected == type,
                        onTap: () => setState(() => _selected = type),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name your creature',
                hintText: 'e.g. Sparky, Luna, Blaze',
                prefixIcon: Icon(Icons.edit),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _confirm,
              child: Text(isEditMode ? 'Save Changes' : "Let's Go!"),
            ),
            if (isEditMode) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/kid/avatar'),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatureCard extends StatelessWidget {
  final CreatureType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _CreatureCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? type.color.withAlpha(30)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? type.color : AppColors.surfaceVariant,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: type.color.withAlpha(40),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? type.color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

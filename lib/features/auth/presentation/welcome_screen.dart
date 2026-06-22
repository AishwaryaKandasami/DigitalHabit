import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../avatar/domain/avatar_state.dart';
import '../../avatar/domain/creature_type.dart';
import '../../family/providers/family_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../domain/app_user.dart';
import '../providers/auth_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  /// Guest / explore mode: spin up a throwaway anonymous family with one
  /// child so every feature works, then drop straight into the app. No PIN,
  /// no account — data lives only on this device.
  Future<void> _continueAsGuest() async {
    setState(() => _busy = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final familyRepo = ref.read(familyRepositoryProvider);

      final user = await authRepo.signInAnonymously();
      final family = await familyRepo.createFamily(
        name: 'My Family',
        parentUid: user.uid,
      );
      final child = await familyRepo.addMember(
        familyId: family.id,
        displayName: 'Explorer',
        role: UserRole.child,
        avatarState: const AvatarState(
          creatureName: 'Buddy',
          creatureType: CreatureType.fireFox,
        ),
      );
      await ref.read(shopRepositoryProvider).seedShopItems(family.id);
      await authRepo.saveUserProfile(
        AppUser(uid: user.uid, email: null, familyId: family.id),
      );

      ref.invalidate(appUserProvider);
      await ref.read(appUserProvider.future);
      ref.invalidate(familyMembersProvider);
      ref.read(activeMemberIdProvider.notifier).set(child.id);

      if (mounted) context.go('/kid');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start guest mode: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 72)),
                ),
              ),
              const SizedBox(height: 32),
              Text('Habit Quest', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Build healthy habits,\ngrow your creature!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Already have an account? Log in'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _continueAsGuest,
                  child: Text(
                    'Just looking? Explore as guest →',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              // Sign-out escape hatch if a session is stuck.
              if (firebaseUser != null && !_busy) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    ref.invalidate(appUserProvider);
                    ref.invalidate(authStateProvider);
                  },
                  child: Text(
                    'Sign out (${firebaseUser.email ?? 'guest'})',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accentRed),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

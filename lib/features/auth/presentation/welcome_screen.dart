import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App logo / creature preview
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
              const SizedBox(height: 16),
              Text(
                'Parents set up here. Kids log in with the email\ntheir parent made for them.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("I'm a Parent"),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Log in'),
                ),
              ),
              // Show sign out if user is stuck in a logged-in state
              if (firebaseUser != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    ref.invalidate(appUserProvider);
                    ref.invalidate(authStateProvider);
                  },
                  child: Text(
                    'Sign out (${firebaseUser.email ?? 'anonymous'})',
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

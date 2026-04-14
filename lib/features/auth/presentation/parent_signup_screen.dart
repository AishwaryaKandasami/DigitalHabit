import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../domain/app_user.dart';

class ParentSignupScreen extends ConsumerStatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  ConsumerState<ParentSignupScreen> createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends ConsumerState<ParentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _familyNameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final familyRepo = ref.read(familyRepositoryProvider);

      User user;
      try {
        // 1. Try creating a new account
        user = await authRepo.signUpParent(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists — try signing in instead
          try {
            user = await authRepo.signIn(
              _emailController.text.trim(),
              _passwordController.text,
            );

            // Check if they already have a profile
            final existing = await authRepo.getUserProfile(user.uid);
            if (existing != null && existing.familyId != null) {
              // Already fully set up — just go to dashboard
              ref.invalidate(appUserProvider);
              await ref.read(appUserProvider.future);
              if (mounted) context.go('/parent');
              return;
            }
            // Profile doc missing — try to recover from existing family data
            // before creating a duplicate family.
            final recovered = await authRepo.recoverUserProfile(user);
            if (recovered != null && recovered.familyId != null) {
              ref.invalidate(appUserProvider);
              await ref.read(appUserProvider.future);
              if (mounted) context.go('/parent');
              return;
            }
            // Nothing to recover — continue to create family below
          } catch (_) {
            setState(() => _error =
                'This email is already registered. Try logging in with the correct password.');
            return;
          }
        } else {
          rethrow;
        }
      }

      // 2. Create family in Firestore
      final family = await familyRepo.createFamily(
        name: _familyNameController.text.trim(),
        parentUid: user.uid,
      );

      // 3. Create parent member in family
      final member = await familyRepo.addMember(
        familyId: family.id,
        displayName: 'Parent',
        role: UserRole.parent,
        authUid: user.uid,
      );

      // 4. Seed shop items for the new family
      await ref.read(shopRepositoryProvider).seedShopItems(family.id);

      // 5. Save user profile mapping
      await authRepo.saveUserProfile(AppUser(
        uid: user.uid,
        email: user.email,
        familyId: family.id,
        memberId: member.id,
        role: UserRole.parent,
      ));

      // 6. Invalidate providers and wait for refetch
      ref.invalidate(appUserProvider);
      await ref.read(appUserProvider.future);

      if (mounted) context.go('/parent');
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in instead.';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Sign Up')),
      body: _isLoading
          ? const LoadingWidget(message: 'Setting up your family...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create Your Family', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your account and family to get started.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
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
                    TextFormField(
                      controller: _familyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Family Name',
                        hintText: 'e.g. The Smiths',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.accentRed),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _signUp,
                      child: const Text('Create Family'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

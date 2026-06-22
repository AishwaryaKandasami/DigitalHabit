import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';
import '../../shop/providers/shop_providers.dart';
import '../domain/app_user.dart';

/// Create the single family account, the first child profile, and the
/// grown-up PIN — all in one step. No separate child logins.
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
  final _childNameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _familyNameController.dispose();
    _childNameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _refreshAppUser() async {
    ref.invalidate(appUserProvider);
    await ref.read(appUserProvider.future);
    ref.invalidate(familyMembersProvider);
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
        user = await authRepo.signUpParent(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        // The account already exists — sign in to finish (or repair) setup.
        // This recovers the common case where the Firestore family was wiped
        // but the auth user still exists.
        try {
          user = await authRepo.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } on FirebaseAuthException {
          setState(() => _error =
              'That email is already registered. Enter its existing password '
              'here to finish setup, or use "Log in".');
          return;
        }
        // Already fully set up → go straight in. Otherwise fall through and
        // create the family for this signed-in account.
        final existing = await authRepo.getUserProfile(user.uid) ??
            await authRepo.recoverUserProfile(user);
        if (existing != null && existing.familyId != null) {
          await _refreshAppUser();
          if (mounted) context.go('/kid');
          return;
        }
      }

      // 1. Create the family (with the grown-up PIN).
      final family = await familyRepo.createFamily(
        name: _familyNameController.text.trim(),
        parentUid: user.uid,
        grownupPin: _pinController.text.trim(),
      );

      // 2. Create the first child profile (no auth account).
      final child = await familyRepo.addMember(
        familyId: family.id,
        displayName: _childNameController.text.trim(),
        role: UserRole.child,
      );

      // 3. Seed shop items.
      await ref.read(shopRepositoryProvider).seedShopItems(family.id);

      // 4. Save the account → family mapping.
      await authRepo.saveUserProfile(AppUser(
        uid: user.uid,
        email: user.email,
        familyId: family.id,
      ));

      // 5. Refresh, select the new child, go pick their creature.
      await _refreshAppUser();
      ref.read(activeMemberIdProvider.notifier).set(child.id);

      if (mounted) context.go('/choose-avatar');
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
      appBar: AppBar(title: const Text('Create Your Family')),
      body: _isLoading
          ? const LoadingWidget(message: 'Setting up your family...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome!', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'One login for the whole family. Your kids each get a '
                      'profile — no separate passwords.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    Text('Grown-up account', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Your email',
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
                        labelText: 'Family name',
                        hintText: 'e.g. The Smiths',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'Grown-up PIN (4 digits)',
                        hintText: 'Keeps kids out of settings',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) =>
                          v == null || v.length != 4 ? 'Enter 4 digits' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('First child', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _childNameController,
                      decoration: const InputDecoration(
                        labelText: "Child's name",
                        prefixIcon: Icon(Icons.child_care),
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
                    const SizedBox(height: 28),
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

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

      // 1. Create Firebase Auth account
      final user = await authRepo.signUpParent(
        _emailController.text.trim(),
        _passwordController.text,
      );

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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating your family...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome, Parent!', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your family to get started.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _familyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Family Name',
                        hintText: 'e.g. The Sharma Family',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
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
                  ],
                ),
              ),
            ),
    );
  }
}

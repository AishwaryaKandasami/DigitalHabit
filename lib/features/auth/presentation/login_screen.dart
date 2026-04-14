import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Wait for profile to load
      ref.invalidate(appUserProvider);
      var appUser = await ref.read(appUserProvider.future);

      // Recovery path: auth succeeded but no userProfile mapping doc exists.
      // This typically means an earlier signup was interrupted after the
      // family/member were created. Rebuild the profile from Firestore data.
      if (appUser == null) {
        appUser = await authRepo.recoverUserProfile(user);
        if (appUser != null) {
          ref.invalidate(appUserProvider);
          await ref.read(appUserProvider.future);
        }
      }

      if (!mounted) return;
      if (appUser == null) {
        // No family found anywhere — genuinely needs to sign up.
        setState(() => _error =
            'Account exists but we could not find your family. Please sign up to complete setup.');
        return;
      }

      if (appUser.isParent) {
        context.go('/parent');
      } else {
        // First-time kid (no creature name yet) → choose-avatar onboarding.
        final familyId = appUser.familyId;
        final memberId = appUser.memberId;
        var goTo = '/kid';
        if (familyId != null && memberId != null) {
          final familyRepo = ref.read(familyRepositoryProvider);
          final member = await familyRepo.getMember(familyId, memberId);
          if (member != null && member.avatarState.creatureName.isEmpty) {
            goTo = '/choose-avatar';
          }
        }
        if (!mounted) return;
        context.go(goTo);
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Wrong email or password. Please try again.';
    }
    if (error.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: _isLoading
          ? const LoadingWidget(message: 'Logging in...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome Back!', style: AppTextStyles.heading2),
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
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
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
                      onPressed: _login,
                      child: const Text('Log In'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text("Don't have an account? Sign up"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

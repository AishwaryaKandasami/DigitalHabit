import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/auth_providers.dart';
import '../domain/app_user.dart';
import '../../family/providers/family_providers.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final familyRepo = ref.read(familyRepositoryProvider);

      // 1. Find family by invite code
      final family = await familyRepo.findByInviteCode(
        _codeController.text.trim().toUpperCase(),
      );
      if (family == null) {
        setState(() => _error = 'Invalid invite code. Please try again.');
        return;
      }

      // 2. Sign in anonymously
      final user = await authRepo.signInAnonymously();

      // 3. Add child member to family
      final member = await familyRepo.addMember(
        familyId: family.id,
        displayName: _nameController.text.trim(),
        role: UserRole.child,
        authUid: user.uid,
      );

      // 4. Save user profile
      await authRepo.saveUserProfile(AppUser(
        uid: user.uid,
        familyId: family.id,
        memberId: member.id,
        role: UserRole.child,
      ));

      ref.invalidate(appUserProvider);
      // Wait for provider to resolve before navigating
      await ref.read(appUserProvider.future);

      if (mounted) context.go('/choose-avatar');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Family')),
      body: _isLoading
          ? const LoadingWidget(message: 'Joining family...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Join Your Family!', style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Ask your parent for the family invite code.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'What should we call you?',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Invite Code',
                        hintText: 'e.g. ABC123',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 6) return 'Code must be 6 characters';
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
                      onPressed: _joinFamily,
                      child: const Text('Join Family'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

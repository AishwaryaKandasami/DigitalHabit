import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../family/presentation/add_child_dialog.dart';
import '../../family/providers/family_providers.dart';
import '../providers/auth_providers.dart';

/// "Who's playing?" — pick the active child profile (single login, many kids).
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's playing?"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tap your profile', style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    for (final child in children)
                      _ProfileCard(
                        name: child.displayName,
                        emoji: child.avatarState.creatureType.emoji,
                        color: child.avatarState.creatureType.color,
                        onTap: () {
                          ref
                              .read(activeMemberIdProvider.notifier)
                              .set(child.id);
                          context.go('/kid');
                        },
                      ),
                    _AddProfileCard(onTap: () => _addChild(context, ref)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/grownups'),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Grown-ups'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addChild(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(appUserProvider).value?.familyId;
    if (familyId == null) return;
    final newId = await showDialog<String>(
      context: context,
      builder: (_) => AddChildDialog(familyId: familyId),
    );
    // Auto-select the newly added child and jump in.
    if (newId != null && context.mounted) {
      ref.read(activeMemberIdProvider.notifier).set(newId);
      context.go('/kid');
    }
  }
}

class _AddProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textSecondary.withAlpha(80),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 56, color: AppColors.textSecondary.withAlpha(150)),
            const SizedBox(height: 8),
            Text('Add a child', style: AppTextStyles.bodyBold),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(100), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(name, style: AppTextStyles.bodyBold),
          ],
        ),
      ),
    );
  }
}

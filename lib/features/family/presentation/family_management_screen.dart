import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/family_providers.dart';
import '../domain/member_model.dart';

class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: familyAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (family) {
          if (family == null) {
            return const Center(child: Text('No family found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Family name
                Text(family.name, style: AppTextStyles.heading2),
                const SizedBox(height: 24),

                // Invite code card
                Card(
                  color: AppColors.primaryLight.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite Code',
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 4),
                              Text(
                                family.inviteCode,
                                style: AppTextStyles.heading2.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: family.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code with your kids to join the family.',
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 32),

                // Members list
                Text('Family Members', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                membersAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Text('Error: $e'),
                  data: (members) => Column(
                    children: members.map((m) => _MemberTile(member: m)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberModel member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isParent = member.role.name == 'parent';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isParent ? AppColors.primary : member.avatarState.creatureType.color,
          child: Text(
            isParent ? 'P' : member.avatarState.creatureType.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyBold),
        subtitle: Text(
          isParent ? 'Parent' : 'Level ${member.avatarState.level} ${member.avatarState.creatureType.displayName}',
          style: AppTextStyles.caption,
        ),
        trailing: isParent
            ? null
            : Text(
                '${member.wallet.coins} coins',
                style: AppTextStyles.label.copyWith(color: AppColors.accent),
              ),
      ),
    );
  }
}

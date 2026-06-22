import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../family/providers/family_providers.dart';
import '../../family/domain/member_model.dart';
import '../../messages/presentation/send_message_dialog.dart';

/// Grown-up monitoring view (shown after the PIN gate). Passive: it shows each
/// child's progress and lets the grown-up add a child, set the PIN, send an
/// encouragement message, or jump in as a child. No approval/verification.
class GrownupMonitorScreen extends ConsumerWidget {
  const GrownupMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyProvider);
    final children = ref.watch(childMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grown-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pin_outlined),
            tooltip: 'Change PIN',
            onPressed: () => _changePin(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              familyAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => Text('Error: $e'),
                data: (family) => Text(
                  family?.name ?? 'My Family',
                  style: AppTextStyles.heading1,
                ),
              ),
              const SizedBox(height: 4),
              Text('Watch your kids build their habits.',
                  style: AppTextStyles.caption),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/grownups/family'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Manage kids'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: children.isEmpty
                          ? null
                          : () => showDialog(
                                context: context,
                                builder: (_) => const SendMessageDialog(),
                              ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send message'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text('Your Kids', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              if (children.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.child_care,
                              size: 48,
                              color: AppColors.textSecondary.withAlpha(100)),
                          const SizedBox(height: 12),
                          Text('No kids yet',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Tap "Manage kids" to add one.',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...children.map((child) => _ChildProgressCard(
                      child: child,
                      onPlayAs: () {
                        ref
                            .read(activeMemberIdProvider.notifier)
                            .set(child.id);
                        context.go('/kid');
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final appUser = ref.read(familyProvider).value;
    if (appUser == null) return;
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set grown-up PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '4-digit PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (pin == null || pin.length != 4) return;
    try {
      await ref
          .read(familyRepositoryProvider)
          .setGrownupPin(appUser.id, pin);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN updated.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ChildProgressCard extends StatelessWidget {
  final MemberModel child;
  final VoidCallback onPlayAs;

  const _ChildProgressCard({required this.child, required this.onPlayAs});

  @override
  Widget build(BuildContext context) {
    final avatar = child.avatarState;
    final moodColor = avatar.moodScore >= GameConstants.moodHappyThreshold
        ? AppColors.moodHappy
        : avatar.moodScore >= GameConstants.moodNeutralThreshold
            ? AppColors.moodNeutral
            : AppColors.moodSad;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatar.creatureType.color.withAlpha(30),
                    border: Border.all(color: moodColor.withAlpha(100), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      avatar.evolutionStage == 1
                          ? '🥚'
                          : avatar.creatureType.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.displayName, style: AppTextStyles.bodyBold),
                      Text(
                        'Lv.${avatar.level} ${avatar.evolutionStageName} ${avatar.creatureType.displayName}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onPlayAs,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Open'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SmallStat(
                  icon: Icons.local_fire_department,
                  color: AppColors.accent,
                  value: '${child.streakDays}',
                  label: 'Streak',
                ),
                _SmallStat(
                  icon: Icons.star,
                  color: AppColors.primary,
                  value: '${avatar.totalXp}',
                  label: 'XP',
                ),
                _SmallStat(
                  icon: Icons.monetization_on,
                  color: AppColors.accent,
                  value: '${child.wallet.coins}',
                  label: 'Coins',
                ),
                _SmallStat(
                  icon: Icons.emoji_emotions,
                  color: moodColor,
                  value: avatar.moodLabel,
                  label: 'Mood',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SmallStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

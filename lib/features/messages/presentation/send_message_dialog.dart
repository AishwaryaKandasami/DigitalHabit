import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/domain/member_model.dart';
import '../../family/providers/family_providers.dart';
import '../domain/message_model.dart';
import '../providers/message_providers.dart';

/// Quick templates shown as tap-to-fill chips. Keep the lists short so the
/// dialog stays a single screen.
const _praiseTemplates = [
  "Great job! 🎉",
  "So proud of you!",
  "Loved your effort today!",
  "Keep it up!",
];
const _nudgeTemplates = [
  "Don't forget your reading time!",
  "Time to take a break! 🌿",
  "Come back to your tasks 🙂",
  "Almost done — finish strong!",
];

class SendMessageDialog extends ConsumerStatefulWidget {
  /// Optional: pre-select a specific kid (when opened from a child row).
  final MemberModel? initialChild;

  const SendMessageDialog({super.key, this.initialChild});

  @override
  ConsumerState<SendMessageDialog> createState() =>
      _SendMessageDialogState();
}

class _SendMessageDialogState extends ConsumerState<SendMessageDialog> {
  MemberModel? _selectedChild;
  MessageKind _kind = MessageKind.praise;
  final _textController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.initialChild;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Resolve the recipient for this send: explicit selection wins, else
  /// fall back to the single child when there's only one in the family.
  MemberModel? _resolveRecipient(List<MemberModel> children) {
    if (_selectedChild != null &&
        children.any((c) => c.id == _selectedChild!.id)) {
      return _selectedChild;
    }
    if (children.length == 1) return children.first;
    return null;
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    final children = ref.read(childMembersProvider);
    final recipient = _resolveRecipient(children);

    if (recipient == null) {
      setState(() => _error = children.isEmpty
          ? 'No kids in this family yet.'
          : 'Pick a child to message.');
      return;
    }
    if (text.isEmpty) {
      setState(() => _error = 'Type or tap a quick message.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final appUser = ref.read(appUserProvider).value;
      if (appUser == null) return;
      await ref.read(messageRepositoryProvider).sendMessage(
            familyId: appUser.familyId!,
            toMemberId: recipient.id,
            fromUid: appUser.uid,
            fromName: 'Parent',
            text: text,
            kind: _kind,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent to ${recipient.displayName}.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childMembersProvider);
    // Ensure _selectedChild is still valid after a refresh.
    if (_selectedChild != null &&
        !children.any((c) => c.id == _selectedChild!.id)) {
      _selectedChild = null;
    }
    // If there's only one kid in the family, auto-select them so the Send
    // button works without an extra tap.
    if (_selectedChild == null && children.length == 1) {
      _selectedChild = children.first;
    }

    final templates = _kind == MessageKind.praise
        ? _praiseTemplates
        : _nudgeTemplates;

    return AlertDialog(
      title: const Text('Send a message'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Child picker
              if (children.isEmpty)
                Text('No kids in this family yet.',
                    style: AppTextStyles.caption)
              else if (children.length == 1) ...[
                Text('To: ${children.first.displayName}',
                    style: AppTextStyles.label),
                const SizedBox(height: 8),
              ] else ...[
                Text('Send to:', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: children
                      .map((c) => ChoiceChip(
                            label: Text(c.displayName),
                            avatar: Text(c.avatarState.creatureType.emoji,
                                style: const TextStyle(fontSize: 16)),
                            selected: _selectedChild?.id == c.id,
                            onSelected: (_) =>
                                setState(() => _selectedChild = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Kind toggle
              Text('Kind of message:', style: AppTextStyles.label),
              const SizedBox(height: 4),
              SegmentedButton<MessageKind>(
                segments: const [
                  ButtonSegment(
                    value: MessageKind.praise,
                    icon: Icon(Icons.celebration),
                    label: Text('Praise'),
                  ),
                  ButtonSegment(
                    value: MessageKind.nudge,
                    icon: Icon(Icons.notifications_active),
                    label: Text('Nudge'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),

              // Templates
              Text('Quick messages:', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: templates
                    .map((t) => ActionChip(
                          label: Text(t),
                          onPressed: () => setState(() {
                            _textController.text = t;
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Free text
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: 200,
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: AppColors.accentRed)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _sending || children.isEmpty ? null : _send,
          icon: const Icon(Icons.send),
          label: Text(_sending ? 'Sending…' : 'Send'),
        ),
      ],
    );
  }
}

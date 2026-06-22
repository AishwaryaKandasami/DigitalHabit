import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/family_providers.dart';
import '../../dashboard/presentation/grownup_monitor_screen.dart';

/// PIN gate for the grown-up area. Shows the monitor once unlocked. If no PIN
/// is set yet, lets the grown-up set one.
class GrownupGateScreen extends ConsumerStatefulWidget {
  const GrownupGateScreen({super.key});

  @override
  ConsumerState<GrownupGateScreen> createState() => _GrownupGateScreenState();
}

class _GrownupGateScreenState extends ConsumerState<GrownupGateScreen> {
  final _pinController = TextEditingController();
  bool _unlocked = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit(String? currentPin, String familyId) async {
    final entered = _pinController.text.trim();
    if (entered.length != 4) {
      setState(() => _error = 'Enter 4 digits');
      return;
    }
    final hasPin = currentPin != null && currentPin.isNotEmpty;
    if (hasPin) {
      if (entered == currentPin) {
        setState(() {
          _unlocked = true;
          _error = null;
        });
      } else {
        setState(() => _error = 'Wrong PIN');
      }
    } else {
      // First time: set this PIN.
      try {
        await ref
            .read(familyRepositoryProvider)
            .setGrownupPin(familyId, entered);
        if (mounted) setState(() => _unlocked = true);
      } catch (e) {
        setState(() => _error = 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const GrownupMonitorScreen();

    final familyAsync = ref.watch(familyProvider);
    final family = familyAsync.value;
    final currentPin = family?.settings.grownupPin;
    final hasPin = currentPin != null && currentPin.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups only')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                hasPin ? 'Enter the grown-up PIN' : 'Set a 4-digit PIN',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasPin
                    ? 'This keeps kids out of settings.'
                    : 'You\'ll use this to open the grown-up area.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onSubmitted: (_) =>
                    _submit(currentPin, family?.id ?? ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: AppColors.accentRed),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: family == null
                    ? null
                    : () => _submit(currentPin, family.id),
                child: Text(hasPin ? 'Unlock' : 'Set PIN'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/kid'),
                child: const Text('Back to kid'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/garden_providers.dart';
import 'widgets/garden_scene.dart';

/// The Garden tab — shows the active child's per-habit garden.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garden = ref.watch(gardenStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Garden')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GardenScene(garden: garden),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(
                  garden.isEmpty
                      ? 'Each habit you keep grows its own plant. Do a mix of '
                          'habits to grow a full, varied garden!'
                      : 'Every day you keep a habit, its plant grows a little. '
                          'Keep going to reach full bloom!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../family/providers/family_providers.dart';
import '../application/garden_builder.dart';
import '../domain/garden_state.dart';

/// The active child's garden, derived purely from their member doc. Recomputes
/// whenever the member changes (e.g. after a task completion bumps gardenDays).
final gardenStateProvider = Provider<GardenState>((ref) {
  final member = ref.watch(currentMemberProvider);
  if (member == null) return const GardenState();
  return GardenBuilder.build(member: member, now: DateTime.now());
});

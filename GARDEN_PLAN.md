# Plan: Rive-powered Habit Garden (a plant per habit)

> Status: approved 2026-06-22 — implementation deferred.

## Context

Habit Quest already grows a creature avatar from cumulative XP, but **nothing visualizes the kid's day-to-day consistency** — the "showed up and finished my plan" signal that is the actual habit the app is trying to build. The next phase adds a **Garden**: an immersive scene planted with **a different kind of plant for each habit type** — Exercise grows a fruit tree, Study a flower, Chores vegetables, Creative tulips, Social a flowering bush, Sleep a climbing creeper. Each plant advances through its own lifecycle (seed → sprout → leaves → flower/fruit) the more consistently the kid does *that* habit, so a balanced set of habits grows a varied, lush garden — and a lopsided week is visible as one tall plant beside bare beds. A 7-day streak (already rewarded in code but invisible) brightens the whole garden.

Decisions locked with the user:
- **Rive now**, using **free Rive Community assets**, swapping custom art later.
- **Scope: garden scene only.** The creature stays the existing emoji `AvatarDisplay` (a Rive creature = 5 types × 5 stages = 25 animations, out of scope until custom art exists).
- **Variety model: each `TaskCategory` grows its own plant species** (chosen over unlock/collection or cosmetic-only).

Hard reality this plan respects: `.riv` files are authored in the Rive editor and **cannot be generated in code**. We wire the real Rive runtime against sourced community `.riv` assets; the wrapper degrades gracefully because a community asset won't expose our exact state-machine inputs.

Design constraints carried from the existing app:
- **All-positive tone** (`moodDailyDecay = 0`, no penalties): per-plant growth is **monotonic** — missed days never shrink or kill any plant; a miss only resets the *streak* (the sun dims gently) and resumes on return.
- **Screen-time guardrail**: growth is once per day per habit, tied to real completion (can't be grinded in-app); a check-in is a glance.

## Approach

New feature module `lib/features/garden/`, mirroring the existing `features/*` layout. All "what grows" logic is pure and lives outside the widgets, so the later Rive→custom-art swap (or a Rive→code fallback) touches nothing else.

### 1. Domain — a plant per habit (pure, testable)
- `lib/features/garden/domain/garden_plant.dart` — `GardenPlant { TaskCategory category, PlantSpecies species, int growth }` and `enum PlantSpecies { tree, flower, veggies, creeper, bush, tulips }`. A `const Map<TaskCategory, PlantSpecies>` assigns a species per habit (exercise→tree, study→flower, chores→veggies, creative→tulips, social→bush, sleep→creeper; `custom`→flower; `screenTime` excluded — it's the unhealthy category).
- `lib/features/garden/domain/garden_state.dart` — `GardenState { List<GardenPlant> plants; int streakDays; int evolutionStage; int moodScore; int health }`.
- `lib/features/garden/application/garden_builder.dart` — pure `GardenState buildGarden({required MemberModel member, required DateTime now})`: reads `member.gardenDays` (a `Map<String,int>` of category-name → cumulative completed days), maps each healthy category present to a `GardenPlant` whose `growth` follows a stage curve; pulls streak/mood/health/stage from `member`. Monotonic by construction (never shrinks).

### 2. Data source — ride the existing completion write (no new query/index)
- `lib/features/family/domain/member_model.dart` — add `gardenDays: Map<String,int>` (category → cumulative days) and `gardenLastDate: Map<String,String>` (category → last-counted date), with map (de)serialization in `toMap`/`fromMap`/`copyWith`.
- `lib/features/tasks/data/task_log_repository.dart` `completeTask` — inside the existing transaction, when `member.gardenLastDate[task.category.name] != date`, add `'gardenDays.<cat>': FieldValue.increment(1)` and `'gardenLastDate.<cat>': date`. Once per day per habit, riding the write already at `task_log_repository.dart:91` — no extra round-trip. Growth is cumulative, so **no weekly query and no new Firestore index are needed.**

### 3. Providers
- `lib/features/garden/providers/garden_providers.dart` — `gardenStateProvider` (Provider) derives from `currentMemberProvider` via `buildGarden(...)`. Optionally also watch the existing `todayLogsProvider` (`tasks/providers`) to know which categories were done today and fire a one-shot grow animation. Reuse `currentMemberProvider` (`family_providers`).

### 4. Rive runtime (the actual "Rive now")
- `pubspec.yaml` — add `rive` (**pin the current pub.dev version at implementation start** — see Risks); **uncomment + populate `flutter: assets:`** with `assets/rive/`. Record source + license in `assets/rive/SOURCES.md`.
- `lib/features/garden/presentation/widgets/rive_plant.dart` — defensive wrapper `RivePlant({required PlantSpecies species, required double growth /*0..1*/, int growSignal = 0})`. Loads the species' artboard; if its state machine exposes a numeric `growth` input, set it; **else fall back** to selecting the lifecycle animation / seeking. The rest of the app only knows `(species, growth)` — the key seam.
- `lib/features/garden/presentation/widgets/garden_scene.dart` — composes the background (sky, sun sized by `streakDays`, grass, soil beds), one `RivePlant` per `GardenPlant` placed across the beds, and the creature via the **existing** `AvatarDisplay` (~120px, emoji stays) overlaid. Tapping the creature pushes the avatar detail.
- `lib/features/garden/presentation/garden_screen.dart` — Scaffold consuming `gardenStateProvider`: full-bleed `GardenScene` + a short caption + loading/empty state (no habits yet → bare beds + friendly hint).

### 5. "It grew" moment — reuse the celebrate pattern
`gardenStateProvider` updates reactively after the existing `_completeTask` flow (`kid_dashboard_screen.dart:431`), which now bumps `gardenDays.<category>` on that habit's first completion of the day. When a plant's `growth` advances, `GardenScene` bumps a per-plant `growSignal` int (same one-shot pattern as `AvatarDisplay.celebrateSignal`) to fire that plant's grow/bloom + sparkle.

### 6. Routing (`lib/routing/app_router.dart`)
- The "Garden" nav tab is branch index 3, root currently `/kid/avatar` → `AvatarScreen` (lines 131–134). Change the branch root to `/kid/garden` → `GardenScreen`.
- Preserve the avatar detail as a child: `/kid/garden/creature` → `AvatarScreen`; the garden's creature-tap pushes it.
- Update the one stale reference: `choose_avatar_screen.dart` edit-cancel redirect `/kid/avatar` → `/kid/garden/creature`. (The "change my creature" button pushes `/choose-avatar`, unaffected.)

## Critical files
- New: `lib/features/garden/{domain/garden_plant.dart, domain/garden_state.dart, application/garden_builder.dart, providers/garden_providers.dart, presentation/garden_screen.dart, presentation/widgets/garden_scene.dart, presentation/widgets/rive_plant.dart}`
- Edit: `pubspec.yaml` (rive + assets); `lib/features/family/domain/member_model.dart` (`gardenDays` + `gardenLastDate` maps); `lib/features/tasks/data/task_log_repository.dart` (per-category once-a-day increment in `completeTask`); `lib/routing/app_router.dart` (branch root + child); `lib/features/avatar/presentation/choose_avatar_screen.dart` (redirect path).
- Reuse: `TaskCategory` (`planner/domain/task_category.dart`), `currentMemberProvider` (`family_providers`), `todayLogsProvider` (`tasks/providers`), `AvatarDisplay`.

## Verification
1. `flutter pub get`, then `flutter analyze` clean.
2. Unit test the pure builder — `test/garden_builder_test.dart`: a member with `gardenDays {exercise:5, study:1}` yields a tree at high growth + a flower at sprout; an absent category → no plant; growth is monotonic (a missed day / streak reset never lowers any plant's `growth`). `MemberModel` map round-trips `gardenDays`/`gardenLastDate`.
3. Manual run (`flutter run`): kid completes an Exercise task → Garden tab shows the tree advance + sparkle; complete a different category → a different species grows. Tap creature → avatar detail opens. Simulate a 7-day streak → brighter garden + bigger sun. A missed day leaves every plant intact (only the streak/sun dims) — nothing wilts.

## Risks / notes
- **Rive package & API**: cutoff predates the current Rive Flutter runtime (`rive` vs newer `rive_native`). Pin the package and confirm the load-state-machine / set-input API on pub.dev **first**.
- **Multiple species = more art.** Mitigation: map the 6 healthy categories onto ~4 base Rive plant types (tree, flower, veggies, creeper) recolored/scaled per category; source a CC0 plant/garden pack or per-species `.riv` files; the wrapper degrades to animation-select if `growth` inputs are absent. Start with the categories that have assets, generic flower for the rest.
- **Asset licensing**: log each `.riv` source + license in `assets/rive/SOURCES.md`.
- After implementation, update the project memory note (`habit-garden-feature.md`) to the final model (Rive-now / garden-only / per-habit plant species).

## Prototypes explored (for reference)
Three interactive mockups were reviewed during planning, converging on the final model: (1) a per-day flower strip, (2) a single hero plant growing in a garden background, (3) **the chosen design** — a garden where each habit type grows its own species through its lifecycle.

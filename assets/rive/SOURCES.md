# Garden Rive assets

The Habit Garden renders plants through `RivePlant`
(`lib/features/garden/presentation/widgets/rive_plant.dart`). Today `RivePlant`
draws each plant with `CodePlant` (a hand-drawn `CustomPainter`). The `rive`
package (`^0.14.9`) is already installed and pinned — dropping a `.riv` here and
flipping `RivePlant` upgrades the visuals to Rive, with `CodePlant` as the
automatic fallback while loading / if anything is missing.

## 1. Get a `.riv` (free Community assets)

- Browse https://rive.app/community/ for plant / garden / growth animations.
- **Check the license** before use (prefer CC0 / permissive). Record each
  asset's source URL + license below.
- Or author your own in the Rive editor (https://rive.app).

| File | Source URL | Author | License |
|------|------------|--------|---------|
| _e.g._ `plants.riv` | _link_ | _name_ | _CC0_ |

## 2. Asset contract the code expects

Put a single `plants.riv` in this folder with **one artboard per species**,
named exactly to match `PlantSpecies.name`:

`tree`, `flower`, `veggies`, `creeper`, `bush`, `tulips`

Each artboard should expose:
- a state machine named **`grow`**
- a **number** input named **`growth`** (range `0`–`100`)
- _(optional)_ a trigger named `bloom` for a one-shot celebration

(Alternatively use one file per species and adjust the loader path below.)

## 3. Declare the asset

In `pubspec.yaml`, under `flutter:`, add:

```yaml
  assets:
    - assets/rive/
```

`rive_native` may require a one-time init before first use — verify against the
installed version (e.g. an `await RiveNative.init();` in `main()` before
`runApp`). Always test the Rive path on a real device/emulator.

## 4. Flip `RivePlant` on (rive 0.14 API)

Replace the body of `RivePlant.build` with:

```dart
import 'package:rive/rive.dart';
// ...
final fallback = CodePlant(species: species, stage: stage, size: size);
return SizedBox(
  width: size,
  height: size,
  child: RiveWidgetBuilder(
    fileLoader: FileLoader.asset(
      'assets/rive/plants.riv',
      riveFactory: Factory.flutter,
    ),
    artboardSelector: ArtboardSelector.byName(species.name),
    stateMachineSelector: StateMachineSelector.byName('grow'),
    onLoaded: (loaded) {
      // Drive the lifecycle. Confirm the number-input accessor against the
      // rive_native StateMachine API in your version.
      loaded.controller.stateMachine.number('growth')?.value =
          (growth * 100).clamp(0, 100).toDouble();
    },
    builder: (context, state) => switch (state) {
      RiveLoading() => fallback,
      RiveFailed() => fallback,
      RiveLoaded() => RiveWidget(
          controller: (state as RiveLoaded).controller,
          fit: Fit.contain,
        ),
    },
  ),
);
```

`RivePlant` already receives `growth` (0..1) and `stage` from `GardenBuilder`,
so no other code changes are needed. If an artboard/state-machine/input name is
missing, the builder lands in `RiveFailed` and the hand-drawn plant shows
instead — so a partial asset set degrades gracefully, species by species.

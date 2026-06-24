# Asset Sources & License Log

## Naming contract

| Asset type | Path pattern | Notes |
|-----------|-------------|-------|
| Plant Lottie | `assets/animations/plant_<species>.json` | One file = all stages, animated |
| Plant image (per stage) | `assets/images/plants/<species>_<stage>.png` | .png / .webp / .jpg |
| Creature image | `assets/images/creatures/<creatureType>.png` | Optional — replaces emoji |
| Background | `assets/images/backgrounds/garden.png` | Optional sky/scene layer |

Species: `tree`, `flower`, `veggies`, `creeper`, `bush`, `tulips`  
Stages: `seed`, `sprout`, `leafy`, `budding`, `blooming`

---

## Files in use

| File | Source | License | Mapped to |
|------|--------|---------|-----------|
| `plant_flower.json` | LottieFiles ("plant5 v1") | LottieFiles free license | `assets/animations/plant_flower.json` |
| `plant_tree.json` | LottieFiles ("Animated plant loader") | LottieFiles free license | `assets/animations/plant_tree.json` |
| `plant_veggies.json` | LottieFiles ("Cycle of growth of tomato plant") | LottieFiles free license | `assets/animations/plant_veggies.json` |

---

## Where to find more free assets

### Plant Lottie animations (best impact — animated growth)
- **LottieFiles.com** — search: "growing plant", "flower bloom", "tree grow", "sprout", "plant growth"
- Download as `.json`, rename to `plant_<species>.json`, drop in `assets/animations/`

### Plant illustration PNGs (static, transparent background)
- **Pixabay.com** — CC0, no attribution. Search: "plant png transparent", "tree illustration png"
- **Kenney.nl** — CC0 game-ready sprites. Download the "Nature" or "Farm" pack
- **OpenGameArt.org** — search "plant" or "crops", filter CC0/CC-BY
- **itch.io** — search "garden asset pack" or "farm asset pack"
- **Freepik.com** — free with attribution. Search: "garden plant illustration png"

### Creature images (optional, replaces emoji)
- Pixabay / Freepik / Vecteezy — search `<animal> illustration png transparent`

### Background (optional)
- **Pexels / Unsplash / Pixabay** — CC0 garden photos
- Freepik illustrated garden backgrounds

### Style tip
Pick **one cohesive illustration style / pack** for all six plants so they look like a set.
Prefer CC0 to skip per-file attribution bookkeeping.
Log every file added to the table above.

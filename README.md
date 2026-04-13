# Habit Quest

A free family planner mobile app that helps kids (ages 8-14) build healthy digital habits through planning, completion tracking, rewards, and a Tamagotchi-style avatar growth system.

## Purpose

Reduce kids' screen time through **self-directed planning** and show the impact of healthy vs unhealthy digital habits through a virtual creature that grows, thrives, or gets sick based on their actions.

## Features

- **Weekly Planner** — Kids plan their day with activities on an hourly basis (weekday & weekend)
- **Parent Approval** — Parents review and approve/reject weekly plans
- **Task Tracking** — Kids mark tasks complete with optional parent verification
- **Rewards (Coins)** — Earn coins for completing tasks, spend in the shop
- **Avatar Growth (XP)** — Virtual creature evolves through 5 stages based on healthy habits
- **Mood & Health System** — Avatar's mood/health reflects digital habit balance

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) — Android + iOS |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Firebase free tier (Auth + Firestore) |
| **Animations** | Lottie, flutter_animate |
| **Charts** | fl_chart |

## Avatar System

5 creature types (Fire Fox, Water Dragon, Earth Bunny, Wind Owl, Star Cat), each with 5 evolution stages:

| Stage | Name | XP Required |
|-------|------|-------------|
| 1 | Egg | 0 |
| 2 | Baby | 100 |
| 3 | Teen | 500 |
| 4 | Adult | 1,500 |
| 5 | Legendary | 4,000 |

Healthy habits make the creature grow and be happy. Unhealthy digital habits (excess screen time) make it sad or sick.

## Project Structure

```
lib/
├── main.dart & app.dart
├── core/          # Theme, constants, shared widgets
├── features/
│   ├── auth/      # Parent signup, kid join, login
│   ├── family/    # Family management, members
│   ├── planner/   # Weekly/daily planning
│   ├── tasks/     # Task completion & verification
│   ├── avatar/    # Creature display, evolution logic
│   ├── shop/      # Rewards shop & inventory
│   └── dashboard/ # Kid & parent home screens
└── routing/       # GoRouter config with role-based nav
```

## Build Phases

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Foundation + Auth + Avatar + Dashboards | Done |
| 2 | Weekly Planner + Parent Approval | Planned |
| 3 | Task Completion + Rewards | Planned |
| 4 | Avatar Growth + Mood System | Planned |
| 5 | Shop + Polish | Planned |

## Getting Started

### Prerequisites
- Flutter SDK 3.41+
- Firebase project ([create one here](https://console.firebase.google.com))

### Setup
```bash
git clone git@github.com:AishwaryaKandasami/DigitalHabit.git
cd DigitalHabit
flutter pub get

# Configure Firebase (replace placeholder firebase_options.dart)
flutterfire configure

# Run
flutter run
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full system design, Firestore data model, auth flow, avatar mechanics, and rewards economy.

## License

MIT

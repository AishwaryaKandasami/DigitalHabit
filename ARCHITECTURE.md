# Habit Quest — Architecture

## System Overview

**Client**: Flutter (Dart) single codebase targeting Android and iOS.
**State Management**: Riverpod (lightweight, no codegen).
**Navigation**: GoRouter with role-based redirects (parent shell vs kid shell).
**Backend**: Firebase Spark plan (free tier).

### COPPA Strategy
- Parents create all accounts. Kids never provide an email address.
- Kids use anonymous Firebase Auth linked to parent's family doc.
- Firestore security rules enforce parent-only writes on child profiles.

### Firebase Free Tier Budget
- 50K reads/day, 20K writes/day, 1GB storage, 10GB bandwidth/month.
- A family of 4 doing heavy usage: ~1,600 reads + 400 writes/day.
- Supports ~30 active families comfortably.

---

## Auth Flow

### Parent Sign-Up
1. Email/password → `FirebaseAuth.createUserWithEmailAndPassword`
2. Create `/families/{id}` with `parentUid` + 6-char invite code
3. Create `/families/{id}/members/{id}` with `role: parent`
4. Save `/userProfiles/{uid}` mapping (uid → familyId, memberId, role)

### Kid Join (Parent-Assisted)
1. Enter invite code → query Firestore for matching family
2. Enter display name (no email)
3. `FirebaseAuth.signInAnonymously()` → stable UID
4. Create member doc with `role: child`
5. Save user profile mapping → choose creature → kid dashboard

---

## Firestore Data Model

All data lives under `/families/{familyId}/` for simple security rules.

### `/families/{familyId}`
```
name: "The Sharma Family"
parentUid: "firebase-auth-uid"
inviteCode: "ABC123"
createdAt: timestamp
settings: {
  requireParentVerification: true,
  weekStartsOn: "monday",
  maxScreenTimeMinutes: 120
}
```

### `/families/{familyId}/members/{memberId}`
```
displayName: "Aarav"
role: "child"
authUid: "anonymous-uid"
avatarState: {                    // embedded to save reads
  creatureName: "Sparky"
  creatureType: "fireFox"
  level: 5
  totalXp: 340
  evolutionStage: 2
  moodScore: 75                   // 0-100
  health: 90                      // 0-100
  lastFedAt: timestamp
  accessories: ["hat_01"]
}
wallet: { coins: 250, totalEarned: 1200 }
streakDays: 12
lastActiveDate: "2026-04-13"
```

### `/families/{familyId}/plans/{planId}`
```
memberId: "member-id"
weekStart: "2026-04-13"
status: "pending_approval"        // draft | pending_approval | approved | revision_requested
parentNote: "Reduce screen time on Saturday"
days: {
  "monday": [
    { taskId: "uuid", hour: 7, duration: 60, title: "Morning walk",
      category: "exercise", isDigitalActivity: false, isHealthy: true },
    { taskId: "uuid", hour: 16, duration: 30, title: "Minecraft",
      category: "screen_time", isDigitalActivity: true, isHealthy: false }
  ],
  ...
}
```

### `/families/{familyId}/taskLogs/{logId}`
```
planId, memberId, date, taskId, title, category, isHealthy
completedAt: timestamp
completedByChild: true
verifiedByParent: false
coinsEarned: 10
xpEarned: 15
```

### `/families/{familyId}/shopItems/{itemId}`
```
name: "Wizard Hat"
type: "accessory"                 // accessory | background | food | potion
cost: 50
imageAsset: "assets/shop/hat_wizard.png"
moodBoost: 0
```

### `/families/{familyId}/transactions/{txId}`
```
memberId, type: "earn"|"spend", amount, reason, itemId, createdAt
```

---

## Avatar Growth Mechanics

### Evolution Stages (XP-based)
| Stage | Name | Cumulative XP |
|-------|------|---------------|
| 1 | Egg | 0 |
| 2 | Baby | 100 |
| 3 | Teen | 500 |
| 4 | Adult | 1,500 |
| 5 | Legendary | 4,000 |

5 creature types: Fire Fox, Water Dragon, Earth Bunny, Wind Owl, Star Cat.

### XP Earning
| Action | XP |
|--------|-----|
| Healthy task completed | +15 |
| Any task completed | +5 |
| Full day bonus | +25 |
| 7-day streak | +50 |
| Parent-verified task | +5 bonus |

### Mood System (0-100)
| Range | State | Visual |
|-------|-------|--------|
| 80-100 | Happy | Bouncing, sparkles |
| 50-79 | Neutral | Idle |
| 25-49 | Sad | Drooping, gray tint |
| 0-24 | Sick | Lying down |

| Event | Mood Change |
|-------|-------------|
| Healthy task | +5 |
| Unhealthy task | -3 |
| Skipped task | -8 |
| Daily decay | -5 |
| Food item | +15 |

### Health System (0-100)
- >70% healthy tasks → +5/day regeneration
- <40% healthy tasks → -10/day decline
- Below 30 health → avatar sick, no streak bonuses
- Healing potion → +25 health

### Digital Habit Classification
- **Healthy**: exercise, study, chores, creative, social
- **Unhealthy**: screen_time exceeding parent-set threshold (default 2hr/day)

---

## Rewards Economy

### Earning Coins
| Action | Coins |
|--------|-------|
| Any task | 10 |
| Healthy task | 15 |
| Full day completion | 30 bonus |
| Full week | 100 bonus |
| 7-day streak | 50 bonus |
| Plan approved first try | 20 bonus |

### Spending
| Item Type | Price Range | Effect |
|-----------|-------------|--------|
| Food | 10-30 | Restore mood |
| Healing Potion | 40 | +25 health |
| Accessories | 50-200 | Cosmetic |
| Backgrounds | 100-300 | Avatar scene |
| XP Boost (1-day) | 150 | 2x XP |

A diligent kid earns ~940 coins/week.

---

## Screen Map

### Kid (Bottom Nav: Home, Planner, Shop, Avatar)
- **KidDashboard**: Avatar, today's timeline, progress ring, coins, streak
- **WeeklyPlanner → DayPlanner → AddTaskSheet**: Hourly grid, categories, submit to parent
- **TaskCompletion**: Mark done, confetti, coin/XP toast
- **AvatarScreen**: Stats, evolution timeline, equipped accessories
- **ShopScreen → InventoryScreen**: Buy items, equip, use consumables

### Parent (Bottom Nav: Home, Plans, Family, Settings)
- **ParentDashboard**: Children overview, pending approval banner
- **PlanReview**: View plan, approve/reject, category pie chart
- **TaskVerification**: Verify/reject completed tasks
- **FamilyManagement**: Members, invite code, per-child settings

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Avatar state embedded in member doc | Saves 1 Firestore read per session |
| One doc per weekly plan (~10KB) | Saves 50+ reads vs one-doc-per-task |
| All game logic client-side | No Cloud Functions cold starts, simpler architecture |
| Mood decay on app open (retroactive) | Free, no scheduled infrastructure needed |
| Anonymous auth for kids | COPPA-safe, stable UID for security rules |

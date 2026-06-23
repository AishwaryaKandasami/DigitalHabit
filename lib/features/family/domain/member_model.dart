import '../../avatar/domain/avatar_state.dart';
import '../../auth/domain/app_user.dart';
import '../../shop/domain/inventory_model.dart';

class MemberModel {
  final String id;
  final String displayName;
  final UserRole role;
  final String? authUid;
  final String? email; // set for kid accounts created with email/password
  final AvatarState avatarState;
  final Wallet wallet;
  final InventoryModel inventory;
  final int streakDays;
  final String? lastActiveDate;

  /// Cumulative days each habit category was completed — grows that habit's
  /// garden plant. Monotonic; never decreases.
  final Map<String, int> gardenDays;

  /// Last date (ISO yyyy-MM-dd) each category's garden day was counted, so a
  /// plant grows at most once per day per habit.
  final Map<String, String> gardenLastDate;

  const MemberModel({
    required this.id,
    required this.displayName,
    required this.role,
    this.authUid,
    this.email,
    required this.avatarState,
    required this.wallet,
    this.inventory = const InventoryModel(),
    this.streakDays = 0,
    this.lastActiveDate,
    this.gardenDays = const {},
    this.gardenLastDate = const {},
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'role': role.name,
        'authUid': authUid,
        'email': email,
        'avatarState': avatarState.toMap(),
        'wallet': wallet.toMap(),
        'inventory': inventory.toList(),
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate,
        'gardenDays': gardenDays,
        'gardenLastDate': gardenLastDate,
      };

  factory MemberModel.fromMap(String id, Map<String, dynamic> map) =>
      MemberModel(
        id: id,
        displayName: map['displayName'] as String,
        role: UserRole.values.byName(map['role'] as String),
        authUid: map['authUid'] as String?,
        email: map['email'] as String?,
        avatarState: AvatarState.fromMap(
            map['avatarState'] as Map<String, dynamic>? ?? {}),
        wallet:
            Wallet.fromMap(map['wallet'] as Map<String, dynamic>? ?? {}),
        inventory:
            InventoryModel.fromList(map['inventory'] as List<dynamic>?),
        streakDays: map['streakDays'] as int? ?? 0,
        lastActiveDate: map['lastActiveDate'] as String?,
        gardenDays: (map['gardenDays'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            const {},
        gardenLastDate: (map['gardenLastDate'] as Map?)
                ?.map((k, v) => MapEntry(k as String, v as String)) ??
            const {},
      );

  MemberModel copyWith({
    String? displayName,
    String? email,
    AvatarState? avatarState,
    Wallet? wallet,
    InventoryModel? inventory,
    int? streakDays,
    String? lastActiveDate,
    Map<String, int>? gardenDays,
    Map<String, String>? gardenLastDate,
  }) {
    return MemberModel(
      id: id,
      displayName: displayName ?? this.displayName,
      role: role,
      authUid: authUid,
      email: email ?? this.email,
      avatarState: avatarState ?? this.avatarState,
      wallet: wallet ?? this.wallet,
      inventory: inventory ?? this.inventory,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      gardenDays: gardenDays ?? this.gardenDays,
      gardenLastDate: gardenLastDate ?? this.gardenLastDate,
    );
  }
}

class Wallet {
  final int coins;
  final int totalEarned;

  const Wallet({this.coins = 0, this.totalEarned = 0});

  Map<String, dynamic> toMap() => {
        'coins': coins,
        'totalEarned': totalEarned,
      };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
        coins: map['coins'] as int? ?? 0,
        totalEarned: map['totalEarned'] as int? ?? 0,
      );

  Wallet addCoins(int amount) => Wallet(
        coins: coins + amount,
        totalEarned: totalEarned + amount,
      );

  Wallet spendCoins(int amount) => Wallet(
        coins: coins - amount,
        totalEarned: totalEarned,
      );
}

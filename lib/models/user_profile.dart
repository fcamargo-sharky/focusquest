import 'dart:math';

class UserProfile {
  final int id;
  final String name;
  final int xp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;
  final int streakShields;

  const UserProfile({
    required this.id,
    required this.name,
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
    required this.streakShields,
  });

  int get xpForCurrentLevel => level * level * 50;
  int get xpForNextLevel => (level + 1) * (level + 1) * 50;
  int get xpInCurrentLevel => xp - xpForCurrentLevel;
  int get xpNeededForNextLevel => xpForNextLevel - xpForCurrentLevel;

  double get levelProgress {
    if (xpNeededForNextLevel <= 0) return 1.0;
    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  static int calculateLevel(int xp) {
    if (xp <= 0) return 1;
    final level = sqrt(xp / 50).floor() + 1;
    return level.clamp(1, 100);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'Student',
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastActiveDate: map['lastActiveDate'] as String?,
      streakShields: map['streakShields'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'streakShields': streakShields,
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
    int? streakShields,
    bool clearLastActiveDate = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate:
          clearLastActiveDate ? null : (lastActiveDate ?? this.lastActiveDate),
      streakShields: streakShields ?? this.streakShields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserProfile && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

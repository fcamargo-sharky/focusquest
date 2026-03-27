class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
  });

  static const List<Achievement> all = [
    Achievement(
      id: 'first_task',
      title: 'First Step',
      description: 'Complete your first task',
      icon: '🎯',
      xpReward: 50,
    ),
    Achievement(
      id: 'first_pomodoro',
      title: 'In the Zone',
      description: 'Complete your first Pomodoro session',
      icon: '🍅',
      xpReward: 30,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: '3-day streak',
      icon: '🔥',
      xpReward: 75,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: '7-day streak',
      icon: '⚡',
      xpReward: 150,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unstoppable',
      description: '30-day streak',
      icon: '💫',
      xpReward: 500,
    ),
    Achievement(
      id: 'tasks_10',
      title: 'Task Crusher',
      description: 'Complete 10 tasks',
      icon: '✅',
      xpReward: 100,
    ),
    Achievement(
      id: 'tasks_50',
      title: 'Task Master',
      description: 'Complete 50 tasks',
      icon: '🏆',
      xpReward: 300,
    ),
    Achievement(
      id: 'study_2h',
      title: 'Focused',
      description: 'Study for 2 hours in a day',
      icon: '📚',
      xpReward: 75,
    ),
    Achievement(
      id: 'study_5h',
      title: 'Deep Work',
      description: 'Study for 5 hours in a day',
      icon: '🧠',
      xpReward: 200,
    ),
    Achievement(
      id: 'study_10h_week',
      title: 'Study Marathon',
      description: 'Study for 10 hours in a week',
      icon: '🎓',
      xpReward: 250,
    ),
    Achievement(
      id: 'pomodoro_10',
      title: 'Pomodoro Pro',
      description: 'Complete 10 Pomodoro sessions',
      icon: '⏱️',
      xpReward: 150,
    ),
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      icon: '⭐',
      xpReward: 100,
    ),
    Achievement(
      id: 'level_10',
      title: 'Scholar',
      description: 'Reach level 10',
      icon: '🎖️',
      xpReward: 200,
    ),
  ];

  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Achievement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

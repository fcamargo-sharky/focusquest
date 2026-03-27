class DailyStat {
  final String date; // YYYY-MM-DD
  final int tasksCompleted;
  final int studySeconds;
  final int routinesCompleted;

  const DailyStat({
    required this.date,
    required this.tasksCompleted,
    required this.studySeconds,
    required this.routinesCompleted,
  });

  double get studyHours => studySeconds / 3600;
  Duration get studyDuration => Duration(seconds: studySeconds);
  bool get hasActivity => tasksCompleted > 0 || studySeconds > 0;

  factory DailyStat.fromMap(Map<String, dynamic> map) {
    return DailyStat(
      date: map['date'] as String,
      tasksCompleted: map['tasksCompleted'] as int? ?? 0,
      studySeconds: map['studySeconds'] as int? ?? 0,
      routinesCompleted: map['routinesCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'tasksCompleted': tasksCompleted,
      'studySeconds': studySeconds,
      'routinesCompleted': routinesCompleted,
    };
  }

  DailyStat copyWith({
    String? date,
    int? tasksCompleted,
    int? studySeconds,
    int? routinesCompleted,
  }) {
    return DailyStat(
      date: date ?? this.date,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      studySeconds: studySeconds ?? this.studySeconds,
      routinesCompleted: routinesCompleted ?? this.routinesCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DailyStat && other.date == date);

  @override
  int get hashCode => date.hashCode;
}

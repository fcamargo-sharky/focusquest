class StudySession {
  final String id;
  final String? taskId;
  final String? subjectId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int pomodoroCount;
  final DateTime createdAt;

  const StudySession({
    required this.id,
    this.taskId,
    this.subjectId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.pomodoroCount = 0,
    required this.createdAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  String get durationFormatted {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    } else if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    } else {
      return '${s}s';
    }
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      taskId: map['taskId'] as String?,
      subjectId: map['subjectId'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      pomodoroCount: map['pomodoroCount'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'subjectId': subjectId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
      'pomodoroCount': pomodoroCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  StudySession copyWith({
    String? id,
    String? taskId,
    String? subjectId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? pomodoroCount,
    DateTime? createdAt,
    bool clearTaskId = false,
    bool clearSubjectId = false,
    bool clearEndTime = false,
  }) {
    return StudySession(
      id: id ?? this.id,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StudySession && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

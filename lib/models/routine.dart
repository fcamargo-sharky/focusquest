import 'dart:convert';

class Routine {
  final String id;
  final String title;
  final String? description;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final List<int> days; // 0=Mon, 6=Sun
  final String? subjectId;
  final bool isActive;
  final DateTime createdAt;

  const Routine({
    required this.id,
    required this.title,
    this.description,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.days,
    this.subjectId,
    this.isActive = true,
    required this.createdAt,
  });

  String get timeString {
    final h = startHour.toString().padLeft(2, '0');
    final m = startMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get durationString {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String get daysString {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(5) && !days.contains(6)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(5) && days.contains(6)) {
      return 'Weekends';
    }
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => dayNames[d]).join(', ');
  }

  bool get isToday {
    final today = DateTime.now().weekday - 1; // Convert to 0-indexed
    return days.contains(today);
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    List<int> parsedDays = [];
    if (map['days'] != null) {
      try {
        parsedDays = List<int>.from(jsonDecode(map['days'] as String));
      } catch (_) {
        parsedDays = [];
      }
    }

    return Routine(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startHour: map['startHour'] as int,
      startMinute: map['startMinute'] as int,
      durationMinutes: map['durationMinutes'] as int,
      days: parsedDays,
      subjectId: map['subjectId'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startHour': startHour,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'days': jsonEncode(days),
      'subjectId': subjectId,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    int? startHour,
    int? startMinute,
    int? durationMinutes,
    List<int>? days,
    String? subjectId,
    bool? isActive,
    DateTime? createdAt,
    bool clearDescription = false,
    bool clearSubjectId = false,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      days: days ?? this.days,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Routine && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

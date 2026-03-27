import 'dart:convert';

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String? subjectId;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> tags;
  final int xpAwarded;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.subjectId,
    this.isCompleted = false,
    this.completedAt,
    this.tags = const [],
    this.xpAwarded = 0,
    required this.createdAt,
  });

  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  int get xpValue {
    switch (priority) {
      case TaskPriority.low:
        return 10;
      case TaskPriority.medium:
        return 20;
      case TaskPriority.high:
        return 30;
    }
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && (map['tags'] as String).isNotEmpty) {
      try {
        parsedTags = List<String>.from(jsonDecode(map['tags'] as String));
      } catch (_) {
        parsedTags = [];
      }
    }

    TaskPriority priority;
    switch (map['priority'] as int? ?? 1) {
      case 0:
        priority = TaskPriority.low;
        break;
      case 2:
        priority = TaskPriority.high;
        break;
      default:
        priority = TaskPriority.medium;
    }

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      priority: priority,
      subjectId: map['subjectId'] as String?,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      tags: parsedTags,
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    int priorityInt;
    switch (priority) {
      case TaskPriority.low:
        priorityInt = 0;
        break;
      case TaskPriority.medium:
        priorityInt = 1;
        break;
      case TaskPriority.high:
        priorityInt = 2;
        break;
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priorityInt,
      'subjectId': subjectId,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'tags': jsonEncode(tags),
      'xpAwarded': xpAwarded,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? subjectId,
    bool? isCompleted,
    DateTime? completedAt,
    List<String>? tags,
    int? xpAwarded,
    DateTime? createdAt,
    bool clearDueDate = false,
    bool clearDescription = false,
    bool clearSubjectId = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      tags: tags ?? this.tags,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

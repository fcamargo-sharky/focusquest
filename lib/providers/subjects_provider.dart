import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/models/subject.dart';
import 'package:uuid/uuid.dart';

class SubjectsNotifier extends StateNotifier<List<Subject>> {
  SubjectsNotifier() : super([]) {
    _loadSubjects();
  }

  final _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<void> _loadSubjects() async {
    final subjects = await _db.getSubjects();
    state = subjects;
  }

  Future<void> addSubject(String name, int colorValue) async {
    final subject = Subject(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _db.insertSubject(subject);
    state = [...state, subject];
  }

  Future<void> updateSubject(Subject subject) async {
    await _db.updateSubject(subject);
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
  }

  Future<void> deleteSubject(String id) async {
    await _db.deleteSubject(id);
    state = state.where((s) => s.id != id).toList();
  }

  Subject? getById(String id) {
    try {
      return state.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, List<Subject>>((ref) {
  return SubjectsNotifier();
});

final selectedSubjectProvider = Provider.family<Subject?, String?>((ref, id) {
  if (id == null) return null;
  final subjects = ref.watch(subjectsProvider);
  try {
    return subjects.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

final subjectColorsProvider = Provider<List<int>>((ref) {
  return AppColors.subjectColors.map((c) => c.value).toList();
});

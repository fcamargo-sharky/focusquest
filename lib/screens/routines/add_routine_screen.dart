import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/providers/routines_provider.dart';
import 'package:focusquest/providers/subjects_provider.dart';

class AddRoutineScreen extends ConsumerStatefulWidget {
  final Routine? routine;

  const AddRoutineScreen({super.key, this.routine});

  @override
  ConsumerState<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends ConsumerState<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 60;
  List<int> _selectedDays = [0, 1, 2, 3, 4]; // Mon-Fri by default
  String? _subjectId;
  bool _enableNotifications = true;
  bool _isSaving = false;

  bool get _isEditing => widget.routine != null;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    if (r != null) {
      _titleController.text = r.title;
      _descController.text = r.description ?? '';
      _startTime = TimeOfDay(hour: r.startHour, minute: r.startMinute);
      _durationMinutes = r.durationMinutes;
      _selectedDays = List.from(r.days);
      _subjectId = r.subjectId;
      _enableNotifications = r.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = widget.routine!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          clearDescription: _descController.text.trim().isEmpty,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          durationMinutes: _durationMinutes,
          days: List.from(_selectedDays),
          subjectId: _subjectId,
          clearSubjectId: _subjectId == null,
          isActive: _enableNotifications,
        );
        await ref.read(routinesProvider.notifier).updateRoutine(updated);
      } else {
        final routine = Routine(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          durationMinutes: _durationMinutes,
          days: List.from(_selectedDays),
          subjectId: _subjectId,
          isActive: _enableNotifications,
          createdAt: DateTime.now(),
        );
        await ref.read(routinesProvider.notifier).addRoutine(routine);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Routine' : 'New Routine'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Routine name *',
                  hintText: 'e.g., Morning Study Session',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What will you do?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Time picker
              const _Label('Start Time'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _startTime.format(context),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Duration
              _Label(
                  'Duration: ${_durationMinutes >= 60 ? '${_durationMinutes ~/ 60}h ' : ''}${_durationMinutes % 60 != 0 ? '${_durationMinutes % 60}m' : _durationMinutes >= 60 ? '' : '${_durationMinutes}m'}'),
              const SizedBox(height: 8),
              Slider(
                value: _durationMinutes.toDouble(),
                min: 15,
                max: 240,
                divisions: 15,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.darkCard,
                onChanged: (v) =>
                    setState(() => _durationMinutes = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('15m', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text('1h', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text('2h', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text('4h', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 20),

              // Days of week
              const _Label('Days'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(7, (i) {
                  final isSelected = _selectedDays.contains(i);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays = _selectedDays
                                  .where((d) => d != i)
                                  .toList();
                            } else {
                              _selectedDays = [..._selectedDays, i]..sort();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.darkCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _dayLabels[i].substring(0, 1),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Quick day presets
              Wrap(
                spacing: 8,
                children: [
                  _DayPreset(
                    label: 'Everyday',
                    onTap: () => setState(() => _selectedDays = List.generate(7, (i) => i)),
                  ),
                  _DayPreset(
                    label: 'Weekdays',
                    onTap: () => setState(() => _selectedDays = [0, 1, 2, 3, 4]),
                  ),
                  _DayPreset(
                    label: 'Weekends',
                    onTap: () => setState(() => _selectedDays = [5, 6]),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subject
              const _Label('Subject (optional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _subjectId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _subjectId == null
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _subjectId == null
                              ? AppColors.primary
                              : AppColors.textMuted.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'None',
                        style: TextStyle(
                          color: _subjectId == null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  ...subjects.map((s) {
                    final isSelected = _subjectId == s.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _subjectId = isSelected ? null : s.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? s.color.withOpacity(0.25)
                              : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? s.color : s.color.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          s.name,
                          style: TextStyle(
                            color: isSelected ? s.color : AppColors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Notifications toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Notifications',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Get reminded when this routine starts',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  value: _enableNotifications,
                  onChanged: (v) => setState(() => _enableNotifications = v),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Routine'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DayPreset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DayPreset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

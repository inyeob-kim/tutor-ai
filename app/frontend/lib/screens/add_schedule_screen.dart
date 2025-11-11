import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _selectedStudentId;
  String? _selectedStudentName;
  String _scheduleType = 'lesson';
  String _color = '#3788D8';
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;

  final List<String> _scheduleTypes = ['lesson', 'consultation', 'meeting', 'other'];
  final List<Map<String, String>> _scheduleTypeLabels = [
    {'value': 'lesson', 'label': '수업'},
    {'value': 'consultation', 'label': '상담'},
    {'value': 'meeting', 'label': '미팅'},
    {'value': 'other', 'label': '기타'},
  ];

  final List<String> _colors = [
    '#3788D8',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#9333EA',
    '#EC4899',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      // 에러는 무시 (선택적 기능)
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime != null && _isEndTimeBeforeStart(picked, _endTime!)) {
          _endTime = TimeOfDay(
            hour: picked.hour,
            minute: (picked.minute + 60) % 60,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 시작 시간을 선택해주세요')),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          TimeOfDay(
            hour: _startTime!.hour,
            minute: (_startTime!.minute + 60) % 60,
          ),
    );
    if (picked != null) {
      if (_isEndTimeBeforeStart(_startTime!, picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다')),
        );
        return;
      }
      setState(() => _endTime = picked);
    }
  }

  bool _isEndTimeBeforeStart(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes <= startMinutes;
  }

  int _calculateDuration() {
    if (_startTime == null || _endTime == null) return 0;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    return endMinutes - startMinutes;
  }

  Future<void> _checkConflict() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return;
    }

    try {
      final conflict = await ApiService.checkScheduleConflict(
        teacherId: 1, // TODO: 실제 teacher_id 가져오기
        lessonDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        startTime: '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
      );

      if (conflict && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이 시간대에 이미 일정이 있습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // 충돌 확인 실패는 무시 (선택적 기능)
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜와 시간을 모두 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'teacher_id': 1, // TODO: 실제 teacher_id 가져오기
        'lesson_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        'schedule_type': _scheduleType,
        if (_selectedStudentId != null) 'student_id': _selectedStudentId,
        if (_titleController.text.isNotEmpty) 'title': _titleController.text.trim(),
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
        'color': _color,
      };

      await ApiService.createSchedule(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 성공적으로 등록되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = _calculateDuration();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('일정 등록'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 필수 정보
            _buildSectionTitle('필수 정보', theme, colorScheme),
            const SizedBox(height: 12),
            _buildDateField(
              label: '날짜',
              value: _selectedDate,
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectDate(context),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    label: '시작 시간',
                    value: _startTime,
                    icon: Icons.access_time_outlined,
                    onTap: () => _selectStartTime(context),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    label: '종료 시간',
                    value: _endTime,
                    icon: Icons.access_time_outlined,
                    onTap: () => _selectEndTime(context),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            if (duration > 0) ...[
              const SizedBox(height: 8),
              Text(
                '총 ${duration}분',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildStudentSelector(theme, colorScheme),
            const SizedBox(height: 24),

            // 추가 정보
            _buildSectionTitle('추가 정보', theme, colorScheme),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: '일정 유형',
              value: _scheduleType,
              options: _scheduleTypeLabels,
              icon: Icons.event_outlined,
              onChanged: (value) => setState(() => _scheduleType = value ?? 'lesson'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: '제목',
              hint: '일정 제목을 입력하세요',
              icon: Icons.title_outlined,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: '메모',
              hint: '추가 메모를 입력하세요',
              icon: Icons.note_outlined,
              maxLines: 3,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildColorSelector(theme, colorScheme),
            const SizedBox(height: 24),

            // 충돌 확인 버튼
            if (_selectedDate != null && _startTime != null && _endTime != null)
              OutlinedButton.icon(
                onPressed: _checkConflict,
                icon: const Icon(Icons.warning_outlined),
                label: const Text('시간 충돌 확인'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            const SizedBox(height: 16),

            // 등록 버튼
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '일정 등록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, ColorScheme colorScheme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label + ' *',
            prefixIcon: Icon(icon, color: colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          child: Text(
            value != null ? DateFormat('yyyy-MM-dd').format(value) : '날짜 선택',
            style: TextStyle(
              color: value != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label + ' *',
            prefixIcon: Icon(icon, color: colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          child: Text(
            value != null
                ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                : '시간 선택',
            style: TextStyle(
              color: value != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: _isLoadingStudents
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : DropdownButtonFormField<int>(
              value: _selectedStudentId,
              decoration: InputDecoration(
                labelText: '학생 (선택)',
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('학생 선택 안함')),
                ..._students.map((student) => DropdownMenuItem(
                      value: student['student_id'] as int?,
                      child: Text(student['name'] as String? ?? ''),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                  if (value != null) {
                    final student = _students.firstWhere(
                      (s) => s['student_id'] == value,
                      orElse: () => {},
                    );
                    _selectedStudentName = student['name'] as String?;
                  } else {
                    _selectedStudentName = null;
                  }
                });
              },
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: options.map((option) => DropdownMenuItem(
              value: option['value'],
              child: Text(option['label']!),
            )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    int maxLines = 1,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildColorSelector(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '색상',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = _color == color;
                return InkWell(
                  onTap: () => setState(() => _color = color),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}


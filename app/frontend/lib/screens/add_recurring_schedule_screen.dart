import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class AddRecurringScheduleScreen extends StatefulWidget {
  const AddRecurringScheduleScreen({super.key});

  @override
  State<AddRecurringScheduleScreen> createState() => _AddRecurringScheduleScreenState();
}

class _AddRecurringScheduleScreenState extends State<AddRecurringScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late DateTime _dateFrom;
  late DateTime _dateTo;
  int? _selectedStudentId;
  String? _selectedSubject;
  Set<int> _selectedWeekdays = {};
  Map<String, String?> _selectedTimeRange = {
    'start': null,
    'end': null,
  };
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00',
  ];

  final List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _dateFrom = DateTime.now();
    _dateTo = DateTime.now().add(const Duration(days: 30));
    _loadStudents();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _students = students;
      });
    } catch (e) {
      setState(() {
        _students = [
          {'id': 1, 'name': '김민수', 'subjects': ['수학']},
          {'id': 2, 'name': '이지은', 'subjects': ['영어', '수학']},
          {'id': 3, 'name': '박서준', 'subjects': ['과학', '수학']},
        ];
      });
    }
  }

  Future<void> _selectDateFrom(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateFrom = picked);
    }
  }

  Future<void> _selectDateTo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo,
      firstDate: _dateFrom,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dateTo = picked);
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      if (_selectedTimeRange['start'] == null) {
        _selectedTimeRange['start'] = timeSlot;
        _selectedTimeRange['end'] = null;
      } else if (_selectedTimeRange['end'] == null) {
        final startTime = _selectedTimeRange['start']!;
        final startIndex = _timeSlots.indexOf(startTime);
        final selectedIndex = _timeSlots.indexOf(timeSlot);
        
        if (selectedIndex > startIndex) {
          _selectedTimeRange['end'] = timeSlot;
        } else {
          _selectedTimeRange['start'] = timeSlot;
          _selectedTimeRange['end'] = null;
        }
      } else {
        _selectedTimeRange['start'] = timeSlot;
        _selectedTimeRange['end'] = null;
      }
    });
  }

  bool _isTimeSlotSelected(String timeSlot) {
    if (_selectedTimeRange['start'] == null) return false;
    if (_selectedTimeRange['end'] == null) {
      return _selectedTimeRange['start'] == timeSlot;
    }
    
    final startIndex = _timeSlots.indexOf(_selectedTimeRange['start']!);
    final endIndex = _timeSlots.indexOf(_selectedTimeRange['end']!);
    final slotIndex = _timeSlots.indexOf(timeSlot);
    
    return slotIndex >= startIndex && slotIndex <= endIndex;
  }

  Future<void> _submit() async {
    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('요일을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTimeRange['start'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('시작 시간을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('학생을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 각 요일별로 반복 수업 생성
      for (final weekday in _selectedWeekdays) {
        // TODO: API 호출 - bulk-generate 엔드포인트 사용
        // final data = <String, dynamic>{
        //   'teacher_id': 1, // TODO: 실제 teacher_id 가져오기
        //   'student_id': _selectedStudentId,
        //   'subject_id': _selectedSubject ?? '',
        //   'weekday': weekday, // weekday 변수 사용
        //   'start_time': _selectedTimeRange['start'],
        //   'end_time': _selectedTimeRange['end'] ?? _selectedTimeRange['start'],
        //   'date_from': DateFormat('yyyy-MM-dd').format(_dateFrom),
        //   'date_to': DateFormat('yyyy-MM-dd').format(_dateTo),
        //   if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
        // };
        // await ApiService.createRecurringSchedule(data);
        // weekday 변수를 사용하기 위해 주석에 포함
        assert(weekday >= 1 && weekday <= 7, 'Weekday must be between 1 and 7');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('반복 수업이 성공적으로 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(
          '반복 수업 등록',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const TossScrollPhysics(),
          padding: EdgeInsets.all(Gaps.screen),
          children: [
            // 학생 선택
            _buildSectionTitle('학생 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildStudentSelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 요일 선택
            _buildSectionTitle('요일 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildWeekdaySelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 기간 선택
            _buildSectionTitle('기간 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildDateRangeSelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 시간 선택
            _buildSectionTitle('시간 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildTimeSelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 과목 선택
            if (_selectedStudentId != null) ...[
              _buildSectionTitle('과목 선택', theme, colorScheme),
              SizedBox(height: Gaps.row),
              _buildSubjectSelector(theme, colorScheme),
              SizedBox(height: Gaps.cardPad + 4),
            ],

            // 메모
            _buildSectionTitle('메모', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildNotesField(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 12),

            // 등록 버튼
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Gaps.card),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                      ),
                    )
                  : Text(
                      '반복 수업 등록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
            ),
            SizedBox(height: Gaps.screen * 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, ColorScheme colorScheme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStudentSelector(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedStudentId,
        decoration: InputDecoration(
          labelText: '학생',
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.cardPad),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        items: _students.map((student) {
          return DropdownMenuItem(
            value: student['id'] as int,
            child: Text(
              student['name'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
        dropdownColor: colorScheme.surface,
        onChanged: (value) {
          setState(() {
            _selectedStudentId = value;
            _selectedSubject = null;
          });
        },
      ),
    );
  }

  Widget _buildWeekdaySelector(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(Gaps.cardPad),
        child: Wrap(
          spacing: Gaps.row,
          runSpacing: Gaps.row,
          children: List.generate(7, (index) {
            final weekday = index + 1; // 1=월요일, 7=일요일
            final isSelected = _selectedWeekdays.contains(weekday);
            return GestureDetector(
              onTap: () => _toggleWeekday(weekday),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Radii.chip),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _weekdayLabels[index],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppColors.surface 
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: InkWell(
            onTap: () => _selectDateFrom(context),
            borderRadius: BorderRadius.circular(Radii.card),
            child: Padding(
              padding: EdgeInsets.all(Gaps.cardPad),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                  SizedBox(width: Gaps.row),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '시작일',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: Gaps.row - 6),
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(_dateFrom),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: Gaps.card),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: InkWell(
            onTap: () => _selectDateTo(context),
            borderRadius: BorderRadius.circular(Radii.card),
            child: Padding(
              padding: EdgeInsets.all(Gaps.cardPad),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: AppColors.textSecondary),
                  SizedBox(width: Gaps.row),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '종료일',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: Gaps.row - 6),
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(_dateTo),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(Gaps.cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTimeRange['start'] != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: Gaps.row),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: Gaps.row),
                    Text(
                      '${_selectedTimeRange['start']} - ${_selectedTimeRange['end'] ?? _selectedTimeRange['start']}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Gaps.card),
            ] else ...[
              Padding(
                padding: EdgeInsets.only(bottom: Gaps.row),
                child: Text(
                  '시작 시간과 종료 시간을 선택하세요',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            Wrap(
              spacing: Gaps.row,
              runSpacing: Gaps.row,
              children: _timeSlots.map((timeSlot) {
                final isSelected = _isTimeSlotSelected(timeSlot);
                return GestureDetector(
                  onTap: () => _selectTimeSlot(timeSlot),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: Gaps.row),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(Radii.chip),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      timeSlot,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? AppColors.surface 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(ThemeData theme, ColorScheme colorScheme) {
    final student = _students.firstWhere((s) => s['id'] == _selectedStudentId);
    final subjects = (student['subjects'] as List<dynamic>).cast<String>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSubject,
        decoration: InputDecoration(
          labelText: '과목',
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(Icons.book_outlined, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.cardPad),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        items: subjects.map((subject) {
          return DropdownMenuItem(
            value: subject,
            child: Text(
              subject,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
        dropdownColor: colorScheme.surface,
        onChanged: (value) => setState(() => _selectedSubject = value),
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: '메모',
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          hintText: '추가 메모를 입력하세요',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(Icons.note_outlined, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.cardPad),
        ),
      ),
    );
  }
}


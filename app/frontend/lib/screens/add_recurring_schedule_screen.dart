import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../widgets/loading_indicator.dart';

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
  // 요일별 시간 범위 (weekday -> {start, end})
  Map<int, Map<String, String?>> _weekdayTimeRanges = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  // 선택된 요일과 기간에 대한 등록된 수업 목록 (disabled 처리용)
  List<Map<String, dynamic>> _existingSchedules = [];

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
    _loadExistingSchedules();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      // 활성화된 학생만 조회
      final studentsData = await ApiService.getStudents(isActive: true);
      // API 응답을 올바른 형식으로 변환
      final studentsList = studentsData.map((s) {
        final studentId = s['student_id'] as int?;
        final name = s['name'] as String? ?? '이름 없음';
        // subjects는 List<dynamic>이거나 없을 수 있음
        final subjects = (s['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                        (s['subject_id'] as String?)?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
        
        return {
          'id': studentId,
          'name': name,
          'subjects': subjects,
        };
      }).where((s) => s['id'] != null).toList();
      
      setState(() {
        _students = studentsList;
      });
      
      // 이미 선택된 학생이 있으면 과목 자동 설정
      if (_selectedStudentId != null) {
        _autoSelectSubject(_selectedStudentId!);
      }
    } catch (e) {
      print('⚠️ 학생 목록 로드 실패: $e');
      setState(() {
        _students = [];
      });
    }
  }

  /// 학생의 과목을 자동으로 선택 (과목이 하나면 자동 선택, 복수면 첫 번째를 디폴트로)
  void _autoSelectSubject(int studentId) {
    final student = _students.firstWhere(
      (s) => s['id'] == studentId,
      orElse: () => {'id': null, 'name': '', 'subjects': <String>[]},
    );
    
    final subjects = (student['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    
    if (subjects.isNotEmpty) {
      setState(() {
        // 과목이 하나면 자동 선택, 복수면 첫 번째를 디폴트로
        _selectedSubject = subjects.first;
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
      // 시작일 변경 시 등록된 수업 목록 다시 로드
      _loadExistingSchedules();
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
      // 종료일 변경 시 등록된 수업 목록 다시 로드
      _loadExistingSchedules();
    }
  }

  /// 선택된 요일과 기간에 대한 등록된 수업 목록 로드
  Future<void> _loadExistingSchedules() async {
    if (_selectedWeekdays.isEmpty) {
      setState(() {
        _existingSchedules = [];
      });
      return;
    }

    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) return;

      final dateFromStr = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final dateToStr = DateFormat('yyyy-MM-dd').format(_dateTo);

      // 선택된 기간의 모든 스케줄 조회
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: dateFromStr,
        dateTo: dateToStr,
        status: 'confirmed', // confirmed 수업만
      );

      // 선택된 요일에 해당하는 날짜의 수업만 필터링
      // 프론트엔드 weekday: 1=월요일, 7=일요일
      // DateTime.weekday: 1=월요일, 7=일요일
      final filteredSchedules = schedules.where((s) {
        final lessonDateStr = s['lesson_date'] as String?;
        if (lessonDateStr == null) return false;

        try {
          final lessonDate = DateTime.parse(lessonDateStr);
          final lessonWeekday = lessonDate.weekday; // 1=월요일, 7=일요일
          return _selectedWeekdays.contains(lessonWeekday);
        } catch (e) {
          return false;
        }
      }).toList();

      if (mounted) {
        setState(() {
          _existingSchedules = filteredSchedules;
        });
      }
    } catch (e) {
      print('⚠️ 등록된 수업 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _existingSchedules = [];
        });
      }
    }
  }


  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
        _weekdayTimeRanges.remove(weekday); // 요일 제거 시 시간 범위도 제거
      } else {
        _selectedWeekdays.add(weekday);
        _weekdayTimeRanges[weekday] = {'start': null, 'end': null}; // 새 요일 추가 시 시간 범위 초기화
      }
    });
    // 요일 변경 시 등록된 수업 목록 다시 로드
    _loadExistingSchedules();
  }

  void _selectTimeSlot(int weekday, String timeSlot) {
    // disabled된 타임슬롯은 선택 불가
    if (_isTimeSlotDisabled(weekday, timeSlot)) {
      return;
    }

    setState(() {
      final timeRange = _weekdayTimeRanges[weekday] ?? {'start': null, 'end': null};
      
      if (timeRange['start'] == null) {
        timeRange['start'] = timeSlot;
        timeRange['end'] = null;
      } else if (timeRange['end'] == null) {
        final startTime = timeRange['start']!;
        final startIndex = _timeSlots.indexOf(startTime);
        final selectedIndex = _timeSlots.indexOf(timeSlot);
        
        if (selectedIndex > startIndex) {
          timeRange['end'] = timeSlot;
        } else {
          timeRange['start'] = timeSlot;
          timeRange['end'] = null;
        }
      } else {
        timeRange['start'] = timeSlot;
        timeRange['end'] = null;
      }
      
      _weekdayTimeRanges[weekday] = timeRange;
    });
  }

  bool _isTimeSlotSelected(int weekday, String timeSlot) {
    final timeRange = _weekdayTimeRanges[weekday];
    if (timeRange == null || timeRange['start'] == null) return false;
    
    if (timeRange['end'] == null) {
      return timeRange['start'] == timeSlot;
    }
    
    final startIndex = _timeSlots.indexOf(timeRange['start']!);
    final endIndex = _timeSlots.indexOf(timeRange['end']!);
    final slotIndex = _timeSlots.indexOf(timeSlot);
    
    return slotIndex >= startIndex && slotIndex <= endIndex;
  }

  bool _isTimeSlotDisabled(int weekday, String timeSlot) {
    if (_existingSchedules.isEmpty || !_selectedWeekdays.contains(weekday)) return false;

    // 타임슬롯의 시간 파싱
    final slotParts = timeSlot.split(':');
    final slotHour = int.tryParse(slotParts[0]) ?? 0;
    final slotMin = int.tryParse(slotParts[1]) ?? 0;
    final slotTime = slotHour * 60 + slotMin; // 분 단위로 변환

    // 해당 요일에 해당하는 등록된 수업만 확인
    for (final schedule in _existingSchedules) {
      final lessonDateStr = schedule['lesson_date'] as String?;
      if (lessonDateStr == null) continue;

      try {
        final lessonDate = DateTime.parse(lessonDateStr);
        final lessonWeekday = lessonDate.weekday; // 1=월요일, 7=일요일
        if (lessonWeekday != weekday) continue; // 다른 요일이면 스킵
      } catch (e) {
        continue;
      }

      final startTime = schedule['start_time'] as String? ?? '00:00';
      final endTime = schedule['end_time'] as String? ?? '00:00';

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 0;
      final startMin = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
      final endHour = int.tryParse(endParts[0]) ?? 0;
      final endMin = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;

      final scheduleStart = startHour * 60 + startMin;
      final scheduleEnd = endHour * 60 + endMin;

      // 타임슬롯이 수업 시간 범위 내에 있는지 확인
      if (slotTime >= scheduleStart && slotTime < scheduleEnd) {
        return true; // 겹침
      }
    }

    return false;
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

    // 모든 선택된 요일에 대해 시간이 설정되었는지 확인
    for (final weekday in _selectedWeekdays) {
      final timeRange = _weekdayTimeRanges[weekday];
      if (timeRange == null || timeRange['start'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_weekdayLabels[weekday - 1]}요일의 시작 시간을 선택해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
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

    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('과목을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 현재 로그인한 선생님 정보 가져오기
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        throw Exception('선생님 정보를 불러올 수 없습니다. 다시 로그인해주세요.');
      }

      final dateFromStr = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final dateToStr = DateFormat('yyyy-MM-dd').format(_dateTo);
      final notes = _notesController.text.trim();

      int totalCreated = 0;

      // 각 요일별로 반복 수업 생성
      for (final weekday in _selectedWeekdays) {
        final timeRange = _weekdayTimeRanges[weekday];
        if (timeRange == null || timeRange['start'] == null) continue;

        final startTime = timeRange['start']!;
        final endTime = timeRange['end'] ?? startTime;
        
        // 프론트엔드: 1=월요일, 7=일요일
        // 백엔드: 0=월요일, 6=일요일 (Python weekday 형식)
        final backendWeekday = weekday - 1;

        try {
          final result = await ApiService.bulkGenerateSchedule(
            teacherId: teacher.teacherId,
            studentId: _selectedStudentId!,
            subjectId: _selectedSubject!,
            weekday: backendWeekday,
            startTime: startTime,
            endTime: endTime,
            dateFrom: dateFromStr,
            dateTo: dateToStr,
            notes: notes.isNotEmpty ? notes : null,
          );

          final created = result['created'] as int? ?? 0;
          totalCreated += created;
        } catch (e) {
          print('⚠️ 요일 $weekday 반복 수업 생성 실패: $e');
          // 일부 요일 실패해도 계속 진행
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('반복 수업이 성공적으로 등록되었습니다. (총 $totalCreated개)'),
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

            // 기간 선택
            _buildSectionTitle('기간 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildDateRangeSelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 요일 선택
            _buildSectionTitle('요일 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildWeekdaySelector(theme, colorScheme),
            SizedBox(height: Gaps.cardPad + 4),

            // 시간 선택 (요일별)
            if (_selectedWeekdays.isNotEmpty) ...[
              _buildSectionTitle('시간 선택', theme, colorScheme),
              SizedBox(height: Gaps.row),
              ..._selectedWeekdays.map((weekday) => Padding(
                padding: EdgeInsets.only(bottom: Gaps.cardPad + 4),
                child: _buildTimeSelectorForWeekday(weekday, theme, colorScheme),
              )),
              SizedBox(height: Gaps.cardPad + 4),
            ],

            // 과목 선택 (복수일 경우에만 표시)
            if (_selectedStudentId != null && _shouldShowSubjectSelector()) ...[
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
                      child: const SmallLoadingIndicator(
                        size: 20,
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
          final studentId = student['id'] as int?;
          final name = student['name'] as String? ?? '이름 없음';
          if (studentId == null) return null;
          return DropdownMenuItem<int>(
            value: studentId,
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }).whereType<DropdownMenuItem<int>>().toList(),
        dropdownColor: colorScheme.surface,
        onChanged: (value) {
          setState(() {
            _selectedStudentId = value;
            _selectedSubject = null; // 학생 변경 시 과목 초기화
          });
          // 학생 변경 시 과목 자동 설정
          if (value != null) {
            _autoSelectSubject(value);
          }
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

  Widget _buildTimeSelectorForWeekday(int weekday, ThemeData theme, ColorScheme colorScheme) {
    final timeRange = _weekdayTimeRanges[weekday];
    final weekdayLabel = _weekdayLabels[weekday - 1];
    
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
            // 요일 제목
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: Gaps.row - 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text(
                    '$weekdayLabel요일',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Gaps.card),
            // 선택된 시간 표시
            if (timeRange != null && timeRange['start'] != null) ...[
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
                      '${timeRange['start']} - ${timeRange['end'] ?? timeRange['start']}',
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
            // 타임슬롯 선택
            Wrap(
              spacing: Gaps.row,
              runSpacing: Gaps.row,
              children: _timeSlots.map((timeSlot) {
                final isSelected = _isTimeSlotSelected(weekday, timeSlot);
                final isDisabled = _isTimeSlotDisabled(weekday, timeSlot);
                return GestureDetector(
                  onTap: isDisabled ? null : () => _selectTimeSlot(weekday, timeSlot),
                  child: Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: Gaps.row),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? colorScheme.surfaceContainerHighest
                            : (isSelected ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(Radii.chip),
                        border: Border.all(
                          color: isDisabled
                              ? colorScheme.outline.withOpacity(0.3)
                              : (isSelected ? AppColors.primary : colorScheme.outline.withOpacity(0.2)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        timeSlot,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? colorScheme.onSurface.withOpacity(0.4)
                              : (isSelected 
                                  ? AppColors.surface 
                                  : AppColors.textSecondary),
                        ),
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

  /// 과목 선택 UI를 표시해야 하는지 확인 (복수일 경우만)
  bool _shouldShowSubjectSelector() {
    if (_selectedStudentId == null) return false;
    
    final student = _students.firstWhere(
      (s) => s['id'] == _selectedStudentId,
      orElse: () => {'id': null, 'name': '', 'subjects': <String>[]},
    );
    
    final subjects = (student['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    
    // 과목이 2개 이상일 때만 선택 UI 표시
    return subjects.length > 1;
  }

  Widget _buildSubjectSelector(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedStudentId == null) {
      return const SizedBox.shrink();
    }
    
    final student = _students.firstWhere(
      (s) => s['id'] == _selectedStudentId,
      orElse: () => {'id': null, 'name': '', 'subjects': <String>[]},
    );
    
    final subjects = (student['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    
    if (subjects.isEmpty) {
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
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: Gaps.row),
              Expanded(
                child: Text(
                  '이 학생의 과목 정보가 없습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Icon(Icons.note_outlined, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.cardPad),
        ),
      ),
    );
  }
}


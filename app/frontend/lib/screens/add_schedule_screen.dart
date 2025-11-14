import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/teacher_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../widgets/loading_indicator.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTimeSlot;

  const AddScheduleScreen({
    super.key,
    this.initialDate,
    this.initialTimeSlot,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  int? _selectedStudentId;
  String? _selectedSubject;
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;
  // 해당 날짜의 등록된 수업 목록 (disabled 처리용)
  List<Map<String, dynamic>> _existingSchedules = [];

  // 타임슬롯 정의 (30분 단위)
  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00',
  ];

  Map<String, String?> _selectedTimeRange = {
    'start': null,
    'end': null,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    
    // initialDate가 전달되면 해당 시간을 미리 선택
    if (widget.initialDate != null) {
      final hour = widget.initialDate!.hour;
      final minute = widget.initialDate!.minute;
      // 가장 가까운 30분 단위로 반올림
      final roundedMinute = minute < 30 ? 0 : 30;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${roundedMinute.toString().padLeft(2, '0')}';
      
      if (_timeSlots.contains(timeStr)) {
        _selectedTimeRange['start'] = timeStr;
      }
    }
    
    _loadStudents();
    _loadExistingSchedules();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      // 활성화된 학생만 조회
      final studentsData = await ApiService.getStudents(isActive: true);
      // API 응답을 올바른 형식으로 변환
      final studentsList = studentsData.map((s) {
        final studentId = s['student_id'] as int?;
        final name = s['name'] as String? ?? '이름 없음';
        // 백엔드에서는 subject_id (단일 문자열)를 반환하므로, 이를 리스트로 변환
        final subjectId = s['subject_id'] as String?;
        List<String> subjects = [];
        if (subjectId != null && subjectId.isNotEmpty) {
          // subject_id가 있으면 리스트에 추가
          subjects = [subjectId];
        } else {
          // 없으면 기존 방식(subjects 배열)도 시도 (하위 호환성)
          final subjectsArray = s['subjects'] as List<dynamic>?;
          if (subjectsArray != null && subjectsArray.isNotEmpty) {
            subjects = subjectsArray.map((e) => e.toString()).toList();
          }
        }
        
        return {
          'id': studentId, // student_id를 id로 변환
          'name': name,
          'subjects': subjects,
        };
      }).where((s) => s['id'] != null).toList();
      
      setState(() {
        _students = studentsList;
        _isLoadingStudents = false;
      });
    } catch (e) {
      print('⚠️ 학생 목록 로드 실패: $e');
      setState(() {
        _students = [];
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // 날짜 변경 시 시간 범위 초기화
        _selectedTimeRange = {'start': null, 'end': null};
      });
      // 날짜 변경 시 해당 날짜의 등록된 수업 목록 다시 로드
      _loadExistingSchedules();
    }
  }

  /// 해당 날짜의 등록된 수업 목록 로드
  Future<void> _loadExistingSchedules() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: dateStr,
        dateTo: dateStr,
        status: 'confirmed', // confirmed 수업만
      );

      if (mounted) {
        setState(() {
          _existingSchedules = schedules;
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

  /// 타임슬롯이 이미 등록된 수업과 겹치는지 확인
  bool _isTimeSlotDisabled(String timeSlot) {
    if (_existingSchedules.isEmpty) return false;

    // 타임슬롯의 시간 파싱
    final slotParts = timeSlot.split(':');
    final slotHour = int.tryParse(slotParts[0]) ?? 0;
    final slotMin = int.tryParse(slotParts[1]) ?? 0;
    final slotTime = slotHour * 60 + slotMin; // 분 단위로 변환

    // 각 등록된 수업과 겹치는지 확인
    for (final schedule in _existingSchedules) {
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
      // 타임슬롯은 30분 단위이므로, 해당 시간대의 시작점을 기준으로 확인
      if (slotTime >= scheduleStart && slotTime < scheduleEnd) {
        return true; // 겹침
      }
    }

    return false;
  }

  void _selectTimeSlot(String timeSlot) {
    // disabled된 타임슬롯은 선택 불가
    if (_isTimeSlotDisabled(timeSlot)) {
      return;
    }

    setState(() {
      if (_selectedTimeRange['start'] == null) {
        // 시작 시간 선택
        _selectedTimeRange['start'] = timeSlot;
        _selectedTimeRange['end'] = null;
      } else if (_selectedTimeRange['end'] == null) {
        // 종료 시간 선택
        final startTime = _selectedTimeRange['start']!;
        final startIndex = _timeSlots.indexOf(startTime);
        final selectedIndex = _timeSlots.indexOf(timeSlot);
        
        if (selectedIndex > startIndex) {
          // 종료 시간이 시작 시간보다 뒤면 설정
          _selectedTimeRange['end'] = timeSlot;
        } else {
          // 종료 시간이 시작 시간보다 앞이면 시작 시간 재설정
          _selectedTimeRange['start'] = timeSlot;
          _selectedTimeRange['end'] = null;
        }
      } else {
        // 새로운 시작 시간 선택
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

  bool _isTimeSlotStart(String timeSlot) {
    return _selectedTimeRange['start'] == timeSlot;
  }

  bool _isTimeSlotEnd(String timeSlot) {
    return _selectedTimeRange['end'] == timeSlot;
  }

  Future<void> _submit() async {
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
      // 현재 로그인한 선생님 정보 가져오기
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        throw Exception('선생님 정보를 불러올 수 없습니다. 다시 로그인해주세요.');
      }

      // 과목이 선택되지 않았으면 에러
      if (_selectedSubject == null || _selectedSubject!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('과목을 선택해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final lessonDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startTime = _selectedTimeRange['start'] as String;
      final endTime = _selectedTimeRange['end'] ?? _selectedTimeRange['start'] as String;

      // 시간 충돌 체크
      final hasConflict = await ApiService.checkScheduleConflict(
        teacherId: teacher.teacherId,
        lessonDate: lessonDate,
        startTime: startTime,
        endTime: endTime,
      );

      if (hasConflict) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('해당 시간대에 이미 등록된 수업이 있습니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final data = <String, dynamic>{
        'teacher_id': teacher.teacherId, // 현재 로그인한 선생님 ID 추가
        'student_id': _selectedStudentId,
        'lesson_date': lessonDate,
        'start_time': startTime,
        'end_time': endTime,
        'subject_id': _selectedSubject!, // subject_id로 변경 (백엔드는 subject_id 사용)
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await ApiService.createSchedule(data);

      // 등록된 수업 목록 다시 로드 (disabled 상태 업데이트)
      await _loadExistingSchedules();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정이 성공적으로 등록되었습니다.'),
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
        title: const Text('일정 추가'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const TossScrollPhysics(),
          padding: EdgeInsets.all(Gaps.card),
          children: [
            // 날짜 선택
            _buildSectionTitle('날짜 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                child: Padding(
                  padding: EdgeInsets.all(Gaps.card),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
                      SizedBox(width: Gaps.row),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: Gaps.row - 6),
                            Text(
                              '날짜 변경',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 시간 선택 (타임슬롯)
            _buildSectionTitle('시간 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(Gaps.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTimeRange['start'] != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: Gaps.card),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, 
                                size: 18, color: AppColors.primary),
                            SizedBox(width: Gaps.row - 2),
                            Text(
                              _selectedTimeRange['end'] != null
                                  ? '${_selectedTimeRange['start']} - ${_selectedTimeRange['end']}'
                                  : '${_selectedTimeRange['start']}부터 선택 중...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: Gaps.row - 2,
                      runSpacing: Gaps.row - 2,
                      children: _timeSlots.map((timeSlot) {
                        final isSelected = _isTimeSlotSelected(timeSlot);
                        final isStart = _isTimeSlotStart(timeSlot);
                        final isEnd = _isTimeSlotEnd(timeSlot);
                        final isDisabled = _isTimeSlotDisabled(timeSlot);
                        
                        return InkWell(
                          onTap: isDisabled ? null : () => _selectTimeSlot(timeSlot),
                          borderRadius: BorderRadius.circular(Radii.icon),
                          child: Opacity(
                            opacity: isDisabled ? 0.4 : 1.0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Gaps.row,
                                vertical: Gaps.row - 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? colorScheme.surfaceContainerHighest
                                    : (isSelected
                                        ? (isStart || isEnd
                                            ? AppColors.primary
                                            : colorScheme.primaryContainer)
                                        : colorScheme.surface),
                                borderRadius: BorderRadius.circular(Radii.chip),
                                border: Border.all(
                                  color: isDisabled
                                      ? colorScheme.outline.withOpacity(0.3)
                                      : (isSelected
                                          ? AppColors.primary
                                          : colorScheme.outline.withOpacity(0.2)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                timeSlot,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: isStart || isEnd
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isDisabled
                                      ? colorScheme.onSurface.withOpacity(0.4)
                                      : (isSelected
                                          ? (isStart || isEnd
                                              ? AppColors.surface
                                              : colorScheme.onPrimaryContainer)
                                          : colorScheme.onSurface),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: Gaps.row - 2),
                    Text(
                      '시작 시간을 선택한 후 종료 시간을 선택하세요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 학생 선택
            _buildSectionTitle('학생 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: _isLoadingStudents
                  ? Padding(
                      padding: EdgeInsets.all(Gaps.cardPad + 4),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _students.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(Gaps.cardPad + 4),
                          child: Center(
                            child: Text(
                              '등록된 학생이 없습니다',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _students.map((student) {
                            final isSelected = _selectedStudentId == student['id'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStudentId = student['id'];
                                  // 학생이 선택되면 첫 번째 과목을 기본값으로 설정
                                  if (student['subjects'] != null &&
                                      student['subjects'] is List &&
                                      (student['subjects'] as List).isNotEmpty) {
                                    _selectedSubject = student['subjects'][0].toString();
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(Gaps.card),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outline.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: Gaps.screen,
                                      backgroundColor: isSelected
                                          ? AppColors.primary
                                          : colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        (student['name']?.toString() ?? '?')[0],
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.surface
                                              : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Gaps.row),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name']?.toString() ?? '이름 없음',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? colorScheme.onPrimaryContainer
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          if (student['subjects'] != null &&
                                              student['subjects'] is List &&
                                              (student['subjects'] as List).isNotEmpty)
                                            Text(
                                              (student['subjects'] as List)
                                                  .map((s) => s.toString())
                                                  .join(', '),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isSelected
                                                    ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                    : colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 과목 선택 (학생 선택 후)
            if (_selectedStudentId != null && _students.isNotEmpty)
              ...() {
                try {
                  final selectedStudent = _students.firstWhere(
                    (s) => s['id'] == _selectedStudentId,
                  );
                  final subjects = selectedStudent['subjects'];
                  
                  if (subjects != null && subjects is List && subjects.isNotEmpty) {
                    return [
                      _buildSectionTitle('과목 선택', theme, colorScheme),
                      SizedBox(height: Gaps.row),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.chip + 4),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(Gaps.card),
                          child: Wrap(
                            spacing: Gaps.row - 2,
                            runSpacing: Gaps.row - 2,
                            children: subjects
                                .map<Widget>((subject) {
                              final subjectStr = subject.toString();
                              final isSelected = _selectedSubject == subjectStr;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedSubject = subjectStr);
                                },
                                borderRadius: BorderRadius.circular(Radii.chip),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Gaps.card,
                                    vertical: Gaps.row,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(Radii.chip),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    subjectStr,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Gaps.cardPad + 4),
                    ];
                  }
                } catch (e) {
                  // 학생을 찾을 수 없거나 과목이 없는 경우
                }
                return <Widget>[];
              }(),

            // 메모
            _buildSectionTitle('메모 (선택사항)', theme, colorScheme),
            SizedBox(height: Gaps.row),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '메모를 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(Gaps.card),
                ),
              ),
            ),
            SizedBox(height: Gaps.cardPad + 12),

            // 등록 버튼
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Gaps.card),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: Gaps.screen,
                      width: Gaps.screen,
                      child: SmallLoadingIndicator(
                        size: 20,
                      ),
                    )
                  : Text(
                      '일정 등록',
                      style: theme.textTheme.bodyLarge?.copyWith(
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

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

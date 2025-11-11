import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';

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
  }

  @override
  void dispose() {
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
      // API 실패 시 데모 데이터 사용
      setState(() {
        _students = [
          {
            'id': 1,
            'name': '김민수',
            'subjects': ['수학'],
          },
          {
            'id': 2,
            'name': '이지은',
            'subjects': ['영어', '수학'],
          },
          {
            'id': 3,
            'name': '박서준',
            'subjects': ['과학', '수학'],
          },
        ];
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
    }
  }

  void _selectTimeSlot(String timeSlot) {
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
        const SnackBar(
          content: Text('시작 시간을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학생을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'student_id': _selectedStudentId,
        'lesson_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time': _selectedTimeRange['start'],
        'end_time': _selectedTimeRange['end'] ?? _selectedTimeRange['start'],
        if (_selectedSubject != null) 'subject': _selectedSubject,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
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
          padding: const EdgeInsets.all(16),
          children: [
            // 날짜 선택
            _buildSectionTitle('날짜 선택', theme, colorScheme),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 4),
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
            const SizedBox(height: 24),

            // 시간 선택 (타임슬롯)
            _buildSectionTitle('시간 선택', theme, colorScheme),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTimeRange['start'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, 
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTimeRange['end'] != null
                                  ? '${_selectedTimeRange['start']} - ${_selectedTimeRange['end']}'
                                  : '${_selectedTimeRange['start']}부터 선택 중...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeSlots.map((timeSlot) {
                        final isSelected = _isTimeSlotSelected(timeSlot);
                        final isStart = _isTimeSlotStart(timeSlot);
                        final isEnd = _isTimeSlotEnd(timeSlot);
                        
                        return InkWell(
                          onTap: () => _selectTimeSlot(timeSlot),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isStart || isEnd
                                      ? colorScheme.primary
                                      : colorScheme.primaryContainer)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              timeSlot,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: isStart || isEnd
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isSelected
                                    ? (isStart || isEnd
                                        ? colorScheme.onPrimary
                                        : colorScheme.onPrimaryContainer)
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
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
            const SizedBox(height: 24),

            // 학생 선택
            _buildSectionTitle('학생 선택', theme, colorScheme),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: _isLoadingStudents
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _students.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
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
                                padding: const EdgeInsets.all(16),
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
                                      radius: 20,
                                      backgroundColor: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        (student['name']?.toString() ?? '?')[0],
                                        style: TextStyle(
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                        color: colorScheme.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 24),

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
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: subjects
                                .map<Widget>((subject) {
                              final subjectStr = subject.toString();
                              final isSelected = _selectedSubject == subjectStr;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedSubject = subjectStr);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
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
                      const SizedBox(height: 24),
                    ];
                  }
                } catch (e) {
                  // 학생을 찾을 수 없거나 과목이 없는 경우
                }
                return <Widget>[];
              }(),

            // 메모
            _buildSectionTitle('메모 (선택사항)', theme, colorScheme),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

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

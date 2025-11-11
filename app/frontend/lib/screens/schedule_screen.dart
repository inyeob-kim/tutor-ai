import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../services/settings_service.dart';
import '../theme/scroll_physics.dart';
import 'add_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now(); // 현재 보는 월
  final ScrollController _dateScrollController = ScrollController();

  // 타임슬롯 설정 (설정에서 가져옴)
  int _startHour = 12;
  int _endHour = 22;
  Set<int> _disabledHours = {};
  bool _excludeWeekends = false;

  // 데모 데이터 - 학생 목록
  final List<Student> _students = [
    Student(
      name: "김민수",
      grade: "고등학교 2학년",
      subjects: ["수학"],
      phone: "010-1234-5678",
      sessions: 24,
      completedSessions: 22,
      color: const Color(0xFF3B82F6),
      nextClass: "11월 7일 10:00",
      attendanceRate: 92,
      isAdult: false,
    ),
    Student(
      name: "이지은",
      grade: "중학교 3학년",
      subjects: ["영어", "수학"],
      phone: "010-2345-6789",
      sessions: 18,
      completedSessions: 18,
      color: const Color(0xFF10B981),
      nextClass: "11월 7일 14:00",
      attendanceRate: 100,
      isAdult: false,
    ),
    Student(
      name: "박서준",
      grade: "고등학교 1학년",
      subjects: ["과학", "수학"],
      phone: "010-3456-7890",
      sessions: 20,
      completedSessions: 18,
      color: const Color(0xFF9333EA),
      nextClass: "11월 7일 16:00",
      attendanceRate: 90,
      isAdult: false,
    ),
    Student(
      name: "최유진",
      grade: "중학교 2학년",
      subjects: ["영어"],
      phone: "010-4567-8901",
      sessions: 16,
      completedSessions: 14,
      color: const Color(0xFFF59E0B),
      nextClass: "11월 7일 19:00",
      attendanceRate: 88,
      isAdult: false,
    ),
    Student(
      name: "정다은",
      grade: "고등학교 3학년",
      subjects: ["국어", "영어"],
      phone: "010-5678-9012",
      sessions: 30,
      completedSessions: 28,
      color: const Color(0xFFEC4899),
      nextClass: "11월 7일 20:00",
      attendanceRate: 93,
      isAdult: false,
    ),
    Student(
      name: "윤서연",
      subjects: ["토익", "영어회화"],
      phone: "010-6789-0123",
      sessions: 12,
      completedSessions: 10,
      color: const Color(0xFF06B6D4),
      nextClass: "11월 7일 21:00",
      attendanceRate: 83,
      isAdult: true,
    ),
  ];

  // 데모 데이터 - 수업 목록 (더미 데이터 추가)
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _initializeLessons();
    _loadSettings();
    // 주말 제외 옵션이 켜져 있고 현재 날짜가 주말이면 다음 평일로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final excludeWeekends = await SettingsService.getExcludeWeekends();
      if (excludeWeekends) {
        final weekday = _selectedDate.weekday;
        if (weekday == 6 || weekday == 7) {
          // 다음 평일 찾기
          int daysToAdd = weekday == 6 ? 2 : 1; // 토요일이면 2일 후(월요일), 일요일이면 1일 후(월요일)
          setState(() {
            _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
          });
        }
      }
      _scrollToSelectedDate();
    });
  }

  Future<void> _loadSettings() async {
    final startHour = await SettingsService.getStartHour();
    final endHour = await SettingsService.getEndHour();
    final disabledHours = await SettingsService.getDisabledHours(_selectedDate);
    final excludeWeekends = await SettingsService.getExcludeWeekends();
    setState(() {
      _startHour = startHour;
      _endHour = endHour;
      _disabledHours = disabledHours;
      _excludeWeekends = excludeWeekends;
    });
  }

  Future<void> _refreshDisabledHours() async {
    final disabledHours = await SettingsService.getDisabledHours(_selectedDate);
    setState(() {
      _disabledHours = disabledHours;
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (!_dateScrollController.hasClients) return;
    
    // 현재 보는 월의 날짜 목록 생성
    final lastDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final dates = List.generate(daysInMonth, (index) {
      return DateTime(_viewMonth.year, _viewMonth.month, index + 1);
    });
    
    final selectedIndex = dates.indexWhere((date) =>
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day);
    
    if (selectedIndex != -1) {
      // 각 날짜 카드의 대략적인 너비 (카드 + 마진) 약 80px
      const itemWidth = 80.0;
      final screenWidth = _dateScrollController.position.viewportDimension;
      final scrollPosition = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _dateScrollController.animateTo(
        scrollPosition.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeLessons() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 오늘 날짜의 수업들
    _lessons = [
      // 오늘 수업들
      Lesson(
        id: '1',
        studentId: '1',
        startsAt: DateTime(today.year, today.month, today.day, 13, 0),
        subject: '수학',
        durationMin: 90,
        status: 'done',
        attendance: 'show',
      ),
      Lesson(
        id: '2',
        studentId: '2',
        startsAt: DateTime(today.year, today.month, today.day, 15, 0),
        subject: '영어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '3',
        studentId: '3',
        startsAt: DateTime(today.year, today.month, today.day, 17, 0),
        subject: '과학',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '4',
        studentId: '4',
        startsAt: DateTime(today.year, today.month, today.day, 19, 0),
        subject: '영어',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '5',
        studentId: '5',
        startsAt: DateTime(today.year, today.month, today.day, 20, 0),
        subject: '국어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      
      // 내일 수업들
      Lesson(
        id: '6',
        studentId: '1',
        startsAt: DateTime(today.year, today.month, today.day + 1, 14, 0),
        subject: '수학',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '7',
        studentId: '2',
        startsAt: DateTime(today.year, today.month, today.day + 1, 16, 0),
        subject: '영어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '8',
        studentId: '6',
        startsAt: DateTime(today.year, today.month, today.day + 1, 18, 0),
        subject: '토익',
        durationMin: 120,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '9',
        studentId: '3',
        startsAt: DateTime(today.year, today.month, today.day + 1, 20, 0),
        subject: '과학',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      
      // 모레 수업들
      Lesson(
        id: '10',
        studentId: '1',
        startsAt: DateTime(today.year, today.month, today.day + 2, 13, 0),
        subject: '수학',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '11',
        studentId: '4',
        startsAt: DateTime(today.year, today.month, today.day + 2, 15, 0),
        subject: '영어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '12',
        studentId: '5',
        startsAt: DateTime(today.year, today.month, today.day + 2, 17, 0),
        subject: '국어',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      
      // 이번 주 다른 날짜들
      Lesson(
        id: '13',
        studentId: '2',
        startsAt: DateTime(today.year, today.month, today.day + 3, 14, 0),
        subject: '영어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '14',
        studentId: '3',
        startsAt: DateTime(today.year, today.month, today.day + 3, 16, 0),
        subject: '과학',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '15',
        studentId: '6',
        startsAt: DateTime(today.year, today.month, today.day + 4, 18, 0),
        subject: '영어회화',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '16',
        studentId: '1',
        startsAt: DateTime(today.year, today.month, today.day + 5, 13, 0),
        subject: '수학',
        durationMin: 90,
        status: 'pending',
        attendance: null,
      ),
      Lesson(
        id: '17',
        studentId: '4',
        startsAt: DateTime(today.year, today.month, today.day + 5, 19, 0),
        subject: '영어',
        durationMin: 60,
        status: 'pending',
        attendance: null,
      ),
    ];
  }


  List<Lesson> get _filteredLessons {
    final selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return _lessons
        .where((lesson) {
          final lessonDate = DateTime(
            lesson.startsAt.year,
            lesson.startsAt.month,
            lesson.startsAt.day,
          );
          return lessonDate.isAtSameMomentAs(selectedDate);
        })
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  // 타임슬롯별 수업 찾기
  Lesson? _findLessonForSlot(int hour) {
    try {
      return _filteredLessons.firstWhere(
        (lesson) => lesson.startsAt.hour == hour,
      );
    } catch (e) {
      return null;
    }
  }

  // 타임슬롯 리스트 생성
  List<int> get _timeSlots {
    return List.generate(
      _endHour - _startHour + 1,
      (index) => _startHour + index,
    );
  }

  void _toggleDone(String lessonId) {
    setState(() {
      final lesson = _lessons.firstWhere((l) => l.id == lessonId);
      final index = _lessons.indexOf(lesson);
      _lessons[index] = Lesson(
        id: lesson.id,
        studentId: lesson.studentId,
        startsAt: lesson.startsAt,
        subject: lesson.subject,
        durationMin: lesson.durationMin,
        status: lesson.status == 'done' ? 'pending' : 'done',
        attendance: lesson.attendance,
      );
    });
  }

  void _setAttendance(String lessonId, String attendance) {
    setState(() {
      final lesson = _lessons.firstWhere((l) => l.id == lessonId);
      final index = _lessons.indexOf(lesson);
      _lessons[index] = Lesson(
        id: lesson.id,
        studentId: lesson.studentId,
        startsAt: lesson.startsAt,
        subject: lesson.subject,
        durationMin: lesson.durationMin,
        status: lesson.status,
        attendance: lesson.attendance == attendance ? null : attendance,
      );
    });
  }

  Student? _findStudent(String studentId) {
    try {
      final index = int.parse(studentId) - 1;
      if (index >= 0 && index < _students.length) {
        return _students[index];
      }
    } catch (e) {
      // 파싱 실패
    }
    return null;
  }

  void _goNewLesson(int hour) async {
    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        0,
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddScheduleScreen(
            initialDate: selectedDateTime,
          ),
        ),
      );
      if (result == true) {
        setState(() {
          // 목록 새로고침
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('화면을 열 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteLesson(String lessonId) async {
    final lesson = _lessons.firstWhere((l) => l.id == lessonId);
    final student = _findStudent(lesson.studentId);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수업 취소'),
        content: Text(
          '${student?.name ?? "학생"}의 수업을 취소하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _lessons.removeWhere((l) => l.id == lessonId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수업이 취소되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 월 선택 및 날짜 선택 스크롤 뷰
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMonthSelector(theme, colorScheme),
                _buildDateScrollSelector(theme, colorScheme),
              ],
            ),
          ),
          // 메인 컨텐츠
          Expanded(
            child: CustomScrollView(
              physics: const TossScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          title: '수업 스케줄',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_filteredLessons.length}개',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 주말 제외 옵션이 켜져 있고 선택된 날짜가 주말이면 메시지 표시
                        Builder(
                          builder: (context) {
                            if (_excludeWeekends) {
                              final weekday = _selectedDate.weekday; // 1=월요일, 7=일요일
                              if (weekday == 6 || weekday == 7) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.weekend_rounded,
                                          size: 64,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '주말에는 수업이 없습니다',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '설정에서 주말 제외 옵션을 끄면\n주말에도 수업을 등록할 수 있습니다',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                            // 평일이거나 주말 제외 옵션이 꺼져 있으면 시간대 표시
                            return Column(
                              children: [
                                for (final hour in _timeSlots)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildScheduleCard(hour, theme, colorScheme),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: subtitle != null ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  String _formatKoreanDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }

  Widget _buildMonthSelector(ThemeData theme, ColorScheme colorScheme) {
    final today = DateTime.now();
    final canGoPrevious = _viewMonth.year > today.year - 1 ||
        (_viewMonth.year == today.year - 1 && _viewMonth.month > 1) ||
        (_viewMonth.year == today.year && _viewMonth.month > today.month - 2);
    final canGoNext = _viewMonth.year < today.year + 1 ||
        (_viewMonth.year == today.year + 1 && _viewMonth.month < 12) ||
        (_viewMonth.year == today.year && _viewMonth.month < today.month + 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 월 버튼
          IconButton(
            onPressed: canGoPrevious
                ? () async {
                    setState(() {
                      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
                      // 선택된 날짜가 새로운 월 범위를 벗어나면 첫 날로 설정
                      if (_selectedDate.year != _viewMonth.year ||
                          _selectedDate.month != _viewMonth.month) {
                        _selectedDate = DateTime(_viewMonth.year, _viewMonth.month, 1);
                      }
                    });
                    await _refreshDisabledHours();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _scrollToSelectedDate();
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: canGoPrevious
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
          // 월/년도 표시 및 선택 버튼
          GestureDetector(
            onTap: () => _showMonthYearPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_viewMonth.year}년 ${_viewMonth.month}월',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          // 다음 월 버튼
          IconButton(
            onPressed: canGoNext
                ? () async {
                    setState(() {
                      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
                      // 선택된 날짜가 새로운 월 범위를 벗어나면 첫 날로 설정
                      if (_selectedDate.year != _viewMonth.year ||
                          _selectedDate.month != _viewMonth.month) {
                        _selectedDate = DateTime(_viewMonth.year, _viewMonth.month, 1);
                      }
                    });
                    await _refreshDisabledHours();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _scrollToSelectedDate();
                    });
                  }
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: canGoNext
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewMonth,
      firstDate: DateTime(DateTime.now().year - 1, DateTime.now().month),
      lastDate: DateTime(DateTime.now().year + 1, DateTime.now().month),
      initialDatePickerMode: DatePickerMode.year,
      helpText: '년도 선택',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _viewMonth = DateTime(picked.year, picked.month, 1);
        // 선택된 날짜가 새로운 월 범위를 벗어나면 첫 날로 설정
        if (_selectedDate.year != _viewMonth.year ||
            _selectedDate.month != _viewMonth.month) {
          _selectedDate = DateTime(_viewMonth.year, _viewMonth.month, 1);
        }
      });
      await _refreshDisabledHours();
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToSelectedDate();
      });
    }
  }

  Widget _buildDateScrollSelector(ThemeData theme, ColorScheme colorScheme) {
    final today = DateTime.now();
    // 현재 보는 월의 마지막 날 계산
    final lastDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // 해당 월의 모든 날짜 생성
    final allDates = List.generate(daysInMonth, (index) {
      return DateTime(_viewMonth.year, _viewMonth.month, index + 1);
    });
    
    // 주말 제외 옵션이 켜져 있으면 주말 제외
    final dates = _excludeWeekends
        ? allDates.where((date) {
            final weekday = date.weekday; // 1=월요일, 7=일요일
            return weekday != 6 && weekday != 7; // 토요일(6), 일요일(7) 제외
          }).toList()
        : allDates;

    return SizedBox(
      height: 80,
      child: dates.isEmpty
          ? Center(
              child: Text(
                '이번 달에는 선택 가능한 날짜가 없습니다',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedDate = date;
                      // 선택한 날짜가 다른 월이면 월도 업데이트
                      if (date.year != _viewMonth.year || date.month != _viewMonth.month) {
                        _viewMonth = DateTime(date.year, date.month, 1);
                      }
                    });
                    await _refreshDisabledHours();
                    // 선택된 날짜로 스크롤
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _scrollToSelectedDate();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: 1,
                            ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatKoreanDate(date).split('(')[1].replaceAll(')', ''), // 요일만
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : isToday
                                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildScheduleCard(
    int hour,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final lesson = _findLessonForSlot(hour);
    final timeStr = '${hour.toString().padLeft(2, '0')}:00';
    final endTimeStr = '${(hour + 1).toString().padLeft(2, '0')}:00';
    final isDisabled = _disabledHours.contains(hour);
    
    if (lesson != null) {
      final student = _findStudent(lesson.studentId);
      final isDone = lesson.status == 'done';
      final endTime = lesson.startsAt.add(Duration(minutes: lesson.durationMin));
      final actualEndTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      
      final accentColor = isDone
          ? const Color(0xFF10B981)
          : colorScheme.primary;

      // 등록된 수업 카드는 스와이프 제스처 없이 일반 Container로 표시
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE7F0FF),
              Color(0xFFDCE8FF),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  GestureDetector(
                    onTap: () => _toggleDone(lesson.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDone 
                            ? accentColor 
                            : Colors.white.withValues(alpha: 0.9),
                        border: Border.all(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDone ? 0.08 : 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '$timeStr - $actualEndTimeStr',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          student?.name ?? "(삭제된 학생)",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                : colorScheme.onSurface,
                            decoration:
                              isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lesson.subject} · ${lesson.durationMin}분',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 삭제 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _deleteLesson(lesson.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.remove_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ),
                ),
              ],
            ),
            if (!isDone) ...[
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAttendanceChip(
                            '출석',
                            'show',
                            lesson.attendance == 'show',
                            false,
                            () => _setAttendance(lesson.id, 'show'),
                            theme,
                            colorScheme,
                          ),
                          _buildAttendanceChip(
                            '지각',
                            'late',
                            lesson.attendance == 'late',
                            false,
                            () => _setAttendance(lesson.id, 'late'),
                            theme,
                            colorScheme,
                          ),
                          _buildAttendanceChip(
                            '결석',
                            'absent',
                            lesson.attendance == 'absent',
                            false,
                            () => _setAttendance(lesson.id, 'absent'),
                            theme,
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // 비활성화된 시간대인 경우
      if (isDisabled) {
        return Dismissible(
          key: Key('disabled_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}_$hour'),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) async {
            // 상태를 먼저 업데이트
            await SettingsService.toggleDisabledHour(_selectedDate, hour);
            if (mounted) {
              await _refreshDisabledHours();
            }
            return false; // dismiss 취소 - 카드는 그대로 유지
          },
          background: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '활성화',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: IgnorePointer(
            ignoring: true, // 클릭 비활성화
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(24),
              padding: EdgeInsets.zero,
              color: Colors.red.withValues(alpha: 0.4),
              strokeWidth: 3,
              dashPattern: const [10, 5],
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 80,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: Colors.red.withValues(alpha: 0.6),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '$timeStr - $endTimeStr (불가)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      // 빈 슬롯 (활성화된 시간대)
      return Dismissible(
        key: Key('empty_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}_$hour'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // 상태를 먼저 업데이트
          await SettingsService.toggleDisabledHour(_selectedDate, hour);
          if (mounted) {
            await _refreshDisabledHours();
          }
          return false; // dismiss 취소 - 카드는 그대로 유지
        },
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.5),
              width: 3,
              style: BorderStyle.solid,
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '비활성화',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.block_rounded,
                color: Colors.red,
                size: 32,
              ),
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            // 스와이프 후 비활성화된 상태인지 확인
            final isNowDisabled = _disabledHours.contains(hour);
            return IgnorePointer(
              ignoring: isNowDisabled, // 비활성화된 경우 클릭 비활성화
              child: GestureDetector(
                onTap: isNowDisabled ? null : () => _goNewLesson(hour),
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(24),
                  padding: EdgeInsets.zero,
                  color: isNowDisabled
                      ? Colors.red.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  strokeWidth: 3,
                  dashPattern: const [10, 5],
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 80,
                    ),
                    decoration: BoxDecoration(
                      color: isNowDisabled
                          ? Colors.grey.withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isNowDisabled
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Icon(
                          isNowDisabled ? Icons.block_rounded : Icons.add,
                          color: isNowDisabled
                              ? Colors.red.withValues(alpha: 0.6)
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isNowDisabled
                                ? Colors.red.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isNowDisabled
                                ? '$timeStr - $endTimeStr (불가)'
                                : '$timeStr - $endTimeStr',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isNowDisabled
                                  ? Colors.red.withValues(alpha: 0.7)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }


  Widget _buildAttendanceChip(
    String label,
    String value,
    bool isSelected,
    bool isDimmed,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDimmed ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

}

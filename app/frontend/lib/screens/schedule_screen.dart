import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import 'add_schedule_screen.dart';
import 'add_recurring_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now(); // 현재 보는 월
  final ScrollController _dateScrollController = ScrollController();

  // 타임슬롯 설정 (설정에서 가져옴)
  int _startHour = 12;
  int _endHour = 22;
  Set<int> _disabledHours = {};
  bool _excludeWeekends = false;

  // 학생 ID -> Student 매핑 (API에서 가져온 데이터 사용)
  Map<int, Student> _studentsMap = {};
  // 수업 목록
  List<Lesson> _lessons = [];
  
  // 마지막으로 화면이 활성화된 시간
  DateTime? _lastActiveTime;

  @override
  bool get wantKeepAlive => false; // 상태를 유지하지 않고 매번 초기화

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 항상 오늘 날짜로 설정
    _resetToToday();
    _loadStudents();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 오늘 날짜로 리셋
    final now = DateTime.now();
    // 마지막 활성화 시간과 비교하여 1초 이상 지났으면 리셋 (중복 호출 방지)
    if (_lastActiveTime == null || now.difference(_lastActiveTime!).inSeconds > 1) {
      _lastActiveTime = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resetToToday();
        }
      });
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  /// 오늘 날짜로 리셋
  Future<void> _resetToToday() async {
    final today = DateTime.now();
    final excludeWeekends = await SettingsService.getExcludeWeekends();
    
    DateTime selectedDate = today;
    if (excludeWeekends) {
      final weekday = today.weekday;
      if (weekday == 6 || weekday == 7) {
        // 다음 평일 찾기
        int daysToAdd = weekday == 6 ? 2 : 1; // 토요일이면 2일 후(월요일), 일요일이면 1일 후(월요일)
        selectedDate = today.add(Duration(days: daysToAdd));
      }
    }
    
    // 오늘 날짜로 변경된 경우에만 업데이트
    if (mounted && (_selectedDate.year != selectedDate.year || 
        _selectedDate.month != selectedDate.month || 
        _selectedDate.day != selectedDate.day)) {
      setState(() {
        _selectedDate = selectedDate;
        _viewMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToSelectedDate();
          _loadLessons();
        }
      });
    } else if (mounted) {
      // 날짜가 같아도 수업 목록은 새로고침
      _loadLessons();
    }
  }

  /// 학생 목록 로드
  Future<void> _loadStudents() async {
    try {
      final studentsData = await ApiService.getStudents();
      final studentsMap = <int, Student>{};
      
      for (final s in studentsData) {
        final studentId = s['student_id'] as int? ?? 0;
        final name = s['name'] as String? ?? '이름 없음';
        final grade = s['grade'] as String?;
        final subjects = (s['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final phone = s['phone'] as String? ?? '';
        final sessions = s['total_sessions'] as int? ?? 0;
        final completedSessions = s['completed_sessions'] as int? ?? 0;
        final isAdult = s['is_adult'] as bool? ?? false;
        final nextClass = s['next_class'] as String? ?? '';
        final attendanceRate = sessions > 0 ? ((completedSessions / sessions) * 100).round() : 0;

        final student = Student(
          name: name,
          grade: grade,
          subjects: subjects,
          phone: phone,
          sessions: sessions,
          completedSessions: completedSessions,
          color: AppColors.primary,
          nextClass: nextClass,
          attendanceRate: attendanceRate,
          isAdult: isAdult,
        );
        
        studentsMap[studentId] = student;
      }

      if (mounted) {
        setState(() {
          _studentsMap = studentsMap;
        });
      }
    } catch (e) {
      print('⚠️ 학생 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _studentsMap = {};
        });
      }
    }
  }

  /// 수업 목록 로드
  Future<void> _loadLessons() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        if (mounted) {
          setState(() {
            _lessons = [];
          });
        }
        return;
      }

      // 선택된 날짜
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // 스케줄 조회
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: dateStr,
        dateTo: dateStr,
      );

      // 학생 정보 다시 로드 (스케줄에 학생 이름 표시용)
      if (_studentsMap.isEmpty) {
        await _loadStudents();
      }

      // 수업을 Lesson으로 변환
      final lessonsList = schedules.map((s) {
        final scheduleId = s['schedule_id'] as int? ?? 0;
        final studentId = s['student_id'] as int? ?? 0;
        final subject = s['subject_id'] as String? ?? '과목 없음';
        final startTime = s['start_time'] as String? ?? '00:00';
        final endTime = s['end_time'] as String? ?? '00:00';
        final status = s['status'] as String? ?? 'pending';

        // 시간 파싱
        final startParts = startTime.split(':');
        final endParts = endTime.split(':');
        final startHour = startParts.isNotEmpty ? int.tryParse(startParts[0]) ?? 0 : 0;
        final startMin = startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;
        final endHour = endParts.isNotEmpty ? int.tryParse(endParts[0]) ?? 0 : 0;
        final endMin = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;

        // 시작 시간 계산
        final startsAt = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          startHour,
          startMin,
        );

        // 종료 시간 계산
        final endsAt = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          endHour,
          endMin,
        );

        // 수업 시간 (분)
        final durationMin = endsAt.difference(startsAt).inMinutes;

        // 출석 상태
        String? attendance;
        if (status == 'completed' || status == 'done') {
          attendance = 'show'; // 기본값은 출석
        }

        return Lesson(
          id: scheduleId.toString(),
          studentId: studentId.toString(),
          startsAt: startsAt,
          subject: subject,
          durationMin: durationMin,
          status: status == 'completed' || status == 'done' ? 'done' : 'pending',
          attendance: attendance,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _lessons = lessonsList;
        });
      }
    } catch (e) {
      print('⚠️ 수업 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _lessons = [];
        });
      }
    }
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
    
    if (selectedIndex != -1 && _dateScrollController.hasClients) {
      // 각 날짜 카드의 대략적인 너비 (카드 + 마진) 약 80px
      const itemWidth = 80.0;
      final position = _dateScrollController.position;
      if (position.hasViewportDimension) {
        final screenWidth = position.viewportDimension;
      final scrollPosition = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _dateScrollController.animateTo(
          scrollPosition.clamp(0.0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
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
      final id = int.parse(studentId);
      return _studentsMap[id];
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
        // 목록 새로고침
        _loadLessons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('화면을 열 수 없습니다: $e'),
            backgroundColor: AppColors.error,
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
              foregroundColor: AppColors.error,
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
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 고정 AppBar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // AppBar
                SizedBox(
                  height: 64,
                  child: AppBar(
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: Text(
                      '수업 스케줄',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: Gaps.screen),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddRecurringScheduleScreen(),
                              ),
                            );
                            if (result == true) {
                              // 목록 새로고침
                              _loadLessons();
                            }
                          },
                          icon: const Icon(Icons.repeat_rounded, size: 18),
                          label: const Text('반복 등록'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 월 선택 및 날짜 선택 스크롤 뷰
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
            ),
            child: Column(
              children: [
                _buildMonthSelector(theme, colorScheme),
                _buildDateScrollSelector(theme, colorScheme),
                      SizedBox(height: Gaps.screen),
                    ],
                  ),
                ),
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
                    padding: EdgeInsets.fromLTRB(Gaps.screen, Gaps.card, Gaps.screen, Gaps.cardPad + 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 주말 제외 옵션이 켜져 있고 선택된 날짜가 주말이면 메시지 표시
                        Builder(
                          builder: (context) {
                            if (_excludeWeekends) {
                              final weekday = _selectedDate.weekday; // 1=월요일, 7=일요일
                              if (weekday == 6 || weekday == 7) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(Gaps.screen * 2),
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
                                      padding: EdgeInsets.only(bottom: Gaps.card - 2),
                                    child: _buildScheduleCard(hour, theme, colorScheme),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: Gaps.screen * 2),
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
      padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: 12),
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
                borderRadius: BorderRadius.circular(Radii.chip),
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
              padding: EdgeInsets.symmetric(horizontal: Gaps.card),
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
                    // 선택된 날짜의 수업 로드
                    _loadLessons();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: Gaps.row),
                    padding: EdgeInsets.symmetric(horizontal: Gaps.screen, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.chip + 4),
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
                                ? AppColors.surface
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
                                ? AppColors.surface.withValues(alpha: 0.9)
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
          ? AppColors.success
          : AppColors.primary;

      // 등록된 수업 카드는 스와이프 제스처 없이 일반 Container로 표시
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight,
              AppColors.primaryLight.withValues(alpha: 0.8),
            ],
          ),
        borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
          ),
          boxShadow: [
            BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(Gaps.cardPad),
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
                        borderRadius: BorderRadius.circular(Radii.icon - 2),
                        color: isDone 
                            ? accentColor 
                            : AppColors.surface.withValues(alpha: 0.9),
                        border: Border.all(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? Icon(Icons.check_rounded, size: 16, color: AppColors.surface)
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
                            borderRadius: BorderRadius.circular(Radii.chip + 2),
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
                          color: AppColors.error,
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
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(Radii.card - 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: 12),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card + 6),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: Gaps.screen),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 32,
                ),
                SizedBox(width: Gaps.row),
                Text(
                  '활성화',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.success,
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
              radius: Radius.circular(Radii.card + 6),
              padding: EdgeInsets.zero,
              color: AppColors.error.withValues(alpha: 0.4),
              strokeWidth: 3,
              dashPattern: const [10, 5],
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 80,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.card + 6),
                ),
                padding: EdgeInsets.symmetric(horizontal: Gaps.screen, vertical: Gaps.cardPad + 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: AppColors.error.withValues(alpha: 0.6),
                      size: 28,
                    ),
                    SizedBox(width: Gaps.card),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.chip + 2),
                      ),
                      child: Text(
                        '$timeStr - $endTimeStr (불가)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error.withValues(alpha: 0.7),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.card + 6),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.5),
              width: 3,
              style: BorderStyle.solid,
            ),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: Gaps.screen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '비활성화',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: Gaps.row),
              Icon(
                Icons.block_rounded,
                color: AppColors.error,
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
                  radius: Radius.circular(Radii.card + 6),
                  padding: EdgeInsets.zero,
                  color: isNowDisabled
                      ? AppColors.error.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  strokeWidth: 3,
                  dashPattern: const [10, 5],
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 80,
                    ),
                    decoration: BoxDecoration(
                      color: isNowDisabled
                          ? AppColors.textMuted.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(Radii.card + 6),
                      boxShadow: isNowDisabled
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: Gaps.screen, vertical: Gaps.cardPad + 4),
                    child: Row(
                      children: [
                        Icon(
                          isNowDisabled ? Icons.block_rounded : Icons.add,
                          color: isNowDisabled
                              ? AppColors.error.withValues(alpha: 0.6)
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 28,
                        ),
                        SizedBox(width: Gaps.card),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isNowDisabled
                                ? AppColors.error.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Radii.chip + 2),
                          ),
                          child: Text(
                            isNowDisabled
                                ? '$timeStr - $endTimeStr (불가)'
                                : '$timeStr - $endTimeStr',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isNowDisabled
                                  ? AppColors.error.withValues(alpha: 0.7)
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
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(Radii.chip),
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

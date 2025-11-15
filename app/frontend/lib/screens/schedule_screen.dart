import 'dart:async';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/teacher_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import 'add_recurring_schedule_screen.dart';
import 'add_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => ScheduleScreenState();
}

/// ScheduleScreen의 State를 외부에서 접근할 수 있도록 public으로 변경
class ScheduleScreenState extends State<ScheduleScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now(); // 현재 보는 월
  final ScrollController _dateScrollController = ScrollController();
  final Map<DateTime, GlobalKey> _dateKeys = {}; // 날짜별 GlobalKey 저장
  double? _measuredItemWidth; // 측정된 실제 아이템 너비

  // 타임슬롯 설정 (설정에서 가져옴)
  int _startHour = 12;
  int _endHour = 22;
  Set<int> _disabledHours = {};
  bool _excludeWeekends = false;

  // 학생 ID -> Student 매핑 (API에서 가져온 데이터 사용)
  Map<int, Student> _studentsMap = {};
  // 수업 목록
  List<Lesson> _lessons = [];
  // 날짜별 수업 목록 캐시 (날짜 문자열 -> 수업 목록)
  Map<String, List<Lesson>> _lessonsCache = {};
  
  // 마지막으로 오늘 날짜로 리셋한 날짜 (날짜 변경 감지용)
  DateTime? _lastResetDate;
  bool _isVisible = false;
  Timer? _lessonEndCheckTimer; // 수업 종료 체크 타이머
  Set<String> _shownLessonEndDialogs = {}; // 이미 표시한 수업 종료 다이얼로그 ID 저장

  @override
  bool get wantKeepAlive => true; // 상태를 유지하되, 화면이 보일 때 리셋

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 진입 시 항상 오늘 날짜로 설정
    _resetToToday();
    _loadStudents();
    _loadSettings();
    _startLessonEndCheckTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateScrollController.dispose();
    _lessonEndCheckTimer?.cancel();
    super.dispose();
  }

  /// 외부에서 호출할 수 있는 리셋 메서드 (화면이 다시 활성화될 때 호출)
  /// 선택된 날짜가 오늘이 아니면 무조건 오늘로 리셋
  void resetToTodayIfNeeded() {
    final today = DateTime.now();
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    // 선택된 날짜가 오늘이 아니면 무조건 오늘로 리셋
    // 또는 마지막 리셋 날짜가 오늘이 아니면 리셋 (날짜가 바뀌었을 수 있음)
    if (selectedDateOnly != todayOnly) {
      // 선택된 날짜가 오늘이 아니면 무조건 리셋
      _resetToToday(force: true);
    } else if (_lastResetDate != null) {
      // 선택된 날짜가 오늘이지만, 마지막 리셋 날짜가 오늘이 아니면 리셋 (날짜가 바뀌었을 수 있음)
      final lastResetDateOnly = DateTime(_lastResetDate!.year, _lastResetDate!.month, _lastResetDate!.day);
      if (lastResetDateOnly != todayOnly) {
        _resetToToday(force: true);
      }
    }
  }
  
  /// 강제로 오늘 날짜로 리셋 (외부에서 호출 가능)
  /// 화면 진입 시 무조건 오늘로 리셋
  void forceResetToToday() {
    _resetToToday(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포그라운드로 돌아올 때 오늘 날짜로 리셋
    if (state == AppLifecycleState.resumed && _isVisible) {
      resetToTodayIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 오늘 날짜로 리셋
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isVisible = true;
        // 설정 다시 로드 (DB에서 최신 값 가져오기)
        _loadSettings();
        resetToTodayIfNeeded();
        // 오늘 날짜의 수업 목록 새로고침 (캐시 무효화)
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        _lessonsCache.remove(todayStr);
        _loadLessons(forceRefresh: true);
        
        // 스크롤 위치도 업데이트 - 여러 프레임에 걸쳐 시도
        // 첫 번째 프레임 후
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _scrollToSelectedDate();
          }
        });
        // 두 번째 프레임 후 (ListView 렌더링 완료 보장)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _scrollToSelectedDate();
          }
        });
        // 세 번째 프레임 후 (GlobalKey 생성 완료 보장)
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _scrollToSelectedDate();
          }
        });
        // 네 번째 프레임 후 (최종 확인)
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _scrollToSelectedDate();
          }
        });
        // 다섯 번째 프레임 후 (추가 확인)
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _scrollToSelectedDate();
          }
        });
      }
    });
  }

  /// 오늘 날짜로 리셋
  Future<void> _resetToToday({bool force = false}) async {
    final today = DateTime.now();
    
    // DB에서 Teacher 정보를 가져와서 주말 제외 설정 사용
    final teacher = await TeacherService.instance.loadTeacher();
    final excludeWeekends = teacher?.excludeWeekends ?? await SettingsService.getExcludeWeekends();
    
    DateTime selectedDate = today;
    if (excludeWeekends) {
      final weekday = today.weekday;
      if (weekday == 6 || weekday == 7) {
        // 다음 평일 찾기
        int daysToAdd = weekday == 6 ? 2 : 1; // 토요일이면 2일 후(월요일), 일요일이면 1일 후(월요일)
        selectedDate = today.add(Duration(days: daysToAdd));
      }
    }
    
    // 날짜 비교 (년, 월, 일만 비교)
    final currentDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final newDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // 강제 리셋이거나 날짜가 다른 경우에만 업데이트
    if (force || (mounted && currentDateOnly != newDateOnly)) {
      // 마지막 리셋 날짜 업데이트
      _lastResetDate = today;
      
      // 강제 리셋 시 캐시 무효화
      if (force) {
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final selectedDateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        _lessonsCache.remove(todayStr);
        _lessonsCache.remove(selectedDateStr);
      }
      
      if (mounted) {
          setState(() {
          _selectedDate = selectedDate;
          _viewMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        });
        // 스크롤을 위해 여러 프레임 대기 (ListView 렌더링 및 GlobalKey 생성 완료 보장)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 첫 번째 프레임 후
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _scrollToSelectedDate();
                _loadLessons(forceRefresh: force);
              }
            });
            // 두 번째 프레임 후 (ListView 렌더링 완료 보장)
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _scrollToSelectedDate();
              }
            });
            // 세 번째 프레임 후 (GlobalKey 생성 완료 보장)
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                _scrollToSelectedDate();
              }
            });
            // 네 번째 프레임 후 (최종 확인)
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                _scrollToSelectedDate();
              }
            });
            // 다섯 번째 프레임 후 (추가 확인)
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _scrollToSelectedDate();
              }
            });
          }
        });
      }
    } else if (mounted) {
      // 날짜가 같아도 수업 목록은 새로고침
      _loadLessons();
    }
  }

  /// 학생 목록 로드
  Future<void> _loadStudents() async {
    try {
      // 활성화된 학생만 조회
      final studentsData = await ApiService.getStudents(isActive: true);
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
        final isActive = s['is_active'] as bool? ?? true;
        final nextClass = s['next_class'] as String? ?? '';
        final attendanceRate = sessions > 0 ? ((completedSessions / sessions) * 100).round() : 0;

        final student = Student(
          studentId: studentId,
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
          isActive: isActive,
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

  /// 수업 목록 로드 (캐시 사용)
  Future<void> _loadLessons({bool forceRefresh = false}) async {
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

      // 선택된 날짜 문자열 생성
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // 캐시 확인 (강제 새로고침이 아닐 때만)
      if (!forceRefresh && _lessonsCache.containsKey(dateStr)) {
        if (mounted) {
          setState(() {
            _lessons = _lessonsCache[dateStr]!;
          });
        }
        print('✅ 캐시에서 수업 목록 로드: $dateStr (${_lessons.length}개)');
        return;
      }

      // 오늘 날짜로 수업 조회
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // 선택된 날짜가 오늘이면 오늘 날짜로 조회, 아니면 선택된 날짜로 조회
      final queryDateStr = dateStr == todayStr ? todayStr : dateStr;

      // 스케줄 조회 (취소된 수업 제외)
      print('🔍 수업 목록 로드 시작: queryDateStr=$queryDateStr, teacherId=${teacher.teacherId}');
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: queryDateStr,
        dateTo: queryDateStr,
        status: 'confirmed', // 취소된 수업 제외
      );
      print('📋 API에서 받은 스케줄 수: ${schedules.length}개');
      if (schedules.isNotEmpty) {
        print('📋 첫 번째 스케줄 샘플: ${schedules.first}');
      }

      // 학생 정보 다시 로드 (스케줄에 학생 이름 표시용)
      if (_studentsMap.isEmpty) {
        await _loadStudents();
      }

      // 수업을 Lesson으로 변환 (취소된 수업 및 비활성화된 학생의 수업 필터링)
      print('🔄 수업 변환 시작: ${schedules.length}개 스케줄');
      print('🔄 학생 맵 크기: ${_studentsMap.length}');
      final lessonsList = schedules
          .where((s) {
            // 취소된 수업 제외
            final status = s['status'] as String? ?? 'pending';
            if (status == 'cancelled') {
              print('  ⏭️ 취소된 수업 제외: schedule_id=${s['schedule_id']}');
              return false;
            }
            
            // 비활성화된 학생의 수업 제외
            final studentId = s['student_id'] as int? ?? 0;
            final student = _studentsMap[studentId];
            if (student != null && !student.isActive) {
              print('  ⏭️ 비활성화된 학생의 수업 제외: student_id=$studentId');
              return false;
            }
            
            return true;
          })
          .map((s) {
        final scheduleId = s['schedule_id'] as int? ?? 0;
        final studentId = s['student_id'] as int? ?? 0;
        final subject = s['subject_id'] as String? ?? '과목 없음';
        final startTime = s['start_time'] as String? ?? '00:00';
        final endTime = s['end_time'] as String? ?? '00:00';
        final status = s['status'] as String? ?? 'pending';
        final lessonDate = s['lesson_date'] as String? ?? queryDateStr;
        final attendanceStatusFromApi = s['attendance_status'] as String?; // 'present', 'late', 'absent', null

        // 날짜 파싱
        final dateParts = lessonDate.split('-');
        final lessonYear = dateParts.isNotEmpty ? int.tryParse(dateParts[0]) ?? _selectedDate.year : _selectedDate.year;
        final lessonMonth = dateParts.length > 1 ? int.tryParse(dateParts[1]) ?? _selectedDate.month : _selectedDate.month;
        final lessonDay = dateParts.length > 2 ? int.tryParse(dateParts[2]) ?? _selectedDate.day : _selectedDate.day;

        // 시간 파싱
        final startParts = startTime.split(':');
        final endParts = endTime.split(':');
        final startHour = startParts.isNotEmpty ? int.tryParse(startParts[0]) ?? 0 : 0;
        final startMin = startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;
        final endHour = endParts.isNotEmpty ? int.tryParse(endParts[0]) ?? 0 : 0;
        final endMin = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;

        // 시작 시간 계산
        final startsAt = DateTime(
          lessonYear,
          lessonMonth,
          lessonDay,
          startHour,
          startMin,
        );

        // 종료 시간 계산
        final endsAt = DateTime(
          lessonYear,
          lessonMonth,
          lessonDay,
          endHour,
          endMin,
        );

        // 수업 시간 (분)
        final durationMin = endsAt.difference(startsAt).inMinutes;

        // 출석 상태 (백엔드의 attendance_status를 프론트엔드 형식으로 변환)
        String? attendance;
        if (attendanceStatusFromApi == 'present') {
          attendance = 'show';
        } else if (attendanceStatusFromApi == 'late') {
          attendance = 'late';
        } else if (attendanceStatusFromApi == 'absent') {
          attendance = 'absent';
        }
        // attendance_status가 없고 수업이 완료된 경우 기본값은 출석
        else if (status == 'completed' || status == 'done') {
          attendance = 'show'; // 기본값은 출석
        }

        final lesson = Lesson(
          id: scheduleId.toString(),
          studentId: studentId.toString(),
          startsAt: startsAt,
          subject: subject,
          durationMin: durationMin,
          status: status == 'completed' || status == 'done' ? 'done' : 'pending',
          attendance: attendance,
        );
        
        print('  ✅ 수업 변환: ${lesson.startsAt.hour}:${lesson.startsAt.minute.toString().padLeft(2, '0')} ${lesson.subject} (${lesson.durationMin}분)');
        
        return lesson;
      }).toList();
      
      print('🔄 수업 변환 완료: ${lessonsList.length}개');

      // 캐시에 저장
      _lessonsCache[dateStr] = lessonsList;

      if (mounted) {
        setState(() {
          _lessons = lessonsList;
        });
        // 수업 목록 로드 후 종료된 수업 체크
        _checkForEndedLessons();
      }
      
      print('✅ 수업 목록 로드 완료: $dateStr (${lessonsList.length}개)');
      if (lessonsList.isNotEmpty) {
        for (final lesson in lessonsList) {
          print('  - ${lesson.startsAt.hour}:${lesson.startsAt.minute.toString().padLeft(2, '0')} ${lesson.subject} (${lesson.durationMin}분)');
        }
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
    // DB에서 Teacher 정보를 가져와서 수업 시간 설정 사용
    final teacher = await TeacherService.instance.loadTeacher();
    
    int startHour = 12; // 기본값
    int endHour = 22; // 기본값
    bool excludeWeekends = false; // 기본값
    
    if (teacher != null) {
      // DB에서 가져온 값 사용 (null이면 기본값 유지)
      startHour = teacher.lessonStartHour ?? 12;
      endHour = teacher.lessonEndHour ?? 22;
      excludeWeekends = teacher.excludeWeekends;
      
      // SettingsService에도 동기화 (다른 화면에서 사용할 수 있도록)
      await SettingsService.setStartHour(startHour);
      await SettingsService.setEndHour(endHour);
      await SettingsService.setExcludeWeekends(excludeWeekends);
    } else {
      // Teacher 정보가 없으면 SettingsService에서 가져오기
      startHour = await SettingsService.getStartHour();
      endHour = await SettingsService.getEndHour();
      excludeWeekends = await SettingsService.getExcludeWeekends();
    }
    
    final disabledHours = await SettingsService.getDisabledHours(_selectedDate);
    
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


  void _scrollToSelectedDate({int retryCount = 0}) {
    // 스크롤 컨트롤러가 아직 준비되지 않았으면 재시도
    if (!_dateScrollController.hasClients) {
      if (retryCount < 20 && mounted) {
        Future.delayed(Duration(milliseconds: 50 * (retryCount + 1)), () {
          if (mounted) {
            _scrollToSelectedDate(retryCount: retryCount + 1);
          }
        });
      }
      return;
    }
    
    final position = _dateScrollController.position;
    if (!position.hasViewportDimension || !position.hasContentDimensions) {
      if (retryCount < 20 && mounted) {
        Future.delayed(Duration(milliseconds: 100 * (retryCount + 1)), () {
          if (mounted) {
            _scrollToSelectedDate(retryCount: retryCount + 1);
          }
        });
      }
      return;
    }
    
    // _buildDateScrollSelector와 동일한 방식으로 날짜 목록 생성
    final lastDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    final allDates = List.generate(daysInMonth, (index) {
      return DateTime(_viewMonth.year, _viewMonth.month, index + 1);
    });
    
    final dates = _excludeWeekends
        ? allDates.where((date) {
            final weekday = date.weekday;
            return weekday != 6 && weekday != 7;
          }).toList()
        : allDates;
    
    final selectedIndex = dates.indexWhere((date) =>
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day);
    
    if (selectedIndex == -1) {
      // 선택된 날짜를 찾을 수 없으면 재시도
      if (retryCount < 10 && mounted) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            _scrollToSelectedDate(retryCount: retryCount + 1);
          }
        });
      }
      return;
    }
    
    // 선택된 날짜의 GlobalKey 찾기 (렌더링된 경우)
    final selectedDateKey = _dateKeys[_selectedDate];
    if (selectedDateKey?.currentContext != null) {
      // Scrollable.ensureVisible을 사용하여 정확한 위치로 스크롤
      try {
        Scrollable.ensureVisible(
          selectedDateKey!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.5, // 중앙 정렬
        );
        return;
      } catch (e) {
        // ensureVisible 실패 시 fallback 사용
        print('⚠️ ensureVisible 실패: $e');
      }
    }
    
    // GlobalKey가 없거나 ensureVisible이 실패한 경우 계산 기반 스크롤 사용
    // 실제 카드 너비 측정 시도
    // 기본값: padding (40px) + 내용 (50px) + margin (10px) = 100px
    // 12일이 중앙에 오는 문제를 해결하기 위해 증가
    double itemWidth = _measuredItemWidth ?? 140.0;
    
    // 첫 번째와 두 번째 렌더링된 아이템의 실제 간격 측정 시도 (가장 정확한 방법)
    if (_measuredItemWidth == null && dates.length >= 2) {
      final firstDate = dates[0];
      final secondDate = dates[1]; 
      final firstKey = _dateKeys[firstDate];
      final secondKey = _dateKeys[secondDate];
      
      if (firstKey?.currentContext != null && secondKey?.currentContext != null) {
        final firstBox = firstKey!.currentContext!.findRenderObject() as RenderBox?;
        final secondBox = secondKey!.currentContext!.findRenderObject() as RenderBox?;
        
        if (firstBox != null && secondBox != null) {
          // 두 아이템의 실제 간격 측정
          // 첫 번째 아이템의 왼쪽 끝에서 두 번째 아이템의 왼쪽 끝까지의 거리
          final firstPosition = firstBox.localToGlobal(Offset.zero);
          final secondPosition = secondBox.localToGlobal(Offset.zero);
          final actualSpacing = secondPosition.dx - firstPosition.dx;
          
          if (actualSpacing > 0) {
            // 측정된 값에 약간의 보정값 추가 (더 정확한 중앙 정렬을 위해)
            final correctedSpacing = actualSpacing + 2.0;
            setState(() {
              _measuredItemWidth = correctedSpacing;
            });
            itemWidth = correctedSpacing;
          }
        }
      }
    }
    
    // 두 번째 방법: 첫 번째 아이템만 측정하고 margin 추가
    if (_measuredItemWidth == null && dates.isNotEmpty) {
      final firstDate = dates[0];
      final firstKey = _dateKeys[firstDate];
      if (firstKey?.currentContext != null) {
        final RenderBox? renderBox = firstKey!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final measuredWidth = renderBox.size.width;
          // Container의 margin (Gaps.row = 10px) 추가
          if (measuredWidth > 0) {
            // 약간의 보정값 추가
            final totalWidth = measuredWidth + Gaps.row + 5.0;
            setState(() {
              _measuredItemWidth = totalWidth;
            });
            itemWidth = totalWidth;
          }
        }
      }
    }
    
    final viewportWidth = position.viewportDimension;
    final maxScrollExtent = position.maxScrollExtent;
    
    // 중앙 정렬 계산
    // 선택된 아이템의 중심이 뷰포트의 중심에 오도록 계산
    // Container의 margin (Gaps.row = 10px)도 포함해야 함
    // 실제 아이템 간격 = itemWidth (이미 margin 포함되어 있음)
    // 하지만 측정된 너비가 margin을 포함하지 않을 수 있으므로 확인 필요
    final itemCenterPosition = selectedIndex * itemWidth + (itemWidth / 2);
    final viewportCenter = viewportWidth / 2;
    // ListView의 padding (Gaps.card = 16px)은 스크롤 위치에 자동으로 포함됨
    // 하지만 실제 스크롤 위치 계산 시 padding을 고려해야 할 수도 있음
    // 12일이 중앙에 오는 문제를 해결하기 위해 약간의 오프셋 추가
    final targetScrollPosition = itemCenterPosition - viewportCenter;
    final clampedPosition = targetScrollPosition.clamp(0.0, maxScrollExtent > 0 ? maxScrollExtent : 0.0);
    
    // 현재 위치와 목표 위치가 충분히 다를 때만 스크롤
    final currentPosition = position.pixels;
    if ((currentPosition - clampedPosition).abs() > 5.0) {
      _dateScrollController.animateTo(
        clampedPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else if (retryCount < 5) {
      // 위치가 거의 맞지만 GlobalKey가 아직 생성되지 않았을 수 있으므로 재시도
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToSelectedDate(retryCount: retryCount + 1);
        }
      });
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
  // 해당 시간대(hour)에 시작하는 수업을 찾습니다
  // 예: 14:00 또는 14:30에 시작하는 수업은 14시 타임슬롯에 표시
  Lesson? _findLessonForSlot(int hour) {
    try {
      return _filteredLessons.firstWhere(
        (lesson) {
          // 수업이 해당 시간대에 시작하는지 확인
          // hour:00 ~ hour:59 사이에 시작하는 수업을 찾음
          final lessonHour = lesson.startsAt.hour;
          return lessonHour == hour;
        },
      );
    } catch (e) {
      return null;
    }
  }

  // 해당 시간대가 등록된 수업의 시간 범위 내에 있는지 확인
  bool _isTimeSlotOccupied(int hour) {
    final slotStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      0,
    );
    final slotEnd = slotStart.add(const Duration(hours: 1));

    // 등록된 수업 중에서 해당 시간대와 겹치는 수업이 있는지 확인
    for (final lesson in _filteredLessons) {
      final lessonEnd = lesson.startsAt.add(Duration(minutes: lesson.durationMin));
      
      // 시간대가 겹치는지 확인: slotStart < lessonEnd && slotEnd > lesson.startsAt
      if (slotStart.isBefore(lessonEnd) && slotEnd.isAfter(lesson.startsAt)) {
        // 해당 시간대에 시작하는 수업이 아니면 (다른 수업의 시간 범위 내에 있으면) occupied
        if (lesson.startsAt.hour != hour) {
          return true;
        }
      }
    }
    return false;
  }

  // 타임슬롯 리스트 생성 (이미 등록된 수업의 시간 범위 내에 있는 타임슬롯 제외)
  List<int> get _timeSlots {
    final allSlots = List.generate(
      _endHour - _startHour + 1,
      (index) => _startHour + index,
    );
    
    // 등록된 수업의 시간 범위 내에 있는 타임슬롯 제외
    return allSlots.where((hour) {
      // 해당 시간대에 시작하는 수업이 있으면 표시 (수업 카드로 표시)
      if (_findLessonForSlot(hour) != null) {
        return true;
      }
      // 해당 시간대가 다른 수업의 시간 범위 내에 있으면 제외
      if (_isTimeSlotOccupied(hour)) {
        return false;
      }
      // 그 외의 경우 표시
      return true;
    }).toList();
  }

  /// 수업 종료 체크 타이머 시작
  void _startLessonEndCheckTimer() {
    _lessonEndCheckTimer?.cancel();
    _lessonEndCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkForEndedLessons();
    });
  }

  /// 종료된 수업 확인 및 자동 출결 다이얼로그 표시
  void _checkForEndedLessons() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 오늘 날짜의 수업만 확인
    for (final lesson in _filteredLessons) {
      final lessonDate = DateTime(
        lesson.startsAt.year,
        lesson.startsAt.month,
        lesson.startsAt.day,
      );
      
      // 오늘 날짜의 수업이고, 아직 완료되지 않았고, 수업이 끝났는지 확인
      if (lessonDate.isAtSameMomentAs(today) &&
          lesson.status != 'done' &&
          lesson.endsAt.isBefore(now)) {
        // 이미 다이얼로그를 표시한 수업이 아니면
        if (!_shownLessonEndDialogs.contains(lesson.id)) {
          _shownLessonEndDialogs.add(lesson.id);
          _showLessonEndDialog(lesson);
        }
      }
    }
  }

  /// 수업 종료 다이얼로그 표시
  Future<void> _showLessonEndDialog(Lesson lesson) async {
    final student = _findStudent(lesson.studentId);
    final studentName = student?.name ?? '학생';
    
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '수업 완료 확인',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$studentName 학생의 수업이 끝났나요?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${lesson.subject} · ${lesson.durationMin}분',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '예를 누르면 자동으로 출석 처리됩니다',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '아니오',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // 자동 출결 처리 및 수업 완료 처리
      await _completeLessonWithAttendance(lesson.id);
    }
  }

  /// 수업 완료 및 출석 처리 (1클릭)
  Future<void> _completeLessonWithAttendance(String lessonId) async {
    try {
      final scheduleId = int.parse(lessonId);
      
      // API로 수업 완료 및 출석 처리
      await ApiService.updateSchedule(
        scheduleId: scheduleId,
        status: 'completed',
      );
      
      // 로컬 상태 업데이트
      setState(() {
        final lesson = _lessons.firstWhere((l) => l.id == lessonId);
        final index = _lessons.indexOf(lesson);
        _lessons[index] = Lesson(
          id: lesson.id,
          studentId: lesson.studentId,
          startsAt: lesson.startsAt,
          subject: lesson.subject,
          durationMin: lesson.durationMin,
          status: 'done',
          attendance: 'show', // 자동 출석 처리
        );
      });
      
      // 캐시 무효화
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      _lessonsCache.remove(dateStr);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('수업이 완료되었고 출석 처리되었습니다.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 수업 완료 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  Future<void> _setAttendance(String lessonId, String attendance) async {
    try {
      final scheduleId = int.parse(lessonId);
      
      // 같은 버튼을 다시 누르면 null로 설정 (출석 상태 해제)
      final lesson = _lessons.firstWhere((l) => l.id == lessonId);
      final newAttendance = lesson.attendance == attendance ? null : attendance;
      final newAttendanceStatus = newAttendance == null ? null : (newAttendance == 'show' ? 'present' : newAttendance);
      
      // 로컬 상태 먼저 업데이트 (즉시 UI 반영)
      if (mounted) {
        setState(() {
          final index = _lessons.indexOf(lesson);
          _lessons[index] = Lesson(
            id: lesson.id,
            studentId: lesson.studentId,
            startsAt: lesson.startsAt,
            subject: lesson.subject,
            durationMin: lesson.durationMin,
            status: lesson.status,
            attendance: newAttendance,
          );
        });
      }
      
      // API 호출하여 서버에 저장
      await ApiService.updateSchedule(
        scheduleId: scheduleId,
        attendanceStatus: newAttendanceStatus,
      );
      
      print('✅ 출석 상태 업데이트 완료: scheduleId=$scheduleId, attendanceStatus=$newAttendanceStatus');
      
      // 캐시 무효화하여 다음 로드 시 서버 데이터 반영
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      _lessonsCache.remove(dateStr);
      
      // 오늘 날짜의 캐시도 무효화 (홈 화면 동기화를 위해)
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      _lessonsCache.remove(todayStr);
      
      // 선택된 날짜가 오늘이면 즉시 새로고침
      if (dateStr == todayStr) {
        await _loadLessons(forceRefresh: true);
      }
      
    } catch (e) {
      print('❌ 출석 상태 업데이트 실패: $e');
      
      // 에러 발생 시 원래 상태로 복구
      if (mounted) {
        final lesson = _lessons.firstWhere((l) => l.id == lessonId);
        final index = _lessons.indexOf(lesson);
        setState(() {
          _lessons[index] = lesson; // 원래 상태로 복구
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출석 상태 업데이트 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
        // 캐시 무효화 (오늘 날짜와 선택된 날짜)
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
        _lessonsCache.remove(todayStr);
        _lessonsCache.remove(selectedDateStr);
        
        // 즉시 새로고침
        if (mounted) {
          _loadLessons(forceRefresh: true);
        }
        
        // 목록 새로고침 - 서버 반영 시간 확보를 위해 여러 번 시도
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadLessons(forceRefresh: true);
          }
        });
        // 한 번 더 시도 (서버 동기화 지연 대비)
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _loadLessons(forceRefresh: true);
          }
        });
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
      try {
        // API 호출하여 스케줄 취소
        final scheduleId = int.parse(lessonId);
        final teacher = await TeacherService.instance.loadTeacher();
        
        await ApiService.deleteSchedule(
          scheduleId: scheduleId,
          cancelledBy: teacher?.teacherId,
          cancelReason: '사용자 취소',
        );
        
        // 캐시 무효화 (오늘 날짜와 선택된 날짜)
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
        _lessonsCache.remove(todayStr);
        _lessonsCache.remove(selectedDateStr);
        
        // 수업 목록 즉시 새로고침 (서버 반영 시간 확보를 위해 약간의 지연)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadLessons(forceRefresh: true);
          }
        });
        // 한 번 더 시도 (서버 동기화 지연 대비)
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _loadLessons(forceRefresh: true);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('수업이 취소되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        print('❌ 수업 취소 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('수업 취소 실패: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
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
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddRecurringScheduleScreen(),
                      ),
                    );
                    if (result == true) {
                      // 캐시 무효화 (오늘 날짜와 선택된 날짜)
                      final today = DateTime.now();
                      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                      final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                      _lessonsCache.remove(todayStr);
                      _lessonsCache.remove(selectedDateStr);
                      
                      // 목록 새로고침 - 서버 반영 시간 확보를 위해 여러 번 시도
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _loadLessons(forceRefresh: true);
                        }
                      });
                      // 한 번 더 시도 (서버 동기화 지연 대비)
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                          _loadLessons(forceRefresh: true);
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.repeat_rounded, size: 18),
                  label: const Text('반복 등록'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),

          // 날짜 선택기
          SliverToBoxAdapter(
            child: Container(
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
                  _buildMonthSelector(theme, colorScheme),
                  _buildDateScrollSelector(theme, colorScheme),
                  SizedBox(height: Gaps.screen),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
              ]),
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

                // 날짜별 GlobalKey 생성 및 저장
                if (!_dateKeys.containsKey(date)) {
                  _dateKeys[date] = GlobalKey();
                }
                final dateKey = _dateKeys[date]!;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedDate = date;
                      // 선택한 날짜가 다른 월이면 월도 업데이트
                      if (date.year != _viewMonth.year || date.month != _viewMonth.month) {
                        _viewMonth = DateTime(date.year, date.month, 1);
                        // 다른 월로 변경되면 이전 월의 키들 정리
                        _dateKeys.removeWhere((key, _) => 
                          key.year != _viewMonth.year || key.month != _viewMonth.month);
                      }
                    });
                    await _refreshDisabledHours();
                    // 선택된 날짜로 스크롤 (중앙 정렬) - 여러 번 시도하여 확실히 중앙 정렬
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _scrollToSelectedDate();
                        // 한 번 더 시도 (중앙 정렬 보장)
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _scrollToSelectedDate();
                          }
                        });
                      }
                    });
                    // 선택된 날짜의 수업 로드 (캐시 사용)
                    _loadLessons();
                  },
                  child: Container(
                    key: dateKey,
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
            horizontal: 16,
            vertical: 12,
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

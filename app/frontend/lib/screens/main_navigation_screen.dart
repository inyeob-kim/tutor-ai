import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'billing_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../theme/tokens.dart';
import '../services/teacher_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScheduleScreenState> _scheduleScreenKey = GlobalKey<ScheduleScreenState>();

  List<Widget> get _screens => [
    const HomeScreen(),
    const StudentsScreen(),
    ScheduleScreen(key: _scheduleScreenKey),
    const StatsScreen(),
    const BillingScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 메인 화면 진입 시 Teacher 정보 로드 (캐시 또는 API)
    _loadTeacherInfo();
    
    // 첫 로드 시 스케줄 화면이 선택되어 있으면 오늘 날짜로 리셋
    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scheduleScreenKey.currentState != null) {
          _scheduleScreenKey.currentState!.forceResetToToday();
        }
      });
    }
  }

  /// Teacher 정보 로드
  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null) {
        print('✅ 메인 화면: Teacher 정보 로드 완료 - name=${teacher.name}, subject_id=${teacher.subjectId}');
        // 필요시 setState로 UI 업데이트
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('⚠️ 메인 화면: Teacher 정보 로드 실패: $e');
    }
  }

  void _onTabTapped(int index) {
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // 스케줄 화면(인덱스 2)으로 전환될 때마다 오늘 날짜로 리셋
    if (index == 2) {
      // 스케줄 화면으로 전환 시 항상 오늘 날짜로 리셋
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scheduleScreenKey.currentState != null) {
          // 다른 화면에서 왔으면 무조건 오늘로 리셋
          if (previousIndex != 2) {
            _scheduleScreenKey.currentState!.forceResetToToday();
          } else {
            // 이미 스케줄 화면이어도 선택된 날짜가 오늘이 아니면 리셋
            _scheduleScreenKey.currentState!.resetToTodayIfNeeded();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(Gaps.screen, 0, Gaps.screen, Gaps.screen),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card + 10),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            height: 64,
            backgroundColor: AppColors.surface.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.home_rounded, size: 24, color: AppColors.primary),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.person_rounded, size: 24, color: AppColors.primary),
                label: '학생',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.event_note_rounded, size: 24, color: AppColors.primary),
                label: '스케줄',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.bar_chart_rounded, size: 24, color: AppColors.primary),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.receipt_long_rounded, size: 24, color: AppColors.primary),
                label: '청구',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_rounded, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.tune_rounded, size: 24, color: AppColors.primary),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


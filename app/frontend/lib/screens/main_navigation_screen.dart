import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'billing_screen.dart';
import 'more_screen.dart';
import '../theme/tokens.dart';
import '../services/teacher_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  PageController? _pageController;
  final GlobalKey<ScheduleScreenState> _scheduleScreenKey = GlobalKey<ScheduleScreenState>();
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  List<Widget> get _screens => [
    HomeScreen(key: _homeScreenKey),           // 0: HOME
    ScheduleScreen(key: _scheduleScreenKey),   // 1: SCHEDULE
    const StudentsScreen(),                    // 2: STUDENTS
    const BillingScreen(),                     // 3: BILLING
    const MoreScreen(),                        // 4: MORE
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // 메인 화면 진입 시 Teacher 정보 로드 (캐시 또는 API)
    _loadTeacherInfo();
    
    // 첫 로드 시 스케줄 화면이 선택되어 있으면 오늘 날짜로 리셋
    if (_currentIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scheduleScreenKey.currentState != null) {
          _scheduleScreenKey.currentState!.forceResetToToday();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Teacher 정보 로드
  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null) {
        print('✅ 메인 화면: Teacher 정보 로드 완료 - nickname=${teacher.nickname}, subject_id=${teacher.subjectId}');
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
    if (_currentIndex == index) return;
    
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // PageView 애니메이션으로 부드럽게 전환
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    
    // 홈 화면(인덱스 0)으로 전환될 때마다 오늘의 수업 목록 새로고침
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _homeScreenKey.currentState != null) {
          _homeScreenKey.currentState!.loadTodaySchedules();
        }
      });
    }
    
    // 스케줄 화면(인덱스 1)으로 전환될 때마다 오늘 날짜로 리셋
    if (index == 1) {
      // 스케줄 화면으로 전환 시 항상 오늘 날짜로 리셋
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scheduleScreenKey.currentState != null) {
          // 다른 화면에서 왔으면 무조건 오늘로 리셋
          if (previousIndex != 1) {
            _scheduleScreenKey.currentState!.forceResetToToday();
          } else {
            // 이미 스케줄 화면이어도 선택된 날짜가 오늘이 아니면 리셋
            _scheduleScreenKey.currentState!.resetToTodayIfNeeded();
          }
        }
      });
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: _pageController != null
          ? PageView(
              controller: _pageController!,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화 (탭으로만 이동)
              children: _screens,
            )
          : IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(Gaps.screen, 0, Gaps.screen, 8),
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
                icon: Icon(Icons.home, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.home, size: 24, color: AppColors.primary),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.calendar_today, size: 24, color: AppColors.primary),
                label: '스케줄',
              ),
              NavigationDestination(
                icon: Icon(Icons.people, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.people, size: 24, color: AppColors.primary),
                label: '학생',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_card, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.credit_card, size: 24, color: AppColors.primary),
                label: '청구',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz, size: 24, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.more_horiz, size: 24, color: AppColors.primary),
                label: '더보기',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


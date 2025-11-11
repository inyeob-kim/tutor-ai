import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'billing_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    StudentsScreen(),
    BillingScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            height: 64,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
            shadowColor: Colors.black.withValues(alpha: 0.08),
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 28),
                selectedIcon: Icon(Icons.home_filled, size: 28, color: colorScheme.primary),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined, size: 28),
                selectedIcon: Icon(Icons.event_note_rounded, size: 28, color: colorScheme.primary),
                label: '스케줄',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 28),
                selectedIcon: Icon(Icons.person_rounded, size: 28, color: colorScheme.primary),
                label: '학생',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, size: 28),
                selectedIcon: Icon(Icons.receipt_long_rounded, size: 28, color: colorScheme.primary),
                label: '청구',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, size: 28),
                selectedIcon: Icon(Icons.bar_chart_rounded, size: 28, color: colorScheme.primary),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined, size: 28),
                selectedIcon: Icon(Icons.tune_rounded, size: 28, color: colorScheme.primary),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


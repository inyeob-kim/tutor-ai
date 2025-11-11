import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'billing_screen.dart';
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
            height: 72,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
            shadowColor: Colors.black.withValues(alpha: 0.08),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_rounded),
                label: '스케줄',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: '학생',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: '청구',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_rounded),
                selectedIcon: Icon(Icons.menu_open_rounded),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}


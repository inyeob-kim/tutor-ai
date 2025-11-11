import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/students_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/add_student_screen.dart';
import '../screens/add_schedule_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String splash = '/splash';
  static const String mainNavigation = '/main';
  static const String schedule = '/schedule';
  static const String students = '/students';
  static const String billing = '/billing';
  static const String settings = '/settings';
  static const String addStudent = '/students/add';
  static const String addSchedule = '/schedules/add';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final routeName = routeSettings.name ?? splash;
    
    switch (routeName) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );
      case mainNavigation:
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: routeSettings,
        );
      case schedule:
        return MaterialPageRoute(
          builder: (_) => const ScheduleScreen(),
          settings: routeSettings,
        );
      case students:
        return MaterialPageRoute(
          builder: (_) => const StudentsScreen(),
          settings: routeSettings,
        );
      case billing:
        return MaterialPageRoute(
          builder: (_) => const BillingScreen(),
          settings: routeSettings,
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: routeSettings,
        );
      case addStudent:
        return MaterialPageRoute(
          builder: (_) => const AddStudentScreen(),
          settings: routeSettings,
        );
      case addSchedule:
        return MaterialPageRoute(
          builder: (_) => const AddScheduleScreen(),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: routeSettings,
        );
    }
  }
}


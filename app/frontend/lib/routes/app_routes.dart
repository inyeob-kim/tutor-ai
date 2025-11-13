import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/students_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/add_student_screen.dart';
import '../screens/add_schedule_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/booking_request_screen.dart';
import '../screens/signup/google_signup_screen.dart';
import '../screens/signup/subject_selection_screen.dart';
import '../screens/signup/name_input_screen.dart';
import '../screens/signup/phone_input_screen.dart';
import '../screens/signup/signup_complete_screen.dart';
import '../screens/add_billing_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/bye_screen.dart';

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
  static const String addBilling = '/billing/add';
  static const String aiAssistant = '/ai-assistant';
  static const String bookingRequest = '/booking-request';
  static const String googleSignup = '/signup/google';
  static const String signupSubject = '/signup/subject';
  static const String signupName = '/signup/name';
  static const String signupPhone = '/signup/phone';
  static const String signupComplete = '/signup/complete';
  static const String welcome = '/welcome';
  static const String bye = '/bye';

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
            case addBilling:
              return MaterialPageRoute(
                builder: (_) => const AddBillingScreen(),
                settings: routeSettings,
              );
            case aiAssistant:
              return MaterialPageRoute(
                builder: (_) => const AiAssistantScreen(),
                settings: routeSettings,
              );
            case bookingRequest:
              return MaterialPageRoute(
                builder: (_) => const BookingRequestScreen(),
                settings: routeSettings,
              );
            case googleSignup:
              return MaterialPageRoute(
                builder: (_) => const GoogleSignupScreen(),
                settings: routeSettings,
              );
            case signupSubject:
              return MaterialPageRoute(
                builder: (_) => const SubjectSelectionScreen(),
                settings: routeSettings,
              );
            case signupName:
              return MaterialPageRoute(
                builder: (_) => const NameInputScreen(),
                settings: routeSettings,
              );
            case signupPhone:
              return MaterialPageRoute(
                builder: (_) => const PhoneInputScreen(),
                settings: routeSettings,
              );
            case signupComplete:
              return MaterialPageRoute(
                builder: (_) => const SignupCompleteScreen(),
                settings: routeSettings,
              );
            case welcome:
              return MaterialPageRoute(
                builder: (_) => const WelcomeScreen(),
                settings: routeSettings,
              );
            case bye:
              return MaterialPageRoute(
                builder: (_) => const ByeScreen(),
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


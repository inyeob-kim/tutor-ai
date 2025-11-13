import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../routes/app_routes.dart';
import '../services/teacher_service.dart';
import '../theme/tokens.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (mounted) {
        setState(() {
          _teacherName = teacher?.name ?? '선생님';
        });
        // 애니메이션 표시 후 메인 화면으로 이동
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
          }
        });
      }
    } catch (e) {
      print('⚠️ Teacher 정보 로드 실패: $e');
      if (mounted) {
        setState(() {
          _teacherName = '선생님';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome 애니메이션
            SizedBox(
              width: 300,
              height: 300,
              child: Lottie.asset(
                'assets/animations/welcome.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: Gaps.screen),
            // 환영 메시지
            Text(
              '${_teacherName ?? ''} 선생님, 다시 와서 반가워요!!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


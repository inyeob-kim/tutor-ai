import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../routes/app_routes.dart';
import '../services/teacher_service.dart';
import '../theme/tokens.dart';

class ByeScreen extends StatefulWidget {
  const ByeScreen({super.key});

  @override
  State<ByeScreen> createState() => _ByeScreenState();
}

class _ByeScreenState extends State<ByeScreen> {
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    try {
      // 로그아웃 전에 Teacher 정보 가져오기 (캐시에서)
      final teacher = TeacherService.instance.currentTeacher;
      if (mounted) {
        setState(() {
          _teacherName = teacher?.name ?? '';
        });
      }
    } catch (e) {
      print('⚠️ Teacher 정보 로드 실패: $e');
      if (mounted) {
        setState(() {
          _teacherName = '';
        });
      }
    }
    
    // 애니메이션 표시 후 로그인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.googleSignup,
          (route) => false, // 모든 이전 화면 제거
        );
      }
    });
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
            // Bye 애니메이션
            SizedBox(
              width: 300,
              height: 300,
              child: Lottie.asset(
                'assets/animations/bye.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: Gaps.screen * 2),
            // 작별 인사 메시지
            Text(
              _teacherName != null && _teacherName!.isNotEmpty
                  ? '$_teacherName 선생님, 또 뵐게요~'
                  : '또 뵐게요~',
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


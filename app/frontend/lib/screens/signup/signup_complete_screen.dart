import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../routes/app_routes.dart';
import '../../theme/tokens.dart';

class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key});

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with TickerProviderStateMixin {
  // ===== 설정 가능한 경로 =====
  static const String _animationPath = 'assets/animations/signup_congrats_animation.json';
  // ============================

  late final AnimationController _fadeController;
  late final AnimationController _lottieController;
  late final Animation<double> _fadeAnimation;
  
  bool _hasAnimation = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lottieController = AnimationController(vsync: this);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 애니메이션 시작
    _fadeController.forward();
    _checkAnimationFile();

    // 3초 후 홈 화면으로 이동
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.mainNavigation,
          (route) => false,
        );
      }
    });
  }

  /// 애니메이션 파일 존재 여부 확인
  Future<void> _checkAnimationFile() async {
    try {
      await rootBundle.load(_animationPath);
      print('✅ 애니메이션 파일 로드 성공: $_animationPath');
      if (mounted) {
        setState(() {
          _hasAnimation = true;
        });
      }
    } catch (e) {
      print('⚠️ 애니메이션 파일 로드 실패: $_animationPath - $e');
      print('Fallback UI를 사용합니다.');
      if (mounted) {
        setState(() {
          _hasAnimation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(Gaps.screen * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 축하 애니메이션
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCelebrationAnimation(theme),
                    ),
                  ),
                  SizedBox(height: Gaps.screen * 2),

                  // 축하 메시지
                  Text(
                    '회원가입 완료! 🎉',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Gaps.card),
                  Text(
                    '쌤대신과 함께\n과외를 시작해보세요!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 축하 애니메이션 표시
  Widget _buildCelebrationAnimation(ThemeData theme) {
    // 애니메이션 파일이 있으면 Lottie 표시
    if (_hasAnimation) {
      return Lottie.asset(
        _animationPath,
        key: const ValueKey('signup-animation'),
        controller: _lottieController,
        fit: BoxFit.contain,
        repeat: true,
        onLoaded: (composition) {
          print('✅ Lottie 애니메이션 로드 완료: duration=${composition.duration}');
          if (mounted) {
            _lottieController
              ..duration = composition.duration
              ..forward()
              ..repeat();
          }
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Lottie 애니메이션 로드 에러: $error');
          return _buildFallbackCelebration(theme);
        },
      );
    } else {
      // Fallback: 애니메이션이 없을 때
      return _buildFallbackCelebration(theme);
    }
  }

  /// Fallback 축하 UI (애니메이션이 없을 때)
  Widget _buildFallbackCelebration(ThemeData theme) {
    return Container(
      key: const ValueKey('fallback-celebration'),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎉',
            style: const TextStyle(fontSize: 80),
          ),
          SizedBox(height: Gaps.row),
          Text(
            '✨',
            style: const TextStyle(fontSize: 40),
          ),
        ],
      ),
    );
  }
}


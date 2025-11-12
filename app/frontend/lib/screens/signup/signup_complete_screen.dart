import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/tokens.dart';
import '../../routes/app_routes.dart';

class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key});

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 애니메이션 시작
    _fadeController.forward();
    _scaleController.forward();

    // 2.5초 후 홈 화면으로 이동
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.mainNavigation,
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
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
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCelebrationAnimation(),
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

  Widget _buildCelebrationAnimation() {
    // Lottie 애니메이션 시도 (없으면 fallback)
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lottie 애니메이션 시도
          Lottie.asset(
            'assets/animations/success_confetti.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: false,
            errorBuilder: (context, error, stackTrace) {
              // Lottie 파일이 없으면 이모티콘으로 대체
              return _buildFallbackCelebration();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCelebration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎉',
            style: TextStyle(fontSize: 80),
          ),
          SizedBox(height: Gaps.row),
          Text(
            '✨',
            style: TextStyle(fontSize: 40),
          ),
        ],
      ),
    );
  }
}


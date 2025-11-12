import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../theme/tokens.dart';

/// 스플래시 화면에서 사용할 애셋 타입
enum _SplashAssetType {
  animation, // Lottie 애니메이션
  image,     // 정적 이미지
  fallback,  // 기본 아이콘
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ===== 설정 가능한 경로 (나중에 쉽게 변경 가능) =====
  static const String _animationPath = 'assets/animations/clockLottieAnimation.json';
  static const String _imagePath = 'assets/images/temp_logo.png';
  // ==============================================

  late final AnimationController _controller;
  late final AnimationController _lottieController;
  late final Animation<double> _fadeIn;
  
  _SplashAssetType _assetType = _SplashAssetType.fallback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lottieController = AnimationController(vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _loadAsset();
    _checkSignupStatus();
  }

  /// 회원가입 여부 확인 후 적절한 화면으로 이동
  Future<void> _checkSignupStatus() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isSignedUp = prefs.getBool('is_signed_up') ?? false;

      if (isSignedUp) {
        // 이미 회원가입 완료 → 메인 화면으로
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
      } else {
        // 회원가입 안됨 → 구글 로그인 화면으로
        Navigator.of(context).pushReplacementNamed(AppRoutes.googleSignup);
      }
    } catch (e) {
      // 에러 발생 시 구글 로그인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.googleSignup);
      }
    }
  }

  /// 애셋 로드 (애니메이션 우선, 없으면 이미지, 둘 다 없으면 fallback)
  Future<void> _loadAsset() async {
    // 1. 애니메이션 파일 확인
    try {
      await rootBundle.load(_animationPath);
      if (mounted) {
        setState(() {
          _assetType = _SplashAssetType.animation;
        });
        return;
      }
    } catch (_) {
      // 애니메이션 파일이 없으면 계속 진행
    }

    // 2. 이미지 파일 확인
    try {
      await rootBundle.load(_imagePath);
      if (mounted) {
        setState(() {
          _assetType = _SplashAssetType.image;
        });
        return;
      }
    } catch (_) {
      // 이미지 파일도 없으면 fallback 사용
    }

    // 3. 둘 다 없으면 fallback (이미 기본값)
    if (mounted) {
      setState(() {
        _assetType = _SplashAssetType.fallback;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildSplashContent(colors),
                ),
              ),
              SizedBox(height: Gaps.cardPad + 8),
              SizedBox(
                width: Gaps.cardPad + 8,
                height: Gaps.cardPad + 8,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 애셋 타입에 따라 적절한 위젯 반환
  Widget _buildSplashContent(ColorScheme colors) {
    switch (_assetType) {
      case _SplashAssetType.animation:
        return Lottie.asset(
          _animationPath,
          key: const ValueKey('splash-animation'),
          controller: _lottieController,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration * 1.6
              ..repeat();
          },
        );
      case _SplashAssetType.image:
        return Image.asset(
          _imagePath,
          key: const ValueKey('splash-image'),
          fit: BoxFit.contain,
        );
      case _SplashAssetType.fallback:
        return Container(
          key: const ValueKey('fallback-icon'),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 72,
            color: colors.onPrimaryContainer,
          ),
        );
    }
  }
}

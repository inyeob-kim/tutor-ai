import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final AnimationController _lottieController;
  bool _hasAnimation = false;

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
    _loadAnimation();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
    });
  }

  Future<void> _loadAnimation() async {
    try {
      await rootBundle.load('assets/animations/clockLottieAnimation.json');
      if (mounted) {
        setState(() {
          _hasAnimation = true;
        });
      }
    } catch (_) {
      // Keep fallback UI if asset missing or invalid
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
                  child: _hasAnimation
                      ? Lottie.asset(
                          'assets/animations/clockLottieAnimation.json',
                          key: const ValueKey('splash-animation'),
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController
                              ..duration = composition.duration * 1.6
                              ..repeat();
                          },
                        )
                      : Container(
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
                        ),
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(height: 24),
              SizedBox(
                width: 28,
                height: 28,
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
}

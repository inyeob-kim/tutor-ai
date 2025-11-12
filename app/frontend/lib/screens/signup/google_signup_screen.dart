import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/tokens.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class GoogleSignupScreen extends StatefulWidget {
  const GoogleSignupScreen({super.key});

  @override
  State<GoogleSignupScreen> createState() => _GoogleSignupScreenState();
}

class _GoogleSignupScreenState extends State<GoogleSignupScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Firebase Auth를 사용한 구글 로그인
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Google Sign-In 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase Auth로 인증
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Firebase에서 idToken 가져오기
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('구글 로그인 토큰을 가져올 수 없습니다');
      }

      // 백엔드 API로 로그인 (Firebase idToken 사용)
      await ApiService.googleLogin(idToken);

      if (mounted) {
        setState(() => _isLoading = false);
        // 구글 로그인 성공 후 과목 선택 화면으로 이동
        Navigator.of(context).pushReplacementNamed(AppRoutes.signupSubject);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구글 로그인 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Gaps.screen),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고/아이콘 영역
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: Gaps.screen * 2),

              // 타이틀
              Text(
                '쌤대신에 오신 것을\n환영합니다! 👋',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: Gaps.card),
              Text(
                '구글 계정으로 간편하게 시작하세요',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: Gaps.screen * 3),

              // 구글 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                      side: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : Image.asset(
                          'assets/icons/google.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.g_mobiledata_rounded,
                              size: 24,
                              color: AppColors.textPrimary,
                            );
                          },
                        ),
                  label: Text(
                    _isLoading ? '로그인 중...' : '구글로 시작하기',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


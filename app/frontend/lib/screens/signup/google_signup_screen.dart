import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../theme/tokens.dart';

class GoogleSignupScreen extends StatefulWidget {
  const GoogleSignupScreen({super.key});

  @override
  State<GoogleSignupScreen> createState() => _GoogleSignupScreenState();
}

class _GoogleSignupScreenState extends State<GoogleSignupScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (!mounted || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      UserCredential? userCredential;

      if (kIsWeb) {
        // ===== Web 환경: signInWithPopup 사용 =====
        print('🔵 Google 로그인 (Web - signInWithPopup) 시작...');
        
        final googleProvider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await auth.signInWithPopup(googleProvider);
        
        print('✅ signInWithPopup 성공: user=${userCredential.user?.uid}');
      } else {
        // ===== 모바일 환경: google_sign_in 패키지 사용 =====
        print('🔵 Google 로그인 (모바일 - google_sign_in) 시작...');
        
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          // 사용자가 로그인 취소
          print('ℹ️ 사용자가 로그인을 취소했습니다');
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
        
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        userCredential = await auth.signInWithCredential(credential);
        print('✅ signInWithCredential 성공: user=${userCredential.user?.uid}');
      }

      final user = userCredential.user;
      
      if (user == null) {
        print('⚠️ 로그인 결과 user가 null입니다');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('로그인에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      print('✅ 로그인 성공: uid=${user.uid}, email=${user.email}');
      
      // ✅ 로그인 성공 후 처리
      // FirebaseAuth.instance.currentUser에 이미 user가 설정됨
      await _handleLoginSuccess(user);
      
    } catch (e, stackTrace) {
      print('🟥 Google 로그인 에러: $e');
      print('에러 타입: ${e.runtimeType}');
      print('스택 트레이스: $stackTrace');

      if (mounted) {
        String errorMessage = '구글 로그인 실패: $e';
        final msg = e.toString();
        
        if (msg.contains('popup_closed_by_user') || msg.contains('sign_in_canceled')) {
          errorMessage = '로그인이 취소되었습니다.';
        } else if (msg.contains('popup_blocked')) {
          errorMessage = '팝업이 차단되었습니다. 브라우저 팝업 차단을 해제하고 다시 시도해주세요.';
        } else if (msg.contains('network_error')) {
          errorMessage = '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 로그인 성공 후 처리 (백엔드 연동 및 화면 이동)
  Future<void> _handleLoginSuccess(User user) async {
    if (!mounted) return;

    try {
      // 백엔드 연동 (선택적)
      final idToken = await user.getIdToken();
      if (idToken != null) {
        final previewLength = idToken.length > 40 ? 40 : idToken.length;
        print('idToken (앞 $previewLength자): ${idToken.substring(0, previewLength)}...');

        try {
          await ApiService.googleLogin(idToken);
          print('✅ 백엔드 연동 성공');
        } catch (apiError) {
          print('⚠️ 백엔드 연동 실패 (계속 진행): $apiError');
          // 백엔드 연동 실패해도 로그인은 성공했으므로 계속 진행
        }
      }

      // ✅ 로그인 성공 후 화면 이동
      // SplashScreen으로 이동하여 인증 상태 확인 및 적절한 화면으로 라우팅
      // (회원가입 여부 확인은 SplashScreen에서 처리)
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.splash);
      }
    } catch (e) {
      print('❌ 로그인 후 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 후 처리 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
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
                'Google 계정으로 간편하게 시작하세요',
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
                      : const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                  label: Text(
                    _isLoading ? '로그인 중...' : 'Google로 시작하기',
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

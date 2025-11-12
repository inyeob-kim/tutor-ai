import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tokens.dart';

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
      // Firebase Auth만 사용한 구글 로그인 (People API 불필요)
      // 웹에서는 signInWithRedirect를 사용합니다
      if (kIsWeb) {
        print('Google 로그인 시작...');
        print('현재 URL: ${Uri.base}');
        
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        print('GoogleAuthProvider 생성 완료');
        
        await FirebaseAuth.instance.signInWithRedirect(googleProvider);
        print('signInWithRedirect 호출 완료 - 리다이렉트 예정');
        
        // signInWithRedirect는 페이지를 리다이렉트하므로 여기서는 반환
        // 리다이렉트 후 main.dart에서 getRedirectResult로 처리합니다
        return;
      } else {
        // 모바일 플랫폼에서는 기존 방식 사용
        throw UnsupportedError('모바일 플랫폼은 아직 지원되지 않습니다');
      }
    } catch (e) {
      print('Google 로그인 에러: $e');
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
                      : Icon(
                          Icons.g_mobiledata_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
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


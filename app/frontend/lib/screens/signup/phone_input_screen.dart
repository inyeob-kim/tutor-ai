import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tokens.dart';
import '../../routes/app_routes.dart';
import '../../services/teacher_service.dart';
import '../../services/settings_service.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 자동으로 키보드 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String value) {
    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // 11자리 제한
    final limited = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    
    // 포맷팅: 010-1234-5678
    if (limited.length <= 3) {
      return limited;
    } else if (limited.length <= 7) {
      return '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      return '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
    }
  }

  bool get _isValid {
    final digitsOnly = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length == 11 && digitsOnly.startsWith('010');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final subjects = args['subjects'] as List<String>? ?? [];
    final name = args['name'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          '전화번호 입력',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 입력 필드 (가운데 정렬)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Gaps.screen),
              child: TextField(
                controller: _phoneController,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.phone, // 전화번호 패드 자동 표시
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13), // 010-1234-5678 형식
                ],
                onChanged: (value) {
                  final formatted = _formatPhoneNumber(value);
                  if (formatted != value) {
                    _phoneController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  if (mounted) setState(() {});
                },
                onSubmitted: (_) {
                  if (_isValid && !_isLoading) {
                    _handleSignup(context, subjects, name);
                  }
                },
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: '010-1234-5678',
                  hintStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(Gaps.cardPad),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: Gaps.cardPad),
                    child: Icon(
                      Icons.phone_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 56,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 하단 버튼
            Container(
              padding: EdgeInsets.all(Gaps.screen),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: (_isValid && !_isLoading)
                      ? () => _handleSignup(context, subjects, name)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surface,
                            ),
                          ),
                        )
                      : Text(
                          '완료',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignup(
    BuildContext context,
    List<String> subjects,
    String name,
  ) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Firebase Auth 사용자 확인
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다. 다시 로그인해주세요.');
      }

      // 전화번호 정리 (하이픈 제거)
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      // Teacher 정보 생성 (DB에 저장)
      await TeacherService.instance.createTeacher(
        name: name,
        phone: phoneDigits,
        email: user.email,
        subjects: subjects,
      );

      // 선생님 과목 목록을 SettingsService에 저장
      if (subjects.isNotEmpty) {
        await SettingsService.setTeacherSubjects(subjects);
      }

      print('✅ 회원가입 완료: Teacher 정보 저장 성공');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (context.mounted) {
        // 회원가입 완료 화면으로 이동
        Navigator.of(context).pushReplacementNamed(AppRoutes.signupComplete);
      }
    } catch (e) {
      print('❌ 회원가입 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (context.mounted) {
        // 에러 메시지 추출 (Exception: ... 부분 제거)
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: '확인',
              textColor: AppColors.surface,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}


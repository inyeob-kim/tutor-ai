import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens.dart';
import '../../services/api_service.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();

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
      ),
      body: SafeArea(
            child: Column(
              children: [
                // 헤더 섹션
                Padding(
                  padding: EdgeInsets.fromLTRB(Gaps.screen, Gaps.card, Gaps.screen, Gaps.cardPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '전화번호를 입력해주세요 📱',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: Gaps.row),
                      Text(
                        '연락이 가능한 번호를 입력해주세요',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 입력 필드
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
      // TODO: 실제 회원가입 API 호출
      // final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      // await ApiService.signup({
      //   'name': name,
      //   'phone': phoneDigits,
      //   'subjects': subjects,
      // });

      // 성공 시 (시뮬레이션)
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입이 완료되었습니다! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}


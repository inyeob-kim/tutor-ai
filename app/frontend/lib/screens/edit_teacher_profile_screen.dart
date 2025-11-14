import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  const EditTeacherProfileScreen({super.key});

  @override
  State<EditTeacherProfileScreen> createState() => _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;

  bool _isLoading = false;
  Teacher? _teacher;

  final List<String> _taxTypeOptions = [
    '사업소득',
    '기타소득',
    '프리랜서',
    '미신고',
  ];
  String? _selectedTaxType;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null && mounted) {
        setState(() {
          _teacher = teacher;
          _nameController = TextEditingController(text: teacher.nickname);
          _phoneController = TextEditingController(text: teacher.phone);
          _emailController = TextEditingController(text: teacher.email ?? '');
          _bankNameController = TextEditingController(text: teacher.bankName ?? '');
          _accountNumberController = TextEditingController(text: teacher.accountNumber ?? '');
          _selectedTaxType = teacher.taxType;
        });
      }
    } catch (e) {
      print('⚠️ 프로필 정보 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 정보를 불러오는데 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    
    if (limited.length <= 3) {
      return limited;
    } else if (limited.length <= 7) {
      return '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      return '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_teacher == null) return;

    setState(() => _isLoading = true);

    try {
      // 전화번호 정리 (하이픈 제거)
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      final updateData = <String, dynamic>{
        'nickname': _nameController.text.trim(),
        'phone': phoneDigits,
        if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
        if (_bankNameController.text.isNotEmpty) 'bank_name': _bankNameController.text.trim(),
        if (_accountNumberController.text.isNotEmpty) 'account_number': _accountNumberController.text.trim(),
        if (_selectedTaxType != null) 'tax_type': _selectedTaxType,
      };

      await ApiService.updateTeacher(_teacher!.teacherId, updateData);

      // TeacherService 캐시 새로고침
      await TeacherService.instance.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필이 성공적으로 수정되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 수정 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_teacher == null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: const Text('프로필 수정'),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const TossScrollPhysics(),
          padding: EdgeInsets.all(Gaps.card),
          children: [
            // 프로필 정보 섹션
            _buildSectionTitle('프로필 정보', theme, colorScheme),
            _buildTextField(
              controller: _nameController,
              label: '닉네임',
              hint: '닉네임을 입력하세요',
              icon: Icons.person_outline_rounded,
              required: true,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),
            _buildTextField(
              controller: _phoneController,
              label: '전화번호',
              hint: '010-1234-5678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              required: true,
              theme: theme,
              colorScheme: colorScheme,
              onChanged: (value) {
                final formatted = _formatPhoneNumber(value);
                if (formatted != value) {
                  _phoneController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            SizedBox(height: Gaps.card),
            _buildTextField(
              controller: _emailController,
              label: '이메일',
              hint: '이메일을 입력하세요',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 계좌 정보 섹션
            _buildSectionTitle('계좌 정보', theme, colorScheme),
            _buildTextField(
              controller: _bankNameController,
              label: '은행명',
              hint: '은행명을 입력하세요',
              icon: Icons.account_balance_outlined,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),
            _buildTextField(
              controller: _accountNumberController,
              label: '계좌번호',
              hint: '계좌번호를 입력하세요',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),
            _buildDropdownField(
              label: '세금 유형',
              value: _selectedTaxType,
              options: _taxTypeOptions,
              icon: Icons.receipt_outlined,
              onChanged: (value) => setState(() => _selectedTaxType = value),
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.cardPad + 12),

            // 저장 버튼
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Gaps.card),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                      ),
                    )
                  : Text(
                      '저장',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
            ),
            SizedBox(height: Gaps.screen * 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: Gaps.cardPad),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    bool required = false,
    ValueChanged<String>? onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.card),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label을(를) 입력해주세요';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Gaps.card),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('선택 안함')),
          ...options.map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}


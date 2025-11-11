import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _gradeController = TextEditingController();
  final _subjectController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isAdult = true; // 디폴트는 성인

  final List<String> _gradeOptions = [
    '초등학교 1학년',
    '초등학교 2학년',
    '초등학교 3학년',
    '초등학교 4학년',
    '초등학교 5학년',
    '초등학교 6학년',
    '중학교 1학년',
    '중학교 2학년',
    '중학교 3학년',
    '고등학교 1학년',
    '고등학교 2학년',
    '고등학교 3학년',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _subjectController.dispose();
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'is_adult': _isAdult,
        // 성인이 아닐 경우에만 보호자 전화번호, 학교, 학년 포함
        if (!_isAdult && _parentPhoneController.text.isNotEmpty)
          'parent_phone': _parentPhoneController.text.trim(),
        if (!_isAdult && _schoolController.text.isNotEmpty) 
          'school': _schoolController.text.trim(),
        if (!_isAdult && _gradeController.text.isNotEmpty) 
          'grade': _gradeController.text.trim(),
        if (_subjectController.text.isNotEmpty) 'subject': _subjectController.text.trim(),
        if (_startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        if (_hourlyRateController.text.isNotEmpty)
          'hourly_rate': int.tryParse(_hourlyRateController.text) ?? 0,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
        'is_active': _isActive,
      };

      await ApiService.createStudent(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('학생이 성공적으로 등록되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('학생 등록'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const TossScrollPhysics(),
          padding: const EdgeInsets.all(16),
          cacheExtent: 500,
          children: [
            // 필수 정보 섹션
            _buildSectionTitle('필수 정보', theme, colorScheme),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: '이름',
              hint: '학생 이름을 입력하세요',
              icon: Icons.person_outline,
              required: true,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: '전화번호',
              hint: '010-1234-5678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              required: true,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // 추가 정보 섹션
            _buildSectionTitle('추가 정보', theme, colorScheme),
            const SizedBox(height: 12),
            // 성인 여부 토글
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: SwitchListTile(
                title: const Text('성인 여부'),
                subtitle: const Text('성인일 경우 보호자 정보와 학년을 입력하지 않습니다'),
                value: _isAdult,
                onChanged: (value) {
                  setState(() {
                    _isAdult = value;
                    if (value) {
                      // 성인으로 변경하면 미성년자 전용 필드들 초기화
                      _gradeController.clear();
                      _parentPhoneController.clear();
                      _schoolController.clear();
                    }
                  });
                },
              ),
            ),
            // 성인이 아닐 경우에만 보호자 전화번호, 학교, 학년 필드 표시
            if (!_isAdult) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _parentPhoneController,
                label: '보호자 전화번호',
                hint: '010-1234-5678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _schoolController,
                label: '학교',
                hint: '학교명을 입력하세요',
                icon: Icons.school_outlined,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: '학년',
                value: _gradeController.text.isEmpty ? null : _gradeController.text,
                options: _gradeOptions,
                icon: Icons.class_outlined,
                onChanged: (value) => setState(() => _gradeController.text = value ?? ''),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _subjectController,
              label: '과목',
              hint: '예: 수학, 영어, 과학',
              icon: Icons.book_outlined,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: '시작일',
              value: _startDate,
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectDate(context),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _hourlyRateController,
              label: '시간당 수강료',
              hint: '예: 50000',
              icon: Icons.attach_money_outlined,
              keyboardType: TextInputType.number,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: '메모',
              hint: '추가 메모를 입력하세요',
              icon: Icons.note_outlined,
              maxLines: 3,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // 활성 상태
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: SwitchListTile(
                title: const Text('활성 상태'),
                subtitle: const Text('학생이 활성 상태인지 설정합니다'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ),
            const SizedBox(height: 32),

            // 등록 버튼
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '학생 등록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 100),
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
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
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
    int maxLines = 1,
    bool required = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
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

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          child: Text(
            value != null ? DateFormat('yyyy-MM-dd').format(value) : '날짜 선택',
            style: TextStyle(
              color: value != null
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

}


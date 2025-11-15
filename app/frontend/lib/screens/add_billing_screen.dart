import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../widgets/loading_indicator.dart';

class AddBillingScreen extends StatefulWidget {
  const AddBillingScreen({super.key});

  @override
  State<AddBillingScreen> createState() => _AddBillingScreenState();
}

class _AddBillingScreenState extends State<AddBillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedStudentId;
  String? _selectedSubject;
  DateTime? _billingDate;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _billingDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _loadStudents();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final studentsData = await ApiService.getStudents();
      // API 응답을 올바른 형식으로 변환
      final studentsList = studentsData.map((s) {
        final studentId = s['student_id'] as int?;
        final name = s['name'] as String? ?? '이름 없음';
        // 백엔드에서는 subject_id (단일 문자열)를 반환하므로, 이를 리스트로 변환
        final subjectId = s['subject_id'] as String?;
        List<String> subjects = [];
        if (subjectId != null && subjectId.isNotEmpty) {
          // subject_id가 있으면 리스트에 추가
          subjects = [subjectId];
        } else {
          // 없으면 기존 방식(subjects 배열)도 시도 (하위 호환성)
          final subjectsArray = s['subjects'] as List<dynamic>?;
          if (subjectsArray != null && subjectsArray.isNotEmpty) {
            subjects = subjectsArray.map((e) => e.toString()).toList();
          }
        }
        
        return {
          'id': studentId, // student_id를 id로 변환
          'name': name,
          'subjects': subjects,
        };
      }).where((s) => s['id'] != null).toList();
      
      setState(() {
        _students = studentsList;
        _selectedStudentId = null; // 명시적으로 선택 해제
        _selectedSubject = null; // 과목도 선택 해제
        _isLoadingStudents = false;
      });
    } catch (e) {
      print('⚠️ 학생 목록 로드 실패: $e');
      setState(() {
        _students = [];
        _selectedStudentId = null;
        _selectedSubject = null;
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _selectBillingDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _billingDate = picked);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('학생을 선택해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('청구 금액을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (amount <= 0) {
        throw Exception('청구 금액은 0보다 커야 합니다');
      }

      final data = <String, dynamic>{
        'student_id': _selectedStudentId,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_billingDate!),
        'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
        if (_selectedSubject != null) 'subject': _selectedSubject,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
      };

      await ApiService.createBilling(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('청구가 성공적으로 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: ${e.toString()}'),
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('청구 추가'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const TossScrollPhysics(),
          padding: EdgeInsets.all(Gaps.card),
          children: [
            // 학생 선택
            _buildSectionTitle('학생 선택', theme, colorScheme),
            SizedBox(height: Gaps.row),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: _isLoadingStudents
                  ? Padding(
                      padding: EdgeInsets.all(Gaps.cardPad + 4),
                      child: const Center(child: LoadingIndicator()),
                    )
                  : _students.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(Gaps.cardPad + 4),
                          child: Center(
                            child: Text(
                              '등록된 학생이 없습니다',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _students.map((student) {
                            final isSelected = _selectedStudentId == student['id'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStudentId = student['id'];
                                  // 과목은 자동 선택하지 않음
                                  _selectedSubject = null;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(Gaps.card),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outline.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: Gaps.screen,
                                      backgroundColor: isSelected
                                          ? AppColors.primary
                                          : colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        (student['name']?.toString() ?? '?')[0],
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.surface
                                              : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Gaps.row),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name']?.toString() ?? '이름 없음',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? colorScheme.onPrimaryContainer
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          if (student['subjects'] != null &&
                                              student['subjects'] is List &&
                                              (student['subjects'] as List).isNotEmpty)
                                            Text(
                                              (student['subjects'] as List)
                                                  .map((s) => s.toString())
                                                  .join(', '),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isSelected
                                                    ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                                                    : colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 과목 선택 (학생 선택 후)
            if (_selectedStudentId != null && _students.isNotEmpty)
              ...() {
                try {
                  final selectedStudent = _students.firstWhere(
                    (s) => s['id'] == _selectedStudentId,
                  );
                  final subjects = selectedStudent['subjects'];
                  
                  if (subjects != null && subjects is List && subjects.isNotEmpty) {
                    return [
                      _buildSectionTitle('과목 선택', theme, colorScheme),
                      SizedBox(height: Gaps.row),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.chip + 4),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(Gaps.card),
                          child: Wrap(
                            spacing: Gaps.row - 2,
                            runSpacing: Gaps.row - 2,
                            children: subjects
                                .map<Widget>((subject) {
                              final subjectStr = subject.toString();
                              final isSelected = _selectedSubject == subjectStr;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedSubject = subjectStr);
                                },
                                borderRadius: BorderRadius.circular(Radii.chip),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Gaps.card,
                                    vertical: Gaps.row,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(Radii.chip),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    subjectStr,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Gaps.cardPad + 4),
                    ];
                  }
                } catch (e) {
                  // 학생을 찾을 수 없거나 과목이 없는 경우
                }
                return <Widget>[];
              }(),

            // 청구 금액
            _buildCurrencyTextField(
              controller: _amountController,
              label: '청구금액',
              hint: '예: 200000',
              required: true,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 청구 날짜
            _buildDateField(
              label: '청구일',
              value: _billingDate,
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectBillingDate(context),
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),

            // 마감일
            _buildDateField(
              label: '마감일',
              value: _dueDate,
              icon: Icons.event_outlined,
              onTap: () => _selectDueDate(context),
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 메모
            _buildTextField(
              controller: _notesController,
              label: '메모',
              hint: '추가 메모를 입력하세요',
              icon: Icons.note_outlined,
              maxLines: 3,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),

            // 등록 버튼
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: Gaps.screen * 2,
                      vertical: 14,
                    ),
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: Gaps.screen,
                          width: Gaps.screen,
                          child: const SmallLoadingIndicator(
                            size: 20,
                          ),
                        )
                      : Text(
                          '청구 등록',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: Gaps.screen),
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
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          label: required
              ? RichText(
                  text: TextSpan(
                    text: label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(label),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            hintText: '날짜 선택',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(Gaps.card),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          child: Text(
            value != null ? DateFormat('yyyy-MM-dd').format(value) : '',
            style: TextStyle(
              color: value != null
                  ? colorScheme.onSurface
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool required = false,
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
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _CurrencyInputFormatter(),
        ],
        decoration: InputDecoration(
          label: required
              ? RichText(
                  text: TextSpan(
                    text: label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(label),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Center(
              widthFactor: 1.0,
              child: Text(
                '₩',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 0,
          ),
          suffixText: '원',
          suffixStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
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
}

/// 원화 금액 입력 포맷터 (쉼표 자동 추가)
class _CurrencyInputFormatter extends TextInputFormatter {
  final numberFormat = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 추출
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return TextEditingValue.empty;
    }

    // 쉼표 추가
    final formatted = numberFormat.format(int.parse(digitsOnly));
    
    // 커서 위치를 끝으로 설정 (간단한 방법)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


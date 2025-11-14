import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/teacher_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../widgets/loading_indicator.dart';
import 'add_recurring_schedule_screen.dart';

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
  final _hourlyRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isAdult = true; // 디폴트는 성인
  List<String> _teacherSubjects = [];
  String? _selectedSubject;

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
  void initState() {
    super.initState();
    _loadTeacherSubjects();
  }

  Future<void> _loadTeacherSubjects() async {
    final subjects = await SettingsService.getTeacherSubjects();
    setState(() {
      _teacherSubjects = subjects;
      if (subjects.isNotEmpty && _selectedSubject == null) {
        _selectedSubject = subjects.first;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
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
      // 현재 로그인한 선생님 정보 가져오기
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        throw Exception('선생님 정보를 불러올 수 없습니다. 다시 로그인해주세요.');
      }

      // 선택된 과목을 subject_id로 변환 (백엔드는 subject_id를 사용)
      String? subjectId;
      if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
        subjectId = _selectedSubject!;
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'teacher_id': teacher.teacherId, // 현재 로그인한 선생님 ID 추가
        'is_adult': _isAdult,
        // 성인이 아닐 경우에만 보호자 전화번호, 학교, 학년 포함
        if (!_isAdult && _parentPhoneController.text.isNotEmpty)
          'parent_phone': _parentPhoneController.text.trim(),
        if (!_isAdult && _schoolController.text.isNotEmpty) 
          'school': _schoolController.text.trim(),
        if (!_isAdult && _gradeController.text.isNotEmpty) 
          'grade': _gradeController.text.trim(),
        if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId, // subject_id로 변경 (백엔드는 subject_id 사용)
        if (_startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        if (_hourlyRateController.text.isNotEmpty)
          'hourly_rate': int.tryParse(_hourlyRateController.text) ?? 0,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
        'is_active': _isActive,
      };

      // 디버깅: 전송할 데이터 확인
      print('📤 학생 등록 요청 데이터:');
      print('  - teacher_id: ${data['teacher_id']}');
      print('  - name: ${data['name']}');
      print('  - phone: ${data['phone']}');
      print('  - subject_id: ${data['subject_id']}');
      print('  - 전체 데이터: $data');

      final studentResult = await ApiService.createStudent(data);
      final studentId = studentResult['student_id'] as int?;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('학생이 성공적으로 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // 스케줄 자동 제안 다이얼로그 표시
        if (studentId != null) {
          await _showScheduleSuggestionDialog(studentId, _nameController.text.trim());
        }
        
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

  /// 스케줄 자동 제안 다이얼로그
  Future<void> _showScheduleSuggestionDialog(int studentId, String studentName) async {
    if (!mounted) return;

    // 일반적인 과외 시간 제안 (수요일/목요일 오후 4시)
    final suggestedWeekday = 3; // 수요일 (0=월요일, 3=수요일)
    final suggestedTime = '16:00';
    final suggestedEndTime = '17:00';
    final suggestedDateFrom = DateTime.now();
    final suggestedDateTo = DateTime.now().add(const Duration(days: 28)); // 4주

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayLabel = weekdayLabels[suggestedWeekday];

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '수업 일정 제안',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$studentName님의 수업 일정을 등록하시겠어요?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '제안 일정',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                        child: Text(
                          '매주 $weekdayLabel',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$suggestedTime - $suggestedEndTime',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('M월 d일').format(suggestedDateFrom)} ~ ${DateFormat('M월 d일').format(suggestedDateTo)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '터치 한 번으로 반복 수업을 등록할 수 있어요',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('skip'),
            child: Text(
              '나중에',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('custom'),
            child: Text(
              '직접 설정',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop('accept'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('추가하기'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );

    if (result == 'accept' && mounted) {
      // 제안된 일정으로 바로 등록
      await _createSuggestedSchedule(
        studentId,
        suggestedWeekday,
        suggestedTime,
        suggestedEndTime,
        suggestedDateFrom,
        suggestedDateTo,
      );
    } else if (result == 'custom' && mounted) {
      // 반복 수업 등록 화면으로 이동
      final scheduleResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddRecurringScheduleScreen(),
        ),
      );
      if (scheduleResult == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수업 일정이 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  /// 제안된 스케줄로 반복 수업 생성
  Future<void> _createSuggestedSchedule(
    int studentId,
    int weekday,
    String startTime,
    String endTime,
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    if (!mounted) return;

    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        throw Exception('선생님 정보를 불러올 수 없습니다.');
      }

      // subject_id 가져오기
      final subjectId = _selectedSubject ?? '';

      // bulk-generate API 호출
      final queryParams = <String, String>{
        'teacher_id': teacher.teacherId.toString(),
        'student_id': studentId.toString(),
        'subject_id': subjectId,
        'weekday': weekday.toString(),
        'start_time': startTime,
        'end_time': endTime,
        'date_from': DateFormat('yyyy-MM-dd').format(dateFrom),
        'date_to': DateFormat('yyyy-MM-dd').format(dateTo),
      };

      final uri = Uri.parse('${ApiService.baseUrl}/schedules/bulk-generate')
          .replace(queryParameters: queryParams);

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final created = result['created'] as int? ?? 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$created개의 수업 일정이 등록되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('스케줄 등록 실패: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스케줄 등록 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
          padding: EdgeInsets.all(Gaps.card),
          cacheExtent: 500,
          children: [
            // 필수 정보 섹션
            _buildSectionTitle('필수 정보', theme, colorScheme),
            SizedBox(height: Gaps.row),
            _buildTextField(
              controller: _nameController,
              label: '이름',
              hint: '학생 이름을 입력하세요',
              icon: Icons.person_outline,
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
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 추가 정보 섹션
            _buildSectionTitle('추가 정보', theme, colorScheme),
            SizedBox(height: Gaps.row),
            // 성인 여부 토글
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
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
              SizedBox(height: Gaps.card),
              _buildTextField(
                controller: _parentPhoneController,
                label: '보호자 전화번호',
                hint: '010-1234-5678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                theme: theme,
                colorScheme: colorScheme,
              ),
              SizedBox(height: Gaps.card),
              _buildTextField(
                controller: _schoolController,
                label: '학교',
                hint: '학교명을 입력하세요',
                icon: Icons.school_outlined,
                theme: theme,
                colorScheme: colorScheme,
              ),
              SizedBox(height: Gaps.card),
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
            SizedBox(height: Gaps.card),
            if (_teacherSubjects.isEmpty)
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
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: Gaps.row),
                      Expanded(
                        child: Text(
                          '설정 화면에서 가르치는 과목을 먼저 선택해주세요',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildDropdownField(
                label: '과목',
                value: _selectedSubject,
                options: _teacherSubjects,
                icon: Icons.book_outlined,
                onChanged: (value) => setState(() => _selectedSubject = value),
                theme: theme,
                colorScheme: colorScheme,
              ),
            SizedBox(height: Gaps.card),
            _buildDateField(
              label: '시작일',
              value: _startDate,
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectDate(context),
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),
            _buildTextField(
              controller: _hourlyRateController,
              label: '시간당 수강료',
              hint: '예: 50000',
              icon: Icons.attach_money_outlined,
              keyboardType: TextInputType.number,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.card),
            _buildTextField(
              controller: _notesController,
              label: '메모',
              hint: '추가 메모를 입력하세요',
              icon: Icons.note_outlined,
              maxLines: 3,
              theme: theme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 활성 상태
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip + 4),
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
            SizedBox(height: Gaps.cardPad + 12),

            // 등록 버튼
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
                      child: const SmallLoadingIndicator(
                        size: 20,
                      ),
                    )
                  : Text(
                      '학생 등록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
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
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(Gaps.card),
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


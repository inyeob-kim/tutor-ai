import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  final List<String>? initialSubjects;
  
  const TeacherSubjectsScreen({
    super.key,
    this.initialSubjects,
  });

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  final List<String> _availableSubjects = [
    '수학',
    '영어',
    '국어',
    '과학',
    '사회',
    '역사',
    '물리',
    '화학',
    '생물',
    '지구과학',
    '영어회화',
    '토익',
    '토플',
    '일본어',
    '중국어',
    '프로그래밍',
    '논술',
    '제2외국어',
  ];

  late List<String> _selectedSubjects;

  final TextEditingController _newSubjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List<String>.from(
      widget.initialSubjects ?? ['수학', '영어', '과학'],
    );
    // 선택된 과목이 사용 가능한 과목 목록에 없으면 추가
    for (final subject in _selectedSubjects) {
      if (!_availableSubjects.contains(subject)) {
        _availableSubjects.add(subject);
      }
    }
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  void _addCustomSubject() {
    final subject = _newSubjectController.text.trim();
    if (subject.isNotEmpty && !_availableSubjects.contains(subject)) {
      setState(() {
        _availableSubjects.add(subject);
        _selectedSubjects.add(subject);
        _newSubjectController.clear();
      });
    }
  }

  void _removeSubject(String subject) {
    setState(() {
      _selectedSubjects.remove(subject);
      // 기본 과목 목록에서는 제거하지 않고, 커스텀 과목만 제거
      if (!['수학', '영어', '국어', '과학', '사회', '역사', '물리', '화학', '생물', 
            '지구과학', '영어회화', '토익', '토플', '일본어', '중국어', '프로그래밍', 
            '논술', '제2외국어'].contains(subject)) {
        _availableSubjects.remove(subject);
      }
    });
  }

  void _saveSubjects() {
    // TODO: API로 서버에 저장
    Navigator.of(context).pop(_selectedSubjects);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('가르치는 과목이 저장되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('가르치는 과목'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSubjects,
            child: Text(
              '저장',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const TossScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 안내 문구
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '가르칠 수 있는 과목을 선택하세요. 학생 등록 시 이 과목들 중에서 선택할 수 있습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 선택된 과목 섹션
          Text(
            '선택된 과목 (${_selectedSubjects.length}개)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedSubjects.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '선택된 과목이 없습니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSubjects.map((subject) {
                return Chip(
                  label: Text(subject),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  onDeleted: () => _removeSubject(subject),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 32),

          // 사용 가능한 과목 섹션
          Text(
            '과목 선택',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                ..._availableSubjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return InkWell(
                    onTap: () => _toggleSubject(subject),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subject,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 커스텀 과목 추가
          Text(
            '새 과목 추가',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSubjectController,
                      decoration: InputDecoration(
                        hintText: '과목 이름 입력',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addCustomSubject(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _addCustomSubject,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('추가'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


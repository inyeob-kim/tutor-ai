import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

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
  String? _selectedCategory;
  late List<String> _selectedSubjects;

  // 카테고리별 과목 목록
  final Map<String, List<Map<String, dynamic>>> _subjectsByCategory = {
    '국어/문학': [
      {'name': '국어', 'icon': Icons.menu_book, 'color': AppColors.success},
      {'name': '문학', 'icon': Icons.book, 'color': AppColors.success},
      {'name': '논술', 'icon': Icons.edit_note, 'color': AppColors.primary},
    ],
    '수학': [
      {'name': '수학', 'icon': Icons.calculate, 'color': AppColors.primary},
    ],
    '외국어': [
      {'name': '영어', 'icon': Icons.translate, 'color': AppColors.warning},
      {'name': '중국어', 'icon': Icons.language, 'color': AppColors.warning},
      {'name': '일본어', 'icon': Icons.translate, 'color': AppColors.warning},
      {'name': '영어회화', 'icon': Icons.chat, 'color': AppColors.warning},
      {'name': '토익', 'icon': Icons.school, 'color': AppColors.warning},
      {'name': '토플', 'icon': Icons.school, 'color': AppColors.warning},
    ],
    '과학': [
      {'name': '과학', 'icon': Icons.science, 'color': AppColors.error},
      {'name': '물리', 'icon': Icons.speed, 'color': AppColors.primary},
      {'name': '화학', 'icon': Icons.science, 'color': AppColors.success},
      {'name': '생물', 'icon': Icons.eco, 'color': AppColors.success},
      {'name': '지구과학', 'icon': Icons.terrain, 'color': AppColors.primary},
    ],
    '사회/역사': [
      {'name': '사회', 'icon': Icons.public, 'color': AppColors.primary},
      {'name': '역사', 'icon': Icons.history, 'color': AppColors.warning},
    ],
    '예체능': [
      {'name': '음악', 'icon': Icons.music_note, 'color': AppColors.warning},
      {'name': '미술', 'icon': Icons.palette, 'color': AppColors.error},
      {'name': '체육', 'icon': Icons.sports_soccer, 'color': AppColors.success},
    ],
    '기타': [
      {'name': '프로그래밍', 'icon': Icons.code, 'color': AppColors.primary},
      {'name': '컴퓨터', 'icon': Icons.computer, 'color': AppColors.primary},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedSubjects = List<String>.from(
      widget.initialSubjects ?? [],
    );
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

  void _saveSubjects() {
    Navigator.of(context).pop(_selectedSubjects);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('가르치는 과목이 저장되었습니다.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  List<Map<String, dynamic>> get _currentSubjects {
    if (_selectedCategory == null) return [];
    return _subjectsByCategory[_selectedCategory!] ?? [];
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
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(Gaps.card),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 안내 문구
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    side: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(Gaps.cardPad),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: Gaps.row),
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
                SizedBox(height: Gaps.cardPad + 4),

                // 선택된 과목 섹션
                Text(
                  '선택된 과목 (${_selectedSubjects.length}개)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: Gaps.row),
                if (_selectedSubjects.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                      side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Gaps.cardPad + 4),
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
                    spacing: Gaps.row - 2,
                    runSpacing: Gaps.row - 2,
                    children: _selectedSubjects.map((subject) {
                      return Chip(
                        label: Text(subject),
                        backgroundColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedSubjects.remove(subject);
                          });
                        },
                      );
                    }).toList(),
                  ),
                SizedBox(height: Gaps.cardPad + 4),

                // 카테고리 선택
                Text(
                  '카테고리 선택',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: Gaps.row),
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _subjectsByCategory.keys.length,
                    itemBuilder: (context, index) {
                      final category = _subjectsByCategory.keys.elementAt(index);
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? null : category;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: Gaps.row),
                          padding: EdgeInsets.symmetric(
                            horizontal: Gaps.card,
                            vertical: Gaps.row,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(Radii.chip),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 선택된 카테고리의 과목들
                if (_selectedCategory != null) ...[
                  Text(
                    '$_selectedCategory 과목',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: Gaps.row),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                      side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Gaps.card),
                      child: Wrap(
                        spacing: Gaps.row,
                        runSpacing: Gaps.row,
                        children: _currentSubjects.map((subjectData) {
                          final subject = subjectData['name'] as String;
                          final icon = subjectData['icon'] as IconData;
                          final color = subjectData['color'] as Color;
                          final isSelected = _selectedSubjects.contains(subject);
                          
                          return InkWell(
                            onTap: () => _toggleSubject(subject),
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
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 20,
                                    color: isSelected ? AppColors.primary : color,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    subject,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                      side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Gaps.cardPad + 4),
                      child: Center(
                        child: Text(
                          '카테고리를 선택하면 관련 과목들이 표시됩니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: Gaps.screen * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

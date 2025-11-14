import 'package:flutter/material.dart';
import '../../theme/scroll_physics.dart';
import '../../theme/tokens.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final Set<String> _selectedSubjects = {};
  String _selectedCategory = '국어/문학';

  final Map<String, List<Map<String, dynamic>>> _subjectsByCategory = {
    '국어/문학': [
      {'name': '국어', 'icon': Icons.menu_book_rounded, 'color': AppColors.success},
      {'name': '문학', 'icon': Icons.book_rounded, 'color': AppColors.success},
      {'name': '논술', 'icon': Icons.edit_note_rounded, 'color': AppColors.primaryDark},
    ],
    '수학': [
      {'name': '수학', 'icon': Icons.calculate_rounded, 'color': AppColors.primary},
    ],
    '외국어': [
      {'name': '영어', 'icon': Icons.translate_rounded, 'color': AppColors.warning},
      {'name': '중국어', 'icon': Icons.language_rounded, 'color': AppColors.warning},
      {'name': '일본어', 'icon': Icons.translate_rounded, 'color': AppColors.warning},
      {'name': '스페인어', 'icon': Icons.language_rounded, 'color': AppColors.warning},
      {'name': '프랑스어', 'icon': Icons.language_rounded, 'color': AppColors.warning},
    ],
    '과학': [
      {'name': '과학', 'icon': Icons.science_rounded, 'color': AppColors.error},
      {'name': '물리', 'icon': Icons.speed_rounded, 'color': AppColors.primary},
      {'name': '화학', 'icon': Icons.science_outlined, 'color': AppColors.success},
      {'name': '생물', 'icon': Icons.eco_rounded, 'color': AppColors.success},
      {'name': '지구과학', 'icon': Icons.terrain_rounded, 'color': AppColors.primaryDark},
    ],
    '사회/역사': [
      {'name': '사회', 'icon': Icons.public_rounded, 'color': AppColors.primaryDark},
      {'name': '한국사', 'icon': Icons.history_rounded, 'color': AppColors.warning},
      {'name': '세계사', 'icon': Icons.public_rounded, 'color': AppColors.primaryDark},
      {'name': '지리', 'icon': Icons.map_rounded, 'color': AppColors.primaryDark},
    ],
    '예체능': [
      {'name': '음악', 'icon': Icons.music_note_rounded, 'color': AppColors.warning},
      {'name': '미술', 'icon': Icons.palette_rounded, 'color': AppColors.error},
      {'name': '체육', 'icon': Icons.sports_soccer_rounded, 'color': AppColors.success},
    ],
    '기타': [
      {'name': '컴퓨터', 'icon': Icons.computer_rounded, 'color': AppColors.primary},
      {'name': '코딩', 'icon': Icons.code_rounded, 'color': AppColors.primary},
    ],
  };

  List<Map<String, dynamic>> get _currentSubjects => _subjectsByCategory[_selectedCategory] ?? [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
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
                    '가르치려는 과목을\n선택해주세요 📚',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: Gaps.row),
                  Text(
                    '여러 개 선택할 수 있어요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 카테고리 선택 탭
            Container(
              height: 50,
              margin: EdgeInsets.symmetric(horizontal: Gaps.screen),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _subjectsByCategory.keys.length,
                itemBuilder: (context, index) {
                  final category = _subjectsByCategory.keys.elementAt(index);
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: Gaps.row),
                      padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: Gaps.row),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
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
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: Gaps.card),

            // 과목 선택 그리드
            Expanded(
              child: CustomScrollView(
                physics: const TossScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: Gaps.screen),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = _currentSubjects[index];
                          final isSelected = _selectedSubjects.contains(subject['name']);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSubjects.remove(subject['name']);
                                } else {
                                  _selectedSubjects.add(subject['name'] as String);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (subject['color'] as Color).withOpacity(0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(Radii.card),
                                border: Border.all(
                                  color: isSelected
                                      ? subject['color'] as Color
                                      : AppColors.divider,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: (subject['color'] as Color)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    subject['icon'] as IconData,
                                    size: 32,
                                    color: isSelected
                                        ? subject['color'] as Color
                                        : AppColors.textSecondary,
                                  ),
                                  SizedBox(height: Gaps.row - 2),
                                  Text(
                                    subject['name'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? subject['color'] as Color
                                          : AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isSelected) ...[
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: subject['color'] as Color,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _currentSubjects.length,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),

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
                  onPressed: _selectedSubjects.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(
                            '/signup/name',
                            arguments: _selectedSubjects.toList(),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedSubjects.isEmpty
                        ? '과목을 선택해주세요'
                        : '다음 (${_selectedSubjects.length}개 선택됨)',
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
}


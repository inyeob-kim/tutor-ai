import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../theme/tokens.dart';
import '../widgets/loading_indicator.dart';

class InactiveStudentsScreen extends StatefulWidget {
  const InactiveStudentsScreen({super.key});

  @override
  State<InactiveStudentsScreen> createState() => _InactiveStudentsScreenState();
}

class _InactiveStudentsScreenState extends State<InactiveStudentsScreen> {
  List<Student> students = [];
  bool _isLoading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  /// 비활성화된 학생 목록 로드
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 비활성화된 학생만 조회
      final studentsData = await ApiService.getStudents(isActive: false);
      final studentsList = studentsData.map((s) {
        final studentId = s['student_id'] as int?;
        final name = s['name'] as String? ?? '이름 없음';
        final grade = s['grade'] as String?;
        
        // 백엔드에서는 subject_id (단일 문자열)를 반환하므로, 이를 리스트로 변환
        final subjectId = s['subject_id'] as String?;
        List<String> subjects = [];
        if (subjectId != null && subjectId.isNotEmpty) {
          subjects = [subjectId];
        } else {
          final subjectsArray = s['subjects'] as List<dynamic>?;
          if (subjectsArray != null && subjectsArray.isNotEmpty) {
            subjects = subjectsArray.map((e) => e.toString()).toList();
          }
        }
        
        final phone = s['phone'] as String? ?? '';
        final sessions = s['total_sessions'] as int? ?? 0;
        final completedSessions = s['completed_sessions'] as int? ?? 0;
        final isAdult = s['is_adult'] as bool? ?? false;
        final isActive = s['is_active'] as bool? ?? false;
        final nextClass = s['next_class'] as String? ?? '';
        final attendanceRate = sessions > 0 ? ((completedSessions / sessions) * 100).round() : 0;

        return Student(
          studentId: studentId,
          name: name,
          grade: grade,
          subjects: subjects,
          phone: phone,
          sessions: sessions,
          completedSessions: completedSessions,
          color: AppColors.primary,
          nextClass: nextClass,
          attendanceRate: attendanceRate,
          isAdult: isAdult,
          isActive: isActive,
        );
      }).toList();

      if (mounted) {
        setState(() {
          students = studentsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ 비활성화된 학생 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          students = [];
          _isLoading = false;
        });
      }
    }
  }

  // 필터링
  List<Student> get filteredStudents {
    List<Student> filtered = students;

    // 검색 필터
    if (query.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(query.toLowerCase().trim()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              '비활성화된 학생',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 검색
                _buildSearchBar(theme, colorScheme),
                SizedBox(height: Gaps.screen),

                // 학생 리스트
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(Gaps.screen * 2),
                      child: const LoadingIndicator(),
                    ),
                  )
                else if (filteredStudents.isEmpty)
                  _buildEmptyState(theme, colorScheme)
                else
                  ...filteredStudents
                      .map((student) => Padding(
                            padding: EdgeInsets.only(bottom: Gaps.card - 2),
                            child: _buildStudentCard(
                              student,
                              theme,
                              colorScheme,
                            ),
                          )),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Gaps.screen * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '비활성화된 학생이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.chip),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => query = value),
        decoration: InputDecoration(
          hintText: '학생 이름 검색...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: Gaps.screen,
            vertical: Gaps.card,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    Student student,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showStudentDetailModal(context, student, theme, colorScheme);
          },
          borderRadius: BorderRadius.circular(Radii.card + 6),
          child: Padding(
            padding: EdgeInsets.all(Gaps.cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    // 아바타
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: student.color.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Radii.chip + 4),
                      ),
                      child: Center(
                        child: Text(
                          student.name[0],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Gaps.card),
                    // 학생 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                student.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(Radii.chip),
                                ),
                                child: Text(
                                  '비활성화',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (student.isAdult == false && student.grade != null) ...[
                            Text(
                              student.grade!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ] else if (student.isAdult) ...[
                            Text(
                              '성인',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 과목
                Wrap(
                  spacing: Gaps.row - 2,
                  runSpacing: Gaps.row - 2,
                  children: student.subjects
                      .map((subject) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(Radii.chip),
                            ),
                            child: Text(
                              subject,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: student.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentDetailModal(
    BuildContext context,
    Student student,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailModal(
        student: student,
        theme: theme,
        colorScheme: colorScheme,
        onClose: () => Navigator.of(context).pop(),
        onActivated: () {
          Navigator.of(context).pop();
          _loadStudents();
        },
      ),
    );
  }
}

class _StudentDetailModal extends StatelessWidget {
  final Student student;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onClose;
  final VoidCallback onActivated;

  const _StudentDetailModal({
    required this.student,
    required this.theme,
    required this.colorScheme,
    required this.onClose,
    required this.onActivated,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: student.color.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, color: AppColors.surface),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 프로필
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surface.withOpacity(0.2),
                    child: Text(
                      student.name[0],
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.surface,
                    ),
                  ),
                  if (student.isAdult == false && student.grade != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      student.grade!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.surface.withOpacity(0.9),
                      ),
                    ),
                  ] else if (student.isAdult) ...[
                    const SizedBox(height: 4),
                    Text(
                      '성인',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.surface.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 바디
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(Gaps.cardPad + 4),
                children: [
                  // 전화번호
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        student.phone,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 학년 또는 성인 여부
                  Row(
                    children: [
                      Icon(
                        student.isAdult ? Icons.person_outline_rounded : Icons.school_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        student.isAdult 
                          ? '성인'
                          : (student.grade ?? '학년 미입력'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // 수강 과목
                  Text(
                    '수강 과목',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (student.subjects.isEmpty)
                    Text(
                      '수강 과목이 없습니다',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: student.subjects.map(
                        (subject) => Chip(
                          label: Text(subject),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).toList(),
                    ),
                  const SizedBox(height: 32),

                  // 활성화 버튼
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: FilledButton.icon(
                        onPressed: student.studentId != null ? () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('학생 활성화'),
                              content: Text(
                                '${student.name} 학생을 다시 활성화하시겠습니까?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('활성화'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && student.studentId != null) {
                            try {
                              await ApiService.updateStudent(
                                studentId: student.studentId!,
                                data: {'is_active': true},
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${student.name} 학생이 활성화되었습니다.'),
                                  ),
                                );
                                onActivated();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('오류가 발생했습니다: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        } : null,
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('활성화'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


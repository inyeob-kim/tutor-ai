import 'package:flutter/material.dart';
import '../models/student.dart';
import '../widgets/section_title.dart';
import 'add_student_screen.dart';

enum TabKey { all, today, lowAttendance }

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  TabKey activeTab = TabKey.all;
  String query = "";
  Student? selectedStudent;

  // 데모 데이터
  final List<Student> students = [
    Student(
      name: "김민수",
      grade: "고등학교 2학년",
      subjects: ["수학"],
      phone: "010-1234-5678",
      sessions: 24,
      completedSessions: 22,
      color: const Color(0xFF3B82F6),
      nextClass: "11월 7일 10:00",
      attendanceRate: 92,
      isAdult: false, // 미성년자
    ),
    Student(
      name: "이지은",
      grade: "중학교 3학년",
      subjects: ["영어", "수학"],
      phone: "010-2345-6789",
      sessions: 18,
      completedSessions: 18,
      color: const Color(0xFF10B981),
      nextClass: "11월 7일 14:00",
      attendanceRate: 100,
      isAdult: false, // 미성년자
    ),
    Student(
      name: "박서준",
      grade: "고등학교 1학년",
      subjects: ["과학", "수학"],
      phone: "010-3456-7890",
      sessions: 20,
      completedSessions: 18,
      color: const Color(0xFF9333EA),
      nextClass: "11월 7일 16:00",
      attendanceRate: 90,
      isAdult: false, // 미성년자
    ),
    Student(
      name: "최성인",
      subjects: ["토익", "영어회화"],
      phone: "010-9999-9999",
      sessions: 12,
      completedSessions: 10,
      color: const Color(0xFFF59E0B),
      nextClass: "11월 8일 19:00",
      attendanceRate: 83,
      isAdult: true, // 성인 (학년 없음)
    ),
  ];

  // 통계
  Map<String, dynamic> get stats {
    final totalStudents = students.length;
    final todayStudents = students
        .where((s) => s.nextClass.contains("11월 7일"))
        .length;
    final avgAttendance = (students
                .map((s) => s.attendanceRate)
                .reduce((a, b) => a + b) /
            students.length)
        .round();
    final perfectAttendance =
        students.where((s) => s.attendanceRate == 100).length;
    return {
      'total': totalStudents,
      'today': todayStudents,
      'avgAttendance': avgAttendance,
      'perfectAttendance': perfectAttendance,
    };
  }

  // 필터링
  List<Student> get filteredStudents {
    List<Student> filtered = students;

    // 탭 필터
    if (activeTab == TabKey.today) {
      filtered = filtered.where((s) => s.nextClass.contains("11월 7일")).toList();
    } else if (activeTab == TabKey.lowAttendance) {
      filtered = filtered.where((s) => s.attendanceRate < 90).toList();
    }

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
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '학생 관리',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '학생을 관리하고 확인하세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStudentScreen(),
                      ),
                    );
                    if (result == true) {
                      // 학생 추가 성공 시 목록 새로고침
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('학생 추가'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 탭
                _buildTabs(theme, colorScheme),
                const SizedBox(height: 16),

                // 검색
                _buildSearchBar(theme, colorScheme),
                const SizedBox(height: 20),

                // 학생 리스트
                if (filteredStudents.isEmpty)
                  _buildEmptyState(theme, colorScheme)
                else
                  ...filteredStudents
                      .map((student) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '학생이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '학생을 추가하여 시작하세요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '전체',
              isActive: activeTab == TabKey.all,
              onTap: () => setState(() => activeTab = TabKey.all),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '오늘 수업',
              isActive: activeTab == TabKey.today,
              onTap: () => setState(() => activeTab = TabKey.today),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '출석 주의',
              isActive: activeTab == TabKey.lowAttendance,
              onTap: () => setState(() => activeTab = TabKey.lowAttendance),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => query = value),
        decoration: InputDecoration(
          hintText: '학생 이름 검색...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
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
    final barColor = student.attendanceRate >= 95
        ? const Color(0xFF10B981)
        : student.attendanceRate >= 85
            ? const Color(0xFF2563EB)
            : const Color(0xFFF97316);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7F0FF),
            Color(0xFFDCE8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedStudent = student;
            });
            _showStudentDetailModal(context, student, theme, colorScheme);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        color: student.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: student.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          student.name[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                              if (student.attendanceRate == 100) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 20,
                                  color: Colors.amber[700],
                                ),
                              ],
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
                  spacing: 8,
                  runSpacing: 8,
                  children: student.subjects
                      .map((subject) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 20),

                // 출석률 및 다음 수업
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 18,
                                color: barColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '출석률',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${student.attendanceRate}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: student.attendanceRate / 100,
                          backgroundColor: barColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          minHeight: 8,
                        ),
                      ),
                      if (student.nextClass.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '다음 수업: ${student.nextClass}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
      ),
    );
  }
}

class _StudentDetailModal extends StatelessWidget {
  final Student student;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onClose;

  const _StudentDetailModal({
    required this.student,
    required this.theme,
    required this.colorScheme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                color: student.color,
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
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 프로필
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      student.name[0],
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (student.isAdult == false && student.grade != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      student.grade!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ] else if (student.isAdult) ...[
                    const SizedBox(height: 4),
                    Text(
                      '성인',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // 통계
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${student.sessions}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '총 수업',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${student.attendanceRate}%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '출석률',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 바디
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
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
                  SectionTitle(title: '수강 과목'),
                  const SizedBox(height: 12),
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

                  // 수정 버튼
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: 학생 정보 수정
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('학생 정보 수정'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

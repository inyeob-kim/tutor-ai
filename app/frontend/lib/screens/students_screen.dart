import 'package:flutter/material.dart';
import '../models/student.dart';
import '../widgets/section_title.dart';

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
                    '총 ${stats['total']}명의 학생',
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
                    final result = await Navigator.of(context).pushNamed(
                      '/students/add',
                    );
                    if (result == true) {
                      // TODO: 학생 목록 새로고침
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 통계 카드
                _buildStatsCard(theme, colorScheme),
                const SizedBox(height: 16),

                // 탭
                _buildTabs(theme, colorScheme),
                const SizedBox(height: 16),

                // 검색
                _buildSearchBar(theme, colorScheme),
                const SizedBox(height: 16),

                // 학생 리스트
                ...filteredStudents
                    .map((student) => _buildStudentCard(
                          student,
                          theme,
                          colorScheme,
                        ))
                    .toList(),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFDBEAFE),
                value: '${stats['total']}',
                label: '전체 학생',
              ),
            ),
            Container(
              width: 1,
              height: 80,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: _buildStatItem(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF9333EA),
                backgroundColor: const Color(0xFFF3E8FF),
                value: '${stats['today']}',
                label: '오늘 수업',
              ),
            ),
            Container(
              width: 1,
              height: 80,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: _buildStatItem(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFD1FAE5),
                value: '${stats['avgAttendance']}%',
                label: '평균 출석률',
              ),
            ),
            Container(
              width: 1,
              height: 80,
              color: colorScheme.outline.withOpacity(0.2),
            ),
            Expanded(
              child: _buildStatItem(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                backgroundColor: const Color(0xFFFEF3C7),
                value: '${stats['perfectAttendance']}',
                label: '100% 출석',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme, ColorScheme colorScheme) {
    return Row(
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '오늘 수업',
            isActive: activeTab == TabKey.today,
            onTap: () => setState(() => activeTab = TabKey.today),
          ),
        ),
        const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => query = value),
        decoration: InputDecoration(
          hintText: '학생 이름 검색...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedStudent = student;
          });
          _showStudentDetailModal(context, student, theme, colorScheme);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Accent line
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: student.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    children: [
                      // 아바타
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: student.color,
                        child: Text(
                          student.name[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (student.attendanceRate == 100) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    size: 18,
                                    color: Colors.amber[700],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.grade,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 출석률
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '출석률',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${student.attendanceRate}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: student.attendanceRate / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 다음 수업
                  if (student.nextClass.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '다음 수업',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.nextClass,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (student.nextClass.isNotEmpty) const SizedBox(height: 16),

                  // 과목 태그 & 횟수
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...student.subjects.map(
                        (subject) => Chip(
                          label: Text(subject),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Chip(
                        label: Text('${student.sessions}회 수업'),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                  const SizedBox(height: 4),
                  Text(
                    student.grade,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
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

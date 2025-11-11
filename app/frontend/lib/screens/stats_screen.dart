import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/lesson.dart';
import '../theme/scroll_physics.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 데모 데이터 - 학생 목록
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
      isAdult: false,
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
      isAdult: false,
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
      isAdult: false,
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
      isAdult: true,
    ),
  ];

  // 데모 데이터 - 청구
  final List<Map<String, dynamic>> billings = [
    {
      'id': '1',
      'student': '김민수',
      'amount': 200000,
      'status': 'paid',
    },
    {
      'id': '2',
      'student': '이지은',
      'amount': 180000,
      'status': 'unpaid',
    },
    {
      'id': '3',
      'student': '박서준',
      'amount': 220000,
      'status': 'pending',
    },
    {
      'id': '4',
      'student': '최유진',
      'amount': 200000,
      'status': 'paid',
    },
  ];

  // 데모 데이터 - 수업
  final List<Lesson> lessons = [
    Lesson(
      id: '1',
      studentId: '1',
      startsAt: DateTime.now(),
      subject: '수학',
      durationMin: 90,
      status: 'done',
      attendance: 'show',
    ),
    Lesson(
      id: '2',
      studentId: '2',
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      subject: '영어',
      durationMin: 60,
      status: 'done',
      attendance: 'show',
    ),
    Lesson(
      id: '3',
      studentId: '3',
      startsAt: DateTime.now().subtract(const Duration(days: 2)),
      subject: '과학',
      durationMin: 90,
      status: 'done',
      attendance: 'late',
    ),
  ];

  // 학생 통계
  Map<String, dynamic> get studentStats {
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
    final lowAttendance =
        students.where((s) => s.attendanceRate < 90).length;

    return {
      'total': totalStudents,
      'today': todayStudents,
      'avgAttendance': avgAttendance,
      'perfectAttendance': perfectAttendance,
      'lowAttendance': lowAttendance,
    };
  }

  // 청구 통계
  Map<String, dynamic> get billingStats {
    final total = billings.fold<int>(
        0, (sum, b) => sum + (b['amount'] as int));
    final paid = billings
        .where((b) => b['status'] == 'paid')
        .fold<int>(0, (sum, b) => sum + (b['amount'] as int));
    final unpaid = billings
        .where((b) => b['status'] == 'unpaid')
        .fold<int>(0, (sum, b) => sum + (b['amount'] as int));
    final unpaidCount =
        billings.where((b) => b['status'] == 'unpaid').length;

    return {
      'total': total,
      'paid': paid,
      'unpaid': unpaid,
      'unpaidCount': unpaidCount,
    };
  }

  // 수업 통계
  Map<String, dynamic> get lessonStats {
    final total = lessons.length;
    final completed = lessons.where((l) => l.status == 'done').length;
    final pending = lessons.where((l) => l.status == 'pending').length;
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;
    final showCount = lessons.where((l) => l.attendance == 'show').length;
    final lateCount = lessons.where((l) => l.attendance == 'late').length;
    final absentCount = lessons.where((l) => l.attendance == 'absent').length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': completionRate,
      'show': showCount,
      'late': lateCount,
      'absent': absentCount,
    };
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}백만원';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}천원';
    }
    return '$amount원';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '통계',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '과외 현황을 한눈에 확인하세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 학생 통계
                _buildSectionHeader('학생 통계', theme, colorScheme),
                const SizedBox(height: 16),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE7F0FF),
                      Color(0xFFDCE8FF),
                    ],
                  ),
                  children: [
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.people_rounded,
                      iconColor: const Color(0xFF2563EB),
                      label: '전체 학생',
                      value: '${studentStats['total']}명',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.calendar_today_rounded,
                      iconColor: const Color(0xFF9333EA),
                      label: '오늘 수업',
                      value: '${studentStats['today']}명',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: '평균 출석률',
                      value: '${studentStats['avgAttendance']}%',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: '100% 출석',
                            value: '${studentStats['perfectAttendance']}명',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.warning_rounded,
                            iconColor: const Color(0xFFF97316),
                            label: '낮은 출석률',
                            value: '${studentStats['lowAttendance']}명',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 청구 통계
                _buildSectionHeader('청구 통계', theme, colorScheme),
                const SizedBox(height: 16),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF3E8FF),
                      Color(0xFFE9D5FF),
                    ],
                  ),
                  children: [
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF9333EA),
                      label: '총 청구 금액',
                      value: _formatCurrency(billingStats['total'] as int),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: '납부 완료',
                            value: _formatCurrency(billingStats['paid'] as int),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.warning_rounded,
                            iconColor: const Color(0xFFF97316),
                            label: '미납',
                            value: '${billingStats['unpaidCount']}건',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 수업 통계
                _buildSectionHeader('수업 통계', theme, colorScheme),
                const SizedBox(height: 16),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8F7F0),
                      Color(0xFFD1FAE5),
                    ],
                  ),
                  children: [
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.event_note_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: '전체 수업',
                      value: '${lessonStats['total']}개',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: '완료',
                            value: '${lessonStats['completed']}개',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: '대기',
                            value: '${lessonStats['pending']}개',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF9333EA),
                      label: '완료율',
                      value: '${lessonStats['completionRate']}%',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: '출석',
                            value: '${lessonStats['show']}회',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: '지각',
                            value: '${lessonStats['late']}회',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.cancel_outlined,
                            iconColor: const Color(0xFFF97316),
                            label: '결석',
                            value: '${lessonStats['absent']}회',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, ColorScheme colorScheme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatsCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Gradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStatRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/lesson.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 학생 목록 (빈 리스트로 시작)
  List<Student> students = [];
  // 청구 목록 (빈 리스트로 시작)
  List<Map<String, dynamic>> billings = [];
  // 수업 목록 (빈 리스트로 시작)
  List<Lesson> lessons = [];

  // 학생 통계
  Map<String, dynamic> get studentStats {
    if (students.isEmpty) {
      return {
        'total': 0,
        'today': 0,
        'avgAttendance': 0,
        'perfectAttendance': 0,
        'lowAttendance': 0,
      };
    }
    final totalStudents = students.length;
    final today = DateTime.now();
    final todayStr = '${today.month}월 ${today.day}일';
    final todayStudents = students
        .where((s) => s.nextClass.contains(todayStr))
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
    if (billings.isEmpty) {
      return {
        'total': 0,
        'paid': 0,
        'unpaid': 0,
        'unpaidCount': 0,
      };
    }
    final total = billings.fold<int>(
        0, (sum, b) => sum + ((b['amount'] as int?) ?? 0));
    final paid = billings
        .where((b) => b['status'] == 'paid')
        .fold<int>(0, (sum, b) => sum + ((b['amount'] as int?) ?? 0));
    final unpaid = billings
        .where((b) => b['status'] == 'unpaid')
        .fold<int>(0, (sum, b) => sum + ((b['amount'] as int?) ?? 0));
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
    if (lessons.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'completionRate': 0,
        'show': 0,
        'late': 0,
        'absent': 0,
      };
    }
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
              title: Text(
                '통계',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 주요 통계 그리드 (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.people_rounded,
                        iconColor: AppColors.primary,
                        label: '전체 학생',
                        value: '${studentStats['total']}명',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primaryLight.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: Gaps.card),
                    Expanded(
                      child: _buildQuickStatCard(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppColors.success,
                        label: '오늘 수업',
                        value: '${studentStats['today']}명',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success.withValues(alpha: 0.15),
                            AppColors.success.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Gaps.card),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.warning,
                        label: '총 청구',
                        value: _formatCurrency(billingStats['total'] as int),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.warning.withValues(alpha: 0.15),
                            AppColors.warning.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: Gaps.card),
                    Expanded(
                      child: _buildQuickStatCard(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.event_note_rounded,
                        iconColor: AppColors.primary,
                        label: '전체 수업',
                        value: '${lessonStats['total']}개',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.7),
                            AppColors.primaryLight.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 16),

                // 학생 통계 상세
                _buildSectionHeader('학생 통계', theme, colorScheme),
                SizedBox(height: Gaps.card + 4),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.7),
                    ],
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatRow(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.success,
                            label: '평균 출석률',
                            value: '${studentStats['avgAttendance']}%',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Gaps.card + 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.emoji_events_rounded,
                            iconColor: AppColors.warning,
                            label: '100% 출석',
                            value: '${studentStats['perfectAttendance']}명',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.warning_rounded,
                            iconColor: AppColors.error,
                            label: '낮은 출석',
                            value: '${studentStats['lowAttendance']}명',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 16),

                // 청구 통계 상세
                _buildSectionHeader('청구 통계', theme, colorScheme),
                SizedBox(height: Gaps.card + 4),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.8),
                      AppColors.primaryLight.withValues(alpha: 0.5),
                    ],
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.success,
                            label: '납부 완료',
                            value: _formatCurrency(billingStats['paid'] as int),
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.warning_rounded,
                            iconColor: AppColors.warning,
                            label: '미납',
                            value: '${billingStats['unpaidCount']}건',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 16),

                // 수업 통계 상세
                _buildSectionHeader('수업 통계', theme, colorScheme),
                SizedBox(height: Gaps.card + 4),
                _buildStatsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success.withValues(alpha: 0.12),
                      AppColors.success.withValues(alpha: 0.06),
                    ],
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.success,
                            label: '완료',
                            value: '${lessonStats['completed']}개',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.schedule_rounded,
                            iconColor: AppColors.warning,
                            label: '대기',
                            value: '${lessonStats['pending']}개',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Gaps.card + 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatRow(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.primary,
                            label: '완료율',
                            value: '${lessonStats['completionRate']}%',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Gaps.card + 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppColors.success,
                            label: '출석',
                            value: '${lessonStats['show']}회',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.access_time_rounded,
                            iconColor: AppColors.warning,
                            label: '지각',
                            value: '${lessonStats['late']}회',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.cancel_outlined,
                            iconColor: AppColors.error,
                            label: '결석',
                            value: '${lessonStats['absent']}회',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Gaps.screen * 2),
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
        borderRadius: BorderRadius.circular(Radii.card + 10),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.all(Gaps.cardPad + 4),
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
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(Radii.icon),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: Gaps.card),
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
      padding: EdgeInsets.all(Gaps.card),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(Radii.card - 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(height: Gaps.row),
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

  Widget _buildQuickStatCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(Gaps.cardPad),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(Radii.card + 8),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(Radii.icon),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(height: Gaps.card),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}


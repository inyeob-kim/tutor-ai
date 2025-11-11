import 'package:flutter/material.dart';
import '../models/student.dart';
import '../theme/scroll_physics.dart';

enum ScheduleFilter { all, today, week, month }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ScheduleFilter activeFilter = ScheduleFilter.today;
  DateTime selectedDate = DateTime.now();

  // 데모 데이터
  final List<Map<String, dynamic>> schedules = [
    {
      'id': '1',
      'date': '2024-11-07',
      'time': '10:00',
      'endTime': '11:30',
      'student': '김민수',
      'subject': '수학',
      'status': 'completed',
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': '2',
      'date': '2024-11-07',
      'time': '14:00',
      'endTime': '15:00',
      'student': '이지은',
      'subject': '영어',
      'status': 'current',
      'color': const Color(0xFF10B981),
    },
    {
      'id': '3',
      'date': '2024-11-07',
      'time': '16:00',
      'endTime': '17:00',
      'student': '박서준',
      'subject': '과학',
      'status': 'upcoming',
      'color': const Color(0xFF9333EA),
    },
    {
      'id': '4',
      'date': '2024-11-08',
      'time': '10:00',
      'endTime': '11:00',
      'student': '최유진',
      'subject': '수학',
      'status': 'upcoming',
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': '5',
      'date': '2024-11-09',
      'time': '14:00',
      'endTime': '15:30',
      'student': '김민수',
      'subject': '수학',
      'status': 'upcoming',
      'color': const Color(0xFF3B82F6),
    },
  ];

  List<Map<String, dynamic>> get filteredSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekLater = today.add(const Duration(days: 7));
    final monthLater = today.add(const Duration(days: 30));

    return schedules.where((schedule) {
      final scheduleDate = DateTime.parse(schedule['date']);
      
      switch (activeFilter) {
        case ScheduleFilter.today:
          return scheduleDate.year == today.year &&
              scheduleDate.month == today.month &&
              scheduleDate.day == today.day;
        case ScheduleFilter.week:
          return scheduleDate.isAfter(today.subtract(const Duration(days: 1))) &&
              scheduleDate.isBefore(weekLater);
        case ScheduleFilter.month:
          return scheduleDate.isAfter(today.subtract(const Duration(days: 1))) &&
              scheduleDate.isBefore(monthLater);
        case ScheduleFilter.all:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        if (dateA != dateB) return dateA.compareTo(dateB);
        return a['time'].compareTo(b['time']);
      });
  }

  Map<String, dynamic> get stats {
    final today = DateTime.now();
    final todaySchedules = schedules.where((s) {
      final date = DateTime.parse(s['date']);
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;
    
    final weekSchedules = schedules.where((s) {
      final date = DateTime.parse(s['date']);
      final weekLater = today.add(const Duration(days: 7));
      return date.isAfter(today.subtract(const Duration(days: 1))) &&
          date.isBefore(weekLater);
    }).length;

    final completed = schedules.where((s) => s['status'] == 'completed').length;
    
    return {
      'today': todaySchedules,
      'week': weekSchedules,
      'completed': completed,
      'total': schedules.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            snap: false,
            forceElevated: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '스케줄',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats['total']}개의 일정',
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
                      '/schedules/add',
                    );
                    if (result == true) {
                      // TODO: 일정 목록 새로고침
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('일정 추가'),
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
              delegate: SliverChildListDelegate(
                [
                // 통계 카드
                _buildStatsCard(theme, colorScheme),
                const SizedBox(height: 16),

                // 필터 탭
                _buildFilterTabs(theme, colorScheme),
                const SizedBox(height: 16),

                // 일정 리스트
                if (filteredSchedules.isEmpty)
                  _buildEmptyState(theme, colorScheme)
                else
                  ...filteredSchedules.map((schedule) => _buildScheduleCard(
                        schedule,
                        theme,
                        colorScheme,
                      )),

                const SizedBox(height: 100),
              ],
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
              ),
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
                icon: Icons.today_rounded,
                iconColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFFDBEAFE),
                value: '${stats['today']}',
                label: '오늘',
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
                icon: Icons.calendar_view_week_rounded,
                iconColor: const Color(0xFF9333EA),
                backgroundColor: const Color(0xFFF3E8FF),
                value: '${stats['week']}',
                label: '이번 주',
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
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFD1FAE5),
                value: '${stats['completed']}',
                label: '완료',
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

  Widget _buildFilterTabs(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '오늘',
            isActive: activeFilter == ScheduleFilter.today,
            onTap: () => setState(() => activeFilter = ScheduleFilter.today),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '이번 주',
            isActive: activeFilter == ScheduleFilter.week,
            onTap: () => setState(() => activeFilter = ScheduleFilter.week),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '이번 달',
            isActive: activeFilter == ScheduleFilter.month,
            onTap: () => setState(() => activeFilter = ScheduleFilter.month),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '전체',
            isActive: activeFilter == ScheduleFilter.all,
            onTap: () => setState(() => activeFilter = ScheduleFilter.all),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
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

  Widget _buildScheduleCard(
    Map<String, dynamic> schedule,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final status = schedule['status'] as String;
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';
    final scheduleDate = DateTime.parse(schedule['date']);
    final dateStr = '${scheduleDate.month}월 ${scheduleDate.day}일';
    
    final accentColor = isCurrent
        ? colorScheme.primary
        : isCompleted
            ? const Color(0xFF10B981)
            : colorScheme.outlineVariant;

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
          // TODO: 일정 상세 페이지
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Accent line
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: schedule['color'] as Color,
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
                  // 날짜와 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isCurrent ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          dateStr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 14, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                '진행중',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isCompleted)
                        Icon(Icons.check_circle_rounded,
                            size: 20, color: accentColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 시간
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${schedule['time']} - ${schedule['endTime']}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 학생 정보
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: schedule['color'] as Color,
                        child: Text(
                          (schedule['student'] as String)[0],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule['student'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              schedule['subject'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '일정이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 일정을 추가해보세요',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

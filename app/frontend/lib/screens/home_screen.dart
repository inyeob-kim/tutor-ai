import 'package:flutter/material.dart';

enum ScheduleStatus { completed, current, upcoming }

class ScheduleItem {
  final String id;
  final String time;
  final String endTime;
  final String student;
  final String subject;
  ScheduleStatus status;

  ScheduleItem({
    required this.id,
    required this.time,
    required this.endTime,
    required this.student,
    required this.subject,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ScheduleItem> schedule = [
    ScheduleItem(
      id: "1",
      time: "10:00",
      endTime: "11:30",
      student: "김민수",
      subject: "수학",
      status: ScheduleStatus.completed,
    ),
    ScheduleItem(
      id: "2",
      time: "14:00",
      endTime: "15:00",
      student: "이지은",
      subject: "영어",
      status: ScheduleStatus.current,
    ),
    ScheduleItem(
      id: "3",
      time: "16:00",
      endTime: "17:00",
      student: "박서준",
      subject: "과학",
      status: ScheduleStatus.upcoming,
    ),
    ScheduleItem(
      id: "4",
      time: "18:00",
      endTime: "19:00",
      student: "최유진",
      subject: "수학",
      status: ScheduleStatus.upcoming,
    ),
  ];

  void toggleComplete(String id) {
    setState(() {
      final item = schedule.firstWhere((s) => s.id == id);
      item.status = item.status == ScheduleStatus.completed
          ? ScheduleStatus.upcoming
          : ScheduleStatus.completed;
    });
  }

  Map<String, dynamic> get stats {
    final total = schedule.length;
    final completed = schedule.where((s) => s.status == ScheduleStatus.completed).length;
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;
    const unpaid = 2;
    return {
      'total': total,
      'completed': completed,
      'completionRate': completionRate,
      'unpaid': unpaid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(theme, colorScheme),
                  const SizedBox(height: 18),
                  _buildHeroCard(theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    title: '오늘의 스케줄',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${stats['total']}개',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final item in schedule)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildScheduleCard(item, theme, colorScheme),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: '빠른 실행',
                    subtitle: '자주 사용하는 기능을 빠르게 실행해요',
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    title: '오늘의 현황',
                    subtitle: '수업과 청구 현황을 확인하세요',
                  ),
                  const SizedBox(height: 16),
                  _buildStatsPanel(theme, colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: AI assistant 기능 연결
        },
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text(
          'AI 어시스턴트',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '할 일',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '과외 진행 현황',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '알림',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(ThemeData theme, ColorScheme colorScheme) {
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.star_rounded, color: colorScheme.primary, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            '돌봄 대시보드',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘의 수업과 청구 현황을 한 번에 확인하고\n빠르게 관리해보세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () {
              // TODO: 포인트 페이지 연결
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('포인트 받으러 가기'),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: subtitle != null ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildScheduleCard(
    ScheduleItem item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isCompleted = item.status == ScheduleStatus.completed;
    final isCurrent = item.status == ScheduleStatus.current;
    final accentColor = isCurrent
        ? colorScheme.primary
        : isCompleted
            ? const Color(0xFF10B981)
            : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () => toggleComplete(item.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isCompleted ? accentColor : Colors.white,
                    border: Border.all(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: isCurrent ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${item.time} - ${item.endTime}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.bolt_rounded, size: 18, color: accentColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.student,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.status != ScheduleStatus.completed) ...[
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '오늘 수업 메모 작성하기',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    final items = [
      (
        icon: Icons.edit_calendar_rounded,
        title: '수업 등록',
        subtitle: '새 과외 일정 만들기',
        background: const Color(0xFFE9F2FF),
        iconColor: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.play_circle_fill_rounded,
        title: 'AI 어시스턴트',
        subtitle: '음성으로 관리',
        background: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: items[i].background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(items[i].icon, color: items[i].iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    items[i].title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    items[i].subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsPanel(ThemeData theme, ColorScheme colorScheme) {
    final statsItems = [
      (
        icon: Icons.calendar_today_rounded,
        value: stats['total'].toString(),
        label: '오늘 수업',
        background: const Color(0xFFE9F2FF),
        iconColor: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.check_circle_rounded,
        value: stats['completed'].toString(),
        label: '완료',
        background: const Color(0xFFE8F7F0),
        iconColor: const Color(0xFF10B981),
      ),
      (
        icon: Icons.trending_up_rounded,
        value: '${stats['completionRate']}%',
        label: '완료율',
        background: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
      (
        icon: Icons.warning_rounded,
        value: stats['unpaid'].toString(),
        label: '미납',
        background: const Color(0xFFFDEAD7),
        iconColor: const Color(0xFFF97316),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < statsItems.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statsItems[i].background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(statsItems[i].icon, color: statsItems[i].iconColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statsItems[i].value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statsItems[i].label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (i != statsItems.length - 1)
              Container(
                width: 1,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

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

  int get todayLessonCount {
    return schedule.length;
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
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Gaps.screen, 8, Gaps.screen, 24),
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
                        borderRadius: BorderRadius.circular(Radii.chip),
                      ),
                      child: Text(
                        '$todayLessonCount개',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Gaps.card),
                  for (final item in schedule)
                    Padding(
                      padding: EdgeInsets.only(bottom: Gaps.card - 2),
                      child: _buildScheduleCard(item, theme, colorScheme),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: '빠른 실행',
                    subtitle: '자주 사용하는 기능을 빠르게 실행해요',
                  ),
                  SizedBox(height: Gaps.card),
                  _buildQuickActions(theme, colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/ai-assistant');
        },
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.auto_awesome_rounded, color: AppColors.surface),
        label: Text(
          'AI 어시스턴트',
          style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w600),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '알림',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 날씨 정보 (데모 데이터)
  Map<String, dynamic> get _weatherInfo {
    // 실제로는 API에서 가져오지만, 데모용으로 랜덤 선택
    final weatherTypes = [
      {'icon': Icons.wb_sunny_rounded, 'text': '맑음', 'temp': '22°', 'color': AppColors.warning},
      {'icon': Icons.cloud_rounded, 'text': '흐림', 'temp': '18°', 'color': AppColors.textMuted},
      {'icon': Icons.wb_cloudy_rounded, 'text': '구름 많음', 'temp': '20°', 'color': AppColors.textSecondary},
      {'icon': Icons.water_drop_rounded, 'text': '비', 'temp': '15°', 'color': AppColors.primary},
    ];
    // 날짜 기반으로 선택 (같은 날에는 같은 날씨)
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return weatherTypes[dayOfYear % weatherTypes.length];
  }

  // 매일 달라지는 덕담 메시지
  String get _dailyMessage {
    final messages = [
      '오늘도 화이팅해요! 🌟',
      '수업이 많지만 오늘도 할 수 있어요! 💪',
      '한 걸음씩 차근차근! 📚',
      '오늘의 노력이 내일의 성과가 됩니다! ✨',
      '포기하지 않으면 성공할 거예요! 🎯',
      '오늘 하루도 수고 많으셨어요! 👏',
      '작은 성취도 축하할 가치가 있어요! 🎉',
      '오늘의 수업도 잘 마무리하세요! 📖',
      '학생들과의 소중한 시간이에요! 💙',
      '지금의 노력이 미래를 만들어요! 🌈',
      '오늘도 학생들에게 좋은 영향을 주세요! 🌱',
      '포기하지 않는 모습이 멋져요! ⭐',
      '오늘의 수업도 기대가 돼요! 📝',
      '한 걸음씩 성장하고 있어요! 🌿',
      '오늘도 최선을 다하세요! 💯',
    ];
    // 날짜 기반으로 선택 (같은 날에는 같은 메시지)
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return messages[dayOfYear % messages.length];
  }

  Widget _buildHeroCard(ThemeData theme, ColorScheme colorScheme) {
    final weather = _weatherInfo;
    final dailyMessage = _dailyMessage;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.card + 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(Gaps.cardPad + 4, 28, Gaps.cardPad + 4, Gaps.cardPad + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날씨 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(Radii.icon),
                ),
                child: Icon(
                  weather['icon'] as IconData,
                  color: weather['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather['text'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    weather['temp'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 오늘 수업 개수
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(Radii.chip + 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '오늘 $todayLessonCount개',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 덕담 메시지
          Text(
            dailyMessage,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.4,
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
        ? AppColors.primary
        : isCompleted
            ? AppColors.success
            : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () => toggleComplete(item.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card + 6),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: EdgeInsets.all(Gaps.cardPad),
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
                    borderRadius: BorderRadius.circular(Radii.icon - 2),
                    color: isCompleted ? accentColor : AppColors.surface,
                    border: Border.all(
                      color: accentColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(Icons.check_rounded, size: 16, color: AppColors.surface)
                      : null,
                ),
                SizedBox(width: Gaps.card),
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
                              borderRadius: BorderRadius.circular(Radii.chip + 2),
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(Radii.card - 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18, color: accentColor),
                    SizedBox(width: Gaps.row),
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
        background: AppColors.primaryLight,
        iconColor: AppColors.primary,
        route: '/schedules/add',
      ),
      (
        icon: Icons.link_rounded,
        title: '예약 요청',
        subtitle: '학생에게 링크 보내기',
        background: AppColors.warning.withValues(alpha: 0.1),
        iconColor: AppColors.warning,
        route: '/booking-request',
      ),
      (
        icon: Icons.play_circle_fill_rounded,
        title: 'AI 어시스턴트',
        subtitle: '음성으로 관리',
        background: AppColors.primaryLight.withValues(alpha: 0.8),
        iconColor: AppColors.primary,
        route: '/ai-assistant',
      ),
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < items.length - 1 ? Gaps.row : 0),
            padding: EdgeInsets.all(Gaps.cardPad),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card + 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(item.route);
              },
              borderRadius: BorderRadius.circular(Radii.card + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.background,
                      borderRadius: BorderRadius.circular(Radii.chip + 4),
                    ),
                    child: Icon(item.icon, color: item.iconColor),
                  ),
                  SizedBox(height: Gaps.card),
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

}

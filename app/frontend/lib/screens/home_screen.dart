import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/teacher_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/loading_indicator.dart';

enum ScheduleStatus { completed, current, upcoming }

class ScheduleItem {
  final String id;
  final String time;
  final String endTime;
  final String student;
  final String subject;
  ScheduleStatus status;
  final String? notes;

  ScheduleItem({
    required this.id,
    required this.time,
    required this.endTime,
    required this.student,
    required this.subject,
    required this.status,
    this.notes,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<ScheduleItem> schedule = [];
  bool _isLoading = true;
  bool _hasNotifications = false; // 알림이 있는지 여부 (나중에 실제 알림 데이터와 연동)

  @override
  void initState() {
    super.initState();
    // 홈화면 진입 시 Teacher 정보 로드 (캐시 또는 API)
    _loadTeacherInfo();
    // 오늘의 스케줄 로드
    loadTodaySchedules();
    // 알림 스케줄링
    _scheduleReminders();
  }

  /// 일정 리마인드 알림 스케줄링
  Future<void> _scheduleReminders() async {
    try {
      await NotificationService.instance.scheduleLessonReminders();
    } catch (e) {
      print('⚠️ 알림 스케줄링 실패: $e');
    }
  }

  /// Teacher 정보 로드
  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null && mounted) {
        print('✅ 홈화면: Teacher 정보 로드 완료 - nickname=${teacher.nickname}, subject_id=${teacher.subjectId}');
        // 필요시 setState로 UI 업데이트
        setState(() {});
      }
    } catch (e) {
      print('⚠️ 홈화면: Teacher 정보 로드 실패: $e');
    }
  }

  /// 오늘의 스케줄 로드 (public으로 변경하여 외부에서 호출 가능)
  Future<void> loadTodaySchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        setState(() {
          schedule = [];
          _isLoading = false;
        });
        return;
      }

      // 오늘 날짜
      final today = DateTime.now();
      final dateFrom = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final dateTo = dateFrom;

      // 스케줄 조회 (취소된 수업 제외)
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: 'confirmed', // 취소된 수업 제외
      );

      // 학생 정보 조회 (스케줄에 학생 이름 표시용) - 활성화된 학생만
      final students = await ApiService.getStudents(isActive: true);

      // 스케줄을 ScheduleItem으로 변환
      final now = DateTime.now();
      final items = schedules.map((s) {
        final studentId = s['student_id'] as int?;
        final student = students.firstWhere(
          (st) => st['student_id'] == studentId,
          orElse: () => {'name': '학생 없음'},
        );
        final studentName = student['name'] as String? ?? '학생 없음';
        final subject = s['subject_id'] as String? ?? '과목 없음';
        final startTime = s['start_time'] as String? ?? '';
        final endTime = s['end_time'] as String? ?? '';
        final status = s['status'] as String? ?? 'pending';
        final notes = s['notes'] as String?;

        // 시간 파싱
        final startParts = startTime.split(':');
        final endParts = endTime.split(':');
        final startHour = startParts.isNotEmpty ? int.tryParse(startParts[0]) ?? 0 : 0;
        final startMin = startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0;
        final endHour = endParts.isNotEmpty ? int.tryParse(endParts[0]) ?? 0 : 0;
        final endMin = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;

        // 스케줄 상태 결정
        ScheduleStatus scheduleStatus;
        if (status == 'completed' || status == 'done') {
          scheduleStatus = ScheduleStatus.completed;
        } else {
          final scheduleDateTime = DateTime(
            today.year,
            today.month,
            today.day,
            startHour,
            startMin,
          );
          if (scheduleDateTime.isBefore(now.subtract(const Duration(minutes: 30)))) {
            scheduleStatus = ScheduleStatus.completed;
          } else if (scheduleDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
            scheduleStatus = ScheduleStatus.current;
          } else {
            scheduleStatus = ScheduleStatus.upcoming;
          }
        }

        return ScheduleItem(
          id: (s['schedule_id'] as int? ?? 0).toString(),
          time: '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}',
          endTime: '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}',
          student: studentName,
          subject: subject,
          status: scheduleStatus,
          notes: notes,
        );
      }).toList();

      // 시간순으로 정렬
      items.sort((a, b) => a.time.compareTo(b.time));

      if (mounted) {
        setState(() {
          schedule = items;
          _isLoading = false;
        });
        // 스케줄 로드 후 알림 재스케줄링
        _scheduleReminders();
      }
    } catch (e) {
      print('⚠️ 홈화면: 스케줄 로드 실패: $e');
      if (mounted) {
        setState(() {
          schedule = [];
          _isLoading = false;
        });
      }
    }
  }

  // toggleComplete 함수 제거 - 체크박스는 자동으로 상태가 결정됨

  int get todayLessonCount {
    return schedule.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await loadTodaySchedules();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: TossScrollPhysics(),
          ),
          slivers: [
          // 고정 AppBar
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Text(
              '과외 진행 현황',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Gaps.screen),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      child: Icon(
                        Icons.notifications,
                        color: _hasNotifications ? AppColors.error : AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    if (_hasNotifications)
                      Positioned(
                        right: 8,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Gaps.screen, Gaps.card, Gaps.screen, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(Gaps.screen * 2),
                        child: const LoadingIndicator(),
                      ),
                    )
                  else if (schedule.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(Gaps.screen * 2),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '오늘 수업이 없습니다',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '수업을 등록하면 여기에 표시됩니다',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/ai-assistant');
        },
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        icon: Icon(Icons.auto_awesome_rounded, color: AppColors.surface),
        label: Text(
          'AI 어시스턴트',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
              fontSize: 20,
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
                  fontSize: 20,
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
    
    // 색상 정의: 완료=회색, 진행중=초록색, 예정=주황색
    final cardColor = isCompleted
        ? AppColors.textMuted
        : isCurrent
            ? AppColors.success
            : AppColors.warning; // 예정
    final accentColor = cardColor;

    return GestureDetector(
      onTap: () {
        // 수업 메모 작성 화면으로 이동
        Navigator.of(context).pushNamed(
          '/lesson-note',
          arguments: {
            'scheduleId': item.id,
            'studentName': item.student,
            'subject': item.subject,
            'time': '${item.time} - ${item.endTime}',
            'notes': item.notes,
          },
        ).then((result) {
          // 메모 저장 후 홈 화면 새로고침
          if (result == true) {
            loadTodaySchedules();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(Gaps.cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Radii.chip + 2),
                      ),
                      child: Text(
                        '${item.time} - ${item.endTime}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cardColor,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.bolt_rounded, size: 18, color: AppColors.success),
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
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(Gaps.card),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(Radii.card - 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note_rounded, size: 18, color: accentColor),
                    SizedBox(width: Gaps.row),
                    Expanded(
                      child: Text(
                        '메모 있음',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.of(context).pushNamed(item.route);
                // 수업 등록 성공 시 스케줄 새로고침
                if (result == true && item.route == '/schedules/add') {
                  loadTodaySchedules();
                }
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

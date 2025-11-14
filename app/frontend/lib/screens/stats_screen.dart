import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';
import '../services/settings_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  
  // 통계 데이터
  Map<String, dynamic> _teacherStats = {};
  Map<String, dynamic> _subjectStats = {};
  Map<String, dynamic> _studentStats = {};
  Map<String, dynamic> _lessonStats = {};
  Map<String, dynamic> _billingStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 현재 날짜 기준
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthStartStr = '${thisMonthStart.year}-${thisMonthStart.month.toString().padLeft(2, '0')}-${thisMonthStart.day.toString().padLeft(2, '0')}';
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 학생 데이터 로드
      final students = await ApiService.getStudents(isActive: true);
      final allStudents = await ApiService.getStudents(); // 전체 학생 (비활성 포함)

      // 이번 달 수업 데이터 로드
      final thisMonthLessons = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: thisMonthStartStr,
        dateTo: todayStr,
        pageSize: 500,
      );

      // 오늘 수업 데이터 로드
      final todayLessons = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: todayStr,
        dateTo: todayStr,
        status: 'confirmed',
        pageSize: 100,
      );

      // 선생님이 가르치는 과목 목록
      final teacherSubjects = await SettingsService.getTeacherSubjects();
      
      // 선생님 통계 계산
      final activeStudents = students.length;
      final totalStudents = allStudents.length;
      final thisMonthLessonCount = thisMonthLessons.length;
      final todayLessonCount = todayLessons.length;
      
      // 이번 달 수입 계산 (수업 시간 * 시간당 수강비)
      int thisMonthIncome = 0;
      final studentsMap = {for (var s in students) s['student_id'] as int: s};
      
      for (var lesson in thisMonthLessons) {
        if (lesson['status'] == 'completed' || lesson['status'] == 'done') {
          final studentId = lesson['student_id'] as int?;
          final student = studentsMap[studentId];
          if (student != null) {
            final hourlyRate = student['hourly_rate'] as int? ?? 0;
            final startTime = lesson['start_time'] as String? ?? '';
            final endTime = lesson['end_time'] as String? ?? '';
            
            // 시간 차이 계산
            if (startTime.isNotEmpty && endTime.isNotEmpty) {
              try {
                final startParts = startTime.split(':');
                final endParts = endTime.split(':');
                final startHour = int.parse(startParts[0]);
                final startMin = int.parse(startParts[1]);
                final endHour = int.parse(endParts[0]);
                final endMin = int.parse(endParts[1]);
                
                final start = DateTime(2000, 1, 1, startHour, startMin);
                final end = DateTime(2000, 1, 1, endHour, endMin);
                final duration = end.difference(start).inMinutes;
                final hours = duration / 60.0;
                
                thisMonthIncome += (hourlyRate * hours).round();
              } catch (e) {
                // 시간 파싱 실패 시 기본 1시간으로 계산
                thisMonthIncome += hourlyRate;
              }
            } else {
              thisMonthIncome += hourlyRate; // 기본 1시간
            }
          }
        }
      }

      // 평균 출석률 계산
      double avgAttendance = 0;
      if (students.isNotEmpty) {
        int totalSessions = 0;
        int completedSessions = 0;
        for (var student in students) {
          totalSessions += student['total_sessions'] as int? ?? 0;
          completedSessions += student['completed_sessions'] as int? ?? 0;
        }
        if (totalSessions > 0) {
          avgAttendance = (completedSessions / totalSessions) * 100;
        }
      }

      // 신규 학생 수 (이번 달에 등록된 학생)
      final newStudentsThisMonth = allStudents.where((s) {
        final createdAt = s['created_at'] as String?;
        if (createdAt == null) return false;
        try {
          final createdDate = DateTime.parse(createdAt);
          return createdDate.isAfter(thisMonthStart.subtract(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).length;

      _teacherStats = {
        'totalStudents': totalStudents,
        'activeStudents': activeStudents,
        'thisMonthLessons': thisMonthLessonCount,
        'todayLessons': todayLessonCount,
        'thisMonthIncome': thisMonthIncome,
        'avgAttendance': avgAttendance.round(),
        'newStudentsThisMonth': newStudentsThisMonth,
      };

      // 과목별 통계 계산
      final subjectStatsMap = <String, Map<String, dynamic>>{};
      for (var subject in teacherSubjects) {
        final subjectStudents = students.where((s) {
          final subjectId = s['subject_id'] as String? ?? '';
          return subjectId == subject || subjectId.split(',').contains(subject);
        }).toList();
        
        final subjectLessons = thisMonthLessons.where((l) {
          final lessonSubject = l['subject_id'] as String? ?? '';
          return lessonSubject == subject;
        }).toList();

        // 평균 수강비 계산
        int totalRate = 0;
        int rateCount = 0;
        for (var student in subjectStudents) {
          final rate = student['hourly_rate'] as int? ?? 0;
          if (rate > 0) {
            totalRate += rate;
            rateCount++;
          }
        }
        final avgRate = rateCount > 0 ? (totalRate / rateCount).round() : 0;

        subjectStatsMap[subject] = {
          'studentCount': subjectStudents.length,
          'lessonCount': subjectLessons.length,
          'avgRate': avgRate,
        };
      }
      _subjectStats = subjectStatsMap;

      // 학생 통계
      final perfectAttendance = students.where((s) {
        final sessions = s['total_sessions'] as int? ?? 0;
        final completed = s['completed_sessions'] as int? ?? 0;
        return sessions > 0 && (completed / sessions) == 1.0;
      }).length;

      final lowAttendance = students.where((s) {
        final sessions = s['total_sessions'] as int? ?? 0;
        final completed = s['completed_sessions'] as int? ?? 0;
        if (sessions == 0) return false;
        return (completed / sessions) < 0.9;
      }).length;

      _studentStats = {
      'total': totalStudents,
        'active': activeStudents,
        'avgAttendance': avgAttendance.round(),
      'perfectAttendance': perfectAttendance,
      'lowAttendance': lowAttendance,
    };

      // 수업 통계
      final completedLessons = thisMonthLessons.where((l) => 
        l['status'] == 'completed' || l['status'] == 'done'
      ).length;
      final pendingLessons = thisMonthLessons.where((l) => 
        l['status'] == 'confirmed' || l['status'] == 'pending'
      ).length;
      final cancelledLessons = thisMonthLessons.where((l) => 
        l['status'] == 'cancelled'
      ).length;

      _lessonStats = {
        'total': thisMonthLessonCount,
        'completed': completedLessons,
        'pending': pendingLessons,
        'cancelled': cancelledLessons,
        'completionRate': thisMonthLessonCount > 0 
          ? ((completedLessons / thisMonthLessonCount) * 100).round() 
          : 0,
      };

      // 청구 통계 (임시로 빈 값, 나중에 실제 API 연동)
      _billingStats = {
        'thisMonthTotal': 0,
        'unpaid': 0,
        'paid': 0,
        'unpaidCount': 0,
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('⚠️ 통계 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: TossScrollPhysics(),
                ),
        slivers: [
                  SliverAppBar(
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    pinned: true,
                    title: Text(
                      '통계',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    centerTitle: false,
                  ),
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                        // 선생님 통계 (우선 배치)
                        _buildSectionHeader('선생님 통계', theme, colorScheme),
                        SizedBox(height: Gaps.row),
                        _buildTeacherStatsCard(theme, colorScheme),
                        SizedBox(height: Gaps.cardPad + 4),

                        // 과목별 통계
                        if (_subjectStats.isNotEmpty) ...[
                          _buildSectionHeader('과목별 통계', theme, colorScheme),
                          SizedBox(height: Gaps.row),
                          ..._subjectStats.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: Gaps.card),
                              child: _buildSubjectStatsCard(
                                entry.key,
                                entry.value,
                                theme,
                                colorScheme,
                              ),
                            );
                          }),
                          SizedBox(height: Gaps.cardPad + 4),
                        ],

                        // 학생 통계
                        _buildSectionHeader('학생 통계', theme, colorScheme),
                        SizedBox(height: Gaps.row),
                        _buildStudentStatsCard(theme, colorScheme),
                        SizedBox(height: Gaps.cardPad + 4),

                        // 수업 통계
                        _buildSectionHeader('수업 통계', theme, colorScheme),
                        SizedBox(height: Gaps.row),
                        _buildLessonStatsCard(theme, colorScheme),
                        SizedBox(height: Gaps.cardPad + 4),

                        // 청구 통계
                        _buildSectionHeader('청구 통계', theme, colorScheme),
                        SizedBox(height: Gaps.row),
                        _buildBillingStatsCard(theme, colorScheme),
                        SizedBox(height: Gaps.screen * 2),
                      ]),
                    ),
                  ),
                ],
              ),
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

  Widget _buildTeacherStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.card + 10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.all(Gaps.cardPad + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Radii.icon),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.surface,
                  size: 24,
                      ),
                    ),
                    SizedBox(width: Gaps.card),
                    Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '활성 학생',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      '${_teacherStats['activeStudents'] ?? 0}명',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Gaps.card),
                Row(
                  children: [
                    Expanded(
                child: _buildMiniStatInCard(
                  theme: theme,
                  icon: Icons.calendar_today_rounded,
                  label: '이번 달 수업',
                  value: '${_teacherStats['thisMonthLessons'] ?? 0}개',
                  isLight: true,
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStatInCard(
                        theme: theme,
                  icon: Icons.today_rounded,
                  label: '오늘 수업',
                  value: '${_teacherStats['todayLessons'] ?? 0}개',
                  isLight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: Gaps.card),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatInCard(
                  theme: theme,
                  icon: Icons.account_balance_wallet_rounded,
                  label: '이번 달 수입',
                  value: _formatCurrency(_teacherStats['thisMonthIncome'] as int? ?? 0),
                  isLight: true,
                ),
              ),
              SizedBox(width: Gaps.row),
                    Expanded(
                child: _buildMiniStatInCard(
                        theme: theme,
                  icon: Icons.trending_up_rounded,
                  label: '평균 출석률',
                  value: '${_teacherStats['avgAttendance'] ?? 0}%',
                  isLight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: Gaps.card),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatInCard(
                  theme: theme,
                  icon: Icons.person_add_rounded,
                  label: '신규 학생',
                  value: '${_teacherStats['newStudentsThisMonth'] ?? 0}명',
                  isLight: true,
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStatInCard(
                  theme: theme,
                  icon: Icons.people_rounded,
                  label: '전체 학생',
                  value: '${_teacherStats['totalStudents'] ?? 0}명',
                  isLight: true,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSubjectStatsCard(
    String subject,
    Map<String, dynamic> stats,
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
      ),
      padding: EdgeInsets.all(Gaps.cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(Radii.icon),
                ),
                child: Text(
                  subject,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Gaps.card),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.people_rounded,
                  iconColor: AppColors.primary,
                  label: '학생 수',
                  value: '${stats['studentCount'] ?? 0}명',
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStat(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.event_note_rounded,
                  iconColor: AppColors.success,
                  label: '수업 수',
                  value: '${stats['lessonCount'] ?? 0}개',
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStat(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.attach_money_rounded,
                  iconColor: AppColors.warning,
                  label: '평균 수강비',
                  value: _formatCurrency(stats['avgRate'] as int? ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.7),
                    ],
                  ),
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
                  value: '${_studentStats['avgAttendance'] ?? 0}%',
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
                  icon: Icons.people_rounded,
                  iconColor: AppColors.primary,
                  label: '전체 학생',
                  value: '${_studentStats['total'] ?? 0}명',
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStat(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  label: '활성 학생',
                  value: '${_studentStats['active'] ?? 0}명',
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
                  value: '${_studentStats['perfectAttendance'] ?? 0}명',
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
                  value: '${_studentStats['lowAttendance'] ?? 0}명',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildLessonStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success.withValues(alpha: 0.12),
                      AppColors.success.withValues(alpha: 0.06),
                    ],
                  ),
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
        children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatRow(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.primary,
                            label: '완료율',
                  value: '${_lessonStats['completionRate'] ?? 0}%',
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
                  icon: Icons.event_note_rounded,
                  iconColor: AppColors.primary,
                  label: '전체 수업',
                  value: '${_lessonStats['total'] ?? 0}개',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  label: '완료',
                  value: '${_lessonStats['completed'] ?? 0}개',
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
                  icon: Icons.schedule_rounded,
                            iconColor: AppColors.warning,
                  label: '예정',
                  value: '${_lessonStats['pending'] ?? 0}개',
                          ),
                        ),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: _buildMiniStat(
                            theme: theme,
                            colorScheme: colorScheme,
                            icon: Icons.cancel_outlined,
                            iconColor: AppColors.error,
                  label: '취소',
                  value: '${_lessonStats['cancelled'] ?? 0}개',
                          ),
                        ),
                      ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning.withValues(alpha: 0.08),
          ],
        ),
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.warning,
                  label: '이번 달 청구',
                  value: _formatCurrency(_billingStats['thisMonthTotal'] as int? ?? 0),
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
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  label: '납부 완료',
                  value: _formatCurrency(_billingStats['paid'] as int? ?? 0),
                ),
              ),
              SizedBox(width: Gaps.row),
              Expanded(
                child: _buildMiniStat(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.warning_rounded,
                  iconColor: AppColors.error,
                  label: '미납',
                  value: '${_billingStats['unpaidCount'] ?? 0}건',
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildMiniStatInCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required bool isLight,
  }) {
    return Container(
      padding: EdgeInsets.all(Gaps.card),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: isLight ? 0.3 : 0.85),
        borderRadius: BorderRadius.circular(Radii.card - 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.surface,
            size: 20,
          ),
          SizedBox(height: Gaps.row),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}



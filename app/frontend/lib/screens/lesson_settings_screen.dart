import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/settings_service.dart';
import '../services/teacher_service.dart';
import '../services/api_service.dart';
import 'teacher_subjects_screen.dart';

class LessonSettingsScreen extends StatefulWidget {
  const LessonSettingsScreen({super.key});

  @override
  State<LessonSettingsScreen> createState() => _LessonSettingsScreenState();
}

class _LessonSettingsScreenState extends State<LessonSettingsScreen> {
  List<String> _teacherSubjects = ['수학', '영어', '과학'];
  
  int _startHour = 12;
  int _endHour = 22;
  bool _excludeWeekends = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTeacherInfo();
  }

  Future<void> _loadSettings() async {
    final startHour = await SettingsService.getStartHour();
    final endHour = await SettingsService.getEndHour();
    final excludeWeekends = await SettingsService.getExcludeWeekends();
    final teacherSubjects = await SettingsService.getTeacherSubjects();
    setState(() {
      _startHour = startHour;
      _endHour = endHour;
      _excludeWeekends = excludeWeekends;
      if (teacherSubjects.isNotEmpty) {
        _teacherSubjects = teacherSubjects;
      }
    });
  }

  /// Teacher 정보 로드
  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ 수업 설정 화면: Teacher 정보 로드 실패: $e');
    }
  }

  Future<void> _saveStartHour(int hour) async {
    await SettingsService.setStartHour(hour);
    setState(() => _startHour = hour);
  }

  Future<void> _saveEndHour(int hour) async {
    await SettingsService.setEndHour(hour);
    setState(() => _endHour = hour);
  }

  Future<void> _saveExcludeWeekends(bool value) async {
    await SettingsService.setExcludeWeekends(value);
    setState(() => _excludeWeekends = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('수업 설정'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(Gaps.card),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.school_outlined,
                      title: '가르치는 과목',
                      subtitle: _teacherSubjects.isEmpty 
                          ? '과목을 선택하세요' 
                          : _teacherSubjects.join(', '),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherSubjectsScreen(
                              initialSubjects: _teacherSubjects,
                            ),
                          ),
                        );
                        if (result != null && result is List<String>) {
                          setState(() {
                            _teacherSubjects = result;
                          });
                          await SettingsService.setTeacherSubjects(result);
                          
                          try {
                            final teacher = await TeacherService.instance.loadTeacher();
                            if (teacher != null) {
                              final subjectId = result.join(',');
                              await ApiService.updateTeacher(teacher.teacherId, {
                                'subject_id': subjectId,
                              });
                              await TeacherService.instance.refresh();
                              print('✅ 선생님 과목 목록 DB 저장 완료: $subjectId');
                            }
                          } catch (e) {
                            print('⚠️ 선생님 과목 목록 DB 저장 실패: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('과목 목록 저장에 실패했습니다: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildTimeRangeTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '수업 시작 시간',
                      value: _startHour,
                      onChanged: _saveStartHour,
                    ),
                    const Divider(height: 1),
                    _buildTimeRangeTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '수업 종료 시간',
                      value: _endHour,
                      onChanged: _saveEndHour,
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '주말 제외',
                      subtitle: '토요일과 일요일은 수업 시간대에서 제외합니다',
                      value: _excludeWeekends,
                      onChanged: _saveExcludeWeekends,
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

  Widget _buildSettingsCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: titleColor ?? colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimeRangeTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        title.contains('시작') ? Icons.access_time : Icons.access_time_filled,
        color: AppColors.textMuted,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        '${value.toString().padLeft(2, '0')}:00',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: () => _showTimePicker(context, value, onChanged),
    );
  }

  void _showTimePicker(BuildContext context, int currentHour, ValueChanged<int> onChanged) {
    int selectedHour = currentHour;
    final scrollController = FixedExtentScrollController(initialItem: currentHour);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card + 2)),
            ),
            padding: EdgeInsets.only(
              left: Gaps.cardPad + 4,
              right: Gaps.cardPad + 4,
              top: Gaps.cardPad + 4,
              bottom: Gaps.cardPad + 4 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '시간 선택',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Gaps.cardPad + 4),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.chip + 4),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(Radii.chip),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        controller: scrollController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setModalState(() {
                            selectedHour = index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final hour = index;
                            final distance = (hour - selectedHour).abs();
                            final opacity = distance == 0 ? 1.0 : (1.0 - (distance * 0.3)).clamp(0.3, 1.0);
                            final fontSize = distance == 0 ? 24.0 : (24.0 - (distance * 2.0)).clamp(16.0, 24.0);
                            final isSelected = distance == 0;
                            
                            return Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 100),
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontSize: fontSize,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: opacity),
                                ),
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                ),
                              ),
                            );
                          },
                          childCount: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Gaps.cardPad + 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Gaps.screen, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text(
                    '${selectedHour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: Gaps.cardPad + 4),
                ElevatedButton(
                  onPressed: () {
                    onChanged(selectedHour);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


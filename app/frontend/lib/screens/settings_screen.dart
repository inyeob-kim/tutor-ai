import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/settings_service.dart';
import '../services/teacher_service.dart';
import '../services/api_service.dart';
import '../routes/app_routes.dart';
import 'teacher_subjects_screen.dart';
import 'edit_teacher_profile_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoBackupEnabled = true;
  List<String> _teacherSubjects = ['수학', '영어', '과학']; // 가르치는 과목 목록
  
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
        setState(() {
          // Teacher 정보를 사용하여 프로필 업데이트
          // (현재는 하드코딩된 값 사용 중, 나중에 실제 값으로 교체 가능)
        });
      }
    } catch (e) {
      print('⚠️ 설정 화면: Teacher 정보 로드 실패: $e');
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
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Text(
              '설정',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(Gaps.card),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                // 프로필 섹션
                _buildProfileSection(theme, colorScheme),
                SizedBox(height: Gaps.card),

                // 알림 설정
                _buildSectionTitle('알림 설정', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildSwitchTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '푸시 알림',
                      subtitle: '수업 일정 및 청구 알림을 받습니다',
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() => notificationsEnabled = value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.notifications_active_rounded,
                      title: '알림 시간 설정',
                      subtitle: '매일 오전 9시',
                      onTap: () {
                        // TODO: 알림 시간 설정
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 수업 설정
                _buildSectionTitle('수업 설정', theme, colorScheme),
                SizedBox(height: Gaps.row),
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
                          // SharedPreferences에 저장
                          await SettingsService.setTeacherSubjects(result);
                          
                          // DB에도 저장 (Teacher 업데이트)
                          try {
                            final teacher = await TeacherService.instance.loadTeacher();
                            if (teacher != null) {
                              // 과목 목록을 콤마로 구분하여 subject_id에 저장
                              final subjectId = result.join(',');
                              await ApiService.updateTeacher(teacher.teacherId, {
                                'subject_id': subjectId,
                              });
                              // TeacherService 캐시 새로고침
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
                SizedBox(height: Gaps.cardPad + 4),

                // 앱 설정
                _buildSectionTitle('앱 설정', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildSwitchTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '다크 모드',
                      subtitle: '어두운 테마를 사용합니다',
                      value: darkModeEnabled,
                      onChanged: (value) {
                        setState(() => darkModeEnabled = value);
                        // TODO: 다크 모드 적용
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      title: '자동 백업',
                      subtitle: '데이터를 자동으로 백업합니다',
                      value: autoBackupEnabled,
                      onChanged: (value) {
                        setState(() => autoBackupEnabled = value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.language_rounded,
                      title: '언어',
                      subtitle: '한국어',
                      onTap: () {
                        // TODO: 언어 설정
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 데이터 관리
                _buildSectionTitle('데이터 관리', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.cloud_download_rounded,
                      title: '데이터 내보내기',
                      subtitle: '모든 데이터를 백업합니다',
                      onTap: () {
                        // TODO: 데이터 내보내기
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.cloud_upload_rounded,
                      title: '데이터 가져오기',
                      subtitle: '백업된 데이터를 복원합니다',
                      onTap: () {
                        // TODO: 데이터 가져오기
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.delete_outline_rounded,
                      title: '데이터 삭제',
                      subtitle: '모든 데이터를 삭제합니다',
                      titleColor: AppColors.error,
                      onTap: () {
                        // TODO: 데이터 삭제 확인
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 정보
                _buildSectionTitle('정보', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.info_outline_rounded,
                      title: '앱 버전',
                      subtitle: '1.0.0',
                      onTap: null,
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 처리방침',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.help_outline_rounded,
                      title: '도움말',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 로그아웃
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: Gaps.card),
                      side: BorderSide(color: AppColors.error),
                    ),
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Gaps.screen * 5),
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

  Widget _buildProfileSection(ThemeData theme, ColorScheme colorScheme) {
    // Teacher 정보 가져오기 (캐시에서)
    final teacher = TeacherService.instance.currentTeacher;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // 표시할 이름과 이메일
    final displayName = teacher?.nickname ?? user?.displayName ?? '선생님';
    final displayEmail = teacher?.email ?? user?.email ?? 'teacher@example.com';
    
    // 이름의 첫 글자 (아바타용)
    final firstChar = displayName.isNotEmpty 
        ? displayName.substring(0, 1) 
        : '선';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditTeacherProfileScreen(),
            ),
          );
          if (result == true && mounted) {
            // 프로필이 수정되었으면 화면 새로고침
            await _loadTeacherInfo();
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: EdgeInsets.all(Gaps.cardPad),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Text(
                  firstChar,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ),
              SizedBox(width: Gaps.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
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

  /// 로그아웃 처리
  Future<void> _handleLogout(BuildContext context) async {
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '로그아웃',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '정말 로그아웃하시겠습니까?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    // 사용자가 취소를 선택한 경우
    if (confirm != true) {
      return;
    }

    try {
      print('🔵 로그아웃 시작...');

      // 1. TeacherService 캐시 초기화
      await TeacherService.instance.clear();
      print('✅ Teacher 정보 캐시 삭제 완료');

      // 2. Firebase Auth에서 로그아웃
      final auth = FirebaseAuth.instance;
      await auth.signOut();
      print('✅ Firebase Auth 로그아웃 완료');

      // 3. 모바일 환경에서 Google Sign-In 로그아웃
      if (!kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
          print('✅ Google Sign-In 로그아웃 완료');
        } catch (e) {
          print('⚠️ Google Sign-In 로그아웃 실패 (무시): $e');
          // Google Sign-In 로그아웃 실패해도 계속 진행
        }
      }

      // 4. SharedPreferences의 is_signed_up 플래그 제거 (더 이상 사용하지 않지만 깔끔하게)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('is_signed_up');
        print('✅ SharedPreferences 정리 완료');
      } catch (e) {
        print('⚠️ SharedPreferences 정리 실패 (무시): $e');
      }

      print('✅ 로그아웃 완료');

      // 5. Bye 화면으로 이동 후 로그인 화면으로 리다이렉트
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.bye,
          (route) => false, // 모든 이전 화면 제거
        );
      }
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
                // 선택된 시간 강조 표시를 위한 컨테이너
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.chip + 4),
                  ),
                  child: Stack(
                    children: [
                      // 선택 영역 표시
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
                      // 스크롤 뷰
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
                // 선택된 시간 표시
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

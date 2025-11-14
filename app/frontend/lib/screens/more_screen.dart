import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/teacher_service.dart';
import '../routes/app_routes.dart';
import 'edit_teacher_profile_screen.dart';
import 'stats_screen.dart';
import 'community_screen.dart';
import 'lesson_settings_screen.dart';
import 'app_settings_screen.dart';
import 'faq_screen.dart';
import 'support_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  /// Teacher 정보 로드
  Future<void> _loadTeacherInfo() async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher != null && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ 더보기 화면: Teacher 정보 로드 실패: $e');
    }
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
              '더보기',
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

                  // 내 정보
                  _buildSectionTitle('내 정보', theme, colorScheme),
                  SizedBox(height: Gaps.row),
                  _buildSettingsCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    children: [
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.person_outline_rounded,
                        title: '프로필 설정',
                        subtitle: '프로필 정보를 수정합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditTeacherProfileScreen(),
                            ),
                          ).then((result) {
                            if (result == true && mounted) {
                              _loadTeacherInfo();
                              setState(() {});
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: Gaps.cardPad + 4),

                  // 업무 도구
                  _buildSectionTitle('업무 도구', theme, colorScheme),
                  SizedBox(height: Gaps.row),
                  _buildSettingsCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    children: [
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.bar_chart_rounded,
                        title: '통계',
                        subtitle: '학생, 수업, 청구 통계를 확인합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '커뮤니티',
                        subtitle: '학생 및 학부모와 소통합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CommunityScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.school_outlined,
                        title: '수업 설정',
                        subtitle: '과목, 수업 시간 등을 설정합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LessonSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: Gaps.cardPad + 4),

                  // 앱 관리
                  _buildSectionTitle('앱 관리', theme, colorScheme),
                  SizedBox(height: Gaps.row),
                  _buildSettingsCard(
                    theme: theme,
                    colorScheme: colorScheme,
                    children: [
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.settings_outlined,
                        title: '앱 설정',
                        subtitle: '앱 기본 설정을 관리합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.help_outline_rounded,
                        title: 'FAQ',
                        subtitle: '자주 묻는 질문을 확인합니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaqScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        theme: theme,
                        colorScheme: colorScheme,
                        icon: Icons.support_agent_outlined,
                        title: '고객센터',
                        subtitle: '문의 및 지원을 받습니다',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
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

      // 4. SharedPreferences의 is_signed_up 플래그 제거
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
}


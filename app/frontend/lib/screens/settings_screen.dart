import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoBackupEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '설정',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '앱 설정 및 계정 관리',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 프로필 섹션
                _buildProfileSection(theme, colorScheme),
                const SizedBox(height: 16),

                // 알림 설정
                _buildSectionTitle('알림 설정', theme, colorScheme),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),

                // 앱 설정
                _buildSectionTitle('앱 설정', theme, colorScheme),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),

                // 데이터 관리
                _buildSectionTitle('데이터 관리', theme, colorScheme),
                const SizedBox(height: 12),
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
                      titleColor: const Color(0xFFEF4444),
                      onTap: () {
                        // TODO: 데이터 삭제 확인
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 정보
                _buildSectionTitle('정보', theme, colorScheme),
                const SizedBox(height: 12),
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
                        // TODO: 이용약관
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 처리방침',
                      onTap: () {
                        // TODO: 개인정보 처리방침
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.help_outline_rounded,
                      title: '도움말',
                      onTap: () {
                        // TODO: 도움말
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 로그아웃
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: 로그아웃
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.error),
                    ),
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: 프로필 편집
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.primary,
                child: Text(
                  '선',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선생님',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'teacher@example.com',
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
        borderRadius: BorderRadius.circular(16),
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
      leading: Icon(icon, color: colorScheme.primary),
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
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
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
}

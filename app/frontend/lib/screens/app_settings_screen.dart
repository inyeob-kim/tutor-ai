import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../main.dart';
import '../services/settings_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool autoBackupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isDarkMode = await SettingsService.getDarkMode();
    if (mounted) {
      setState(() {
        darkModeEnabled = isDarkMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('앱 설정'),
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
                      icon: Icons.notifications_active,
                      title: '알림 시간 설정',
                      subtitle: '매일 오전 9시',
                      onTap: () {
                        // TODO: 알림 시간 설정
                      },
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
                      onChanged: (value) async {
                        setState(() => darkModeEnabled = value);
                        await SettingsService.setDarkMode(value);
                        // 테마 변경 적용
                        final appState = App.of(context);
                        if (appState != null) {
                          appState.changeThemeMode(value);
                        }
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
                SizedBox(height: Gaps.screen * 2),
              ]),
            ),
          ),
        ],
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
}


import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('고객센터'),
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
                // 문의 방법
                _buildSectionTitle('문의 방법', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.email_outlined,
                      title: '이메일 문의',
                      subtitle: 'support@example.com',
                      onTap: () {
                        // TODO: 이메일 앱 실행
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이메일 앱을 실행합니다: support@example.com'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.phone_outlined,
                      title: '전화 문의',
                      subtitle: '1588-0000 (평일 09:00 - 18:00)',
                      onTap: () {
                        // TODO: 전화 앱 실행
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('전화 앱을 실행합니다: 1588-0000'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: '채팅 상담',
                      subtitle: '실시간 채팅으로 문의하세요',
                      onTap: () {
                        // TODO: 채팅 상담 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('채팅 상담 기능은 준비 중입니다.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 운영 시간
                _buildSectionTitle('운영 시간', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildSettingsCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  children: [
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.access_time_rounded,
                      title: '평일',
                      subtitle: '09:00 - 18:00',
                      onTap: null,
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      theme: theme,
                      colorScheme: colorScheme,
                      icon: Icons.event_busy_rounded,
                      title: '주말 및 공휴일',
                      subtitle: '휴무',
                      onTap: null,
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
}


import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('도움말'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const TossScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 자주 묻는 질문
                _buildSectionTitle('자주 묻는 질문', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildFaqCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '학생을 어떻게 등록하나요?',
                  answer: '학생 화면에서 "+" 버튼을 눌러 학생 정보를 입력하고 저장하면 됩니다. 이름과 전화번호는 필수 입력 항목입니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '수업 일정을 어떻게 등록하나요?',
                  answer: '스케줄 화면에서 "+" 버튼을 눌러 수업 일정을 등록할 수 있습니다. 학생, 날짜, 시간, 과목을 선택하여 등록하세요.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '청구서를 어떻게 생성하나요?',
                  answer: '청구 화면에서 "+" 버튼을 눌러 청구서를 생성할 수 있습니다. 학생, 청구 금액, 납부 기한 등을 입력하세요.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '프로필 정보를 변경하려면?',
                  answer: '설정 화면에서 프로필 카드를 클릭하면 프로필 수정 화면으로 이동합니다. 이름, 전화번호, 이메일, 계좌 정보 등을 수정할 수 있습니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '가르치는 과목을 변경하려면?',
                  answer: '설정 화면 > 수업 설정 > 가르치는 과목 메뉴에서 과목을 추가하거나 삭제할 수 있습니다. 학생 등록 시 선택한 과목만 선택할 수 있습니다.',
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 주요 기능
                _buildSectionTitle('주요 기능', theme, colorScheme),
                SizedBox(height: Gaps.row),
                _buildFeatureCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.people_rounded,
                  title: '학생 관리',
                  description: '학생 정보를 등록하고 관리할 수 있습니다. 학생의 이름, 전화번호, 학년, 과목 등의 정보를 저장합니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFeatureCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.event_note_rounded,
                  title: '수업 일정 관리',
                  description: '수업 일정을 등록하고 관리할 수 있습니다. 날짜, 시간, 학생, 과목 등을 지정하여 일정을 관리합니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFeatureCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.receipt_long_rounded,
                  title: '청구 관리',
                  description: '청구서를 생성하고 관리할 수 있습니다. 청구 금액, 납부 상태, 납부 기한 등을 관리합니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFeatureCard(
                  theme: theme,
                  colorScheme: colorScheme,
                  icon: Icons.bar_chart_rounded,
                  title: '통계 확인',
                  description: '학생 통계, 청구 통계, 수업 통계를 확인할 수 있습니다. 전체 학생 수, 평균 출석률, 완료율 등을 확인할 수 있습니다.',
                ),
                SizedBox(height: Gaps.cardPad + 4),

                // 문의하기
                _buildSectionTitle('문의하기', theme, colorScheme),
                SizedBox(height: Gaps.row),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    side: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(Gaps.cardPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            SizedBox(width: Gaps.row),
                            Text(
                              '이메일 문의',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          'support@example.com',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            SizedBox(width: Gaps.row),
                            Text(
                              '전화 문의',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '평일 09:00 - 18:00',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '02-1234-5678',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Gaps.screen * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, ColorScheme colorScheme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFaqCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String question,
    required String answer,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(Gaps.cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(Radii.icon),
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: Gaps.row),
                Expanded(
                  child: Text(
                    question,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Gaps.row),
            Padding(
              padding: EdgeInsets.only(left: 38),
              child: Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(Gaps.cardPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(Radii.icon),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            SizedBox(width: Gaps.card),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: Gaps.row - 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


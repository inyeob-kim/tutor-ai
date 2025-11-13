import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('이용약관'),
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
                        Text(
                          '제1조 (목적)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '본 약관은 선생님 과외 관리 서비스(이하 "서비스")의 이용과 관련하여 서비스 제공자와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제2조 (정의)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. "서비스"란 과외 수업 관리, 학생 관리, 일정 관리 등을 위한 온라인 플랫폼을 의미합니다.\n'
                          '2. "이용자"란 본 약관에 따라 서비스를 이용하는 선생님을 의미합니다.\n'
                          '3. "콘텐츠"란 서비스를 통해 제공되는 모든 정보, 자료, 데이터 등을 의미합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제3조 (약관의 효력 및 변경)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.\n'
                          '2. 서비스 제공자는 필요하다고 인정되는 경우 본 약관을 변경할 수 있으며, 약관을 변경한 경우에는 변경된 약관의 내용과 시행일을 명시하여 공지합니다.\n'
                          '3. 변경된 약관은 공지한 시행일로부터 효력이 발생합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제4조 (서비스의 제공)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 다음과 같은 서비스를 제공합니다:\n'
                          '   - 학생 정보 관리\n'
                          '   - 수업 일정 관리\n'
                          '   - 청구 및 결제 관리\n'
                          '   - 통계 및 분석\n'
                          '2. 서비스는 연중무휴, 1일 24시간 제공함을 원칙으로 합니다.\n'
                          '3. 서비스 제공자는 서비스의 일부 또는 전부를 수정, 중단, 변경할 수 있습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제5조 (이용자의 의무)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 이용자는 서비스를 이용함에 있어 다음 행위를 하여서는 안 됩니다:\n'
                          '   - 타인의 정보 도용\n'
                          '   - 서비스의 안정적 운영을 방해하는 행위\n'
                          '   - 법령 또는 본 약관에 위배되는 행위\n'
                          '2. 이용자는 본인의 계정 정보를 안전하게 관리할 책임이 있습니다.\n'
                          '3. 이용자는 서비스를 이용하여 얻은 정보를 본인의 과외 활동 이외의 목적으로 사용할 수 없습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제6조 (개인정보 보호)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '서비스 제공자는 이용자의 개인정보를 보호하기 위해 노력하며, 개인정보의 보호 및 사용에 대해서는 관련 법령 및 개인정보 처리방침에 따릅니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제7조 (면책사항)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.\n'
                          '2. 서비스 제공자는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.\n'
                          '3. 서비스 제공자는 이용자가 서비스를 이용하여 기대하는 수익을 상실한 것에 대하여 책임을 지지 않으며, 그 밖의 서비스를 통하여 얻은 자료로 인한 손해에 관하여 책임을 지지 않습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제8조 (준거법 및 관할법원)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 본 약관의 해석 및 서비스 제공자와 이용자 간의 분쟁에 대하여는 대한민국 법을 적용합니다.\n'
                          '2. 서비스 이용과 관련하여 발생한 분쟁에 대하여는 민사소송법상의 관할법원에 제소합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '부칙',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '본 약관은 2024년 1월 1일부터 시행됩니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.screen * 2),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


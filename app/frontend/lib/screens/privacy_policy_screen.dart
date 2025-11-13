import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
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
                          '제1조 (개인정보의 처리 목적)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '서비스 제공자는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.\n\n'
                          '1. 서비스 제공: 학생 관리, 수업 일정 관리, 청구 관리 등 서비스 제공\n'
                          '2. 회원 관리: 회원 가입, 본인 확인, 회원 자격 유지·관리\n'
                          '3. 고객 지원: 문의사항 처리, 불만 처리 등 원활한 의사소통 경로의 확보',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제2조 (개인정보의 처리 및 보유기간)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.\n'
                          '2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:\n'
                          '   - 회원 정보: 회원 탈퇴 시까지\n'
                          '   - 학생 정보: 해당 학생 삭제 시까지\n'
                          '   - 수업 정보: 해당 수업 삭제 시까지\n'
                          '3. 이용자의 개인정보는 원칙적으로 개인정보의 처리목적이 달성되면 지체 없이 파기합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제3조 (처리하는 개인정보의 항목)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '서비스 제공자는 다음의 개인정보 항목을 처리하고 있습니다:\n\n'
                          '1. 회원 정보:\n'
                          '   - 필수 항목: 이름, 전화번호, 이메일, OAuth ID\n'
                          '   - 선택 항목: 은행명, 계좌번호, 세금 유형\n\n'
                          '2. 학생 정보:\n'
                          '   - 필수 항목: 이름, 전화번호\n'
                          '   - 선택 항목: 보호자 전화번호, 학교, 학년, 과목\n\n'
                          '3. 서비스 이용 정보:\n'
                          '   - 수업 일정, 청구 정보, 통계 데이터 등',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제4조 (개인정보의 제3자 제공)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 정보주체의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보 보호법 제17조 및 제18조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.\n'
                          '2. 서비스 제공자는 원칙적으로 정보주체의 개인정보를 제3자에게 제공하지 않습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제5조 (개인정보처리의 위탁)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:\n'
                          '   - 클라우드 서비스 제공자: 서버 호스팅 및 데이터 저장\n'
                          '   - 인증 서비스 제공자: 소셜 로그인 서비스\n\n'
                          '2. 서비스 제공자는 위탁계약 체결 시 개인정보 보호법 제26조에 따라 위탁업무 수행목적 외 개인정보 처리금지, 기술적·관리적 보호조치, 재위탁 제한, 수탁자에 대한 관리·감독, 손해배상 등에 관한 사항을 계약서 등 문서에 명시하고, 수탁자가 개인정보를 안전하게 처리하는지를 감독하고 있습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제6조 (정보주체의 권리·의무 및 행사방법)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 정보주체는 서비스 제공자에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:\n'
                          '   - 개인정보 처리정지 요구\n'
                          '   - 개인정보 열람 요구\n'
                          '   - 개인정보 정정·삭제 요구\n'
                          '   - 개인정보 처리정지 요구 등\n\n'
                          '2. 제1항에 따른 권리 행사는 서비스 제공자에 대해 서면, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며, 서비스 제공자는 이에 대해 지체 없이 조치하겠습니다.\n'
                          '3. 정보주체가 개인정보의 오류 등에 대한 정정 또는 삭제를 요구한 경우에는 서비스 제공자는 정정 또는 삭제를 완료할 때까지 당해 개인정보를 이용하거나 제공하지 않습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제7조 (개인정보의 파기)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.\n'
                          '2. 개인정보 파기의 절차 및 방법은 다음과 같습니다:\n'
                          '   - 파기 절차: 서비스 제공자는 파기 사유가 발생한 개인정보를 선정하고, 서비스 제공자의 개인정보 보호책임자의 승인을 받아 개인정보를 파기합니다.\n'
                          '   - 파기 방법: 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제8조 (개인정보 보호책임자)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '1. 서비스 제공자는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다:\n\n'
                          '   - 성명: 개인정보 보호팀\n'
                          '   - 연락처: privacy@example.com\n\n'
                          '2. 정보주체께서는 서비스 제공자의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제9조 (개인정보의 안전성 확보조치)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '서비스 제공자는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:\n\n'
                          '1. 관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육 등\n'
                          '2. 기술적 조치: 개인정보처리시스템 등의 접근권한 관리, 접근통제시스템 설치, 고유식별정보 등의 암호화, 보안프로그램 설치\n'
                          '3. 물리적 조치: 전산실, 자료보관실 등의 접근통제',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Gaps.cardPad),
                        Text(
                          '제10조 (개인정보 처리방침 변경)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          '이 개인정보 처리방침은 2024년 1월 1일부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.',
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


import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

/// FAQ 화면 - Help 화면을 재사용하거나 FAQ 전용 화면으로 확장 가능
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('FAQ'),
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
                // FAQ 섹션
                _buildFaqItem(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '앱 사용 방법은?',
                  answer: '홈 화면에서 오늘의 수업을 확인하고, 스케줄 탭에서 일정을 관리할 수 있습니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqItem(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '학생을 추가하려면?',
                  answer: '학생 관리 탭에서 추가 버튼을 눌러 학생 정보를 입력하세요.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqItem(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '수업 일정을 변경하려면?',
                  answer: '스케줄 탭에서 해당 일정을 선택하고 수정 또는 삭제할 수 있습니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqItem(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '청구 내역을 확인하려면?',
                  answer: '청구 탭에서 모든 청구 내역을 확인하고 관리할 수 있습니다.',
                ),
                SizedBox(height: Gaps.card),
                _buildFaqItem(
                  theme: theme,
                  colorScheme: colorScheme,
                  question: '앱 설정은 어디서 하나요?',
                  answer: '더보기 탭 > 앱 설정에서 알림, 수업 시간, 언어 등을 설정할 수 있습니다.',
                ),
                SizedBox(height: Gaps.screen * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
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
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(Gaps.cardPad),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


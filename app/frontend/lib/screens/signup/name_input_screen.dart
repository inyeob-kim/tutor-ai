import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 자동으로 키보드 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ModalRoute.of(context)!.settings.arguments as List<String>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 섹션
            Padding(
              padding: EdgeInsets.fromLTRB(Gaps.screen, Gaps.card, Gaps.screen, Gaps.cardPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이름을 입력해주세요 ✏️',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: Gaps.row),
                  Text(
                    '학생들이 부를 이름이에요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 입력 필드
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Gaps.screen),
              child: TextField(
                controller: _nameController,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_isValid) {
                    Navigator.of(context).pushNamed(
                      '/signup/phone',
                      arguments: {
                        'subjects': subjects,
                        'name': _nameController.text.trim(),
                      },
                    );
                  }
                },
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '이름을 입력하세요',
                  hintStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.card),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(Gaps.cardPad),
                ),
              ),
            ),

            const Spacer(),

            // 하단 버튼
            Container(
              padding: EdgeInsets.all(Gaps.screen),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: _isValid
                      ? () {
                          Navigator.of(context).pushNamed(
                            '/signup/phone',
                            arguments: {
                              'subjects': subjects,
                              'name': _nameController.text.trim(),
                            },
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '다음',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


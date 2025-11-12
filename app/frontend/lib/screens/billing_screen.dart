import 'package:flutter/material.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

enum BillingStatus { paid, unpaid, pending }
enum BillingFilter { all, unpaid, paid, thisMonth }

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  BillingFilter activeFilter = BillingFilter.all;

  // 데모 데이터
  final List<Map<String, dynamic>> billings = [
    {
      'id': '1',
      'student': '김민수',
      'subject': '수학',
      'amount': 200000,
      'date': '2024-11-01',
      'dueDate': '2024-11-05',
      'status': BillingStatus.paid,
      'color': AppColors.primary,
    },
    {
      'id': '2',
      'student': '이지은',
      'subject': '영어',
      'amount': 180000,
      'date': '2024-11-03',
      'dueDate': '2024-11-07',
      'status': BillingStatus.unpaid,
      'color': AppColors.success,
    },
    {
      'id': '3',
      'student': '박서준',
      'subject': '과학',
      'amount': 220000,
      'date': '2024-11-05',
      'dueDate': '2024-11-10',
      'status': BillingStatus.pending,
      'color': AppColors.primary,
    },
    {
      'id': '4',
      'student': '최유진',
      'subject': '수학',
      'amount': 200000,
      'date': '2024-10-28',
      'dueDate': '2024-11-02',
      'status': BillingStatus.paid,
      'color': AppColors.warning,
    },
  ];

  List<Map<String, dynamic>> get filteredBillings {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    return billings.where((billing) {
      final billingDate = DateTime.parse(billing['date']);

      switch (activeFilter) {
        case BillingFilter.unpaid:
          return billing['status'] == BillingStatus.unpaid;
        case BillingFilter.paid:
          return billing['status'] == BillingStatus.paid;
        case BillingFilter.thisMonth:
          return billingDate.isAfter(thisMonth.subtract(const Duration(days: 1)));
        case BillingFilter.all:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA); // 최신순
      });
  }

  Map<String, dynamic> get stats {
    final total = billings.fold<int>(
        0, (sum, b) => sum + (b['amount'] as int));
    final paid = billings
        .where((b) => b['status'] == BillingStatus.paid)
        .fold<int>(0, (sum, b) => sum + (b['amount'] as int));
    final unpaid = billings
        .where((b) => b['status'] == BillingStatus.unpaid)
        .fold<int>(0, (sum, b) => sum + (b['amount'] as int));
    final unpaidCount =
        billings.where((b) => b['status'] == BillingStatus.unpaid).length;

    return {
      'total': total,
      'paid': paid,
      'unpaid': unpaid,
      'unpaidCount': unpaidCount,
    };
  }

  String _formatCurrency(int amount) {
    return '${(amount / 1000).toStringAsFixed(0)}천원';
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
              '청구 관리',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 청구 추가 페이지로 이동
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('청구 추가'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                // 필터 탭
                _buildFilterTabs(theme, colorScheme),
                SizedBox(height: Gaps.screen),

                // 청구 리스트
                if (filteredBillings.isEmpty)
                  _buildEmptyState(theme, colorScheme)
                else
                  ...filteredBillings.map((billing) => Padding(
                        padding: EdgeInsets.only(bottom: Gaps.card - 2),
                        child: _buildBillingCard(
                          billing,
                          theme,
                          colorScheme,
                        ),
                      )),

                SizedBox(height: Gaps.screen * 2),
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Gaps.screen * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '청구 내역이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '청구를 추가하여 시작하세요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.chip),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '전체',
              isActive: activeFilter == BillingFilter.all,
              onTap: () => setState(() => activeFilter = BillingFilter.all),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '미납',
              isActive: activeFilter == BillingFilter.unpaid,
              onTap: () => setState(() => activeFilter = BillingFilter.unpaid),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '납부',
              isActive: activeFilter == BillingFilter.paid,
              onTap: () => setState(() => activeFilter = BillingFilter.paid),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterTab(
              theme: theme,
              colorScheme: colorScheme,
              label: '이번 달',
              isActive: activeFilter == BillingFilter.thisMonth,
              onTap: () => setState(() => activeFilter = BillingFilter.thisMonth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.surface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingCard(
    Map<String, dynamic> billing,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final status = billing['status'] as BillingStatus;
    final dueDate = DateTime.parse(billing['dueDate']);
    final dateStr = '${dueDate.month}월 ${dueDate.day}일';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case BillingStatus.paid:
        statusColor = AppColors.success;
        statusText = '납부 완료';
        statusIcon = Icons.check_circle_rounded;
        break;
      case BillingStatus.unpaid:
        statusColor = AppColors.warning;
        statusText = '미납';
        statusIcon = Icons.warning_rounded;
        break;
      case BillingStatus.pending:
        statusColor = AppColors.primary;
        statusText = '대기중';
        statusIcon = Icons.schedule_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: 청구 상세 페이지
          },
          borderRadius: BorderRadius.circular(Radii.card + 6),
          child: Padding(
            padding: EdgeInsets.all(Gaps.cardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billing['student'] as String,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            billing['subject'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Radii.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Gaps.screen),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                SizedBox(height: Gaps.screen),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '청구 금액',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(billing['amount'] as int),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '마감일',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateStr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // 미납인 경우 청구발송 버튼
                if (status == BillingStatus.unpaid) ...[
                  SizedBox(height: Gaps.screen),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 카톡/문자로 청구 발송 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${billing['student']}님에게 청구를 발송합니다.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: Icon(Icons.send_rounded, size: 18),
                      label: Text('청구 발송'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Gaps.card),
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}

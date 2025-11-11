import 'package:flutter/material.dart';

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
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': '2',
      'student': '이지은',
      'subject': '영어',
      'amount': 180000,
      'date': '2024-11-03',
      'dueDate': '2024-11-07',
      'status': BillingStatus.unpaid,
      'color': const Color(0xFF10B981),
    },
    {
      'id': '3',
      'student': '박서준',
      'subject': '과학',
      'amount': 220000,
      'date': '2024-11-05',
      'dueDate': '2024-11-10',
      'status': BillingStatus.pending,
      'color': const Color(0xFF9333EA),
    },
    {
      'id': '4',
      'student': '최유진',
      'subject': '수학',
      'amount': 200000,
      'date': '2024-10-28',
      'dueDate': '2024-11-02',
      'status': BillingStatus.paid,
      'color': const Color(0xFFF59E0B),
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
                    '청구 관리',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 ${billings.length}건의 청구',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 통계 카드
                _buildStatsCard(theme, colorScheme),
                const SizedBox(height: 16),

                // 필터 탭
                _buildFilterTabs(theme, colorScheme),
                const SizedBox(height: 16),

                // 청구 리스트
                if (filteredBillings.isEmpty)
                  _buildEmptyState(theme, colorScheme)
                else
                  ...filteredBillings.map((billing) => _buildBillingCard(
                        billing,
                        theme,
                        colorScheme,
                      )),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 총 청구 금액
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 청구 금액',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatCurrency(stats['total'] as int),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme: theme,
                    colorScheme: colorScheme,
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFD1FAE5),
                    value: _formatCurrency(stats['paid'] as int),
                    label: '납부 완료',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    theme: theme,
                    colorScheme: colorScheme,
                    icon: Icons.warning_rounded,
                    iconColor: const Color(0xFFF97316),
                    backgroundColor: const Color(0xFFFDEAD7),
                    value: '${stats['unpaidCount']}건',
                    label: '미납',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme, ColorScheme colorScheme) {
    return Row(
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '미납',
            isActive: activeFilter == BillingFilter.unpaid,
            onTap: () => setState(() => activeFilter = BillingFilter.unpaid),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab(
            theme: theme,
            colorScheme: colorScheme,
            label: '납부',
            isActive: activeFilter == BillingFilter.paid,
            onTap: () => setState(() => activeFilter = BillingFilter.paid),
          ),
        ),
        const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? colorScheme.onPrimary
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
    final isPaid = status == BillingStatus.paid;
    final isUnpaid = status == BillingStatus.unpaid;
    final dueDate = DateTime.parse(billing['dueDate']);
    final dateStr = '${dueDate.month}월 ${dueDate.day}일';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case BillingStatus.paid:
        statusColor = const Color(0xFF10B981);
        statusText = '납부 완료';
        statusIcon = Icons.check_circle_rounded;
        break;
      case BillingStatus.unpaid:
        statusColor = const Color(0xFFF97316);
        statusText = '미납';
        statusIcon = Icons.warning_rounded;
        break;
      case BillingStatus.pending:
        statusColor = const Color(0xFF2563EB);
        statusText = '대기중';
        statusIcon = Icons.schedule_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: 청구 상세 페이지
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Accent line
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: billing['color'] as Color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: billing['color'] as Color,
                            child: Text(
                              (billing['student'] as String)[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                billing['student'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                billing['subject'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 금액
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '청구 금액',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatCurrency(billing['amount'] as int),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 마감일
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnpaid
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: isUnpaid
                              ? const Color(0xFFEF4444)
                              : colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUnpaid ? '마감일' : '납부일',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isUnpaid
                                      ? const Color(0xFFEF4444)
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnpaid)
                          FilledButton(
                            onPressed: () {
                              // TODO: 납부 처리
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              backgroundColor: statusColor,
                            ),
                            child: const Text('납부 처리'),
                          ),
                      ],
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '청구 내역이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 청구를 추가해보세요',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

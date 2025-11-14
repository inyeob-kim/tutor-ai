import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';
import 'add_billing_screen.dart';

enum BillingStatus { paid, unpaid, pending }
enum BillingFilter { all, unpaid, paid, thisMonth }

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  BillingFilter activeFilter = BillingFilter.all;
  bool _isLoading = false;
  List<Map<String, dynamic>> billings = [];
  Map<int, Map<String, dynamic>> _studentsMap = {}; // student_id -> student data

  @override
  void initState() {
    super.initState();
    _loadBillings();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getStudents(isActive: true);
      final studentsMap = <int, Map<String, dynamic>>{};
      for (final s in students) {
        final studentId = s['student_id'] as int? ?? 0;
        if (studentId > 0) {
          studentsMap[studentId] = s;
        }
      }
      if (mounted) {
        setState(() {
          _studentsMap = studentsMap;
        });
      }
    } catch (e) {
      print('⚠️ 학생 목록 로드 실패: $e');
    }
  }

  Future<void> _loadBillings() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        if (mounted) {
          setState(() {
            billings = [];
            _isLoading = false;
          });
        }
        return;
      }

      final invoices = await ApiService.getInvoices(
        teacherId: teacher.teacherId,
        pageSize: 100,
      );

      // Invoice를 Billing 형식으로 변환
      final billingsList = invoices.map((invoice) {
        final studentId = invoice['student_id'] as int? ?? 0;
        final student = _studentsMap[studentId];
        final studentName = student?['name'] as String? ?? '학생';
        
        final statusStr = invoice['status'] as String? ?? 'draft';
        BillingStatus status;
        if (statusStr == 'paid') {
          status = BillingStatus.paid;
        } else if (statusStr == 'sent' || statusStr == 'partial') {
          status = BillingStatus.unpaid;
        } else {
          status = BillingStatus.pending;
        }

        final finalAmount = invoice['final_amount'] as int? ?? 0;
        final billingPeriodEnd = invoice['billing_period_end'] as String?;
        final dueDate = billingPeriodEnd != null
            ? DateTime.tryParse(billingPeriodEnd) ?? DateTime.now().add(const Duration(days: 7))
            : DateTime.now().add(const Duration(days: 7));

        return {
          'id': invoice['invoice_id']?.toString() ?? '',
          'invoice_id': invoice['invoice_id'] as int? ?? 0,
          'student_id': studentId,
          'student': studentName,
          'subject': student?['subjects'] != null && (student!['subjects'] as List).isNotEmpty
              ? (student['subjects'] as List).first.toString()
              : '과목',
          'amount': finalAmount,
          'date': invoice['created_at'] != null
              ? DateTime.tryParse(invoice['created_at'].toString())?.toIso8601String().split('T')[0]
              : DateTime.now().toIso8601String().split('T')[0],
          'dueDate': dueDate.toIso8601String().split('T')[0],
          'status': status,
          'kakao_pay_link': invoice['kakao_pay_link'] as String?,
          'color': AppColors.primary,
        };
      }).toList();

      if (mounted) {
        setState(() {
          billings = billingsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ 청구 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          billings = [];
          _isLoading = false;
        });
      }
    }
  }


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

  /// 청구서 발송 다이얼로그 표시
  Future<void> _showSendInvoiceDialog(Map<String, dynamic> billing) async {
    final invoiceId = billing['invoice_id'] as int? ?? 0;
    final studentName = billing['student'] as String? ?? '학생';
    final amount = billing['amount'] as int? ?? 0;
    final studentId = billing['student_id'] as int? ?? 0;
    final student = _studentsMap[studentId];
    final phone = student?['phone'] as String? ?? '';
    final parentPhone = student?['parent_phone'] as String?;

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        title: Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '청구서 발송',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$studentName님에게 청구서를 발송하시겠습니까?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '청구 금액',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '발송 방법을 선택하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop('kakao_pay'),
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('카카오페이 링크'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );

    if (result == 'kakao_pay' && mounted) {
      await _sendInvoiceLink(invoiceId, billing, phone, parentPhone);
    }
  }

  /// 청구서 링크 생성 및 발송
  Future<void> _sendInvoiceLink(
    int invoiceId,
    Map<String, dynamic> billing,
    String? phone,
    String? parentPhone,
  ) async {
    if (!mounted) return;

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 카카오페이 링크 생성
      final invoice = await ApiService.createAndSendInvoiceLink(
        invoiceId: invoiceId,
      );

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
      }

      final link = invoice['kakao_pay_link'] as String?;
      if (link == null || link.isEmpty) {
        throw Exception('링크 생성에 실패했습니다.');
      }

      // 링크 복사 및 공유 옵션 표시
      if (mounted) {
        await _showLinkShareDialog(link, billing, phone, parentPhone);
      }

      // 청구 목록 새로고침
      await _loadBillings();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('청구서 발송 실패: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 링크 공유 다이얼로그
  Future<void> _showLinkShareDialog(
    String link,
    Map<String, dynamic> billing,
    String? phone,
    String? parentPhone,
  ) async {
    if (!mounted) return;

    final studentName = billing['student'] as String? ?? '학생';
    final amount = billing['amount'] as int? ?? 0;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        title: Row(
          children: [
            Icon(Icons.link, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '청구서 링크',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '청구서 링크가 생성되었습니다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(color: AppColors.divider),
              ),
              child: SelectableText(
                link,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '공유 방법을 선택하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '닫기',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('링크가 클립보드에 복사되었습니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              Navigator.of(context).pop('copy');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('복사'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop('share'),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('공유'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );

    if (result == 'copy') {
      // 이미 복사됨
    } else if (result == 'share' && mounted) {
      // 링크 복사 (공유는 시스템 공유 기능 사용)
      final message = '$studentName님, 과외비 청구서입니다.\n금액: ${_formatCurrency(amount)}\n결제 링크: $link';
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('청구서 링크가 클립보드에 복사되었습니다. 카카오톡 등으로 공유해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBillingScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadBillings();
                    }
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
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                      onPressed: () => _showSendInvoiceDialog(billing),
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

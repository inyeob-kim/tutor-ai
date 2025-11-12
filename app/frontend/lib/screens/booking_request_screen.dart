import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/tokens.dart';

class BookingRequestScreen extends StatefulWidget {
  final String? studentId; // 선택적으로 학생 ID를 받을 수 있음
  
  const BookingRequestScreen({super.key, this.studentId});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStudentId;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getStudents();
      setState(() {
        _students = students;
        if (widget.studentId != null) {
          _selectedStudentId = widget.studentId;
        } else if (_students.isNotEmpty) {
          _selectedStudentId = _students.first['student_id']?.toString();
        }
      });
    } catch (e) {
      // 에러 처리 - 데모 데이터 사용
      setState(() {
        _students = [
          {'student_id': 1, 'name': '김민수'},
          {'student_id': 2, 'name': '이지은'},
          {'student_id': 3, 'name': '박서준'},
        ];
        if (_students.isNotEmpty) {
          _selectedStudentId = _students.first['student_id']?.toString();
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _generateBookingLink() {
    // 예약 링크 생성 (실제로는 서버에서 생성해야 함)
    final studentId = _selectedStudentId ?? '';
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    // 실제로는 서버 URL이어야 함
    return 'https://tutor-ai.app/booking?student_id=$studentId&date=$dateStr';
  }

  Future<void> _shareLink() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생을 선택해주세요')),
      );
      return;
    }

    final link = _generateBookingLink();
    final student = _students.firstWhere(
      (s) => s['student_id']?.toString() == _selectedStudentId,
      orElse: () => {'name': '학생'},
    );
    final studentName = student['name']?.toString() ?? '학생';
    final message = '$studentName님, 수업 예약을 위해 아래 링크를 클릭해주세요:\n\n$link';

    // 클립보드에 복사
    await Clipboard.setData(ClipboardData(text: message));
    
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크가 클립보드에 복사되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // 공유 다이얼로그 표시
        _showShareDialog(message);
      }
  }

  void _showShareDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card + 2)),
        ),
        padding: EdgeInsets.all(Gaps.cardPad + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '예약 링크 공유',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),
            Container(
              padding: EdgeInsets.all(Gaps.card),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: SelectableText(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: 카카오톡 공유 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('카카오톡 공유 기능은 준비 중입니다')),
                      );
                    },
                    child: Text('카카오톡'),
                  ),
                ),
                SizedBox(width: Gaps.row),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: 문자 메시지 공유 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('문자 메시지 공유 기능은 준비 중입니다')),
                      );
                    },
                    child: Text('문자'),
                  ),
                ),
              ],
            ),
            SizedBox(height: Gaps.row),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKoreanDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('예약 요청'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Gaps.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학생 선택
            if (_students.isNotEmpty) ...[
              Text(
                '학생 선택',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Gaps.row),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Gaps.card, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Radii.chip + 4),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedStudentId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _students.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['student_id']?.toString(),
                      child: Text(student['name']?.toString() ?? '이름 없음'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStudentId = value;
                    });
                  },
                ),
              ),
              SizedBox(height: Gaps.cardPad + 4),
            ],

            // 날짜 선택
            Text(
              '날짜 선택',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: Gaps.row),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.all(Gaps.cardPad),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Radii.chip + 4),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
                    SizedBox(width: Gaps.row),
                    Text(
                      _formatKoreanDate(_selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 안내 메시지
            Container(
              padding: EdgeInsets.all(Gaps.card),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
                  SizedBox(width: Gaps.row),
                  Expanded(
                    child: Text(
                      '학생에게 링크를 보내면 학생이 직접 시간대를 선택해서 예약할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Gaps.cardPad + 4),

            // 링크 생성 및 공유 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _shareLink,
                icon: Icon(Icons.share_rounded),
                label: Text(
                  '예약 링크 생성 및 공유',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: Gaps.card),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                ),
              ),
            ),
            SizedBox(height: Gaps.row),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final link = _generateBookingLink();
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('링크가 클립보드에 복사되었습니다'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: Icon(Icons.copy_rounded),
                label: Text('링크만 복사'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: Gaps.card),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
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


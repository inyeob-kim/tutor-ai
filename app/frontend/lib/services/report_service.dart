import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';
import '../theme/tokens.dart';

/// 자동 리포트 생성 및 공유 서비스
class ReportService {
  static final ReportService instance = ReportService._internal();
  factory ReportService() => instance;
  ReportService._internal();

  /// 리포트 데이터 생성
  Future<Map<String, dynamic>> generateReport({
    required String period, // 'weekly' or 'monthly'
  }) async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        throw Exception('선생님 정보를 불러올 수 없습니다.');
      }

      final now = DateTime.now();
      DateTime periodStart;
      DateTime periodEnd = now;

      if (period == 'weekly') {
        // 이번 주 월요일부터
        final weekday = now.weekday;
        periodStart = now.subtract(Duration(days: weekday - 1));
        periodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
      } else {
        // 이번 달 1일부터
        periodStart = DateTime(now.year, now.month, 1);
      }

      final periodStartStr = '${periodStart.year}-${periodStart.month.toString().padLeft(2, '0')}-${periodStart.day.toString().padLeft(2, '0')}';
      final periodEndStr = '${periodEnd.year}-${periodEnd.month.toString().padLeft(2, '0')}-${periodEnd.day.toString().padLeft(2, '0')}';

      // 학생 데이터
      final students = await ApiService.getStudents(isActive: true);
      final allStudents = await ApiService.getStudents();

      // 수업 데이터
      final lessons = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        dateFrom: periodStartStr,
        dateTo: periodEndStr,
        pageSize: 500,
      );

      // 청구 데이터
      final invoices = await ApiService.getInvoices(
        teacherId: teacher.teacherId,
        pageSize: 500,
      );

      // 통계 계산
      final completedLessons = lessons.where((l) => 
        l['status'] == 'completed' || l['status'] == 'done'
      ).length;

      // 수입 계산
      int income = 0;
      final studentsMap = {for (var s in students) s['student_id'] as int: s};
      for (var lesson in lessons) {
        if (lesson['status'] == 'completed' || lesson['status'] == 'done') {
          final studentId = lesson['student_id'] as int?;
          final student = studentsMap[studentId];
          if (student != null) {
            final hourlyRate = student['hourly_rate'] as int? ?? 0;
            final startTime = lesson['start_time'] as String? ?? '';
            final endTime = lesson['end_time'] as String? ?? '';
            
            if (startTime.isNotEmpty && endTime.isNotEmpty) {
              try {
                final startParts = startTime.split(':');
                final endParts = endTime.split(':');
                final startHour = int.parse(startParts[0]);
                final startMin = int.parse(startParts[1]);
                final endHour = int.parse(endParts[0]);
                final endMin = int.parse(endParts[1]);
                
                final start = DateTime(2000, 1, 1, startHour, startMin);
                final end = DateTime(2000, 1, 1, endHour, endMin);
                final duration = end.difference(start).inMinutes;
                final hours = duration / 60.0;
                
                income += (hourlyRate * hours).round();
              } catch (e) {
                income += hourlyRate;
              }
            } else {
              income += hourlyRate;
            }
          }
        }
      }

      // 미납 계산
      final unpaidInvoices = invoices.where((inv) {
        final status = inv['status'] as String? ?? '';
        return status == 'sent' || status == 'partial';
      }).toList();
      final unpaidAmount = unpaidInvoices.fold<int>(0, (sum, inv) {
        return sum + (inv['final_amount'] as int? ?? 0);
      });

      // 출석률 계산
      double avgAttendance = 0;
      if (students.isNotEmpty) {
        int totalSessions = 0;
        int completedSessions = 0;
        for (var student in students) {
          totalSessions += student['total_sessions'] as int? ?? 0;
          completedSessions += student['completed_sessions'] as int? ?? 0;
        }
        if (totalSessions > 0) {
          avgAttendance = (completedSessions / totalSessions) * 100;
        }
      }

      return {
        'period': period,
        'periodStart': periodStartStr,
        'periodEnd': periodEndStr,
        'lessonCount': completedLessons,
        'income': income,
        'unpaidAmount': unpaidAmount,
        'unpaidCount': unpaidInvoices.length,
        'avgAttendance': avgAttendance.round(),
        'activeStudents': students.length,
        'totalStudents': allStudents.length,
      };
    } catch (e) {
      print('❌ 리포트 생성 실패: $e');
      rethrow;
    }
  }

  /// 리포트 텍스트 포맷팅
  String formatReportText(Map<String, dynamic> report) {
    final period = report['period'] as String? ?? 'monthly';
    final periodLabel = period == 'weekly' ? '이번 주' : '이번 달';
    final periodStart = report['periodStart'] as String? ?? '';
    final periodEnd = report['periodEnd'] as String? ?? '';
    
    final lessonCount = report['lessonCount'] as int? ?? 0;
    final income = report['income'] as int? ?? 0;
    final unpaidAmount = report['unpaidAmount'] as int? ?? 0;
    final unpaidCount = report['unpaidCount'] as int? ?? 0;
    final avgAttendance = report['avgAttendance'] as int? ?? 0;
    final activeStudents = report['activeStudents'] as int? ?? 0;

    final incomeStr = _formatCurrency(income);
    final unpaidStr = _formatCurrency(unpaidAmount);

    return '''
📊 $periodLabel 활동 리포트

📅 기간: $periodStart ~ $periodEnd

👥 학생 현황
• 활성 학생: ${activeStudents}명

📚 수업 현황
• 완료된 수업: ${lessonCount}개
• 평균 출석률: ${avgAttendance}%

💰 수익 현황
• 총 수입: $incomeStr
• 미납 금액: $unpaidStr (${unpaidCount}건)

---
과외 관리 앱에서 자동 생성된 리포트입니다.
''';
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}백만원';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}천원';
    }
    return '$amount원';
  }

  /// 리포트 복사
  Future<void> copyReport(BuildContext context, Map<String, dynamic> report) async {
    final reportText = formatReportText(report);
    await Clipboard.setData(ClipboardData(text: reportText));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('리포트가 클립보드에 복사되었습니다.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}


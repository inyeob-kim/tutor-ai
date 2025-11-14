import '../services/api_service.dart';
import '../services/teacher_service.dart';

/// 학생 관리 노트 서비스
class StudentNoteService {
  static final StudentNoteService instance = StudentNoteService._internal();
  factory StudentNoteService() => instance;
  StudentNoteService._internal();

  /// 학생의 모든 수업 메모 수집
  Future<List<Map<String, dynamic>>> getStudentNotes(int studentId) async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        return [];
      }

      // 최근 10개 수업의 메모만 가져오기 (성능 최적화)
      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        studentId: studentId,
        pageSize: 10,
      );

      // 메모가 있는 수업만 필터링
      final notes = schedules.where((s) {
        final notes = s['notes'] as String?;
        return notes != null && notes.trim().isNotEmpty;
      }).map((s) {
        return {
          'schedule_id': s['schedule_id'],
          'lesson_date': s['lesson_date'],
          'subject': s['subject_id'],
          'notes': s['notes'],
          'status': s['status'],
        };
      }).toList();

      // 날짜순 정렬 (최신순)
      notes.sort((a, b) {
        final dateA = a['lesson_date'] as String? ?? '';
        final dateB = b['lesson_date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });

      return notes;
    } catch (e) {
      print('❌ 학생 메모 수집 실패: $e');
      return [];
    }
  }

  /// AI 요약 생성 (간단한 요약 로직 - 나중에 백엔드 AI API로 교체 가능)
  Future<String> generateSummary(List<Map<String, dynamic>> notes) async {
    if (notes.isEmpty) {
      return '아직 수업 메모가 없습니다.';
    }

    // 간단한 요약 로직 (키워드 추출 및 요약)
    final allNotes = notes.map((n) => n['notes'] as String? ?? '').join('\n');
    
    // 키워드 추출
    final keywords = <String, int>{};
    final commonWords = ['오늘', '집중력', '이해', '빠름', '느림', '좋음', '어려움', '쉬움', '준비', '숙제'];
    
    for (final word in commonWords) {
      final count = allNotes.split(word).length - 1;
      if (count > 0) {
        keywords[word] = count;
      }
    }

    // 요약 생성
    final summaryParts = <String>[];
    
    if (keywords.containsKey('집중력')) {
      summaryParts.add('집중력 관련 메모가 ${keywords['집중력']}회 언급되었습니다.');
    }
    if (keywords.containsKey('빠름')) {
      summaryParts.add('진도가 빠르다는 메모가 있습니다.');
    }
    if (keywords.containsKey('느림')) {
      summaryParts.add('진도가 느리다는 메모가 있습니다.');
    }
    if (keywords.containsKey('어려움')) {
      summaryParts.add('어려워하는 부분이 있다는 메모가 있습니다.');
    }
    if (keywords.containsKey('숙제')) {
      summaryParts.add('숙제 관련 메모가 있습니다.');
    }

    if (summaryParts.isEmpty) {
      return '최근 ${notes.length}개의 수업 메모가 있습니다.';
    }

    return summaryParts.join(' ');
  }

  /// 다음 수업 정보 가져오기
  Future<Map<String, dynamic>?> getNextLesson(int studentId) async {
    try {
      final teacher = await TeacherService.instance.loadTeacher();
      if (teacher == null) {
        return null;
      }

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 오늘부터 30일 후까지의 수업 조회
      final futureDate = now.add(const Duration(days: 30));
      final futureStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

      final schedules = await ApiService.getSchedules(
        teacherId: teacher.teacherId,
        studentId: studentId,
        dateFrom: todayStr,
        dateTo: futureStr,
        status: 'confirmed',
        pageSize: 10,
      );

      // 가장 가까운 미래 수업 찾기
      for (final schedule in schedules) {
        final lessonDate = schedule['lesson_date'] as String?;
        if (lessonDate != null) {
          try {
            final date = DateTime.parse(lessonDate);
            if (date.isAfter(now) || date.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
              return {
                'schedule_id': schedule['schedule_id'],
                'lesson_date': lessonDate,
                'start_time': schedule['start_time'],
                'end_time': schedule['end_time'],
                'subject': schedule['subject_id'],
              };
            }
          } catch (e) {
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ 다음 수업 정보 가져오기 실패: $e');
      return null;
    }
  }
}


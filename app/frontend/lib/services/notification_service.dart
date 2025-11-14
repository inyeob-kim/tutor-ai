import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../services/settings_service.dart';
import '../services/api_service.dart';
import '../services/teacher_service.dart';

/// 일정 리마인드 알림 서비스
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 웹 환경에서는 알림 기능 비활성화
    if (kIsWeb) {
      print('ℹ️ 웹 환경에서는 로컬 알림이 지원되지 않습니다.');
      _isInitialized = true; // 초기화 완료로 표시하되 실제로는 사용하지 않음
      return;
    }

    try {
      // Timezone 초기화
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // Android 초기화 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 초기화 설정
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized ?? false) {
        _isInitialized = true;
        print('✅ 알림 서비스 초기화 완료');
      } else {
        print('⚠️ 알림 서비스 초기화 실패');
      }
    } catch (e) {
      print('❌ 알림 서비스 초기화 중 에러: $e');
      // 초기화 실패해도 앱은 계속 작동하도록 함
    }
  }

  /// 알림 탭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 알림 탭됨: ${response.payload}');
    // TODO: 알림 탭 시 해당 화면으로 이동
  }

  /// 오늘과 내일의 수업 일정을 확인하고 알림 스케줄링
  Future<void> scheduleLessonReminders() async {
    try {
      // 초기화 확인
      if (!_isInitialized) {
        print('⚠️ 알림 서비스가 초기화되지 않았습니다. 초기화를 시도합니다...');
        await initialize();
      }

      // 알림 설정 확인
      bool notificationsEnabled;
      try {
        notificationsEnabled = await SettingsService.getNotificationsEnabled();
      } catch (e) {
        print('❌ 알림 설정 확인 실패: $e');
        return;
      }
      
      if (!notificationsEnabled) {
        print('ℹ️ 알림이 비활성화되어 있습니다.');
        return;
      }

      // Teacher 정보 로드
      Teacher? teacher;
      try {
        teacher = await TeacherService.instance.loadTeacher();
      } catch (e) {
        print('❌ Teacher 정보 로드 실패: $e');
        return;
      }
      
      if (teacher == null) {
        print('⚠️ 선생님 정보를 불러올 수 없습니다.');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // 오늘과 내일의 스케줄 조회
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> schedules;
      try {
        schedules = await ApiService.getSchedules(
          teacherId: teacher.teacherId,
          dateFrom: todayStr,
          dateTo: tomorrowStr,
          status: 'confirmed',
        );
      } catch (e) {
        print('❌ 스케줄 조회 실패: $e');
        return;
      }

      // 학생 정보 조회
      List<Map<String, dynamic>> students;
      try {
        students = await ApiService.getStudents(isActive: true);
      } catch (e) {
        print('❌ 학생 정보 조회 실패: $e');
        return;
      }
      final studentsMap = <int, Map<String, dynamic>>{};
      for (final s in students) {
        final studentId = s['student_id'] as int? ?? 0;
        if (studentId > 0) {
          studentsMap[studentId] = s;
        }
      }

      // 기존 알림 취소 (초기화 확인 후, 웹 환경 제외)
      if (_isInitialized && !kIsWeb) {
        try {
          await _notifications.cancelAll();
        } catch (e) {
          // 에러는 무시하고 계속 진행
        }
      }

      // 각 수업에 대해 알림 스케줄링
      for (final schedule in schedules) {
        final studentId = schedule['student_id'] as int? ?? 0;
        final student = studentsMap[studentId];
        final studentName = student?['name'] as String? ?? '학생';
        final subject = schedule['subject_id'] as String? ?? '과목';
        final lessonDate = schedule['lesson_date'] as String?;
        final startTime = schedule['start_time'] as String? ?? '';

        if (lessonDate == null || startTime.isEmpty) continue;

        // 날짜와 시간 파싱
        final dateParts = lessonDate.split('-');
        if (dateParts.length != 3) continue;

        final year = int.tryParse(dateParts[0]) ?? now.year;
        final month = int.tryParse(dateParts[1]) ?? now.month;
        final day = int.tryParse(dateParts[2]) ?? now.day;

        final timeParts = startTime.split(':');
        if (timeParts.length < 2) continue;

        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        final lessonDateTime = DateTime(year, month, day, hour, minute);
        final scheduleId = schedule['schedule_id'] as int? ?? 0;

        // 수업 30분 전 알림
        final reminderTime = lessonDateTime.subtract(const Duration(minutes: 30));
        if (reminderTime.isAfter(now)) {
          await _scheduleNotification(
            id: scheduleId,
            title: '수업 일정 알림',
            body: '$studentName님의 $subject 수업이 30분 후에 시작됩니다.',
            scheduledDate: reminderTime,
            payload: 'schedule_$scheduleId',
          );
        }

        // 수업 10분 전 출석 체크 알림 (오늘 수업만)
        if (lessonDate == todayStr) {
          final checkTime = lessonDateTime.subtract(const Duration(minutes: 10));
          if (checkTime.isAfter(now)) {
            await _scheduleNotification(
              id: scheduleId + 10000, // 고유 ID를 위해 오프셋 추가
              title: '출석 체크',
              body: '$studentName님의 수업이 10분 후입니다. 출석을 확인해주세요.',
              scheduledDate: checkTime,
              payload: 'attendance_$scheduleId',
            );
          }
        }
      }

      print('✅ 수업 알림 스케줄링 완료: ${schedules.length}개 수업');
    } catch (e, stackTrace) {
      print('❌ 알림 스케줄링 실패: $e');
      print('스택 트레이스: $stackTrace');
    }
  }

  /// 알림 스케줄링
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // 웹 환경에서는 알림 스케줄링 불가
    if (kIsWeb || !_isInitialized) {
      return;
    }

    try {
      // timezone이 초기화되었는지 확인
      tz.Location? localLocation;
      try {
        localLocation = tz.local;
      } catch (e) {
        print('⚠️ timezone 초기화되지 않음, 재초기화 시도...');
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
        localLocation = tz.local;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, localLocation),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'lesson_reminders',
            '수업 알림',
            channelDescription: '수업 일정 및 출석 체크 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // 에러는 무시하고 계속 진행 (웹 환경에서는 정상)
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    if (!_isInitialized || kIsWeb) {
      return;
    }
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // 에러는 무시
    }
  }
}


import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsService {
  static const String _keyStartHour = 'lesson_start_hour';
  static const String _keyEndHour = 'lesson_end_hour';
  static const String _keyDisabledHours = 'disabled_hours';
  static const String _keyExcludeWeekends = 'exclude_weekends';
  static const String _keyTeacherSubjects = 'teacher_subjects';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const int _defaultStartHour = 12;
  static const int _defaultEndHour = 22;

  // 수업 시작시간 가져오기
  static Future<int> getStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStartHour) ?? _defaultStartHour;
  }

  // 수업 시작시간 저장
  static Future<void> setStartHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartHour, hour);
  }

  // 수업 종료시간 가져오기
  static Future<int> getEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyEndHour) ?? _defaultEndHour;
  }

  // 수업 종료시간 저장
  static Future<void> setEndHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEndHour, hour);
  }

  // 비활성화된 시간대 가져오기 (날짜별)
  static Future<Set<int>> getDisabledHours(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${_keyDisabledHours}_${date.year}_${date.month}_${date.day}';
    final hoursString = prefs.getString(dateKey);
    if (hoursString == null || hoursString.isEmpty) {
      return <int>{};
    }
    return hoursString.split(',').map((e) => int.parse(e)).toSet();
  }

  // 비활성화된 시간대 저장 (날짜별)
  static Future<void> setDisabledHours(DateTime date, Set<int> hours) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${_keyDisabledHours}_${date.year}_${date.month}_${date.day}';
    if (hours.isEmpty) {
      await prefs.remove(dateKey);
    } else {
      await prefs.setString(dateKey, hours.join(','));
    }
  }

  // 특정 시간대 비활성화 토글
  static Future<void> toggleDisabledHour(DateTime date, int hour) async {
    final disabledHours = await getDisabledHours(date);
    if (disabledHours.contains(hour)) {
      disabledHours.remove(hour);
    } else {
      disabledHours.add(hour);
    }
    await setDisabledHours(date, disabledHours);
  }

  // 특정 시간대가 비활성화되어 있는지 확인
  static Future<bool> isHourDisabled(DateTime date, int hour) async {
    final disabledHours = await getDisabledHours(date);
    return disabledHours.contains(hour);
  }

  // 주말 제외 설정 가져오기
  static Future<bool> getExcludeWeekends() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExcludeWeekends) ?? false;
  }

  // 주말 제외 설정 저장
  static Future<void> setExcludeWeekends(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExcludeWeekends, value);
  }

  // 선생님 과목 목록 가져오기
  static Future<List<String>> getTeacherSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = prefs.getString(_keyTeacherSubjects);
    if (subjectsJson == null || subjectsJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> subjectsList = jsonDecode(subjectsJson);
      return subjectsList.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // 선생님 과목 목록 저장
  static Future<void> setTeacherSubjects(List<String> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = jsonEncode(subjects);
    await prefs.setString(_keyTeacherSubjects, subjectsJson);
  }

  // 다크 모드 설정 가져오기
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }

  // 다크 모드 설정 저장
  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
  }

  // 알림 설정 가져오기
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true; // 기본값: 활성화
  }

  // 알림 설정 저장
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }
}


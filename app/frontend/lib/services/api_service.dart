import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';  // /api/v1 제거 (백엔드 라우터가 직접 /students, /schedules 사용)
  
  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create student: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating student: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudents({String? query}) async {
    try {
      final uri = Uri.parse('$baseUrl/students').replace(
        queryParameters: query != null ? {'q': query} : null,
      );
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get students: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting students: $e');
    }
  }

  static Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  static Future<bool> checkScheduleConflict({
    required int teacherId,
    required String lessonDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/schedules/check-conflict').replace(
        queryParameters: {
          'teacher_id': teacherId.toString(),
          'lesson_date': lessonDate,
          'start_time': startTime,
          'end_time': endTime,
        },
      );
      
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['conflict'] as bool? ?? false;
      } else {
        throw Exception('Failed to check conflict: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking conflict: $e');
    }
  }
}


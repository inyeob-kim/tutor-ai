import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  static Future<Map<String, dynamic>> processAudio(
    List<int> audioBytes, {
    String? sessionId,
    int teacherId = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ai/process_audio');
      final request = http.MultipartRequest('POST', uri);
      
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }
      request.fields['teacher_id'] = teacherId.toString();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.m4a',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to process audio: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing audio: $e');
    }
  }

  static Future<Map<String, dynamic>> createBilling(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create billing: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating billing: $e');
    }
  }

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'google',
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during google login: $e');
    }
  }

  /// Teacher 생성 (회원가입 시 사용)
  static Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teachers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('서버 연결 시간이 초과되었습니다. 백엔드 서버가 실행 중인지 확인해주세요.');
        },
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body;
        // 더 친화적인 에러 메시지 제공
        if (errorBody.contains('Connect call failed') || errorBody.contains('5432')) {
          throw Exception('데이터베이스 연결에 실패했습니다. PostgreSQL이 실행 중인지 확인해주세요.');
        } else if (errorBody.contains('password authentication failed') || errorBody.contains('authentication failed')) {
          throw Exception('데이터베이스 인증에 실패했습니다. .env 파일의 DATABASE_URL 설정을 확인해주세요.');
        } else if (errorBody.contains('does not exist') || errorBody.contains('relation') && errorBody.contains('does not exist')) {
          throw Exception('데이터베이스 테이블이 없습니다. 마이그레이션을 실행해주세요: alembic upgrade head');
        }
        throw Exception('회원가입 실패: ${response.statusCode} - ${errorBody.length > 100 ? errorBody.substring(0, 100) : errorBody}');
      }
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? '서버 연결 시간이 초과되었습니다. 백엔드 서버가 실행 중인지 확인해주세요.');
    } on SocketException {
      throw Exception('백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요. (http://localhost:8000)');
    } on FormatException {
      throw Exception('서버 응답 형식이 올바르지 않습니다. 백엔드 서버 상태를 확인해주세요.');
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Connect call failed') || errorMsg.contains('5432')) {
        throw Exception('데이터베이스 연결에 실패했습니다. PostgreSQL이 실행 중인지 확인해주세요.');
      } else if (errorMsg.contains('password authentication failed') || errorMsg.contains('authentication failed')) {
        throw Exception('데이터베이스 인증에 실패했습니다. .env 파일의 DATABASE_URL 설정을 확인해주세요.');
      } else if (errorMsg.contains('Connection refused') || errorMsg.contains('Failed host lookup') || errorMsg.contains('Failed to fetch')) {
        throw Exception('백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요. (http://localhost:8000)');
      }
      throw Exception('회원가입 중 오류가 발생했습니다: ${errorMsg.length > 150 ? errorMsg.substring(0, 150) : errorMsg}');
    }
  }

  /// OAuth provider와 oauth_id로 Teacher 조회
  static Future<Map<String, dynamic>?> getTeacherByOAuth({
    required String provider,
    required String oauthId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/teachers/by-oauth').replace(
        queryParameters: {
          'provider': provider,
          'oauth_id': oauthId,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Teacher를 찾지 못한 경우 (회원가입이 안된 경우)
        return null;
      } else {
        throw Exception('Failed to get teacher: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting teacher: $e');
    }
  }

  /// Teacher ID로 Teacher 조회
  static Future<Map<String, dynamic>> getTeacher(int teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get teacher: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting teacher: $e');
    }
  }
}


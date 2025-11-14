import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  /// 플랫폼별 baseUrl 설정
  /// - Web: localhost 사용
  /// - Android 에뮬레이터: 10.0.2.2 사용 (localhost를 호스트 머신으로 매핑)
  /// - iOS 시뮬레이터/실제 기기: localhost 사용
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';  // Android 에뮬레이터용
    } else {
      return 'http://localhost:8000';  // iOS 시뮬레이터, 실제 기기
    }
  }
  
  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    try {
      // 디버깅: 전송할 데이터 확인
      print('📤 API 서비스: 학생 생성 요청');
      print('  - URL: $baseUrl/students');
      print('  - teacher_id: ${data['teacher_id']}');
      print('  - 전체 데이터: $data');

      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // 디버깅: 응답 확인
      print('📥 API 서비스: 학생 생성 응답');
      print('  - Status Code: ${response.statusCode}');
      print('  - Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ 학생 생성 성공: teacher_id=${result['teacher_id']}');
        return result;
      } else {
        print('❌ 학생 생성 실패: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create student: ${response.body}');
      }
    } catch (e) {
      print('❌ 학생 생성 에러: $e');
      throw Exception('Error creating student: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudents({
    String? query,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null) queryParams['q'] = query;
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final uri = Uri.parse('$baseUrl/students').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
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

  /// 학생 정보 업데이트
  static Future<Map<String, dynamic>> updateStudent({
    required int studentId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/students/$studentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data ?? {}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update student: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating student: $e');
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

  /// 반복 수업 일괄 생성
  static Future<Map<String, dynamic>> bulkGenerateSchedule({
    required int teacherId,
    required int studentId,
    required String subjectId,
    required int weekday, // 0=월요일, 6=일요일 (Python weekday 형식)
    required String startTime,
    required String endTime,
    required String dateFrom,
    required String dateTo,
    String? notes,
  }) async {
    try {
      final queryParams = <String, String>{
        'teacher_id': teacherId.toString(),
        'student_id': studentId.toString(),
        'subject_id': subjectId,
        'weekday': weekday.toString(),
        'start_time': startTime,
        'end_time': endTime,
        'date_from': dateFrom,
        'date_to': dateTo,
      };
      if (notes != null && notes.isNotEmpty) {
        queryParams['notes'] = notes;
      }

      final uri = Uri.parse('$baseUrl/schedules/bulk-generate').replace(
        queryParameters: queryParams,
      );

      final response = await http.post(uri);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to bulk generate schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error bulk generating schedule: $e');
    }
  }

  /// 스케줄 목록 조회
  static Future<List<Map<String, dynamic>>> getSchedules({
    int? teacherId,
    int? studentId,
    String? subjectId,
    String? status,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId;
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final uri = Uri.parse('$baseUrl/schedules').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get schedules: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting schedules: $e');
    }
  }

  /// 스케줄 업데이트
  static Future<Map<String, dynamic>> updateSchedule({
    required int scheduleId,
    String? notes,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notes != null) data['notes'] = notes;
      if (status != null) data['status'] = status;

      final response = await http.patch(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

  /// 스케줄 취소 (삭제)
  static Future<void> deleteSchedule({
    required int scheduleId,
    int? cancelledBy,
    String? cancelReason,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (cancelledBy != null) queryParams['cancelled_by'] = cancelledBy.toString();
      if (cancelReason != null) queryParams['cancel_reason'] = cancelReason;

      final uri = Uri.parse('$baseUrl/schedules/$scheduleId').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.delete(uri);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ 스케줄 취소 성공: schedule_id=$scheduleId');
        return;
      } else {
        throw Exception('Failed to delete schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
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

  /// 청구서 목록 조회
  static Future<List<Map<String, dynamic>>> getInvoices({
    int? teacherId,
    int? studentId,
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/invoices').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get invoices: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting invoices: $e');
    }
  }

  /// 청구서 업데이트
  static Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data ?? {}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update invoice: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating invoice: $e');
    }
  }

  /// 청구서 카카오페이 링크 생성 및 발송
  static Future<Map<String, dynamic>> createAndSendInvoiceLink({
    required int invoiceId,
    String? approvalUrl,
    String? cancelUrl,
    String? failUrl,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (approvalUrl != null) queryParams['approval_url'] = approvalUrl;
      if (cancelUrl != null) queryParams['cancel_url'] = cancelUrl;
      if (failUrl != null) queryParams['fail_url'] = failUrl;

      final uri = Uri.parse('$baseUrl/invoices/$invoiceId/create-kakao-pay-link')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create invoice link: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating invoice link: $e');
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

  /// Teacher 정보 업데이트
  static Future<Map<String, dynamic>> updateTeacher(
    int teacherId,
    Map<String, dynamic> data,
  ) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다. 다시 로그인해주세요.');
      }

      // ID 토큰 가져오기
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('인증 토큰을 가져올 수 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/teachers/$teacherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('서버 응답 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body;
        if (errorBody.contains('password authentication failed')) {
          throw Exception('데이터베이스 연결에 실패했습니다. 백엔드 서버와 데이터베이스가 실행 중인지 확인해주세요.');
        } else if (errorBody.contains('Failed to fetch') || errorBody.contains('Connection refused')) {
          throw Exception('백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
        } else {
          throw Exception('프로필 수정 실패: ${response.statusCode} - $errorBody');
        }
      }
    } on SocketException {
      throw Exception('네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.');
    } on TimeoutException {
      throw Exception('서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
    } on FormatException {
      throw Exception('서버 응답 형식이 올바르지 않습니다.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('프로필 수정 중 오류가 발생했습니다: $e');
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


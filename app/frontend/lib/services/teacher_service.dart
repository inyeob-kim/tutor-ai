import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'settings_service.dart';

/// Teacher 정보 모델
class Teacher {
  final int teacherId;
  final String name;
  final String phone;
  final String? email;
  final String? subjectId;
  final String provider;
  final String oauthId;
  final int? totalStudents;
  final int? monthlyIncome;
  final String? bankName;
  final String? accountNumber;
  final String? taxType;
  final String? hourlyRateMin;
  final String? hourlyRateMax;
  final String? availableDays;
  final String? availableTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.teacherId,
    required this.name,
    required this.phone,
    this.email,
    this.subjectId,
    required this.provider,
    required this.oauthId,
    this.totalStudents,
    this.monthlyIncome,
    this.bankName,
    this.accountNumber,
    this.taxType,
    this.hourlyRateMin,
    this.hourlyRateMax,
    this.availableDays,
    this.availableTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 Teacher 생성
  factory Teacher.fromJson(Map<String, dynamic> json) {
    // DateTime 파싱 (안전하게 처리)
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('⚠️ DateTime 파싱 실패: $value - $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Teacher(
      teacherId: json['teacher_id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      subjectId: json['subject_id'] as String?,
      provider: json['provider'] as String,
      oauthId: json['oauth_id'] as String,
      totalStudents: json['total_students'] as int?,
      monthlyIncome: json['monthly_income'] as int?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      taxType: json['tax_type'] as String?,
      hourlyRateMin: json['hourly_rate_min']?.toString(),
      hourlyRateMax: json['hourly_rate_max']?.toString(),
      availableDays: json['available_days'] as String?,
      availableTime: json['available_time'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'teacher_id': teacherId,
      'name': name,
      'phone': phone,
      'email': email,
      'subject_id': subjectId,
      'provider': provider,
      'oauth_id': oauthId,
      'total_students': totalStudents,
      'monthly_income': monthlyIncome,
      'bank_name': bankName,
      'account_number': accountNumber,
      'tax_type': taxType,
      'hourly_rate_min': hourlyRateMin != null ? int.tryParse(hourlyRateMin!) : null,
      'hourly_rate_max': hourlyRateMax != null ? int.tryParse(hourlyRateMax!) : null,
      'available_days': availableDays,
      'available_time': availableTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Teacher 정보를 관리하는 서비스 (싱글톤)
class TeacherService {
  static TeacherService? _instance;
  static TeacherService get instance => _instance ??= TeacherService._();

  TeacherService._();

  Teacher? _currentTeacher;
  static const String _cacheKey = 'cached_teacher';

  /// 현재 Teacher 정보 가져오기 (캐시 우선)
  Teacher? get currentTeacher => _currentTeacher;

  /// Teacher 정보가 로드되었는지 확인
  bool get isLoaded => _currentTeacher != null;

  /// Teacher 정보 로드 (캐시 또는 API)
  Future<Teacher?> loadTeacher({bool forceRefresh = false}) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        print('⚠️ 로그인된 사용자가 없습니다.');
        return null;
      }

      // 캐시에서 로드 (forceRefresh가 false일 때)
      if (!forceRefresh && _currentTeacher != null) {
        print('✅ 캐시에서 Teacher 정보 로드: ${_currentTeacher!.name}');
        return _currentTeacher;
      }

      // SharedPreferences에서 로드 시도
      if (!forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null) {
          try {
            final json = jsonDecode(cachedJson) as Map<String, dynamic>;
            _currentTeacher = Teacher.fromJson(json);
            
            // subject_id에서 과목 목록을 파싱하여 SettingsService에 저장
            if (_currentTeacher!.subjectId != null && _currentTeacher!.subjectId!.isNotEmpty) {
              final subjectList = _currentTeacher!.subjectId!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              if (subjectList.isNotEmpty) {
                await SettingsService.setTeacherSubjects(subjectList);
                print('✅ 선생님 과목 목록 로드 (캐시): ${subjectList.join(", ")}');
              }
            }
            
            print('✅ SharedPreferences에서 Teacher 정보 로드: ${_currentTeacher!.name}');
            return _currentTeacher;
          } catch (e) {
            print('⚠️ 캐시된 Teacher 정보 파싱 실패: $e');
          }
        }
      }

      // API에서 로드
      // Firebase Auth의 UID를 oauth_id로 사용
      // provider는 'google'로 고정 (현재는 Google만 지원)
      final teacherJson = await ApiService.getTeacherByOAuth(
        provider: 'google',
        oauthId: user.uid,
      );

      if (teacherJson == null) {
        print('ℹ️ Teacher 정보를 찾을 수 없습니다. (회원가입이 필요할 수 있습니다.)');
        _currentTeacher = null;
        await _clearCache();
        return null;
      }

      _currentTeacher = Teacher.fromJson(teacherJson);
      await _saveCache(_currentTeacher!);
      
      // subject_id에서 과목 목록을 파싱하여 SettingsService에 저장
      if (_currentTeacher!.subjectId != null && _currentTeacher!.subjectId!.isNotEmpty) {
        final subjectList = _currentTeacher!.subjectId!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (subjectList.isNotEmpty) {
          await SettingsService.setTeacherSubjects(subjectList);
          print('✅ 선생님 과목 목록 로드: ${subjectList.join(", ")}');
        }
      }
      
      print('✅ API에서 Teacher 정보 로드: ${_currentTeacher!.name}');
      return _currentTeacher;
    } catch (e) {
      print('❌ Teacher 정보 로드 실패: $e');
      return null;
    }
  }

  /// Teacher 정보 생성 (회원가입 시 사용)
  Future<Teacher?> createTeacher({
    required String name,
    required String phone,
    String? email,
    String? subjectId,
    List<String>? subjects, // 여러 과목을 선택한 경우, 첫 번째 과목을 subject_id로 사용
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다. 다시 로그인해주세요.');
      }

      // subjects가 있으면 모든 과목을 콤마로 구분하여 subject_id로 저장
      final finalSubjectId = subjectId ?? 
          (subjects != null && subjects.isNotEmpty 
              ? subjects.join(',') 
              : null);

      final teacherJson = await ApiService.createTeacher({
        'name': name,
        'phone': phone,
        'email': email ?? user.email,
        'subject_id': finalSubjectId,
        'provider': 'google',
        'oauth_id': user.uid,
      });

      _currentTeacher = Teacher.fromJson(teacherJson);
      await _saveCache(_currentTeacher!);
      
      // subject_id에서 과목 목록을 파싱하여 SettingsService에 저장
      if (_currentTeacher!.subjectId != null && _currentTeacher!.subjectId!.isNotEmpty) {
        final subjectList = _currentTeacher!.subjectId!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (subjectList.isNotEmpty) {
          await SettingsService.setTeacherSubjects(subjectList);
        }
      }
      
      print('✅ Teacher 정보 생성 성공: ${_currentTeacher!.name}');
      return _currentTeacher;
    } catch (e) {
      print('❌ Teacher 정보 생성 실패: $e');
      // 더 명확한 에러 메시지를 위해 원본 에러를 그대로 전달
      // (ApiService에서 이미 친화적인 메시지로 변환됨)
      rethrow;
    }
  }

  /// Teacher 정보 캐시 저장
  Future<void> _saveCache(Teacher teacher) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(teacher.toJson());
      await prefs.setString(_cacheKey, json);
      print('✅ Teacher 정보 캐시 저장 완료');
    } catch (e) {
      print('⚠️ Teacher 정보 캐시 저장 실패: $e');
    }
  }

  /// Teacher 정보 캐시 삭제
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      _currentTeacher = null;
      print('✅ Teacher 정보 캐시 삭제 완료');
    } catch (e) {
      print('⚠️ Teacher 정보 캐시 삭제 실패: $e');
    }
  }

  /// Teacher 정보 초기화 (로그아웃 시 사용)
  Future<void> clear() async {
    await _clearCache();
  }

  /// Teacher 정보 새로고침
  Future<Teacher?> refresh() async {
    return await loadTeacher(forceRefresh: true);
  }
}


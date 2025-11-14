import 'package:flutter/material.dart';

class Student {
  final int? studentId; // 학생 ID
  final String name;
  final String? grade; // 성인일 경우에만 입력
  final List<String> subjects;
  final String phone;
  final int sessions;
  final int completedSessions;
  final Color color;
  final String nextClass; // ex) "11월 7일 10:00"
  final int attendanceRate; // 0~100
  final bool isAdult; // 성인 여부 (기본값: true)
  final bool isActive; // 활성화 여부 (기본값: true)

  Student({
    this.studentId,
    required this.name,
    this.grade,
    required this.subjects,
    required this.phone,
    required this.sessions,
    required this.completedSessions,
    required this.color,
    required this.nextClass,
    required this.attendanceRate,
    this.isAdult = true, // 디폴트는 성인
    this.isActive = true, // 디폴트는 활성화
  });
}


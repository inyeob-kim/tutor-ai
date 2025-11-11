import 'package:flutter/material.dart';

class Student {
  final String name;
  final String grade;
  final List<String> subjects;
  final String phone;
  final int sessions;
  final int completedSessions;
  final Color color;
  final String nextClass; // ex) "11월 7일 10:00"
  final int attendanceRate; // 0~100

  Student({
    required this.name,
    required this.grade,
    required this.subjects,
    required this.phone,
    required this.sessions,
    required this.completedSessions,
    required this.color,
    required this.nextClass,
    required this.attendanceRate,
  });
}


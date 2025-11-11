class Lesson {
  final String id;
  final String studentId;
  final DateTime startsAt;
  final String subject;
  final int durationMin;
  final String status; // 'done', 'pending', 'cancelled'
  final String? attendance; // 'show', 'late', 'absent', null

  Lesson({
    required this.id,
    required this.studentId,
    required this.startsAt,
    required this.subject,
    required this.durationMin,
    this.status = 'pending',
    this.attendance,
  });

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMin));
}


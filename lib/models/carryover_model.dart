class CarryoverModel {
  final String id;
  final String studentId;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final String semesterFailed;
  final String currentSemester;
  final String declarationStatus;
  final DateTime declaredAt;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  // Joined fields
  final String? studentName;
  final String? studentMatric;
  final String? acknowledgerName;

  const CarryoverModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.semesterFailed,
    required this.currentSemester,
    required this.declarationStatus,
    required this.declaredAt,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.studentName,
    this.studentMatric,
    this.acknowledgerName,
  });

  // ─── From Supabase JSON ──────────────────────────────────────────────────
  factory CarryoverModel.fromJson(Map<String, dynamic> json) {
    return CarryoverModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      courseId: json['course_id'] as String,
      courseCode: json['course_code'] as String,
      courseTitle: json['course_title'] as String,
      creditUnits: json['credit_units'] as int,
      semesterFailed: json['semester_failed'] as String,
      currentSemester: json['current_semester'] as String,
      declarationStatus: json['declaration_status'] as String,
      declaredAt: DateTime.parse(json['declared_at'] as String),
      acknowledgedBy: json['acknowledged_by'] as String?,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      studentName: json['student_name'] as String?,
      studentMatric: json['student_matric'] as String?,
      acknowledgerName: json['acknowledger_name'] as String?,
    );
  }

  // ─── To JSON for Supabase Insert ─────────────────────────────────────────
  Map<String, dynamic> toInsertJson() {
    return {
      'student_id': studentId,
      'course_id': courseId,
      'course_code': courseCode,
      'course_title': courseTitle,
      'credit_units': creditUnits,
      'semester_failed': semesterFailed,
      'current_semester': currentSemester,
      'declaration_status': 'pending',
      'declared_at': DateTime.now().toIso8601String(),
    };
  }

  // ─── CopyWith ─────────────────────────────────────────────────────────────
  CarryoverModel copyWith({
    String? id,
    String? studentId,
    String? courseId,
    String? courseCode,
    String? courseTitle,
    int? creditUnits,
    String? semesterFailed,
    String? currentSemester,
    String? declarationStatus,
    DateTime? declaredAt,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? studentName,
    String? studentMatric,
    String? acknowledgerName,
  }) {
    return CarryoverModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      creditUnits: creditUnits ?? this.creditUnits,
      semesterFailed: semesterFailed ?? this.semesterFailed,
      currentSemester: currentSemester ?? this.currentSemester,
      declarationStatus: declarationStatus ?? this.declarationStatus,
      declaredAt: declaredAt ?? this.declaredAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      studentName: studentName ?? this.studentName,
      studentMatric: studentMatric ?? this.studentMatric,
      acknowledgerName: acknowledgerName ?? this.acknowledgerName,
    );
  }

  // ─── Convenience Getters ──────────────────────────────────────────────────
  bool get isPending => declarationStatus == 'pending';
  bool get isAcknowledged => declarationStatus == 'acknowledged';
  bool get isCleared => declarationStatus == 'cleared';

  String get statusDisplay {
    switch (declarationStatus) {
      case 'pending':
        return 'Pending Review';
      case 'acknowledged':
        return 'Acknowledged';
      case 'cleared':
        return 'Cleared';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'CarryoverModel(id: $id, course: $courseCode, status: $declarationStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarryoverModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

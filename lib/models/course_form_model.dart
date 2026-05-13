// Represents a single course inside a course form
class CourseEntry {
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final bool isCarryover;

  const CourseEntry({
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.isCarryover,
  });

  factory CourseEntry.fromJson(Map<String, dynamic> json) {
    return CourseEntry(
      courseCode: json['course_code'] as String,
      courseTitle: json['course_title'] as String,
      creditUnits: json['credit_units'] as int,
      isCarryover: json['is_carryover'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_code': courseCode,
      'course_title': courseTitle,
      'credit_units': creditUnits,
      'is_carryover': isCarryover,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CourseFormModel {
  final String id;
  final String studentId;
  final String semester;
  final String session;
  final String formPdfUrl;
  final int totalUnits;
  final List<CourseEntry> coursesListed;
  final String submissionStatus;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? qrCodeUrl;
  final bool digitalStamp;
  final DateTime createdAt;

  // Extra joined fields from Supabase (not stored in this table)
  // These are populated when we do a join query
  final String? reviewerName;
  final String? studentName;
  final String? studentMatric;
  final String? studentDepartment;
  final String? studentLevel;

  const CourseFormModel({
    required this.id,
    required this.studentId,
    required this.semester,
    required this.session,
    required this.formPdfUrl,
    required this.totalUnits,
    required this.coursesListed,
    required this.submissionStatus,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.qrCodeUrl,
    required this.digitalStamp,
    required this.createdAt,
    this.reviewerName,
    this.studentName,
    this.studentMatric,
    this.studentDepartment,
    this.studentLevel,
  });

  // ─── From Supabase JSON ────────────────────────────────────────────────────
  factory CourseFormModel.fromJson(Map<String, dynamic> json) {
    // Parse the courses_listed JSONB array from Supabase
    List<CourseEntry> courses = [];
    if (json['courses_listed'] != null) {
      final rawList = json['courses_listed'] as List<dynamic>;
      courses = rawList
          .map((item) => CourseEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CourseFormModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      semester: json['semester'] as String,
      session: json['session'] as String,
      formPdfUrl: json['form_pdf_url'] as String,
      totalUnits: json['total_units'] as int,
      coursesListed: courses,
      submissionStatus: json['submission_status'] as String,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      digitalStamp: json['digital_stamp'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Joined fields - these come from a Supabase join query
      reviewerName: json['reviewer_name'] as String?,
      studentName: json['student_name'] as String?,
      studentMatric: json['student_matric'] as String?,
      studentDepartment: json['student_department'] as String?,
      studentLevel: json['student_level'] as String?,
    );
  }

  // ─── To JSON for Supabase Insert ──────────────────────────────────────────
  Map<String, dynamic> toInsertJson() {
    return {
      'student_id': studentId,
      'semester': semester,
      'session': session,
      'form_pdf_url': formPdfUrl,
      'total_units': totalUnits,
      'courses_listed': coursesListed.map((c) => c.toJson()).toList(),
      'submission_status': submissionStatus,
      'submitted_at': submittedAt?.toIso8601String(),
      'digital_stamp': false,
    };
  }

  // ─── CopyWith ──────────────────────────────────────────────────────────────
  CourseFormModel copyWith({
    String? id,
    String? studentId,
    String? semester,
    String? session,
    String? formPdfUrl,
    int? totalUnits,
    List<CourseEntry>? coursesListed,
    String? submissionStatus,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? qrCodeUrl,
    bool? digitalStamp,
    DateTime? createdAt,
    String? reviewerName,
    String? studentName,
    String? studentMatric,
    String? studentDepartment,
    String? studentLevel,
  }) {
    return CourseFormModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      semester: semester ?? this.semester,
      session: session ?? this.session,
      formPdfUrl: formPdfUrl ?? this.formPdfUrl,
      totalUnits: totalUnits ?? this.totalUnits,
      coursesListed: coursesListed ?? this.coursesListed,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      digitalStamp: digitalStamp ?? this.digitalStamp,
      createdAt: createdAt ?? this.createdAt,
      reviewerName: reviewerName ?? this.reviewerName,
      studentName: studentName ?? this.studentName,
      studentMatric: studentMatric ?? this.studentMatric,
      studentDepartment: studentDepartment ?? this.studentDepartment,
      studentLevel: studentLevel ?? this.studentLevel,
    );
  }

  // ─── Convenience Getters ──────────────────────────────────────────────────
  bool get isDraft => submissionStatus == 'draft';
  bool get isSubmitted => submissionStatus == 'submitted';
  bool get isApproved => submissionStatus == 'approved';
  bool get isRejected => submissionStatus == 'rejected';
  bool get isUnderReview => submissionStatus == 'under_review';

  bool get canResubmit => isRejected;
  bool get needsAttention => isRejected;

  int get carryoverCount =>
      coursesListed.where((c) => c.isCarryover).length;

  int get regularCount =>
      coursesListed.where((c) => !c.isCarryover).length;

  String get statusDisplay {
    switch (submissionStatus) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'CourseFormModel(id: $id, student: $studentId, status: $submissionStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseFormModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

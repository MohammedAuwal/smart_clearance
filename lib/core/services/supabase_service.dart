import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../models/course_form_model.dart';
import '../../models/notification_model.dart';
import '../../models/announcement_model.dart';
import '../../models/carryover_model.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Access the Supabase client that was initialized in main.dart
  SupabaseClient get _client => Supabase.instance.client;

  // ════════════════════════════════════════════════════════════════════════════
  // USER OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Create User Profile After Firebase Registration ──────────────────────
  Future<ServiceResult<UserModel>> createUserProfile(
      UserModel user) async {
    try {
      final response = await _client
          .from('users')
          .insert(user.toJson())
          .select()
          .single();

      return ServiceResult.success(UserModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to create profile. Please try again.');
    }
  }

  Future<ServiceResult<UserModel>> getUserByEmail(String email) async {
  try {
    final response = await _client
        .from('users')
        .select()
        .eq('email', email.trim().toLowerCase())
        .single();

    return ServiceResult.success(UserModel.fromJson(response));
  } on PostgrestException catch (e) {
    return ServiceResult.error(
      _getSupabaseErrorMessage(e.code ?? '', e.message),
    );
  } catch (e) {
    return ServiceResult.error('Failed to fetch user by email.');
  }
}
  // ─── Get User By Firebase UID ─────────────────────────────────────────────
  Future<ServiceResult<UserModel>> getUserByFirebaseUid(
      String firebaseUid) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUid)
          .single();

      return ServiceResult.success(UserModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch user profile.');
    }
  }

  // ─── Get User By ID ───────────────────────────────────────────────────────
  Future<ServiceResult<UserModel>> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return ServiceResult.success(UserModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch user.');
    }
  }

  // ─── Update User Profile ──────────────────────────────────────────────────
  Future<ServiceResult<UserModel>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return ServiceResult.success(UserModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to update profile.');
    }
  }

  // ─── Get All Advisers in a Department ─────────────────────────────────────
 Future<ServiceResult<List<UserModel>>> getAdvisersByDepartment(
  String department, {
  String? level,
}) async {
  try {
    var query = _client
        .from('users')
        .select()
        .eq('department', department)
        .eq('role', 'adviser')
        .eq('is_active', true);

    if (level != null && level.trim().isNotEmpty) {
      query = query.eq('current_level', level);
    }

    final response = await query.order('full_name', ascending: true);

    final advisers = (response as List<dynamic>)
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ServiceResult.success(advisers);
  } on PostgrestException catch (e) {
    return ServiceResult.error(
      _getSupabaseErrorMessage(e.code ?? '', e.message),
    );
  } catch (e) {
    return ServiceResult.error('Failed to fetch advisers.');
  }
}

  // ════════════════════════════════════════════════════════════════════════════
  // PAYMENT OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Save Verified Payment ────────────────────────────────────────────────
  Future<ServiceResult<PaymentModel>> savePayment(
      PaymentModel payment) async {
    try {
      final response = await _client
          .from('payments')
          .insert(payment.toInsertJson())
          .select()
          .single();

      return ServiceResult.success(PaymentModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to save payment record.');
    }
  }

  // ─── Get All Payments for a Student ──────────────────────────────────────
  Future<ServiceResult<List<PaymentModel>>> getStudentPayments(
      String studentId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      final payments = (response as List<dynamic>)
          .map((item) => PaymentModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ServiceResult.success(payments);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch payment history.');
    }
  }

  // ─── Check if RRR Already Exists ─────────────────────────────────────────
  // Prevents a student from verifying the same RRR twice
  Future<bool> rrrAlreadyVerified(String rrr) async {
    try {
      final response = await _client
          .from('payments')
          .select('id')
          .eq('rrr_number', rrr)
          .eq('verification_status', 'verified');

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ─── Update Payment Receipt URL ───────────────────────────────────────────
  Future<ServiceResult<void>> updatePaymentReceipt({
    required String paymentId,
    required String receiptUrl,
  }) async {
    try {
      await _client
          .from('payments')
          .update({'receipt_url': receiptUrl})
          .eq('id', paymentId);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to update receipt.');
    }
  }

  // ─── Get Verified Students for ICT Admin ─────────────────────────────────
  Future<ServiceResult<List<Map<String, dynamic>>>>
      getVerifiedPaymentsForICT({
    required String semester,
    required String session,
  }) async {
    try {
      // Join payments with users to get student details
      final response = await _client
          .from('payments')
          .select('*, users!inner(full_name, matric_number, department, current_level)')
          .eq('semester', semester)
          .eq('session', session)
          .eq('verification_status', 'verified');

      return ServiceResult.success(
          (response as List<dynamic>).cast<Map<String, dynamic>>());
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch verified payments.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // COURSE FORM OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Submit Course Form ───────────────────────────────────────────────────
  Future<ServiceResult<CourseFormModel>> submitCourseForm(
      CourseFormModel form) async {
    try {
      final response = await _client
          .from('course_forms')
          .insert(form.toInsertJson())
          .select()
          .single();

      return ServiceResult.success(CourseFormModel.fromJson(response));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to submit course form.');
    }
  }

  // ─── Get Student's Current Semester Form ──────────────────────────────────
  Future<ServiceResult<CourseFormModel?>> getCurrentForm({
    required String studentId,
    required String semester,
    required String session,
  }) async {
    try {
      final response = await _client
          .from('course_forms')
          .select()
          .eq('student_id', studentId)
          .eq('semester', semester)
          .eq('session', session)
          .maybeSingle();

      if (response == null) return ServiceResult.success(null);

      return ServiceResult.success(
          CourseFormModel.fromJson(response as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch current form.');
    }
  }

  // ─── Get All Forms for a Student (Academic Timeline) ─────────────────────
  Future<ServiceResult<List<CourseFormModel>>> getStudentAllForms(
      String studentId) async {
    try {
      final response = await _client
          .from('course_forms')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      final forms = (response as List<dynamic>)
          .map((item) =>
              CourseFormModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ServiceResult.success(forms);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch academic timeline.');
    }
  }

  // ─── Get Submissions for an Adviser ───────────────────────────────────────
  Future<ServiceResult<List<CourseFormModel>>> getAdviserSubmissions({
    required String adviserId,
    String? statusFilter,
    String? levelFilter,
  }) async {
    try {
      var query = _client
          .from('course_forms')
          .select('''
            *,
            users!inner(
              full_name,
              matric_number,
              department,
              current_level,
              phone_number
            )
          ''')
          .eq('reviewed_by', adviserId);

      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('submission_status', statusFilter);
      }

      final response = await query.order('submitted_at', ascending: false);

      final forms = (response as List<dynamic>).map((item) {
        final map = item as Map<String, dynamic>;
        // Flatten the joined user data into the form map
        final userMap = map['users'] as Map<String, dynamic>?;
        return CourseFormModel.fromJson({
          ...map,
          'student_name': userMap?['full_name'],
          'student_matric': userMap?['matric_number'],
          'student_department': userMap?['department'],
          'student_level': userMap?['current_level'],
        });
      }).toList();

      // Filter by level if needed
      if (levelFilter != null && levelFilter != 'all') {
        return ServiceResult.success(
          forms
              .where((f) =>
                  f.studentLevel?.toLowerCase() ==
                  levelFilter.toLowerCase())
              .toList(),
        );
      }

      return ServiceResult.success(forms);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch submissions.');
    }
  }

  // ─── Approve a Course Form ────────────────────────────────────────────────
  Future<ServiceResult<void>> approveCourseForm({
    required String formId,
    required String adviserId,
    String? qrCodeUrl,
  }) async {
    try {
      await _client.from('course_forms').update({
        'submission_status': 'approved',
        'reviewed_by': adviserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'digital_stamp': true,
        'qr_code_url': qrCodeUrl,
      }).eq('id', formId);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to approve form.');
    }
  }

  // ─── Reject a Course Form ─────────────────────────────────────────────────
  Future<ServiceResult<void>> rejectCourseForm({
    required String formId,
    required String adviserId,
    required String reason,
  }) async {
    try {
      await _client.from('course_forms').update({
        'submission_status': 'rejected',
        'reviewed_by': adviserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
        'digital_stamp': false,
      }).eq('id', formId);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to reject form.');
    }
  }

  // ─── Bulk Approve Forms ───────────────────────────────────────────────────
  Future<ServiceResult<void>> bulkApproveForms({
    required List<String> formIds,
    required String adviserId,
  }) async {
    try {
      await _client.from('course_forms').update({
        'submission_status': 'approved',
        'reviewed_by': adviserId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'digital_stamp': true,
      }).inFilter('id', formIds);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to bulk approve forms.');
    }
  }

  // ─── Resubmit Rejected Form ───────────────────────────────────────────────
  Future<ServiceResult<void>> resubmitForm({
    required String formId,
    required String newPdfUrl,
  }) async {
    try {
      await _client.from('course_forms').update({
        'submission_status': 'submitted',
        'form_pdf_url': newPdfUrl,
        'rejection_reason': null,
        'reviewed_by': null,
        'reviewed_at': null,
        'submitted_at': DateTime.now().toIso8601String(),
      }).eq('id', formId);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to resubmit form.');
    }
  }

  // ─── HOD Archive Search ───────────────────────────────────────────────────
  Future<ServiceResult<List<Map<String, dynamic>>>> searchDepartmentArchive({
    required String department,
    required String searchQuery,
  }) async {
    try {
      final response = await _client
          .from('course_forms')
          .select('''
            *,
            users!inner(
              full_name,
              matric_number,
              department,
              current_level,
              phone_number,
              email
            )
          ''')
          .eq('users.department', department)
          .or(
            'users.matric_number.ilike.%$searchQuery%,'
            'users.full_name.ilike.%$searchQuery%',
          )
          .order('created_at', ascending: false);

      return ServiceResult.success(
          (response as List<dynamic>).cast<Map<String, dynamic>>());
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to search archive.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NOTIFICATION OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Create a Notification ────────────────────────────────────────────────
  Future<ServiceResult<void>> createNotification(
      NotificationModel notification) async {
    try {
      await _client
          .from('notifications')
          .insert(notification.toInsertJson());

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to send notification.');
    }
  }

  // ─── Get All Notifications for a User ────────────────────────────────────
  Future<ServiceResult<List<NotificationModel>>> getUserNotifications(
      String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (response as List<dynamic>)
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ServiceResult.success(notifications);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch notifications.');
    }
  }

  // ─── Mark Notification as Read ────────────────────────────────────────────
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      // Silently fail, not critical
    }
  }

  // ─── Mark All Notifications as Read ──────────────────────────────────────
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (e) {
      // Silently fail, not critical
    }
  }

  // ─── Get Unread Count ─────────────────────────────────────────────────────
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENT OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Post Announcement ────────────────────────────────────────────────────
  Future<ServiceResult<AnnouncementModel>> postAnnouncement(
      AnnouncementModel announcement) async {
    try {
      final response = await _client
          .from('announcements')
          .insert(announcement.toInsertJson())
          .select()
          .single();

      return ServiceResult.success(
          AnnouncementModel.fromJson(response as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to post announcement.');
    }
  }

  // ─── Get Announcements for a Student ─────────────────────────────────────
  Future<ServiceResult<List<AnnouncementModel>>> getAnnouncementsForStudent({
    required String department,
    required String level,
  }) async {
    try {
      // Normalize level string for comparison e.g "100 Level" -> "100level"
      final normalizedLevel =
          level.toLowerCase().replaceAll(' ', '');

      final response = await _client
          .from('announcements')
          .select()
          .eq('department', department)
          .eq('is_active', true)
          .or('target_audience.eq.all,target_audience.eq.$normalizedLevel')
          .order('created_at', ascending: false);

      final announcements = (response as List<dynamic>)
          .map((item) =>
              AnnouncementModel.fromJson(item as Map<String, dynamic>))
          // Filter out expired ones in Dart
          .where((a) => !a.isExpired)
          .toList();

      return ServiceResult.success(announcements);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch announcements.');
    }
  }

  // ─── Get All Announcements for HOD Management ─────────────────────────────
  Future<ServiceResult<List<AnnouncementModel>>> getDepartmentAnnouncements(
      String department) async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('department', department)
          .order('created_at', ascending: false);

      final announcements = (response as List<dynamic>)
          .map((item) =>
              AnnouncementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ServiceResult.success(announcements);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch announcements.');
    }
  }

  // ─── Deactivate Announcement ──────────────────────────────────────────────
  Future<ServiceResult<void>> deactivateAnnouncement(
      String announcementId) async {
    try {
      await _client
          .from('announcements')
          .update({'is_active': false}).eq('id', announcementId);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to deactivate announcement.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CARRYOVER OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Submit Carryover Declarations ────────────────────────────────────────
  Future<ServiceResult<void>> submitCarryoverDeclarations(
      List<CarryoverModel> declarations) async {
    try {
      final insertList =
          declarations.map((d) => d.toInsertJson()).toList();

      await _client.from('carryover_declarations').insert(insertList);

      return ServiceResult.success(null);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to submit carryover declaration.');
    }
  }

  // ─── Get Student's Carryover Declarations ─────────────────────────────────
  Future<ServiceResult<List<CarryoverModel>>> getStudentCarryovers(
      String studentId) async {
    try {
      final response = await _client
          .from('carryover_declarations')
          .select()
          .eq('student_id', studentId)
          .order('declared_at', ascending: false);

      final carryovers = (response as List<dynamic>)
          .map((item) =>
              CarryoverModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ServiceResult.success(carryovers);
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch carryover declarations.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ICT ADMIN OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Log ICT Admin Action ─────────────────────────────────────────────────
  Future<void> logIctAction({
    required String ictAdminId,
    required String actionType,
    required String targetStudentId,
    required String description,
  }) async {
    try {
      await _client.from('ict_activity_log').insert({
        'ict_admin_id': ictAdminId,
        'action_type': actionType,
        'target_student_id': targetStudentId,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log silently, do not interrupt the main flow
    }
  }

  // ─── Get ICT Activity Log ─────────────────────────────────────────────────
  Future<ServiceResult<List<Map<String, dynamic>>>> getIctActivityLog(
      String ictAdminId) async {
    try {
      final response = await _client
          .from('ict_activity_log')
          .select('''
            *,
            target_student:users!target_student_id(full_name, matric_number)
          ''')
          .eq('ict_admin_id', ictAdminId)
          .order('timestamp', ascending: false)
          .limit(100);

      return ServiceResult.success(
          (response as List<dynamic>).cast<Map<String, dynamic>>());
    } on PostgrestException catch (e) {
      return ServiceResult.error(
        _getSupabaseErrorMessage(e.code ?? '', e.message),
      );
    } catch (e) {
      return ServiceResult.error('Failed to fetch activity log.');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // REAL-TIME SUBSCRIPTIONS
  // ════════════════════════════════════════════════════════════════════════════

  // ─── Listen to Course Form Status Changes ────────────────────────────────
  // Student calls this so they get live updates without refreshing
  RealtimeChannel subscribeToCourseFormUpdates({
    required String studentId,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _client
        .channel('course_forms_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'course_forms',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ─── Listen to New Notifications ──────────────────────────────────────────
  RealtimeChannel subscribeToNotifications({
    required String userId,
    required Function(Map<String, dynamic>) onNew,
  }) {
    return _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) {
            onNew(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ─── Error Code Translation ───────────────────────────────────────────────
  String _getSupabaseErrorMessage(String code, String message) {
    switch (code) {
      case '23505':
        return 'A record with this information already exists';
      case '23503':
        return 'Related record not found';
      case '42501':
        return 'You do not have permission to perform this action';
      case 'PGRST116':
        return 'Record not found';
      default:
        if (message.contains('duplicate')) {
          return 'This record already exists';
        }
        if (message.contains('network')) {
          return 'Network error. Please check your connection';
        }
        return 'Database error. Please try again';
    }
  }
}

// ─── Service Result Wrapper ───────────────────────────────────────────────────
// Same concept as AuthResult but for Supabase operations
// Every service call returns this so UI always gets clean success/error data
class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const ServiceResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory ServiceResult.success(T data) {
    return ServiceResult._(success: true, data: data);
  }

  factory ServiceResult.error(String message) {
    return ServiceResult._(success: false, error: message);
  }

  // Convenience getter
  bool get hasError => !success;
  bool get hasData => success && data != null;
}
// ════════════════════════════════════════════════════════════════════════════
// STAFF INVITE OPERATIONS (HOD -> Staff onboarding)
// Table: staff_invites
// Columns suggested:
// id uuid pk default gen_random_uuid()
// token text unique
// email text null
// department text
// role text  (adviser, ict_admin, hod)
// assigned_level text null (only for adviser)
// is_used boolean default false
// created_by uuid
// created_at timestamp default now()
// used_by uuid null
// used_at timestamp null
// expires_at timestamp null
// ════════════════════════════════════════════════════════════════════════════

Future<ServiceResult<Map<String, dynamic>>> createStaffInvite({
  required String createdBy,
  required String department,
  required String role,
  String? assignedLevel,
  String? email,
  DateTime? expiresAt,
  required String token,
}) async {
  try {
    final response = await _client.from('staff_invites').insert({
      'token': token,
      'email': email?.trim().toLowerCase(),
      'department': department,
      'role': role,
      'assigned_level': assignedLevel,
      'is_used': false,
      'created_by': createdBy,
      'expires_at': expiresAt?.toIso8601String(),
    }).select().single();

    return ServiceResult.success(response as Map<String, dynamic>);
  } on PostgrestException catch (e) {
    return ServiceResult.error(_getSupabaseErrorMessage(e.code ?? '', e.message));
  } catch (e) {
    return ServiceResult.error('Failed to create invite. Please try again.');
  }
}

Future<ServiceResult<Map<String, dynamic>>> getStaffInviteByToken(String token) async {
  try {
    final response = await _client
        .from('staff_invites')
        .select()
        .eq('token', token.trim())
        .single();

    return ServiceResult.success(response as Map<String, dynamic>);
  } on PostgrestException catch (e) {
    return ServiceResult.error(_getSupabaseErrorMessage(e.code ?? '', e.message));
  } catch (e) {
    return ServiceResult.error('Invite not found or invalid.');
  }
}

Future<ServiceResult<void>> markStaffInviteUsed({
  required String token,
  required String usedBy,
}) async {
  try {
    await _client.from('staff_invites').update({
      'is_used': true,
      'used_by': usedBy,
      'used_at': DateTime.now().toIso8601String(),
    }).eq('token', token.trim());

    return ServiceResult.success(null);
  } on PostgrestException catch (e) {
    return ServiceResult.error(_getSupabaseErrorMessage(e.code ?? '', e.message));
  } catch (e) {
    return ServiceResult.error('Failed to update invite usage.');
  }
}

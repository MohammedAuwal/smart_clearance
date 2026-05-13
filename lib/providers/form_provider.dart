import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_form_model.dart';
import '../models/notification_model.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/helpers.dart';

// ─── Form State ───────────────────────────────────────────────────────────────
class FormState {
  final bool isLoading;
  final bool isSubmitting;
  final bool isApproving;
  final CourseFormModel? currentForm;
  final List<CourseFormModel> allForms;
  final List<CourseFormModel> adviserSubmissions;
  final String? errorMessage;
  final String? successMessage;
  final List<String> selectedFormIds; // For bulk approval

  const FormState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isApproving = false,
    this.currentForm,
    this.allForms = const [],
    this.adviserSubmissions = const [],
    this.errorMessage,
    this.successMessage,
    this.selectedFormIds = const [],
  });

  FormState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isApproving,
    CourseFormModel? currentForm,
    List<CourseFormModel>? allForms,
    List<CourseFormModel>? adviserSubmissions,
    String? errorMessage,
    String? successMessage,
    List<String>? selectedFormIds,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrentForm = false,
  }) {
    return FormState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isApproving: isApproving ?? this.isApproving,
      currentForm:
          clearCurrentForm ? null : currentForm ?? this.currentForm,
      allForms: allForms ?? this.allForms,
      adviserSubmissions:
          adviserSubmissions ?? this.adviserSubmissions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      selectedFormIds: selectedFormIds ?? this.selectedFormIds,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
  bool get hasCurrentForm => currentForm != null;
  bool get hasSelectedForms => selectedFormIds.isNotEmpty;

  // Pending submissions count for adviser badge
  int get pendingCount => adviserSubmissions
      .where((f) => f.submissionStatus == 'submitted')
      .length;

  // Get submissions filtered by status
  List<CourseFormModel> getByStatus(String status) {
    if (status == 'all') return adviserSubmissions;
    return adviserSubmissions
        .where((f) => f.submissionStatus == status)
        .toList();
  }

  // Get submissions filtered by level
  List<CourseFormModel> getByLevel(String level) {
    if (level == 'all') return adviserSubmissions;
    return adviserSubmissions
        .where((f) =>
            f.studentLevel?.toLowerCase() == level.toLowerCase())
        .toList();
  }
}

// ─── Form Notifier ────────────────────────────────────────────────────────────
class FormNotifier extends StateNotifier<FormState> {
  final SupabaseService _supabaseService;

  FormNotifier({required SupabaseService supabaseService})
      : _supabaseService = supabaseService,
        super(const FormState());

  // ─── Load Current Semester Form for Student ────────────────────────────
  Future<void> loadCurrentForm({
    required String studentId,
    required String semester,
    required String session,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _supabaseService.getCurrentForm(
      studentId: studentId,
      semester: semester,
      session: session,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        currentForm: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  // ─── Load All Forms for Student Timeline ──────────────────────────────
  Future<void> loadAllStudentForms(String studentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result =
        await _supabaseService.getStudentAllForms(studentId);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        allForms: result.data ?? [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  // ─── Submit Course Form ────────────────────────────────────────────────
  Future<bool> submitCourseForm({
    required String studentId,
    required String pdfUrl,
    required int totalUnits,
    required String adviserId,
    required String semester,
    required String session,
    List<CourseEntry> courses = const [],
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final form = CourseFormModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        semester: semester,
        session: session,
        formPdfUrl: pdfUrl,
        totalUnits: totalUnits,
        coursesListed: courses,
        submissionStatus: 'submitted',
        submittedAt: DateTime.now(),
        reviewedBy: adviserId, // Pre-assign to selected adviser
        digitalStamp: false,
        createdAt: DateTime.now(),
      );

      final result = await _supabaseService.submitCourseForm(form);

      if (result.success) {
        // Create a notification for the adviser
        await _supabaseService.createNotification(
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            recipientId: adviserId,
            title: 'New Course Form Submission',
            body: 'A student has submitted their course form for $semester. '
                'Please review.',
            type: NotificationType.form,
            isRead: false,
            relatedId: result.data?.id,
            createdAt: DateTime.now(),
          ),
        );

        state = state.copyWith(
          isSubmitting: false,
          currentForm: result.data,
          successMessage:
              'Course form submitted successfully! '
              'Your Level Adviser will review it shortly.',
        );
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: result.error ?? 'Failed to submit form.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Submission failed. Please try again.',
      );
      return false;
    }
  }

  // ─── Load Adviser Submissions ──────────────────────────────────────────
  Future<void> loadAdviserSubmissions({
    required String adviserId,
    String? statusFilter,
    String? levelFilter,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _supabaseService.getAdviserSubmissions(
      adviserId: adviserId,
      statusFilter: statusFilter,
      levelFilter: levelFilter,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        adviserSubmissions: result.data ?? [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  // ─── Approve a Single Form ─────────────────────────────────────────────
  Future<bool> approveForm({
    required String formId,
    required String adviserId,
    required String studentId,
    required String studentName,
    String? qrCodeUrl,
  }) async {
    state = state.copyWith(isApproving: true, clearError: true);

    final result = await _supabaseService.approveCourseForm(
      formId: formId,
      adviserId: adviserId,
      qrCodeUrl: qrCodeUrl,
    );

    if (result.success) {
      // Update local adviser submissions list
      final updated = state.adviserSubmissions.map((f) {
        if (f.id == formId) {
          return f.copyWith(
            submissionStatus: 'approved',
            reviewedBy: adviserId,
            reviewedAt: DateTime.now(),
            digitalStamp: true,
            qrCodeUrl: qrCodeUrl,
          );
        }
        return f;
      }).toList();

      // Notify the student
      await _supabaseService.createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          recipientId: studentId,
          title: '🎉 Course Form Approved!',
          body: 'Your course registration form has been approved by '
              'your Level Adviser. You are officially registered!',
          type: NotificationType.form,
          isRead: false,
          relatedId: formId,
          createdAt: DateTime.now(),
        ),
      );

      state = state.copyWith(
        isApproving: false,
        adviserSubmissions: updated,
        successMessage: 'Form approved. $studentName has been notified.',
      );
      return true;
    } else {
      state = state.copyWith(
        isApproving: false,
        errorMessage: result.error ?? 'Failed to approve form.',
      );
      return false;
    }
  }

  // ─── Reject a Single Form ──────────────────────────────────────────────
  Future<bool> rejectForm({
    required String formId,
    required String adviserId,
    required String studentId,
    required String rejectionReason,
  }) async {
    state = state.copyWith(isApproving: true, clearError: true);

    final result = await _supabaseService.rejectCourseForm(
      formId: formId,
      adviserId: adviserId,
      reason: rejectionReason,
    );

    if (result.success) {
      // Update local list
      final updated = state.adviserSubmissions.map((f) {
        if (f.id == formId) {
          return f.copyWith(
            submissionStatus: 'rejected',
            reviewedBy: adviserId,
            reviewedAt: DateTime.now(),
            rejectionReason: rejectionReason,
          );
        }
        return f;
      }).toList();

      // Notify the student with the reason
      await _supabaseService.createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          recipientId: studentId,
          title: 'Course Form Needs Attention',
          body: 'Your course form was returned. Reason: $rejectionReason. '
              'Please correct and resubmit.',
          type: NotificationType.form,
          isRead: false,
          relatedId: formId,
          createdAt: DateTime.now(),
        ),
      );

      state = state.copyWith(
        isApproving: false,
        adviserSubmissions: updated,
        successMessage: 'Form rejected. Student has been notified with the reason.',
      );
      return true;
    } else {
      state = state.copyWith(
        isApproving: false,
        errorMessage: result.error ?? 'Failed to reject form.',
      );
      return false;
    }
  }

  // ─── Bulk Approve Selected Forms ───────────────────────────────────────
  Future<bool> bulkApproveSelected({
    required String adviserId,
  }) async {
    if (state.selectedFormIds.isEmpty) return false;

    state = state.copyWith(isApproving: true, clearError: true);

    final result = await _supabaseService.bulkApproveForms(
      formIds: state.selectedFormIds,
      adviserId: adviserId,
    );

    if (result.success) {
      // Update local list for all selected forms
      final approvedIds = Set<String>.from(state.selectedFormIds);
      final updated = state.adviserSubmissions.map((f) {
        if (approvedIds.contains(f.id)) {
          return f.copyWith(
            submissionStatus: 'approved',
            reviewedBy: adviserId,
            reviewedAt: DateTime.now(),
            digitalStamp: true,
          );
        }
        return f;
      }).toList();

      // Send notifications to all affected students
      for (final form in state.adviserSubmissions) {
        if (approvedIds.contains(form.id)) {
          await _supabaseService.createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              recipientId: form.studentId,
              title: '🎉 Course Form Approved!',
              body: 'Your course registration form has been approved. '
                  'You are officially registered for this semester!',
              type: NotificationType.form,
              isRead: false,
              relatedId: form.id,
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      final count = approvedIds.length;
      state = state.copyWith(
        isApproving: false,
        adviserSubmissions: updated,
        selectedFormIds: [],
        successMessage:
            '$count ${count == 1 ? 'form' : 'forms'} approved successfully. '
            'All students have been notified.',
      );
      return true;
    } else {
      state = state.copyWith(
        isApproving: false,
        errorMessage: result.error ?? 'Bulk approval failed.',
      );
      return false;
    }
  }

  // ─── Toggle Form Selection for Bulk Approve ────────────────────────────
  void toggleFormSelection(String formId) {
    final current = List<String>.from(state.selectedFormIds);
    if (current.contains(formId)) {
      current.remove(formId);
    } else {
      current.add(formId);
    }
    state = state.copyWith(selectedFormIds: current);
  }

  // ─── Select All Pending Forms ──────────────────────────────────────────
  void selectAllPending() {
    final pendingIds = state.adviserSubmissions
        .where((f) => f.submissionStatus == 'submitted')
        .map((f) => f.id)
        .toList();
    state = state.copyWith(selectedFormIds: pendingIds);
  }

  // ─── Clear All Selections ──────────────────────────────────────────────
  void clearSelections() {
    state = state.copyWith(selectedFormIds: []);
  }

  // ─── Resubmit Rejected Form ────────────────────────────────────────────
  Future<bool> resubmitForm({
    required String formId,
    required String newPdfUrl,
    required String adviserId,
    required String studentId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _supabaseService.resubmitForm(
      formId: formId,
      newPdfUrl: newPdfUrl,
    );

    if (result.success) {
      // Notify adviser of resubmission
      await _supabaseService.createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          recipientId: adviserId,
          title: 'Course Form Resubmitted',
          body: 'A student has resubmitted their course form after corrections. '
              'Please review again.',
          type: NotificationType.form,
          isRead: false,
          relatedId: formId,
          createdAt: DateTime.now(),
        ),
      );

      // Update current form state
      if (state.currentForm?.id == formId) {
        state = state.copyWith(
          isSubmitting: false,
          currentForm: state.currentForm?.copyWith(
            submissionStatus: 'submitted',
            formPdfUrl: newPdfUrl,
            rejectionReason: null,
          ),
          successMessage:
              'Form resubmitted! Your Level Adviser will review it again.',
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          successMessage:
              'Form resubmitted! Your Level Adviser will review it again.',
        );
      }
      return true;
    } else {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: result.error ?? 'Resubmission failed.',
      );
      return false;
    }
  }

  // ─── Clear Helpers ─────────────────────────────────────────────────────
  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

// ─── Form Provider ────────────────────────────────────────────────────────────
final formProvider =
    StateNotifierProvider<FormNotifier, FormState>((ref) {
  return FormNotifier(supabaseService: SupabaseService());
});

// ─── Student Timeline Provider ────────────────────────────────────────────────
final studentTimelineProvider =
    FutureProvider.family<List<CourseFormModel>, String>(
        (ref, studentId) async {
  final result =
      await SupabaseService().getStudentAllForms(studentId);
  if (result.success) return result.data ?? [];
  return [];
});

// ─── Pending Submissions Count for Adviser Badge ──────────────────────────────
final pendingSubmissionsCountProvider = Provider<int>((ref) {
  return ref.watch(formProvider).pendingCount;
});

// ─── Selected Forms Count ─────────────────────────────────────────────────────
final selectedFormsCountProvider = Provider<int>((ref) {
  return ref.watch(formProvider).selectedFormIds.length;
});

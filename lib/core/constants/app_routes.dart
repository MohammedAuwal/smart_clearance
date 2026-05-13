class AppRoutes {
  // Private constructor so this class cannot be instantiated
  AppRoutes._();

  // ─── Auth Routes ─────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ─── Student Routes ──────────────────────────────────────────────────────────
  static const String studentDashboard = '/student/dashboard';
  static const String paymentVerification = '/student/payment-verification';
  static const String receiptWallet = '/student/receipt-wallet';
  static const String courseFormSubmission = '/student/course-form-submission';
  static const String formStatusTracker = '/student/form-status';
  static const String carryoverDeclaration = '/student/carryover';
  static const String academicTimeline = '/student/timeline';
  static const String notifications = '/student/notifications';
  static const String studentProfile = '/student/profile';

  // ─── Adviser Routes ──────────────────────────────────────────────────────────
  static const String adviserDashboard = '/adviser/dashboard';
  static const String submissionList = '/adviser/submissions';
  static const String studentFormDetail = '/adviser/form-detail';
  static const String bulkApproval = '/adviser/bulk-approval';
  static const String announcementCreate = '/adviser/announcement-create';
  static const String adviserProfile = '/adviser/profile';

  // ─── ICT Admin Routes ────────────────────────────────────────────────────────
  static const String ictDashboard = '/ict/dashboard';
  static const String lateRegistrationList = '/ict/late-registration';
  static const String paymentOverride = '/ict/payment-override';
  static const String activityLog = '/ict/activity-log';
  static const String ictProfile = '/ict/profile';

  // ─── HOD Routes ──────────────────────────────────────────────────────────────
  static const String hodDashboard = '/hod/dashboard';
  static const String departmentArchive = '/hod/archive';
  static const String announcementManagement = '/hod/announcements';
  static const String hodProfile = '/hod/profile';

  // ─── Route helper to get dashboard by role ───────────────────────────────────
  static String getDashboardByRole(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return studentDashboard;
      case 'adviser':
        return adviserDashboard;
      case 'ict_admin':
        return ictDashboard;
      case 'hod':
      case 'super_admin':
        return hodDashboard;
      default:
        return login;
    }
  }
}

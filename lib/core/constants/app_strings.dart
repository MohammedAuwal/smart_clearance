class AppStrings {
  // Private constructor so this class cannot be instantiated
  AppStrings._();

  // ─── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'SmartClearance';
  static const String appTagline = 'Your Campus, Paperless.';
  static const String appVersion = 'v1.0.0 MVP';

  // ─── Onboarding ──────────────────────────────────────────────────────────────
  static const String onboarding1Title = 'No More ICT Queues';
  static const String onboarding1Body =
      'Verify your school fee payment instantly with your RRR number. '
      'No more standing in long lines at the ICT office.';

  static const String onboarding2Title = 'Submit Forms Digitally';
  static const String onboarding2Body =
      'Upload your course form and send it directly to your Level Adviser '
      'from your phone. No more printing, no more cybercafe bills.';

  static const String onboarding3Title = 'Track Everything Live';
  static const String onboarding3Body =
      'Know the moment your form is approved or rejected. '
      'Get notified instantly so you are never left guessing.';

  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String next = 'Next';

  // ─── Authentication ──────────────────────────────────────────────────────────
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';

  static const String welcomeBack = 'Welcome Back';
  static const String welcomeBackSub =
      'Sign in to continue to SmartClearance';
  static const String createAccountTitle = 'Create Account';
  static const String createAccountSub =
      'Join SmartClearance and go paperless today';

  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordSub =
      'Enter your email and we will send you a reset link';
  static const String sendResetLink = 'Send Reset Link';
  static const String resetLinkSent =
      'Reset link sent! Check your email inbox.';

  // ─── Form Field Labels ───────────────────────────────────────────────────────
  static const String fullName = 'Full Name';
  static const String matricNumber = 'Matric Number';
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String phoneNumber = 'Phone Number';
  static const String department = 'Department';
  static const String faculty = 'Faculty';
  static const String level = 'Current Level';

  // ─── Form Field Hints ────────────────────────────────────────────────────────
  static const String fullNameHint = 'e.g. Chukwuemeka Obi';
  static const String matricHint = 'e.g. U20/CSC/1045';
  static const String emailHint = 'e.g. student@university.edu.ng';
  static const String passwordHint = 'Minimum 8 characters';
  static const String phoneHint = 'e.g. 08012345678';
  static const String rrrHint = 'e.g. 280012345678';

  // ─── Dashboard ───────────────────────────────────────────────────────────────
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String dashboard = 'Dashboard';
  static const String currentSemester = 'Current Semester';
  static const String quickActions = 'Quick Actions';
  static const String recentActivity = 'Recent Activity';

  // ─── Payment ─────────────────────────────────────────────────────────────────
  static const String paymentVerification = 'Payment Verification';
  static const String verifyPayment = 'Verify Payment';
  static const String rrrNumber = 'RRR Number';
  static const String enterRrr = 'Enter your Remita RRR Number';
  static const String paymentVerified = 'Payment Verified';
  static const String paymentPending = 'Payment Pending';
  static const String paymentFailed = 'Payment Failed';
  static const String verifying = 'Verifying...';
  static const String receiptWallet = 'Receipt Wallet';
  static const String noPaymentsYet = 'No payments verified yet';
  static const String noPaymentsSub =
      'Verify your school fee payment using your RRR number';
  static const String amountPaid = 'Amount Paid';
  static const String paymentDate = 'Payment Date';
  static const String semester = 'Semester';
  static const String session = 'Session';

  // ─── Course Form ─────────────────────────────────────────────────────────────
  static const String courseFormSubmission = 'Course Form Submission';
  static const String submitForm = 'Submit Form';
  static const String uploadForm = 'Upload Course Form';
  static const String uploadFormSub =
      'Upload the PDF you downloaded from SAFRecords';
  static const String selectAdviser = 'Select Your Level Adviser';
  static const String totalUnits = 'Total Credit Units';
  static const String hasCarryover = 'I have carryover course(s)';
  static const String submitting = 'Submitting...';
  static const String formSubmitted = 'Form Submitted Successfully';
  static const String formSubmittedSub =
      'Your Level Adviser will review and respond shortly';

  // ─── Form Status ─────────────────────────────────────────────────────────────
  static const String formStatus = 'Form Status';
  static const String statusTracker = 'Status Tracker';
  static const String submitted = 'Submitted';
  static const String underReview = 'Under Review';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String pending = 'Pending';
  static const String resubmit = 'Resubmit Form';
  static const String rejectionReason = 'Reason for Rejection';
  static const String noFormThisSemester = 'No form submitted this semester';
  static const String noFormSub =
      'Submit your course form to get started';

  // ─── Notifications ───────────────────────────────────────────────────────────
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications yet';
  static const String noNotificationsSub =
      'You will be notified when something needs your attention';
  static const String markAllRead = 'Mark All as Read';

  // ─── Adviser Strings ─────────────────────────────────────────────────────────
  static const String submissions = 'Submissions';
  static const String pendingReview = 'Pending Review';
  static const String approvedForms = 'Approved Forms';
  static const String bulkApprove = 'Bulk Approve';
  static const String approveSelected = 'Approve Selected';
  static const String approveForm = 'Approve Form';
  static const String rejectForm = 'Reject Form';
  static const String enterRejectionReason =
      'Please provide a reason for rejection';
  static const String rejectionReasonHint =
      'e.g. Course load exceeds allowed units for your level';
  static const String noSubmissions = 'No submissions yet';
  static const String noSubmissionsSub =
      'Student submissions will appear here';

  // ─── ICT Admin Strings ───────────────────────────────────────────────────────
  static const String lateRegistration = 'Late Registration';
  static const String lateRegistrationRequests = 'Late Registration Requests';
  static const String approveAccess = 'Approve Access';
  static const String unlockRegistration = 'Unlock Registration';
  static const String activityLog = 'Activity Log';
  static const String noLateRequests = 'No pending late requests';
  static const String paymentOverride = 'Payment Override';

  // ─── HOD Strings ─────────────────────────────────────────────────────────────
  static const String departmentArchive = 'Department Archive';
  static const String searchByMatric = 'Search by Matric Number';
  static const String searchHint = 'e.g. U20/CSC/1045';
  static const String noResults = 'No records found';
  static const String noResultsSub =
      'Try a different matric number or name';

  // ─── Announcements ───────────────────────────────────────────────────────────
  static const String announcements = 'Announcements';
  static const String createAnnouncement = 'Create Announcement';
  static const String announcementTitle = 'Announcement Title';
  static const String announcementBody = 'Message';
  static const String targetAudience = 'Target Audience';
  static const String expiryDate = 'Expiry Date';
  static const String postAnnouncement = 'Post Announcement';
  static const String noAnnouncements = 'No announcements at this time';

  // ─── Carryover ───────────────────────────────────────────────────────────────
  static const String carryoverDeclaration = 'Carryover Declaration';
  static const String declareCarryover = 'Declare Carryover Courses';
  static const String selectCarryoverCourses = 'Select your carryover courses';
  static const String noCarryover = 'No carryover courses declared';
  static const String submitDeclaration = 'Submit Declaration';

  // ─── Academic Timeline ───────────────────────────────────────────────────────
  static const String academicTimeline = 'Academic Timeline';
  static const String allSemesters = 'All Semesters';
  static const String noTimelineData = 'No academic records yet';
  static const String noTimelineDataSub =
      'Your registration history will appear here each semester';

  // ─── Profile ─────────────────────────────────────────────────────────────────
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String changePhoto = 'Change Photo';
  static const String saveChanges = 'Save Changes';
  static const String personalInfo = 'Personal Information';
  static const String academicInfo = 'Academic Information';
  static const String appSettings = 'App Settings';

  // ─── General UI ──────────────────────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String done = 'Done';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String close = 'Close';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String all = 'All';
  static const String refresh = 'Refresh';
  static const String seeAll = 'See All';
  static const String goBack = 'Go Back';
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgain = 'Please try again';
  static const String noInternetTitle = 'No Internet Connection';
  static const String noInternetSub =
      'Please check your connection and try again';

  // ─── Success Messages ────────────────────────────────────────────────────────
  static const String profileUpdated = 'Profile updated successfully';
  static const String formApproved = 'Form approved successfully';
  static const String formRejected = 'Form rejected. Student has been notified';
  static const String announcementPosted = 'Announcement posted successfully';
  static const String declarationSubmitted = 'Carryover declaration submitted';
  static const String accessGranted = 'Registration access granted';

  // ─── Error Messages ──────────────────────────────────────────────────────────
  static const String loginFailed = 'Login failed. Check your credentials';
  static const String registerFailed = 'Registration failed. Please try again';
  static const String rrrNotFound =
      'RRR not found or payment not confirmed by Remita';
  static const String uploadFailed = 'File upload failed. Please try again';
  static const String networkError =
      'Network error. Please check your connection';

  // ─── Levels ──────────────────────────────────────────────────────────────────
  static const List<String> levels = [
    '100 Level',
    '200 Level',
    '300 Level',
    '400 Level',
    '500 Level',
  ];

  // ─── Departments (customize for your university) ─────────────────────────────
  static const List<String> departments = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Biochemistry',
    'Microbiology',
    'Statistics',
    'Geology',
    'Geography',
  ];

  // ─── Faculties ───────────────────────────────────────────────────────────────
  static const List<String> faculties = [
    'Faculty of Science',
    'Faculty of Arts',
    'Faculty of Social Sciences',
    'Faculty of Law',
    'Faculty of Engineering',
    'Faculty of Education',
    'Faculty of Agriculture',
    'Faculty of Medicine',
    'Faculty of Management Sciences',
  ];

  // ─── Semesters ───────────────────────────────────────────────────────────────
  static const String firstSemester = 'First Semester';
  static const String secondSemester = 'Second Semester';
  static const String currentSession = '2024/2025';
}

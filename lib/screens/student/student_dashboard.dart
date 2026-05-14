import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../auth/login_screen.dart';
import 'academic_timeline_screen.dart';
import 'course_form_submission_screen.dart';
import 'form_status_tracker_screen.dart';
import 'notification_screen.dart';
import 'payment_verification_screen.dart';
import 'profile_screen.dart';
import 'receipt_wallet_screen.dart';
import 'student_announcements_screen.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;

        _initialized = true;

        final semester = AppHelpers.getCurrentSemester();
        final session = AppHelpers.getCurrentSession();

        ref.read(paymentProvider.notifier).loadStudentPayments(user.id);
        ref.read(formProvider.notifier).loadCurrentForm(
              studentId: user.id,
              semester: semester,
              session: session,
            );
        ref.read(notificationProvider.notifier).loadNotifications(user.id);
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    await ref.read(paymentProvider.notifier).loadStudentPayments(user.id);
    await ref.read(formProvider.notifier).loadCurrentForm(
          studentId: user.id,
          semester: semester,
          session: session,
        );
    await ref.read(notificationProvider.notifier).refresh(user.id);
  }

  Future<void> _logout() async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDangerous: true,
    );
    if (!confirm) return;

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final paymentState = ref.watch(paymentProvider);
    final formState = ref.watch(formProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    return userAsync.when(
      loading: () => const _DashboardLoading(),
      error: (e, _) => _DashboardError(message: e.toString(), onRetry: _refresh),
      data: (user) {
        if (user == null) {
          return _DashboardError(
            message: 'Session expired. Please login again.',
            onRetry: () async {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          );
        }

        final isPaid = paymentState.isPaidForSemester(semester, session);
        final currentForm = formState.currentForm;

        // Smarter course-form primary action:
        // - if not submitted or rejected => submit
        // - else => track
        final coursePrimaryLabel =
            (currentForm == null || currentForm.isRejected) ? 'Submit Form' : 'Track Status';

        final coursePrimaryAction = () {
          if (currentForm == null || currentForm.isRejected) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CourseFormSubmissionScreen()),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FormStatusTrackerScreen()),
            );
          }
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.dashboard),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _HeaderCard(
                  name: user.fullName,
                  matric: user.matricNumber,
                  department: user.department,
                  level: user.currentLevel,
                ),

                const SizedBox(height: 14),

                _StatusCard(
                  title: 'School Fee Payment',
                  subtitle: '$semester • $session',
                  statusLabel: isPaid ? 'Verified' : 'Pending',
                  statusColor: isPaid ? AppColors.success : AppColors.warning,
                  background: isPaid ? AppColors.successLight : AppColors.warningLight,
                  icon: isPaid ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                  primaryActionText: isPaid ? 'View Receipts' : 'Verify Payment',
                  onPrimaryAction: () {
                    if (isPaid) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReceiptWalletScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaymentVerificationScreen()),
                      );
                    }
                  },
                  secondaryActionText: 'Receipt Wallet',
                  onSecondaryAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReceiptWalletScreen()),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _StatusCard(
                  title: 'Course Form',
                  subtitle: '$semester • $session',
                  statusLabel: currentForm == null ? 'Not Submitted' : currentForm.statusDisplay,
                  statusColor: currentForm == null
                      ? AppColors.mediumGrey
                      : AppColors.getStatusColor(currentForm.submissionStatus),
                  background: currentForm == null
                      ? AppColors.surfaceGrey
                      : AppColors.getStatusBackgroundColor(currentForm.submissionStatus),
                  icon: currentForm == null
                      ? Icons.description_outlined
                      : currentForm.isApproved
                          ? Icons.verified_rounded
                          : currentForm.isRejected
                              ? Icons.error_outline_rounded
                              : Icons.hourglass_top_rounded,
                  primaryActionText: coursePrimaryLabel,
                  onPrimaryAction: coursePrimaryAction,
                  secondaryActionText: 'Track Status',
                  onSecondaryAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FormStatusTrackerScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Text(AppStrings.quickActions, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      title: 'Submit Form',
                      icon: Icons.upload_file_rounded,
                      color: AppColors.success,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CourseFormSubmissionScreen()),
                        );
                      },
                    ),
                    _QuickAction(
                      title: 'Timeline',
                      icon: Icons.timeline_rounded,
                      color: AppColors.info,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AcademicTimelineScreen()),
                        );
                      },
                    ),
                    _QuickAction(
                      title: 'Announcements',
                      icon: Icons.campaign_outlined,
                      color: AppColors.accentDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StudentAnnouncementsScreen()),
                        );
                      },
                    ),
                    _QuickAction(
                      title: 'Profile',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- UI widgets below unchanged (same as your previous file) ----

class _HeaderCard extends StatelessWidget {
  final String name;
  final String matric;
  final String department;
  final String level;

  const _HeaderCard({
    required this.name,
    required this.matric,
    required this.department,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              AppHelpers.getInitials(name),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppHelpers.getGreeting()},',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$matric • $department • $level',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Color background;
  final IconData icon;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String secondaryActionText;
  final VoidCallback onSecondaryAction;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.background,
    required this.icon,
    required this.primaryActionText,
    required this.onPrimaryAction,
    required this.secondaryActionText,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.darkGrey)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionText),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    child: Text(primaryActionText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mediumGrey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => onRetry(), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

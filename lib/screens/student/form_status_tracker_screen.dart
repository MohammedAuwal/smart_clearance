import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class FormStatusTrackerScreen extends ConsumerStatefulWidget {
  const FormStatusTrackerScreen({super.key});

  @override
  ConsumerState<FormStatusTrackerScreen> createState() => _FormStatusTrackerScreenState();
}

class _FormStatusTrackerScreenState extends ConsumerState<FormStatusTrackerScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) async {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;

        final semester = AppHelpers.getCurrentSemester();
        final session = AppHelpers.getCurrentSession();

        await ref.read(formProvider.notifier).loadCurrentForm(
              studentId: user.id,
              semester: semester,
              session: session,
            );
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    await ref.read(formProvider.notifier).loadCurrentForm(
          studentId: user.id,
          semester: semester,
          session: session,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formProvider);

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.formStatus),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Semester',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$semester • $session',
                      style: const TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (formState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (formState.currentForm == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: const [
                      Icon(Icons.description_outlined, size: 42, color: AppColors.lightGrey),
                      SizedBox(height: 10),
                      Text(
                        AppStrings.noFormThisSemester,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppStrings.noFormSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mediumGrey,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _FormStatusView(
                status: formState.currentForm!.submissionStatus,
                rejectionReason: formState.currentForm!.rejectionReason,
                submittedAt: formState.currentForm!.submittedAt,
                reviewedAt: formState.currentForm!.reviewedAt,
              ),
          ],
        ),
      ),
    );
  }
}

class _FormStatusView extends StatelessWidget {
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const _FormStatusView({
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.reviewedAt,
  });

  @override
  Widget build(BuildContext context) {
    final props = AppHelpers.getStatusProps(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: props.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: props.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Form Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        props.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: props.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Timeline
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 14),
                _TimelineItem(
                  title: 'Submitted',
                  isDone: status != 'draft',
                  subtitle: submittedAt == null ? null : AppHelpers.formatDateTime(submittedAt!),
                ),
                _TimelineItem(
                  title: 'Under Review',
                  isDone: status == 'under_review' || status == 'approved' || status == 'rejected',
                  subtitle: status == 'under_review' ? 'Your adviser is reviewing it' : null,
                ),
                _TimelineItem(
                  title: status == 'rejected' ? 'Rejected' : 'Approved',
                  isDone: status == 'approved' || status == 'rejected',
                  subtitle: reviewedAt == null ? null : AppHelpers.formatDateTime(reviewedAt!),
                  isError: status == 'rejected',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (status == 'rejected' && (rejectionReason ?? '').trim().isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.rejectionReason,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rejectionReason!,
                    style: const TextStyle(
                      color: AppColors.mediumGrey,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      case 'under_review':
        return Icons.hourglass_top_rounded;
      case 'submitted':
        return Icons.mark_email_read_rounded;
      default:
        return Icons.description_outlined;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final bool isDone;
  final bool isError;
  final String? subtitle;

  const _TimelineItem({
    required this.title,
    required this.isDone,
    this.isError = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? AppColors.error
        : isDone
            ? AppColors.success
            : AppColors.lightGrey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : Icons.circle,
              size: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGrey,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

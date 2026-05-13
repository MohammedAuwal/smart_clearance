import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/course_form_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class StudentFormDetailScreen extends ConsumerStatefulWidget {
  final CourseFormModel form;

  const StudentFormDetailScreen({super.key, required this.form});

  @override
  ConsumerState<StudentFormDetailScreen> createState() => _StudentFormDetailScreenState();
}

class _StudentFormDetailScreenState extends ConsumerState<StudentFormDetailScreen> {
  Future<void> _approve() async {
    final adviser = await ref.read(currentUserProvider.future);
    if (adviser == null) return;

    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Approve Form',
      message: 'Approve this course form for ${widget.form.studentName ?? 'this student'}?',
      confirmText: 'Approve',
    );
    if (!confirm) return;

    final ok = await ref.read(formProvider.notifier).approveForm(
          formId: widget.form.id,
          adviserId: adviser.id,
          studentId: widget.form.studentId,
          studentName: widget.form.studentName ?? 'Student',
          qrCodeUrl: null,
        );

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Form approved successfully.', isSuccess: true);
      Navigator.of(context).pop();
    } else {
      final err = ref.read(formProvider).errorMessage;
      AppHelpers.showSnackBar(context, message: err ?? 'Approval failed.', isError: true);
      ref.read(formProvider.notifier).clearError();
    }
  }

  Future<void> _reject() async {
    final adviser = await ref.read(currentUserProvider.future);
    if (adviser == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Form'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter reason (e.g. course load exceeds allowed units)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final r = controller.text.trim();
              final err = Validators.validateRejectionReason(r);
              if (err != null) {
                AppHelpers.showSnackBar(context, message: err, isError: true);
                return;
              }
              Navigator.pop(context, r);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    final ok = await ref.read(formProvider.notifier).rejectForm(
          formId: widget.form.id,
          adviserId: adviser.id,
          studentId: widget.form.studentId,
          rejectionReason: reason,
        );

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Form rejected and student notified.', isSuccess: true);
      Navigator.of(context).pop();
    } else {
      final err = ref.read(formProvider).errorMessage;
      AppHelpers.showSnackBar(context, message: err ?? 'Rejection failed.', isError: true);
      ref.read(formProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(formProvider).isApproving;

    final props = AppHelpers.getStatusProps(widget.form.submissionStatus);

    return Scaffold(
      appBar: AppBar(title: const Text('Form Detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 10),
                  _kv('Name', widget.form.studentName ?? '—'),
                  _kv('Matric', widget.form.studentMatric ?? '—'),
                  _kv('Level', widget.form.studentLevel ?? '—'),
                  _kv('Dept', widget.form.studentDepartment ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submission',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 10),
                  _kv('Semester', widget.form.semester),
                  _kv('Session', widget.form.session),
                  _kv('Total Units', widget.form.totalUnits.toString()),
                  Row(
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text(
                          'Status',
                          style: TextStyle(fontSize: 12, color: AppColors.mediumGrey, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: props.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          props.label,
                          style: TextStyle(color: props.color, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Course Form PDF Link',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    widget.form.formPdfUrl,
                    style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: widget.form.formPdfUrl));
                      if (!context.mounted) return;
                      AppHelpers.showSnackBar(context, message: 'PDF link copied.');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (widget.form.submissionStatus == 'submitted' ||
              widget.form.submissionStatus == 'under_review') ...[
            ElevatedButton(
              onPressed: isBusy ? null : _approve,
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Approve'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isBusy ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Reject'),
            ),
          ],

          if (widget.form.isRejected && (widget.form.rejectionReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.form.rejectionReason!,
                      style: const TextStyle(color: AppColors.mediumGrey, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

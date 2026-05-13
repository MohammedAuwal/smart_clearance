import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/course_form_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class AcademicTimelineScreen extends ConsumerStatefulWidget {
  const AcademicTimelineScreen({super.key});

  @override
  ConsumerState<AcademicTimelineScreen> createState() => _AcademicTimelineScreenState();
}

class _AcademicTimelineScreenState extends ConsumerState<AcademicTimelineScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;

        ref.read(formProvider.notifier).loadAllStudentForms(user.id);
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(formProvider.notifier).loadAllStudentForms(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Timeline'),
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
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.allForms.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      SizedBox(height: 40),
                      Icon(Icons.timeline_rounded, size: 52, color: AppColors.lightGrey),
                      SizedBox(height: 14),
                      Text(
                        'No academic records yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your submitted course forms will appear here semester by semester.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mediumGrey, height: 1.6),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: state.allForms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final form = state.allForms[index];
                      return _TimelineCard(
                        form: form,
                        onTap: () => _showDetails(form),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _showDetails(CourseFormModel form) async {
    final props = AppHelpers.getStatusProps(form.submissionStatus);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: props.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    form.isApproved
                        ? Icons.verified_rounded
                        : form.isRejected
                            ? Icons.error_outline_rounded
                            : Icons.description_outlined,
                    color: props.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${form.semester} • ${form.session}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        props.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: props.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _kv('Total Units', form.totalUnits.toString()),
            if (form.submittedAt != null)
              _kv('Submitted', AppHelpers.formatDateTime(form.submittedAt!)),
            if (form.reviewedAt != null)
              _kv('Reviewed', AppHelpers.formatDateTime(form.reviewedAt!)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'PDF Link',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: SelectableText(
                form.formPdfUrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mediumGrey,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: form.formPdfUrl));
                      if (!context.mounted) return;
                      AppHelpers.showSnackBar(context, message: 'PDF link copied.');
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Link'),
                  ),
                ),
              ],
            ),
            if (form.isRejected && (form.rejectionReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      form.rejectionReason!,
                      style: const TextStyle(
                        color: AppColors.darkGrey,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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

class _TimelineCard extends StatelessWidget {
  final CourseFormModel form;
  final VoidCallback onTap;

  const _TimelineCard({required this.form, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final props = AppHelpers.getStatusProps(form.submissionStatus);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: props.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            form.isApproved
                ? Icons.verified_rounded
                : form.isRejected
                    ? Icons.error_outline_rounded
                    : Icons.description_outlined,
            color: props.color,
          ),
        ),
        title: Text(
          '${form.semester} • ${form.session}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.darkGrey,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          'Units: ${form.totalUnits}',
          style: const TextStyle(
            color: AppColors.mediumGrey,
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: props.background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            props.label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: props.color,
              fontSize: 12,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/course_form_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class ResubmitFormScreen extends ConsumerStatefulWidget {
  final CourseFormModel form;

  const ResubmitFormScreen({super.key, required this.form});

  @override
  ConsumerState<ResubmitFormScreen> createState() => _ResubmitFormScreenState();
}

class _ResubmitFormScreenState extends ConsumerState<ResubmitFormScreen> {
  File? _selectedPdf;
  String? _selectedPdfName;

  bool _uploading = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    setState(() {
      _selectedPdf = File(file.path!);
      _selectedPdfName = file.name;
    });
  }

  Future<void> _resubmit() async {
    FocusScope.of(context).unfocus();

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      AppHelpers.showSnackBar(context, message: 'Please login again.', isError: true);
      return;
    }

    final adviserId = widget.form.reviewedBy;
    if (adviserId == null || adviserId.trim().isEmpty) {
      AppHelpers.showSnackBar(
        context,
        message: 'No adviser assigned to this form. Contact your department.',
        isError: true,
      );
      return;
    }

    if (_selectedPdf == null) {
      AppHelpers.showSnackBar(context, message: 'Please select your corrected PDF.', isError: true);
      return;
    }

    setState(() => _uploading = true);

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();
    final fileTag = 'resub_${DateTime.now().millisecondsSinceEpoch}';

    // 1) Upload corrected PDF
    final upload = await CloudinaryService().uploadCourseFormPdf(
      file: _selectedPdf!,
      studentMatric: user.matricNumber,
      semester: semester,
      session: session,
      fileTag: fileTag,
    );

    if (!mounted) return;

    if (!upload.success || !upload.hasUrl) {
      setState(() => _uploading = false);
      AppHelpers.showSnackBar(
        context,
        message: upload.error ?? 'Upload failed. Please try again.',
        isError: true,
      );
      return;
    }

    // 2) Resubmit in Supabase + notify adviser
    final ok = await ref.read(formProvider.notifier).resubmitForm(
          formId: widget.form.id,
          newPdfUrl: upload.url!,
          adviserId: adviserId,
          studentId: user.id,
        );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Form resubmitted successfully.', isSuccess: true);
      Navigator.of(context).pop(true); // return success to tracker screen
    } else {
      final err = ref.read(formProvider).errorMessage;
      AppHelpers.showSnackBar(context, message: err ?? 'Resubmission failed.', isError: true);
      ref.read(formProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = (widget.form.rejectionReason ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Resubmit Form')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (reason.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason for Rejection',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: const TextStyle(color: AppColors.darkGrey, height: 1.6),
                  ),
                ],
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
                    'Corrected Course Form PDF',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: _uploading ? null : _pickPdf,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_rounded, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedPdfName ?? 'Tap to select corrected PDF',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _uploading ? null : _resubmit,
                    child: _uploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Resubmit to Adviser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

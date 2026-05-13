import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class CourseFormSubmissionScreen extends ConsumerStatefulWidget {
  const CourseFormSubmissionScreen({super.key});

  @override
  ConsumerState<CourseFormSubmissionScreen> createState() =>
      _CourseFormSubmissionScreenState();
}

class _CourseFormSubmissionScreenState
    extends ConsumerState<CourseFormSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _totalUnitsController = TextEditingController();

  File? _selectedPdf;
  String? _selectedPdfName;

  List<UserModel> _advisers = [];
  bool _loadingAdvisers = false;
  String? _selectedAdviserId;

  @override
  void dispose() {
    _totalUnitsController.dispose();
    super.dispose();
  }

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

  Future<void> _loadAdvisersIfNeeded(UserModel user) async {
    if (_advisers.isNotEmpty || _loadingAdvisers) return;

    setState(() => _loadingAdvisers = true);

    final result = await SupabaseService().getAdvisersByDepartment(user.department);

    if (!mounted) return;

    setState(() {
      _loadingAdvisers = false;
      _advisers = result.data ?? [];
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      AppHelpers.showSnackBar(context, message: 'Please login again.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedPdf == null) {
      AppHelpers.showSnackBar(context, message: 'Please select your course form PDF.', isError: true);
      return;
    }

    if (_selectedAdviserId == null) {
      AppHelpers.showSnackBar(context, message: 'Please select your Level Adviser.', isError: true);
      return;
    }

    final totalUnits = int.tryParse(_totalUnitsController.text.trim());
    if (totalUnits == null) {
      AppHelpers.showSnackBar(context, message: 'Enter valid total units.', isError: true);
      return;
    }

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    // 1) Upload PDF to Cloudinary
    AppHelpers.showLoadingDialog(context, message: 'Uploading PDF...');
    final upload = await CloudinaryService().uploadCourseFormPdf(
      file: _selectedPdf!,
      studentMatric: user.matricNumber,
      semester: semester,
      session: session,
    );
    AppHelpers.hideLoadingDialog(context);

    if (!mounted) return;

    if (!upload.success || !upload.hasUrl) {
      AppHelpers.showSnackBar(
        context,
        message: upload.error ?? 'Upload failed. Please try again.',
        isError: true,
      );
      return;
    }

    // 2) Submit form record to Supabase
    AppHelpers.showLoadingDialog(context, message: 'Submitting form...');
    final ok = await ref.read(formProvider.notifier).submitCourseForm(
          studentId: user.id,
          pdfUrl: upload.url!,
          totalUnits: totalUnits,
          adviserId: _selectedAdviserId!,
          semester: semester,
          session: session,
        );
    AppHelpers.hideLoadingDialog(context);

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Form submitted successfully.', isSuccess: true);
      Navigator.of(context).pop();
    } else {
      final err = ref.read(formProvider).errorMessage;
      AppHelpers.showSnackBar(context, message: err ?? 'Failed to submit form.', isError: true);
      ref.read(formProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.courseFormSubmission)),
      body: FutureBuilder<UserModel?>(
        future: ref.read(currentUserProvider.future),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (user == null) {
            return const Center(child: Text('Please login again.'));
          }

          _loadAdvisersIfNeeded(user);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Course Form (PDF)',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkGrey),
                        ),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: _pickPdf,
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
                                    _selectedPdfName ?? 'Tap to select PDF',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGrey,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          AppStrings.totalUnits,
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _totalUnitsController,
                          keyboardType: TextInputType.number,
                          validator: Validators.validateCreditUnits,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 18',
                            prefixIcon: Icon(Icons.calculate_outlined),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          AppStrings.selectAdviser,
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        _loadingAdvisers
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(color: AppColors.primary),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedAdviserId,
                                validator: (v) => Validators.validateDropdown(v, 'Level Adviser'),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.person_search_outlined),
                                ),
                                hint: const Text('Select Adviser'),
                                items: _advisers
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a.id,
                                        child: Text('${a.fullName} (${a.currentLevel})'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedAdviserId = v),
                              ),

                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: formState.isSubmitting ? null : _submit,
                          child: formState.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(AppStrings.submitForm),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

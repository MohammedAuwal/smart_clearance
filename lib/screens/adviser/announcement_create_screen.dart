import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/services/supabase_service.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  const AnnouncementCreateScreen({super.key});

  @override
  ConsumerState<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState
    extends ConsumerState<AnnouncementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  bool _isPosting = false;

  // Stored values in DB: all, 100level, 200level...
  String _target = 'all';
  DateTime? _expiry;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _expiry ?? now,
    );
    if (picked == null) return;
    setState(() => _expiry = picked);
  }

  Future<void> _post() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      AppHelpers.showSnackBar(context, message: 'Please login again.', isError: true);
      return;
    }

    setState(() => _isPosting = true);

    final model = AnnouncementModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postedBy: user.id,
      title: _title.text.trim(),
      body: _body.text.trim(),
      targetAudience: _target,
      department: user.department,
      isActive: true,
      createdAt: DateTime.now(),
      expiresAt: _expiry,
    );

    final result = await SupabaseService().postAnnouncement(model);

    if (!mounted) return;

    setState(() => _isPosting = false);

    if (result.success) {
      AppHelpers.showSnackBar(context, message: 'Announcement posted.', isSuccess: true);
      Navigator.of(context).pop();
    } else {
      AppHelpers.showSnackBar(
        context,
        message: result.error ?? 'Failed to post announcement.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Announcement')),
      body: ListView(
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
                    const Text('Title',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      validator: Validators.validateAnnouncementTitle,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Course form deadline extended',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Message',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _body,
                      maxLines: 5,
                      validator: Validators.validateAnnouncementBody,
                      decoration: const InputDecoration(
                        hintText: 'Type the announcement message...',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Target Audience',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _target,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Students')),
                        DropdownMenuItem(value: '100level', child: Text('100 Level')),
                        DropdownMenuItem(value: '200level', child: Text('200 Level')),
                        DropdownMenuItem(value: '300level', child: Text('300 Level')),
                        DropdownMenuItem(value: '400level', child: Text('400 Level')),
                        DropdownMenuItem(value: '500level', child: Text('500 Level')),
                      ],
                      onChanged: (v) => setState(() => _target = v ?? 'all'),
                    ),

                    const SizedBox(height: 16),
                    const Text('Expiry (optional)',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickExpiry,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _expiry == null
                                    ? 'Tap to pick expiry date'
                                    : AppHelpers.formatDateLong(_expiry!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                            ),
                            if (_expiry != null)
                              IconButton(
                                onPressed: () => setState(() => _expiry = null),
                                icon: const Icon(Icons.close_rounded, color: AppColors.lightGrey),
                                tooltip: 'Clear expiry',
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _isPosting ? null : _post,
                      child: _isPosting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Post Announcement'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

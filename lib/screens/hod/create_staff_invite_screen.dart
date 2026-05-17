import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class CreateStaffInviteScreen extends ConsumerStatefulWidget {
  const CreateStaffInviteScreen({super.key});

  @override
  ConsumerState<CreateStaffInviteScreen> createState() => _CreateStaffInviteScreenState();
}

class _CreateStaffInviteScreenState extends ConsumerState<CreateStaffInviteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  String _role = 'adviser'; // adviser | ict_admin | hod
  String? _assignedLevel; // only for adviser
  DateTime? _expiresAt;

  bool _loading = false;
  String? _lastToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _generateToken({int length = 10}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing O/0, I/1
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
    );
    if (picked == null) return;
    setState(() => _expiresAt = picked);
  }

  Future<void> _createInvite() async {
    FocusScope.of(context).unfocus();

    final hod = await ref.read(currentUserProvider.future);
    if (hod == null) return;

    if (!_formKey.currentState!.validate()) return;

    // Adviser must have assigned level
    if (_role == 'adviser' && _assignedLevel == null) {
      AppHelpers.showSnackBar(context, message: 'Select adviser level.', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _lastToken = null;
    });

    final token = _generateToken();

    final result = await SupabaseService().createStaffInvite(
      createdBy: hod.id,
      department: hod.department,
      role: _role,
      assignedLevel: _role == 'adviser' ? _assignedLevel : null,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      expiresAt: _expiresAt,
      token: token,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.success) {
      setState(() => _lastToken = token);
      AppHelpers.showSnackBar(context, message: 'Invite created. Copy and send to staff.', isSuccess: true);
    } else {
      AppHelpers.showSnackBar(context, message: result.error ?? 'Failed to create invite.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hodAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Staff Invite')),
      body: hodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hod) {
          if (hod == null) return const Center(child: Text('Please login again.'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Department',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hod.department,
                        style: const TextStyle(color: AppColors.mediumGrey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Role', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _role,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                          items: const [
                            DropdownMenuItem(value: 'adviser', child: Text('Level Adviser')),
                            DropdownMenuItem(value: 'ict_admin', child: Text('ICT Admin')),
                            DropdownMenuItem(value: 'hod', child: Text('HOD')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _role = v ?? 'adviser';
                              if (_role != 'adviser') _assignedLevel = null;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        if (_role == 'adviser') ...[
                          const Text('Assigned Level', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _assignedLevel,
                            validator: (v) => _role == 'adviser'
                                ? Validators.validateDropdown(v, 'Assigned Level')
                                : null,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.stairs_rounded)),
                            items: AppStrings.levels
                                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) => setState(() => _assignedLevel = v),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Text('Staff Email (optional)', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return Validators.validateEmail(v);
                          },
                          decoration: const InputDecoration(
                            hintText: 'staff@school.edu.ng',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text('Expiry (optional)', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickExpiry,
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
                                const Icon(Icons.event_outlined, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _expiresAt == null
                                        ? 'Tap to select expiry date'
                                        : AppHelpers.formatDateLong(_expiresAt!),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (_expiresAt != null)
                                  IconButton(
                                    onPressed: () => setState(() => _expiresAt = null),
                                    icon: const Icon(Icons.close_rounded, color: AppColors.lightGrey),
                                  )
                                else
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        ElevatedButton.icon(
                          onPressed: _loading ? null : _createInvite,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Icon(Icons.key_rounded, color: Colors.white),
                          label: const Text('Create Invite Code'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_lastToken != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invite Code', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.successBorder),
                          ),
                          child: SelectableText(
                            _lastToken!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: _lastToken!));
                            if (!context.mounted) return;
                            AppHelpers.showSnackBar(context, message: 'Invite code copied.');
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy Code'),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share this code with staff. They will register using the Staff Registration screen.',
                          style: TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

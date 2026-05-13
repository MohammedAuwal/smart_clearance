import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AssignLevelAdviserScreen extends ConsumerStatefulWidget {
  const AssignLevelAdviserScreen({super.key});

  @override
  ConsumerState<AssignLevelAdviserScreen> createState() =>
      _AssignLevelAdviserScreenState();
}

class _AssignLevelAdviserScreenState
    extends ConsumerState<AssignLevelAdviserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  String? _selectedLevel;

  bool _loading = false;
  String? _error;

  List<UserModel> _currentAdvisers = [];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAdvisers(String department) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await SupabaseService().getAdvisersByDepartment(
      department,
      // no level filter here; we want to show all advisers
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (res.success) {
        _currentAdvisers = res.data ?? [];
      } else {
        _error = res.error ?? 'Failed to load advisers.';
      }
    });
  }

  Future<void> _assign() async {
    FocusScope.of(context).unfocus();

    final hod = await ref.read(currentUserProvider.future);
    if (hod == null) {
      AppHelpers.showSnackBar(context, message: 'Please login again.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final level = _selectedLevel!;

    // Find user by email
    final findRes = await SupabaseService().getUserByEmail(email);

    if (!mounted) return;

    if (!findRes.success || findRes.data == null) {
      setState(() {
        _loading = false;
        _error = findRes.error ?? 'User not found with this email.';
      });
      return;
    }

    final user = findRes.data!;

    // Security: HOD can only assign within own department
    if (user.department != hod.department) {
      setState(() {
        _loading = false;
        _error =
            'This user is not in your department.\n'
            'User department: ${user.department}\n'
            'Your department: ${hod.department}';
      });
      return;
    }

    // Extra safety: stop HOD from accidentally converting a student account
    // (MVP heuristic: if matric number looks like a student matric, warn)
    final isLikelyStudent = user.matricNumber.contains('/');
    if (isLikelyStudent && user.role == 'student') {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(
        context,
        message:
            'This looks like a student account. Do not assign students as advisers.',
        isError: true,
      );
      return;
    }

    // Update user to adviser role + assign level
    final updateRes = await SupabaseService().updateUserProfile(
      userId: user.id,
      updates: {
        'role': 'adviser',
        'current_level': level, // level they advise (MVP design)
        'is_active': true,
      },
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (updateRes.success) {
      AppHelpers.showSnackBar(
        context,
        message: 'Assigned successfully: ${user.fullName} → $level Adviser',
        isSuccess: true,
      );
      _emailController.clear();
      setState(() => _selectedLevel = null);

      await _loadCurrentAdvisers(hod.department);
    } else {
      setState(() => _error = updateRes.error ?? 'Assignment failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hodAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Level Adviser')),
      body: hodAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hod) {
          if (hod == null) return const Center(child: Text('Please login again.'));

          // Load advisers once per open
          if (_currentAdvisers.isEmpty && !_loading && _error == null) {
            // ignore: discarded_futures
            _loadCurrentAdvisers(hod.department);
          }

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
                        'Assign by Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Department: ${hod.department}',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 14),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                              decoration: const InputDecoration(
                                hintText: 'Staff email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedLevel,
                              validator: (v) => Validators.validateDropdown(v, 'Level'),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.stairs_rounded),
                              ),
                              hint: const Text('Select level (they will advise this level)'),
                              items: AppStrings.levels
                                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedLevel = v),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _assign,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                              label: const Text('Assign Adviser'),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.errorBorder),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.darkGrey,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Text(
                        'Current Advisers',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loading ? null : () => _loadCurrentAdvisers(hod.department),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_currentAdvisers.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(
                    child: Text(
                      'No advisers found in this department.',
                      style: TextStyle(color: AppColors.mediumGrey),
                    ),
                  ),
                )
              else
                ..._currentAdvisers.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                        title: Text(
                          a.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${a.email}\nAssigned Level: ${a.currentLevel}',
                          style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

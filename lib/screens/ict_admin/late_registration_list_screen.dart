import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class LateRegistrationListScreen extends ConsumerStatefulWidget {
  const LateRegistrationListScreen({super.key});

  @override
  ConsumerState<LateRegistrationListScreen> createState() => _LateRegistrationListScreenState();
}

class _LateRegistrationListScreenState extends ConsumerState<LateRegistrationListScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _verifiedPayments = [];
  final Set<String> _processedStudentIds = {}; // local UI-only

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    final result = await SupabaseService().getVerifiedPaymentsForICT(
      semester: semester,
      session: session,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _verifiedPayments = result.data ?? [];
      } else {
        _error = result.error ?? 'Failed to load verified payments.';
      }
    });
  }

  Map<String, dynamic>? _studentFromPayment(Map<String, dynamic> paymentRow) {
    // Supabase join returns "users": { ... }
    final u = paymentRow['users'];
    if (u is Map<String, dynamic>) return u;
    return null;
  }

  Future<void> _grantAccessForRow(Map<String, dynamic> row) async {
    final ict = await ref.read(currentUserProvider.future);
    if (ict == null) return;

    final student = _studentFromPayment(row);
    final studentName = student?['full_name']?.toString() ?? 'Student';
    final matric = student?['matric_number']?.toString() ?? '';
    final studentId = row['student_id']?.toString();

    if (studentId == null || studentId.isEmpty) {
      AppHelpers.showSnackBar(context, message: 'Invalid student record.', isError: true);
      return;
    }

    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Grant Late Registration Access',
      message: 'Grant access for $studentName ($matric)?\n\nThis will be logged.',
      confirmText: 'Grant',
    );
    if (!confirm) return;

    await SupabaseService().logIctAction(
      ictAdminId: ict.id,
      actionType: 'unlocked',
      targetStudentId: studentId,
      description: 'Granted late registration access (MVP log only). Matric: $matric',
    );

    if (!mounted) return;

    setState(() => _processedStudentIds.add(studentId));
    AppHelpers.showSnackBar(context, message: 'Access granted (logged).', isSuccess: true);
  }

  Future<void> _bulkGrant() async {
    final ict = await ref.read(currentUserProvider.future);
    if (ict == null) return;

    if (_verifiedPayments.isEmpty) return;

    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Bulk Grant Access',
      message:
          'Grant late registration access for ALL verified students shown here?\n\nThis will only log actions for MVP.',
      confirmText: 'Grant All',
      isDangerous: false,
    );
    if (!confirm) return;

    int done = 0;
    for (final row in _verifiedPayments) {
      final studentId = row['student_id']?.toString();
      final student = _studentFromPayment(row);
      final matric = student?['matric_number']?.toString() ?? '';

      if (studentId == null || studentId.isEmpty) continue;
      if (_processedStudentIds.contains(studentId)) continue;

      await SupabaseService().logIctAction(
        ictAdminId: ict.id,
        actionType: 'unlocked',
        targetStudentId: studentId,
        description: 'Bulk granted late registration access (MVP log only). Matric: $matric',
      );

      _processedStudentIds.add(studentId);
      done++;
    }

    if (!mounted) return;
    setState(() {});
    AppHelpers.showSnackBar(context, message: 'Granted (logged) for $done student(s).', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final semester = AppHelpers.getCurrentSemester();
    final session = AppHelpers.getCurrentSession();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Late Registration (MVP)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
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
                    'Verified Payments',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$semester • $session',
                    style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: ${_verifiedPayments.length}',
                          style: const TextStyle(color: AppColors.mediumGrey, fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _verifiedPayments.isEmpty ? null : _bulkGrant,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Grant All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(_error!, style: const TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else if (_verifiedPayments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No verified payments found.', style: TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else
            ..._verifiedPayments.map((row) {
              final student = _studentFromPayment(row);
              final name = student?['full_name']?.toString() ?? 'Student';
              final matric = student?['matric_number']?.toString() ?? '';
              final level = student?['current_level']?.toString() ?? '';
              final dept = student?['department']?.toString() ?? '';
              final studentId = row['student_id']?.toString() ?? '';
              final rrr = row['rrr_number']?.toString() ?? '';
              final processed = _processedStudentIds.contains(studentId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: processed ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        processed ? Icons.check_rounded : Icons.lock_open_rounded,
                        color: processed ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$matric • $level\n$dept\nRRR: $rrr',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                      ),
                    ),
                    trailing: processed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Granted',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => _grantAccessForRow(row),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(110, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Grant'),
                          ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

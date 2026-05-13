import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';

class BulkApprovalScreen extends ConsumerStatefulWidget {
  const BulkApprovalScreen({super.key});

  @override
  ConsumerState<BulkApprovalScreen> createState() => _BulkApprovalScreenState();
}

class _BulkApprovalScreenState extends ConsumerState<BulkApprovalScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;

        ref.read(formProvider.notifier).loadAdviserSubmissions(
              adviserId: user.id,
              statusFilter: 'submitted',
            );
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    await ref.read(formProvider.notifier).loadAdviserSubmissions(
          adviserId: user.id,
          statusFilter: 'submitted',
        );
  }

  Future<void> _approveSelected() async {
    final adviser = await ref.read(currentUserProvider.future);
    if (adviser == null) return;

    final count = ref.read(selectedFormsCountProvider);

    if (count == 0) {
      AppHelpers.showSnackBar(context, message: 'Select at least one form.');
      return;
    }

    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Bulk Approve',
      message: 'Approve $count selected form(s)?',
      confirmText: 'Approve',
    );
    if (!confirm) return;

    final ok = await ref.read(formProvider.notifier).bulkApproveSelected(
          adviserId: adviser.id,
        );

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Approved $count form(s).', isSuccess: true);
      await _refresh();
    } else {
      final err = ref.read(formProvider).errorMessage;
      AppHelpers.showSnackBar(context, message: err ?? 'Bulk approval failed.', isError: true);
      ref.read(formProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(formProvider);
    final selectedCount = ref.watch(selectedFormsCountProvider);

    final pending = state.adviserSubmissions
        .where((f) => f.submissionStatus == 'submitted')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Approval'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderGrey)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: selectedCount == 0
                    ? null
                    : () => ref.read(formProvider.notifier).clearSelections(),
                child: Text('Clear ($selectedCount)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: state.isApproving ? null : _approveSelected,
                child: state.isApproving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Approve ($selectedCount)'),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pending: ${pending.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: pending.isEmpty
                          ? null
                          : () => ref.read(formProvider.notifier).selectAllPending(),
                      icon: const Icon(Icons.select_all_rounded),
                      label: const Text('Select All'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No pending submissions.', style: TextStyle(color: AppColors.mediumGrey)),
                ),
              )
            else
              ...pending.map((f) {
                final isSelected = state.selectedFormIds.contains(f.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => ref.read(formProvider.notifier).toggleFormSelection(f.id),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        f.studentName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${f.studentMatric ?? ''}\n${f.semester} • ${f.session}',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

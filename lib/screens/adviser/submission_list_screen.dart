import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/course_form_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import 'student_form_detail_screen.dart';

class SubmissionListScreen extends ConsumerStatefulWidget {
  const SubmissionListScreen({super.key});

  @override
  ConsumerState<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends ConsumerState<SubmissionListScreen> {
  bool _initialized = false;

  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;
        _load(user.id);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String adviserId) async {
    await ref.read(formProvider.notifier).loadAdviserSubmissions(
          adviserId: adviserId,
          statusFilter: _statusFilter == 'all' ? null : _statusFilter,
        );
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await _load(user.id);
  }

  List<CourseFormModel> _applySearch(List<CourseFormModel> list) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((f) {
      final name = (f.studentName ?? '').toLowerCase();
      final matric = (f.studentMatric ?? '').toLowerCase();
      return name.contains(q) || matric.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(formProvider);

    final filtered = _applySearch(formState.adviserSubmissions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by student name or matric',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),

            const SizedBox(height: 12),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', 'all'),
                  _chip('Submitted', 'submitted'),
                  _chip('Approved', 'approved'),
                  _chip('Rejected', 'rejected'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (formState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No submissions found.',
                    style: TextStyle(color: AppColors.mediumGrey),
                  ),
                ),
              )
            else
              ...filtered.map((f) => _SubmissionCard(form: f)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isActive = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) async {
          setState(() => _statusFilter = value);
          final user = await ref.read(currentUserProvider.future);
          if (user == null) return;
          await _load(user.id);
        },
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  final CourseFormModel form;

  const _SubmissionCard({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = AppHelpers.getStatusProps(form.submissionStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
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
            form.studentName ?? 'Student',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${form.studentMatric ?? ''}\n${form.semester} • ${form.session}',
              style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey, height: 1.4),
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
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: props.color),
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentFormDetailScreen(form: form),
              ),
            );
          },
        ),
      ),
    );
  }
}

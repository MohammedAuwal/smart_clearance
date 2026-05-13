import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class DepartmentArchiveScreen extends ConsumerStatefulWidget {
  const DepartmentArchiveScreen({super.key});

  @override
  ConsumerState<DepartmentArchiveScreen> createState() => _DepartmentArchiveScreenState();
}

class _DepartmentArchiveScreenState extends ConsumerState<DepartmentArchiveScreen> {
  final _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      AppHelpers.showSnackBar(context, message: 'Enter a matric number or name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    final result = await SupabaseService().searchDepartmentArchive(
      department: user.department,
      searchQuery: query,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _results = result.data ?? [];
      } else {
        _error = result.error ?? 'Search failed.';
      }
    });
  }

  Map<String, dynamic>? _userFromRow(Map<String, dynamic> row) {
    final u = row['users'];
    return u is Map<String, dynamic> ? u : null;
  }

  Future<void> _openRow(Map<String, dynamic> row) async {
    final u = _userFromRow(row);
    final studentName = u?['full_name']?.toString() ?? 'Student';
    final matric = u?['matric_number']?.toString() ?? '';
    final level = u?['current_level']?.toString() ?? '';

    final status = row['submission_status']?.toString() ?? '';
    final semester = row['semester']?.toString() ?? '';
    final session = row['session']?.toString() ?? '';
    final pdfUrl = row['form_pdf_url']?.toString() ?? '';
    final reason = row['rejection_reason']?.toString();

    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);

    final props = AppHelpers.getStatusProps(status);

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
                  child: Icon(Icons.folder_open_rounded, color: props.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$studentName ${matric.isEmpty ? '' : '($matric)'}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$level • $semester • $session',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12),
                      ),
                    ],
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
            const SizedBox(height: 14),
            _kv('Created', createdAt == null ? '—' : AppHelpers.formatDateTime(createdAt)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'PDF Link',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
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
                pdfUrl.isEmpty ? '—' : pdfUrl,
                style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pdfUrl.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: pdfUrl));
                            if (!context.mounted) return;
                            AppHelpers.showSnackBar(context, message: 'PDF link copied.');
                          },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Link'),
                  ),
                ),
              ],
            ),
            if ((reason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
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
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.error),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason!,
                      style: const TextStyle(color: AppColors.darkGrey, height: 1.5, fontSize: 13),
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
    return Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department Archive')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Enter matric number or student name',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                    label: const Text('Search'),
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
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(_error!, style: const TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text('No results.', style: TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else
            ..._results.map((row) {
              final u = _userFromRow(row);
              final name = u?['full_name']?.toString() ?? 'Student';
              final matric = u?['matric_number']?.toString() ?? '';
              final status = row['submission_status']?.toString() ?? '';
              final semester = row['semester']?.toString() ?? '';
              final session = row['session']?.toString() ?? '';

              final props = AppHelpers.getStatusProps(status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () => _openRow(row),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: props.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_outlined, color: props.color),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    subtitle: Text(
                      '$matric\n$semester • $session',
                      style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                    ),
                    trailing: Container(
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
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

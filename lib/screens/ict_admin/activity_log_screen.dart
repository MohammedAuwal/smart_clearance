import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _logs = [];

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

    final ict = await ref.read(currentUserProvider.future);
    if (ict == null) {
      setState(() {
        _loading = false;
        _error = 'Please login again.';
      });
      return;
    }

    final result = await SupabaseService().getIctActivityLog(ict.id);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _logs = result.data ?? [];
      } else {
        _error = result.error ?? 'Failed to load activity log.';
      }
    });
  }

  Map<String, dynamic>? _targetStudent(Map<String, dynamic> row) {
    final t = row['target_student'];
    if (t is Map<String, dynamic>) return t;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(_error!, style: const TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No activity yet.', style: TextStyle(color: AppColors.mediumGrey)),
              ),
            )
          else
            ..._logs.map((row) {
              final target = _targetStudent(row);
              final action = row['action_type']?.toString() ?? 'action';
              final desc = row['description']?.toString() ?? '';
              final tsRaw = row['timestamp']?.toString();
              final ts = tsRaw == null ? null : DateTime.tryParse(tsRaw);

              final name = target?['full_name']?.toString() ?? 'Student';
              final matric = target?['matric_number']?.toString() ?? '';

              final color = action == 'unlocked'
                  ? AppColors.success
                  : action == 'rejected'
                      ? AppColors.error
                      : AppColors.info;

              final bg = color.withOpacity(0.10);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action == 'unlocked'
                            ? Icons.lock_open_rounded
                            : action == 'rejected'
                                ? Icons.block_rounded
                                : Icons.info_outline_rounded,
                        color: color,
                      ),
                    ),
                    title: Text(
                      '$name ${matric.isEmpty ? '' : '($matric)'}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${action.toUpperCase()}\n$desc${ts == null ? '' : '\n${AppHelpers.formatDateTime(ts)}'}',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
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

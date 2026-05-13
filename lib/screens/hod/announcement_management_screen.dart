import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/supabase_service.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class AnnouncementManagementScreen extends ConsumerStatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  ConsumerState<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends ConsumerState<AnnouncementManagementScreen> {
  bool _loading = true;
  String? _error;
  List<AnnouncementModel> _announcements = [];

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

    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Please login again.';
      });
      return;
    }

    final result = await SupabaseService().getDepartmentAnnouncements(user.department);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _announcements = result.data ?? [];
      } else {
        _error = result.error ?? 'Failed to load announcements.';
      }
    });
  }

  Future<void> _deactivate(AnnouncementModel a) async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Deactivate Announcement',
      message: 'Deactivate "${a.title}"?\n\nStudents will stop seeing it.',
      confirmText: 'Deactivate',
      isDangerous: true,
    );
    if (!confirm) return;

    final result = await SupabaseService().deactivateAnnouncement(a.id);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _announcements = _announcements
            .map((x) => x.id == a.id ? x.copyWith(isActive: false) : x)
            .toList();
      });
      AppHelpers.showSnackBar(context, message: 'Deactivated.', isSuccess: true);
    } else {
      AppHelpers.showSnackBar(
        context,
        message: result.error ?? 'Failed to deactivate.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
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
              child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.mediumGrey))),
            )
          else if (_announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No announcements.', style: TextStyle(color: AppColors.mediumGrey))),
            )
          else
            ..._announcements.map((a) {
              final isVisible = a.isVisibleNow;
              final statusColor = isVisible ? AppColors.success : AppColors.mediumGrey;
              final statusBg = isVisible ? AppColors.successLight : AppColors.surfaceGrey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.campaign_outlined, color: statusColor),
                    ),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${AppHelpers.truncate(a.body, 90)}\n${a.timeAgo} • ${a.targetAudienceDisplay}',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                      ),
                    ),
                    trailing: a.isActive
                        ? OutlinedButton(
                            onPressed: () => _deactivate(a),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size(100, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Deactivate'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGrey,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderGrey),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: AppColors.mediumGrey,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
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

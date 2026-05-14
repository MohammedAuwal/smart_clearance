import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class StudentAnnouncementsScreen extends ConsumerStatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  ConsumerState<StudentAnnouncementsScreen> createState() => _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends ConsumerState<StudentAnnouncementsScreen> {
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

    final res = await SupabaseService().getAnnouncementsForStudent(
      department: user.department,
      level: user.currentLevel,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (res.success) {
        _announcements = (res.data ?? []).where((a) => a.isVisibleNow).toList();
      } else {
        _error = res.error ?? 'Failed to load announcements.';
      }
    });
  }

  Future<void> _open(AnnouncementModel a) async {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.darkGrey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${a.targetAudienceDisplay} • ${a.timeAgo}',
              style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(
              a.body,
              style: const TextStyle(color: AppColors.darkGrey, height: 1.6, fontSize: 14),
            ),
            if (a.expiresAt != null) ...[
              const SizedBox(height: 14),
              Text(
                'Expires: ${AppHelpers.formatDateLong(a.expiresAt!)}',
                style: const TextStyle(color: AppColors.lightGrey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
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
                child: Center(
                  child: Text('No announcements right now.', style: TextStyle(color: AppColors.mediumGrey)),
                ),
              )
            else
              ..._announcements.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _open(a),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: const Icon(Icons.campaign_outlined, color: AppColors.accentDark),
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${AppHelpers.truncate(a.body, 90)}\n${a.targetAudienceDisplay} • ${a.timeAgo}',
                          style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
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

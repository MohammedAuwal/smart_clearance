import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../auth/login_screen.dart';
import 'bulk_approval_screen.dart';
import 'submission_list_screen.dart';
import 'announcement_create_screen.dart';

class AdviserDashboard extends ConsumerStatefulWidget {
  const AdviserDashboard({super.key});

  @override
  ConsumerState<AdviserDashboard> createState() => _AdviserDashboardState();
}

class _AdviserDashboardState extends ConsumerState<AdviserDashboard> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;

        // Load adviser submissions (all)
        ref.read(formProvider.notifier).loadAdviserSubmissions(adviserId: user.id);
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(formProvider.notifier).loadAdviserSubmissions(adviserId: user.id);
  }

  Future<void> _logout() async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDangerous: true,
    );
    if (!confirm) return;

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final formState = ref.watch(formProvider);
    final pendingCount = ref.watch(pendingSubmissionsCountProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Please login again.')));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Adviser Dashboard'),
            actions: [
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
              IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.adviserGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppHelpers.getGreeting(),
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${user.department} • ${user.currentLevel}',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Pending',
                            value: pendingCount.toString(),
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: 'Total Loaded',
                            value: formState.adviserSubmissions.length.toString(),
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),

                _ActionCard(
                  title: 'View Submissions',
                  subtitle: 'Review submitted course forms',
                  icon: Icons.inbox_rounded,
                  color: AppColors.primary,
                  trailing: pendingCount > 0 ? _Badge(text: pendingCount.toString()) : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubmissionListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _ActionCard(
                  title: 'Bulk Approve',
                  subtitle: 'Approve multiple forms at once',
                  icon: Icons.done_all_rounded,
                  color: AppColors.success,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BulkApprovalScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _ActionCard(
                  title: 'Post Announcement',
                  subtitle: 'Send update to students',
                  icon: Icons.campaign_rounded,
                  color: AppColors.accentDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AnnouncementCreateScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

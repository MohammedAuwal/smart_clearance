import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'department_archive_screen.dart';
import 'assign_level_adviser_screen.dart';
import 'announcement_management_screen.dart';
import 'manage_advisers_screen.dart';
import 'assign_level_adviser_screen.dart';

class HodDashboard extends ConsumerWidget {
  const HodDashboard({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDangerous: true,
    );
    if (!confirm) return;

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Please login again.')));

        return Scaffold(
          appBar: AppBar(
            title: const Text('HOD Dashboard'),
            actions: [
              IconButton(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.hodGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        user.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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
                            user.department,
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text('Department Tools', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),

              _ToolCard(
                title: 'Department Archive',
                subtitle: 'Search course forms by matric or name',
                icon: Icons.folder_open_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DepartmentArchiveScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ToolCard(
                title: 'Manage Announcements',
                subtitle: 'Deactivate old announcements',
                icon: Icons.campaign_rounded,
                color: AppColors.accentDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnnouncementManagementScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
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
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
      ),
    );
  }
}
_ToolCard(
  title: 'Assign Level Adviser',
  subtitle: 'Assign an adviser using staff email + level',
  icon: Icons.person_add_alt_1_rounded,
  color: AppColors.info,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssignLevelAdviserScreen()),
    );
  },
),
const SizedBox(height: 10),
_ToolCard(
  title: 'Assign Level Adviser',
  subtitle: 'Assign adviser using staff email + level',
  icon: Icons.person_add_alt_1_rounded,
  color: AppColors.info,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssignLevelAdviserScreen()),
    );
  },
),
const SizedBox(height: 10),

_ToolCard(
  title: 'Manage Advisers',
  subtitle: 'Change adviser level or deactivate/reactivate',
  icon: Icons.manage_accounts_rounded,
  color: AppColors.primary,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageAdvisersScreen()),
    );
  },
),
const SizedBox(height: 10),

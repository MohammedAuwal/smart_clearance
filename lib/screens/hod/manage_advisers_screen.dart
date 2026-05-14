import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ManageAdvisersScreen extends ConsumerStatefulWidget {
  const ManageAdvisersScreen({super.key});

  @override
  ConsumerState<ManageAdvisersScreen> createState() => _ManageAdvisersScreenState();
}

class _ManageAdvisersScreenState extends ConsumerState<ManageAdvisersScreen> {
  bool _loading = true;
  String? _error;

  List<UserModel> _advisers = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hod = await ref.read(currentUserProvider.future);
    if (hod == null) {
      setState(() {
        _loading = false;
        _error = 'Please login again.';
      });
      return;
    }

    final res = await SupabaseService().getAdvisersByDepartment(hod.department);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (res.success) {
        _advisers = res.data ?? [];
      } else {
        _error = res.error ?? 'Failed to load advisers.';
      }
    });
  }

  List<UserModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _advisers;
    return _advisers.where((a) {
      return a.fullName.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          a.currentLevel.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _changeLevel(UserModel adviser) async {
    String? selected = adviser.currentLevel;

    final newLevel = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Assigned Level'),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.stairs_rounded)),
            items: AppStrings.levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => selected = v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Save')),
        ],
      ),
    );

    if (newLevel == null || newLevel.trim().isEmpty) return;

    final res = await SupabaseService().updateUserProfile(
      userId: adviser.id,
      updates: {'current_level': newLevel},
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _advisers = _advisers.map((a) => a.id == adviser.id ? res.data! : a).toList();
      });
      AppHelpers.showSnackBar(context, message: 'Updated adviser level.', isSuccess: true);
    } else {
      AppHelpers.showSnackBar(context, message: res.error ?? 'Update failed.', isError: true);
    }
  }

  Future<void> _toggleActive(UserModel adviser) async {
    final makeActive = !adviser.isActive;

    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: makeActive ? 'Reactivate Adviser' : 'Deactivate Adviser',
      message: makeActive
          ? 'Reactivate ${adviser.fullName}? They will be able to login.'
          : 'Deactivate ${adviser.fullName}? They will NOT be able to login.',
      confirmText: makeActive ? 'Reactivate' : 'Deactivate',
      isDangerous: !makeActive,
    );
    if (!confirm) return;

    final res = await SupabaseService().updateUserProfile(
      userId: adviser.id,
      updates: {'is_active': makeActive},
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _advisers = _advisers.map((a) => a.id == adviser.id ? res.data! : a).toList();
      });
      AppHelpers.showSnackBar(
        context,
        message: makeActive ? 'Adviser reactivated.' : 'Adviser deactivated.',
        isSuccess: true,
      );
    } else {
      AppHelpers.showSnackBar(context, message: res.error ?? 'Action failed.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Advisers'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by name, email, or level',
              prefixIcon: Icon(Icons.search_rounded),
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
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.mediumGrey))),
            )
          else if (_filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No advisers found.', style: TextStyle(color: AppColors.mediumGrey))),
            )
          else
            ..._filtered.map((a) {
              final badgeColor = a.isActive ? AppColors.success : AppColors.mediumGrey;
              final badgeBg = a.isActive ? AppColors.successLight : AppColors.surfaceGrey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        a.initials,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ),
                    title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${a.email}\nAssigned Level: ${a.currentLevel}',
                        style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12, height: 1.4),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            a.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'level') _changeLevel(a);
                            if (value == 'toggle') _toggleActive(a);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'level',
                              child: Text('Change Level'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(a.isActive ? 'Deactivate' : 'Reactivate'),
                            ),
                          ],
                        ),
                      ],
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

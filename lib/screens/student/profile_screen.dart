import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/cloudinary_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    AppHelpers.showLoadingDialog(context, message: 'Uploading photo...');
    final upload = await CloudinaryService().uploadProfilePhoto(
      file: File(picked.path),
      userId: user.id,
    );
    AppHelpers.hideLoadingDialog(context);

    if (!context.mounted) return;

    if (!upload.success || !upload.hasUrl) {
      AppHelpers.showSnackBar(
        context,
        message: upload.error ?? 'Photo upload failed.',
        isError: true,
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).updateProfile(
      userId: user.id,
      updates: {'profile_image_url': upload.url},
    );

    if (!context.mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Profile photo updated.', isSuccess: true);
    } else {
      AppHelpers.showSnackBar(context, message: 'Failed to update profile.', isError: true);
    }
  }

  Future<void> _editPhone(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final controller = TextEditingController(text: user.phoneNumber);

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'e.g. 08012345678'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final ok = await ref.read(authProvider.notifier).updateProfile(
      userId: user.id,
      updates: {'phone_number': result},
    );

    if (!context.mounted) return;

    if (ok) {
      AppHelpers.showSnackBar(context, message: 'Phone number updated.', isSuccess: true);
    } else {
      AppHelpers.showSnackBar(context, message: 'Failed to update phone number.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Please login again.'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                            ? Text(
                                user.initials,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkGrey,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.matricNumber} • ${user.department}',
                              style: const TextStyle(
                                color: AppColors.mediumGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _changePhoto(context, ref),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone Number'),
                      subtitle: Text(user.phoneNumber),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editPhone(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(user.email),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.stairs_rounded),
                      title: const Text('Level'),
                      subtitle: Text(user.currentLevel),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    ref.listen(currentUserProvider, (prev, next) {
      next.whenData((user) {
        if (user == null) return;
        if (_initialized) return;
        _initialized = true;
        ref.read(notificationProvider.notifier).loadNotifications(user.id);
      });
    });
  }

  Future<void> _refresh() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(notificationProvider.notifier).refresh(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () async {
              final user = await ref.read(currentUserProvider.future);
              if (user == null) return;
              await ref.read(notificationProvider.notifier).markAllAsRead(user.id);
            },
            icon: const Icon(Icons.done_all_rounded),
            tooltip: AppStrings.markAllRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.notifications.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      SizedBox(height: 40),
                      Icon(Icons.notifications_none_rounded,
                          size: 50, color: AppColors.lightGrey),
                      SizedBox(height: 14),
                      Text(
                        AppStrings.noNotifications,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppStrings.noNotificationsSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mediumGrey, height: 1.6),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      final isUnread = n.isUnread;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isUnread ? AppColors.primarySurface : AppColors.surfaceGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconFor(n.iconName),
                              color: isUnread ? AppColors.primary : AppColors.mediumGrey,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.darkGrey,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${n.body}\n${n.timeAgo}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumGrey,
                                height: 1.4,
                              ),
                            ),
                          ),
                          trailing: isUnread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (n.isUnread) {
                              ref.read(notificationProvider.notifier).markAsRead(n.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'payment':
        return Icons.payments_outlined;
      case 'description':
        return Icons.description_outlined;
      case 'campaign':
        return Icons.campaign_outlined;
      case 'alarm':
        return Icons.alarm_outlined;
      case 'lock_open':
        return Icons.lock_open_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}

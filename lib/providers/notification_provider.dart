import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../core/services/supabase_service.dart';

// ─── Notification State ───────────────────────────────────────────────────────
class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  // Total unread count shown on notification bell badge
  int get unreadCount =>
      notifications.where((n) => n.isUnread).length;

  bool get hasUnread => unreadCount > 0;

  // Group notifications by type for filtered views
  List<NotificationModel> get paymentNotifications =>
      notifications.where((n) => n.isPaymentNotification).toList();

  List<NotificationModel> get formNotifications =>
      notifications.where((n) => n.isFormNotification).toList();

  List<NotificationModel> get announcements =>
      notifications.where((n) => n.isAnnouncement).toList();

  List<NotificationModel> getByType(String type) {
    if (type == 'all') return notifications;
    return notifications.where((n) => n.type == type).toList();
  }
}

// ─── Notification Notifier ────────────────────────────────────────────────────
class NotificationNotifier extends StateNotifier<NotificationState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _subscription;

  NotificationNotifier({required SupabaseService supabaseService})
      : _supabaseService = supabaseService,
        super(const NotificationState());

  // ─── Load Notifications ────────────────────────────────────────────────
  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result =
        await _supabaseService.getUserNotifications(userId);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        notifications: result.data ?? [],
      );

      // Start real-time subscription after loading
      _subscribeToNewNotifications(userId);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  // ─── Real-Time Subscription ────────────────────────────────────────────
  // When a new notification arrives in Supabase, prepend it to the list
  // This means the user sees it instantly without refreshing
  void _subscribeToNewNotifications(String userId) {
    // Cancel existing subscription if any
    _subscription?.unsubscribe();

    _subscription = _supabaseService.subscribeToNotifications(
      userId: userId,
      onNew: (data) {
        try {
          final newNotification = NotificationModel.fromJson(data);
          state = state.copyWith(
            notifications: [newNotification, ...state.notifications],
          );
        } catch (e) {
          // Silently ignore malformed notification data
        }
      },
    );
  }

  // ─── Mark Single Notification as Read ─────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    // Update local state immediately for snappy UI
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updated);

    // Then update in Supabase in the background
    await _supabaseService.markNotificationAsRead(notificationId);
  }

  // ─── Mark All as Read ──────────────────────────────────────────────────
  Future<void> markAllAsRead(String userId) async {
    // Update local state immediately
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    state = state.copyWith(notifications: updated);

    // Then update Supabase in background
    await _supabaseService.markAllNotificationsAsRead(userId);
  }

  // ─── Refresh Notifications ─────────────────────────────────────────────
  Future<void> refresh(String userId) async {
    await loadNotifications(userId);
  }

  // ─── Cancel Subscription on Dispose ───────────────────────────────────
  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

// ─── Notification Provider ────────────────────────────────────────────────────
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(supabaseService: SupabaseService());
});

// ─── Unread Count Provider ────────────────────────────────────────────────────
// Widgets that show the badge number watch this
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

// ─── Has Unread Provider ──────────────────────────────────────────────────────
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).hasUnread;
});

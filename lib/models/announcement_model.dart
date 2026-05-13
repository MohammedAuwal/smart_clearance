// Enum-style constants for notification types
// We use String constants instead of enums so they
// map directly to what is stored in Supabase
class NotificationType {
  NotificationType._();

  static const String payment = 'payment';
  static const String form = 'form';
  static const String announcement = 'announcement';
  static const String reminder = 'reminder';
  static const String lateRegistration = 'late_registration';
  static const String system = 'system';
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  // ─── From Supabase JSON ──────────────────────────────────────────────────
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      relatedId: json['related_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ─── To JSON ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'related_id': relatedId,
    };
  }

  // ─── CopyWith ─────────────────────────────────────────────────────────────
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    String? relatedId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Convenience Getters ──────────────────────────────────────────────────
  bool get isUnread => !isRead;

  bool get isPaymentNotification => type == NotificationType.payment;
  bool get isFormNotification => type == NotificationType.form;
  bool get isAnnouncement => type == NotificationType.announcement;
  bool get isReminder => type == NotificationType.reminder;

  // Returns how long ago the notification was created
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      // Return formatted date for older notifications
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Icon name based on notification type
  // We return a string and map it to an icon in the UI layer
  String get iconName {
    switch (type) {
      case NotificationType.payment:
        return 'payment';
      case NotificationType.form:
        return 'description';
      case NotificationType.announcement:
        return 'campaign';
      case NotificationType.reminder:
        return 'alarm';
      case NotificationType.lateRegistration:
        return 'lock_open';
      default:
        return 'notifications';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

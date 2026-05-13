class AnnouncementModel {
  final String id;
  final String postedBy;
  final String title;
  final String body;
  final String targetAudience;
  final String department;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  // Joined field - name of the person who posted it
  final String? posterName;
  final String? posterRole;

  const AnnouncementModel({
    required this.id,
    required this.postedBy,
    required this.title,
    required this.body,
    required this.targetAudience,
    required this.department,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
    this.posterName,
    this.posterRole,
  });

  // ─── From Supabase JSON ──────────────────────────────────────────────────
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      postedBy: json['posted_by'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      targetAudience: json['target_audience'] as String,
      department: json['department'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      posterName: json['poster_name'] as String?,
      posterRole: json['poster_role'] as String?,
    );
  }

  // ─── To JSON ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toInsertJson() {
    return {
      'posted_by': postedBy,
      'title': title,
      'body': body,
      'target_audience': targetAudience,
      'department': department,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // ─── CopyWith ─────────────────────────────────────────────────────────────
  AnnouncementModel copyWith({
    String? id,
    String? postedBy,
    String? title,
    String? body,
    String? targetAudience,
    String? department,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? posterName,
    String? posterRole,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      postedBy: postedBy ?? this.postedBy,
      title: title ?? this.title,
      body: body ?? this.body,
      targetAudience: targetAudience ?? this.targetAudience,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      posterName: posterName ?? this.posterName,
      posterRole: posterRole ?? this.posterRole,
    );
  }

  // ─── Convenience Getters ──────────────────────────────────────────────────
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isVisibleNow => isActive && !isExpired;

  // Check if this announcement targets a specific student level
  bool targetsLevel(String level) {
    if (targetAudience == 'all') return true;
    return targetAudience.toLowerCase() ==
        level.toLowerCase().replaceAll(' ', '');
  }

  String get targetAudienceDisplay {
    switch (targetAudience.toLowerCase()) {
      case 'all':
        return 'All Students';
      case '100level':
        return '100 Level Students';
      case '200level':
        return '200 Level Students';
      case '300level':
        return '300 Level Students';
      case '400level':
        return '400 Level Students';
      case '500level':
        return '500 Level Students';
      default:
        return targetAudience;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

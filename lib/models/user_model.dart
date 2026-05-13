class UserModel {
  final String id;
  final String firebaseUid;
  final String fullName;
  final String matricNumber;
  final String email;
  final String phoneNumber;
  final String department;
  final String faculty;
  final String currentLevel;
  final String role;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.matricNumber,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.faculty,
    required this.currentLevel,
    required this.role,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
  });

  // ─── From Supabase JSON ──────────────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      fullName: json['full_name'] as String,
      matricNumber: json['matric_number'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      department: json['department'] as String,
      faculty: json['faculty'] as String,
      currentLevel: json['current_level'] as String,
      role: json['role'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ─── To JSON for Supabase Insert/Update ─────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'full_name': fullName,
      'matric_number': matricNumber,
      'email': email,
      'phone_number': phoneNumber,
      'department': department,
      'faculty': faculty,
      'current_level': currentLevel,
      'role': role,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ─── CopyWith for state updates ──────────────────────────────────────────────
  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? fullName,
    String? matricNumber,
    String? email,
    String? phoneNumber,
    String? department,
    String? faculty,
    String? currentLevel,
    String? role,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      fullName: fullName ?? this.fullName,
      matricNumber: matricNumber ?? this.matricNumber,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      faculty: faculty ?? this.faculty,
      currentLevel: currentLevel ?? this.currentLevel,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Convenience Getters ─────────────────────────────────────────────────────
  bool get isStudent => role == 'student';
  bool get isAdviser => role == 'adviser';
  bool get isIctAdmin => role == 'ict_admin';
  bool get isHod => role == 'hod';
  bool get isSuperAdmin => role == 'super_admin';

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $fullName, role: $role, matric: $matricNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

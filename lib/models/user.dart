import 'package:real_galaxy/models/role.dart';

class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final Role role;
  final bool mustChangePassword;
  final bool isActive;
  final String? createdBy;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPasswordChange;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.mustChangePassword = false,
    this.isActive = true,
    this.createdBy,
    this.phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastPasswordChange,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'password': password,
      'role': role.name,
      'must_change_password': mustChangePassword ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_by': createdBy,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_password_change': lastPasswordChange?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: RoleExtension.fromString(map['role'] as String? ?? 'parent'),
      mustChangePassword: (map['must_change_password'] as int?) == 1,
      isActive: (map['is_active'] as int?) != 0,
      createdBy: map['created_by'] as String?,
      phoneNumber: map['phone_number'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastPasswordChange: map['last_password_change'] != null
          ? DateTime.tryParse(map['last_password_change'].toString())
          : null,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    Role? role,
    bool? mustChangePassword,
    bool? isActive,
    String? createdBy,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPasswordChange,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
    );
  }
}

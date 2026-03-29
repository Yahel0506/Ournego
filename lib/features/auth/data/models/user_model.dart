import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/domain/entities/app_user.dart';

/// Data model for AppUser.
///
/// Extends the domain entity and adds serialization capabilities.
/// Used in the data layer for API communication and local storage.
class UserModel extends AppUser {
  UserModel({
    required super.uid,
    super.name,
    super.email,
    super.phoneNum,
    super.profilePicture,
  });

  /// Create model from JSON (e.g., from Supabase 'users' table)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNum: json['phone_num'] as String?,
      profilePicture: json['avatar_url'] as String?,
    );
  }

  /// Convert model to JSON (e.g., for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'phone_num': phoneNum,
      'avatar_url': profilePicture,
    };
  }

  /// Create model from Supabase Auth User object
  /// Used when signing up or logging in
  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      uid: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String?,
      profilePicture: user.userMetadata?['avatar_url'] as String?,
      phoneNum: user.phone,
    );
  }

  /// Create model from domain entity
  /// Useful when you need to serialize an entity
  factory UserModel.fromEntity(AppUser entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      phoneNum: entity.phoneNum,
      profilePicture: entity.profilePicture,
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNum,
    String? profilePicture,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNum: phoneNum ?? this.phoneNum,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isEmailVerified;
  final String? idToken;
  final String? phoneNumber;
  final Map<String, dynamic>? customData;
  final List<String>? roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isEmailVerified = false,
    this.idToken,
    this.phoneNumber,
    this.customData,
    this.roles,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      idToken: json['id_token'] as String?,
      phoneNumber: json['phone_number'] as String?,
      customData: json['custom_data'] as Map<String, dynamic>?,
      roles: (json['roles'] as List?)?.map((e) => e as String).toList(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'is_email_verified': isEmailVerified,
      'phone_number': phoneNumber,
      'custom_data': customData,
      'roles': roles,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isEmailVerified,
    String? phoneNumber,
    Map<String, dynamic>? customData,
    List<String>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      customData: customData ?? this.customData,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    email,
    photoUrl,
    isEmailVerified,
    phoneNumber,
    customData,
    roles,
    createdAt,
    updatedAt,
  ];
}

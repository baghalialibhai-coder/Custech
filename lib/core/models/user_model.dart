import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String role; // customer | technician
  final String country;
  final String city;
  final String? serviceCharge;
  final String address;
  final String pinCode;
  final List<String> ? pinCodes;
  final bool isVerified;
  final bool isMembershipActive;
  final DateTime? membershipExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    this.pinCodes,
    this.serviceCharge,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.role,
    required this.country,
    required this.city,
    required this.address,
    required this.pinCode,
    required this.isVerified,
    required this.isMembershipActive,
    this.membershipExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String ? serviceCharge,
    List<String>? pinCodes,
    String? email,
    String? phone,
    String? profileImage,
    String? role,
    String? country,
    String? city,
    String? address,
    String? pinCode,
    bool? isVerified,
    bool? isMembershipActive,
    DateTime? membershipExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      pinCodes: pinCodes ?? this.pinCodes,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      isVerified: isVerified ?? this.isVerified,
      isMembershipActive:
      isMembershipActive ?? this.isMembershipActive,
      membershipExpiry:
      membershipExpiry ?? this.membershipExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pinCodes':pinCodes,
      'email': email,
      'phone': phone,
      'serviceCharge':serviceCharge,
      'profileImage': profileImage,
      'role': role,
      'country': country,
      'city': city,
      'address': address,
      'pinCode': pinCode,
      'isVerified': isVerified,
      'isMembershipActive': isMembershipActive,
      'membershipExpiry':
      membershipExpiry?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      pinCodes:map['pinCodes'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      serviceCharge:map['serviceCharge'] ?? '',
      profileImage: map['profileImage'] ?? '',
      role: map['role'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      pinCode: map['pinCode'] ?? '',
      isVerified: map['isVerified'] ?? false,
      isMembershipActive:
      map['isMembershipActive'] ?? false,
      membershipExpiry: map['membershipExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
        map['membershipExpiry'],
      )
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? 0,
      ),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            email == other.email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
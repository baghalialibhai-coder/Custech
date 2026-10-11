// lib/core/models/merchant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantModel {
  final String merchantId;
  final String userName;
  final String userPhoneNumber;
  final String shopName;
  final String shopPhoneNumber;
  final String address;
  final String shopType;
  final double latitude;
  final double longitude;
  final String pincode;
  final String role;
  final bool isProfileComplete;
  final String shopImageUrl;
  final String openingTime;
  final String closingTime;
  final String shopOffDay;
  final List<String> workingDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MerchantModel({
    required this.merchantId,
    required this.userName,
    required this.userPhoneNumber,
    required this.shopName,
    required this.shopPhoneNumber,
    required this.address,
    required this.shopType,
    required this.latitude,
    required this.longitude,
    required this.pincode,
    this.role = 'merchant',
    this.isProfileComplete = true,
    this.shopImageUrl = '',
    this.openingTime = '09:00 AM',
    this.closingTime = '09:00 PM',
    this.shopOffDay = 'Sunday',
    required this.workingDays,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'userName': userName,
      'userPhoneNumber': userPhoneNumber,
      'shopName': shopName,
      'shopPhoneNumber': shopPhoneNumber,
      'address': address,
      'shopType': shopType,
      'latitude': latitude,
      'longitude': longitude,
      'pincode': pincode,
      'role': role,
      'isProfileComplete': isProfileComplete,
      'shopImageUrl': shopImageUrl,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'shopOffDay': shopOffDay,
      'workingDays': workingDays,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      merchantId: map['merchantId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoneNumber: map['userPhoneNumber'] ?? '',
      shopName: map['shopName'] ?? '',
      shopPhoneNumber: map['shopPhoneNumber'] ?? '',
      address: map['address'] ?? '',
      shopType: map['shopType'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      pincode: map['pincode'] ?? '',
      role: map['role'] ?? 'merchant',
      isProfileComplete: map['isProfileComplete'] ?? false,
      shopImageUrl: map['shopImageUrl'] ?? '',
      openingTime: map['openingTime'] ?? '09:00 AM',
      closingTime: map['closingTime'] ?? '09:00 PM',
      shopOffDay: map['shopOffDay'] ?? 'Sunday',
      workingDays: List<String>.from(map['workingDays'] ?? []),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}

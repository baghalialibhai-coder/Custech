import 'package:flutter/foundation.dart';

@immutable
class CustomerModel {
  final String userId;

  // Saved Information
  final List<String> savedTechnicians;
  final List<String> favoriteCategories;

  // Addresses
  final List<String> addresses;
  final String defaultAddress;

  // Activity
  final int totalJobsPosted;
  final int completedJobs;
  final int cancelledJobs;

  // Rating
  final double averageRatingGiven;

  const CustomerModel({
    required this.userId,
    required this.savedTechnicians,
    required this.favoriteCategories,
    required this.addresses,
    required this.defaultAddress,
    required this.totalJobsPosted,
    required this.completedJobs,
    required this.cancelledJobs,
    required this.averageRatingGiven,
  });

  CustomerModel copyWith({
    String? userId,
    List<String>? savedTechnicians,
    List<String>? favoriteCategories,
    List<String>? addresses,
    String? defaultAddress,
    int? totalJobsPosted,
    int? completedJobs,
    int? cancelledJobs,
    double? averageRatingGiven,
  }) {
    return CustomerModel(
      userId: userId ?? this.userId,
      savedTechnicians: savedTechnicians ?? this.savedTechnicians,
      favoriteCategories:
      favoriteCategories ?? this.favoriteCategories,
      addresses: addresses ?? this.addresses,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      totalJobsPosted: totalJobsPosted ?? this.totalJobsPosted,
      completedJobs: completedJobs ?? this.completedJobs,
      cancelledJobs: cancelledJobs ?? this.cancelledJobs,
      averageRatingGiven:
      averageRatingGiven ?? this.averageRatingGiven,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'savedTechnicians': savedTechnicians,
      'favoriteCategories': favoriteCategories,
      'addresses': addresses,
      'defaultAddress': defaultAddress,
      'totalJobsPosted': totalJobsPosted,
      'completedJobs': completedJobs,
      'cancelledJobs': cancelledJobs,
      'averageRatingGiven': averageRatingGiven,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      userId: map['userId'] ?? '',
      savedTechnicians:
      List<String>.from(map['savedTechnicians'] ?? []),
      favoriteCategories:
      List<String>.from(map['favoriteCategories'] ?? []),
      addresses: List<String>.from(map['addresses'] ?? []),
      defaultAddress: map['defaultAddress'] ?? '',
      totalJobsPosted: map['totalJobsPosted'] ?? 0,
      completedJobs: map['completedJobs'] ?? 0,
      cancelledJobs: map['cancelledJobs'] ?? 0,
      averageRatingGiven:
      (map['averageRatingGiven'] ?? 0).toDouble(),
    );
  }
}
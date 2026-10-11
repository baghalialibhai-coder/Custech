import 'package:flutter/foundation.dart';

@immutable
class TechnicianModel {
  final String userId;

  // Professional Information
  final List<String> categories;
  final List<String> subCategories;
  final int experience; // Years
  final String about;

  // Service Area
  final List<String> servicePinCodes;
  final double latitude;
  final double longitude;
  final double serviceRadius; // KM

  // Pricing
  final double hourlyRate;
  final double visitingCharges;

  // Availability
  final bool isAvailable;
  final bool isOnline;

  // Ratings
  final double rating;
  final int totalReviews;
  final int completedJobs;

  // Verification
  final bool isApproved;
  final bool isDocumentsVerified;

  const TechnicianModel({
    required this.userId,
    required this.categories,
    required this.subCategories,
    required this.experience,
    required this.about,
    required this.servicePinCodes,
    required this.latitude,
    required this.longitude,
    required this.serviceRadius,
    required this.hourlyRate,
    required this.visitingCharges,
    required this.isAvailable,
    required this.isOnline,
    required this.rating,
    required this.totalReviews,
    required this.completedJobs,
    required this.isApproved,
    required this.isDocumentsVerified,
  });

  TechnicianModel copyWith({
    String? userId,
    List<String>? categories,
    List<String>? subCategories,
    int? experience,
    String? about,
    List<String>? servicePinCodes,
    double? latitude,
    double? longitude,
    double? serviceRadius,
    double? hourlyRate,
    double? visitingCharges,
    bool? isAvailable,
    bool? isOnline,
    double? rating,
    int? totalReviews,
    int? completedJobs,
    bool? isApproved,
    bool? isDocumentsVerified,
  }) {
    return TechnicianModel(
      userId: userId ?? this.userId,
      categories: categories ?? this.categories,
      subCategories: subCategories ?? this.subCategories,
      experience: experience ?? this.experience,
      about: about ?? this.about,
      servicePinCodes: servicePinCodes ?? this.servicePinCodes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      visitingCharges: visitingCharges ?? this.visitingCharges,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      isApproved: isApproved ?? this.isApproved,
      isDocumentsVerified:
      isDocumentsVerified ?? this.isDocumentsVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categories': categories,
      'subCategories': subCategories,
      'experience': experience,
      'about': about,
      'servicePinCodes': servicePinCodes,
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadius': serviceRadius,
      'hourlyRate': hourlyRate,
      'visitingCharges': visitingCharges,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'rating': rating,
      'totalReviews': totalReviews,
      'completedJobs': completedJobs,
      'isApproved': isApproved,
      'isDocumentsVerified': isDocumentsVerified,
    };
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map) {
    return TechnicianModel(
      userId: map['userId'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      subCategories: List<String>.from(map['subCategories'] ?? []),
      experience: map['experience'] ?? 0,
      about: map['about'] ?? '',
      servicePinCodes: List<String>.from(map['servicePinCodes'] ?? []),
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      serviceRadius: (map['serviceRadius'] ?? 0).toDouble(),
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      visitingCharges: (map['visitingCharges'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      isOnline: map['isOnline'] ?? false,
      rating: (map['rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      completedJobs: map['completedJobs'] ?? 0,
      isApproved: map['isApproved'] ?? false,
      isDocumentsVerified:
      map['isDocumentsVerified'] ?? false,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus {
  available,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected,
}

class JobModel {
  final String id;
  final String title;
  final String description;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> subCategories;
  final double budget;
  final double serviceCharge;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final JobStatus status;
  final String? cancellationReason;
  final String? technicianId;
  final String? technicianName;
  final String? technicianPhone;
  final double? rating;
  final String? review;
  final List<String> images;
  final bool isUrgent;
  final String pincode;
  final DateTime? rejectedAt;
  final String? rejectedBy;

  // ✅ Currency Fields
  final String currencyCode;
  final String currencySymbol;
  final String countryCode;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.subCategories = const [],
    required this.budget,
    this.serviceCharge = 0.0,
    required this.createdAt,
    this.scheduledDate,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.status,
    this.cancellationReason,
    this.technicianId,
    this.technicianName,
    this.technicianPhone,
    this.rating,
    this.review,
    this.images = const [],
    this.isUrgent = false,
    required this.pincode,
    this.rejectedAt,
    this.rejectedBy,
    this.currencyCode = 'PKR',
    this.currencySymbol = 'Rs',
    this.countryCode = 'PK',
  });

  // ✅ Helper getters for currency
  String get currencySymbolDisplay => currencySymbol.isNotEmpty ? currencySymbol : '\$';
  String get currencyCodeDisplay => currencyCode.isNotEmpty ? currencyCode : 'USD';

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ Parse status with proper mapping
    JobStatus status;
    final statusValue = data['status'] ?? 'available';
    switch (statusValue) {
      case 'open':
      case 'available':
        status = JobStatus.available;
        break;
      case 'accepted':
        status = JobStatus.accepted;
        break;
      case 'inProgress':
        status = JobStatus.inProgress;
        break;
      case 'completed':
        status = JobStatus.completed;
        break;
      case 'cancelled':
        status = JobStatus.cancelled;
        break;
      case 'rejected':
        status = JobStatus.rejected;
        break;
      default:
        status = JobStatus.available;
    }

    return JobModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['address'] ?? data['customerAddress'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      subCategories: List<String>.from(data['subCategories'] ?? []),
      budget: (data['budget'] ?? 0.0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      status: status,
      cancellationReason: data['cancellationReason'],
      technicianId: data['technicianId'],
      technicianName: data['technicianName'],
      technicianPhone: data['technicianPhone'],
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review'],
      images: List<String>.from(data['images'] ?? []),
      isUrgent: data['isUrgent'] ?? false,
      pincode: data['pincode'] ?? '',
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectedBy: data['rejectedBy'],
      // ✅ Parse currency fields
      currencyCode: data['currencyCode'] ?? 'PKR',
      currencySymbol: data['currencySymbol'] ?? 'Rs',
      countryCode: data['countryCode'] ?? 'PK',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': customerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'subCategories': subCategories,
      'budget': budget,
      'serviceCharge': serviceCharge,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'status': _statusToString(status),
      'cancellationReason': cancellationReason,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'technicianPhone': technicianPhone,
      'rating': rating,
      'review': review,
      'images': images,
      'isUrgent': isUrgent,
      'pincode': pincode,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectedBy': rejectedBy,
      // ✅ Save currency fields
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'countryCode': countryCode,
    };
  }

  String _statusToString(JobStatus status) {
    switch (status) {
      case JobStatus.available:
        return 'available';
      case JobStatus.accepted:
        return 'accepted';
      case JobStatus.inProgress:
        return 'inProgress';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
      case JobStatus.rejected:
        return 'rejected';
    }
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? subCategories,
    double? budget,
    double? serviceCharge,
    DateTime? createdAt,
    DateTime? scheduledDate,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    JobStatus? status,
    String? cancellationReason,
    String? technicianId,
    String? technicianName,
    String? technicianPhone,
    double? rating,
    String? review,
    List<String>? images,
    bool? isUrgent,
    String? pincode,
    DateTime? rejectedAt,
    String? rejectedBy,
    String? currencyCode,
    String? currencySymbol,
    String? countryCode,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      subCategories: subCategories ?? this.subCategories,
      budget: budget ?? this.budget,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      technicianPhone: technicianPhone ?? this.technicianPhone,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      images: images ?? this.images,
      isUrgent: isUrgent ?? this.isUrgent,
      pincode: pincode ?? this.pincode,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}
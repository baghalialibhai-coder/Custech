import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  open,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String address;

  final String pincode;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> subCategories;
  final double budget;

  // Add these fields to TaskModel
  final String? currencyCode;
  final String? currencySymbol;
  final String? countryCode;

  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final TaskStatus status;
  final String? cancellationReason;
  final String? technicianId;
  final String? technicianName;
  final String? technicianPhone;
  final double? technicianRating;
  final double? customerRating;
  final String? customerReview;
  final bool isUrgent;
  final List<String> images;

  final double? serviceCharge;
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.pincode,



    required this.latitude,
    required this.longitude,
    required this.category,
    this.subCategories = const [],
    required this.budget,
    required this.createdAt,
    this.scheduledDate,
    this.acceptedAt,
    this.startedAt,
    this.currencyCode,
    this.currencySymbol,
    this.countryCode,
    this.completedAt,
    this.cancelledAt,
    required this.status,
    this.cancellationReason,
    this.technicianId,
    this.technicianName,
    this.technicianPhone,
    this.technicianRating,
    this.customerRating,
    this.customerReview,
    this.isUrgent = false,
    this.images = const [],
      this.serviceCharge,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',

      currencyCode: data['currencyCode'] ?? 'PKR',
      currencySymbol: data['currencySymbol'] ?? 'Rs',
      countryCode: data['countryCode'] ?? 'PK',

      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      subCategories: List<String>.from(data['subCategories'] ?? []),
      budget: (data['budget'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      status: TaskStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => TaskStatus.open,
      ),
      cancellationReason: data['cancellationReason'],
      technicianId: data['technicianId'],
      technicianName: data['technicianName'],
      technicianPhone: data['technicianPhone'],
      technicianRating: (data['technicianRating'] as num?)?.toDouble(),
      customerRating: (data['customerRating'] as num?)?.toDouble(),
      customerReview: data['customerReview'],
      isUrgent: data['isUrgent'] ?? false,
      images: List<String>.from(data['images'] ?? []),
        serviceCharge:data['serviceCharge'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'pincode': pincode,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'subCategories': subCategories,
      'budget': budget,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'status': status.name,
      'cancellationReason': cancellationReason,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'technicianPhone': technicianPhone,
      'technicianRating': technicianRating,
      'customerRating': customerRating,
      'customerReview': customerReview,
      'isUrgent': isUrgent,
      'images': images,
      'serviceCharge':serviceCharge
    };
  }

  TaskModel copyWith({TaskStatus? status}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      pincode: pincode,


      countryCode: countryCode,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,

      latitude: latitude,
      longitude: longitude,
      category: category,
      subCategories: subCategories,
      budget: budget,
      createdAt: createdAt,
      scheduledDate: scheduledDate,
      acceptedAt: acceptedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      status: status ?? this.status,
      cancellationReason: cancellationReason,
      technicianId: technicianId,
      technicianName: technicianName,
      technicianPhone: technicianPhone,
      technicianRating: technicianRating,
      customerRating: customerRating,
      customerReview: customerReview,
      isUrgent: isUrgent,
      images: images,
        serviceCharge:serviceCharge
    );
  }
}
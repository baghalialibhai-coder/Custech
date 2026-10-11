// lib/Merchants_Screen/add_parts/models/part_model.dart

class PartModel {
  final String partId;
  final String merchantId;
  final String storeName;
  final String partName;
  final String brand;
  final String compatibility;
  final double price;
  final int stock;
  final String category;
  final String description;
  final List<String> images;
  final DateTime createdAt;

  PartModel({
    required this.partId,
    required this.merchantId,
    required this.storeName,
    required this.partName,
    required this.brand,
    required this.compatibility,
    required this.price,
    required this.stock,
    required this.category,
    required this.description,
    this.images = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'partId': partId,
    'merchantId': merchantId,
    'storeName': storeName,
    'partName': partName,
    'brand': brand,
    'compatibility': compatibility,
    'price': price,
    'stock': stock,
    'category': category,
    'description': description,
    'images': images,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PartModel.fromMap(Map<String, dynamic> map, String id) => PartModel(
    partId: id,
    merchantId: map['merchantId'] ?? '',
    storeName: map['storeName'] ?? '',
    partName: map['partName'] ?? '',
    brand: map['brand'] ?? '',
    compatibility: map['compatibility'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    stock: (map['stock'] ?? 0).toInt(),
    category: map['category'] ?? '',
    description: map['description'] ?? '',
    images: List<String>.from(map['images'] ?? []),
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
  );
}

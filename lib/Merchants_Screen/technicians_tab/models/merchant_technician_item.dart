// lib/Merchants_Screen/technicians_tab/models/merchant_technician_item.dart

import '../../../../core/models/technician_model.dart';

class MerchantTechnicianItem {
  final TechnicianModel technician;
  final String name;
  final String phone;
  final String profileImage;
  final String address;
  final double distanceInKm;

  MerchantTechnicianItem({
    required this.technician,
    required this.name,
    required this.phone,
    required this.profileImage,
    required this.address,
    required this.distanceInKm,
  });
}

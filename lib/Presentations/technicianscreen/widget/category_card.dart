import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  // ✅ Complete Icon Mapping with fallback
  IconData _getCategoryIcon(String category) {
    switch (category) {
    // ============================================================
    // 🔧 HOME SERVICES
    // ============================================================
      case 'Plumber':
        return Icons.plumbing;
      case 'Electrician':
        return Icons.electrical_services;
      case 'Carpenter':
        return Icons.handyman;
      case 'Painter':
        return Icons.brush;
      case 'Roofing':
        return Icons.roofing;
      case 'Tiling':
        return Icons.grid_on;
      case 'Flooring':
        return Icons.square_foot;
      case 'Cleaning Services':
        return Icons.cleaning_services;
      case 'Deep Cleaning':
        return Icons.cleaning_services;
      case 'Carpet Cleaning':
        return Icons.cleaning_services;
      case 'Sofa Cleaning':
        return Icons.cleaning_services;
      case 'Mattress Cleaning':
        return Icons.cleaning_services;
      case 'Curtain Cleaning':
        return Icons.cleaning_services;
      case 'Upholstery Cleaning':
        return Icons.cleaning_services;
      case 'Pest Control':
        return Icons.bug_report;
      case 'Termite Control':
        return Icons.bug_report;
      case 'Bed Bug Treatment':
        return Icons.bug_report;
      case 'Mosquito Control':
        return Icons.bug_report;
      case 'Waterproofing':
        return Icons.water;
      case 'Damp Proofing':
        return Icons.water;
      case 'Wall Crack Repair':
        return Icons.construction;
      case 'Grouting':
        return Icons.grid_on;
      case 'Epoxy Flooring':
        return Icons.square_foot;
      case 'Tile Grouting':
        return Icons.grid_on;
      case 'Bathroom Waterproofing':
        return Icons.water;
      case 'Plumbing Installation':
        return Icons.plumbing;

    // ============================================================
    // ❄️ APPLIANCE REPAIR
    // ============================================================
      case 'AC Repair':
        return Icons.ac_unit;
      case 'AC Installation':
        return Icons.ac_unit;
      case 'AC Gas Filling':
        return Icons.ac_unit;
      case 'AC Duct Cleaning':
        return Icons.ac_unit;
      case 'Refrigerator Repair':
        return Icons.kitchen;
      case 'Refrigerator Gas Filling':
        return Icons.kitchen;
      case 'Washing Machine Repair':
        return Icons.local_laundry_service;
      case 'Dryer Repair':
        return Icons.local_laundry_service;
      case 'Dishwasher Repair':
        return Icons.kitchen;
      case 'TV Repair':
        return Icons.tv;
      case 'LED/LCD TV Repair':
        return Icons.tv;
      case 'Microwave Repair':
        return Icons.microwave;
      case 'Geyser Repair':
        return Icons.water;
      case 'Water Purifier Repair':
        return Icons.water;
      case 'Chimney Repair':
        return Icons.fireplace;
      case 'Gas Stove Repair':
        return Icons.fireplace;
      case 'Mixer Grinder Repair':
        return Icons.blender; // ✅ Fixed: blender exists
      case 'Juicer Repair':
        return Icons.blender; // ✅ Fixed: blender exists
      case 'Oven Repair':
        return Icons.kitchen;
      case 'Air Fryer Repair':
        return Icons.kitchen;
      case 'Coffee Machine Repair':
        return Icons.coffee;
      case 'Vacuum Cleaner Repair':
        return Icons.cleaning_services;

    // ============================================================
    // 💻 TECH & ELECTRONICS
    // ============================================================
      case 'Computer Repair':
        return Icons.computer;
      case 'Laptop Repair':
        return Icons.laptop;
      case 'Mobile Repair':
        return Icons.phone_android;
      case 'Tablet Repair':
        return Icons.tablet;
      case 'Smartphone Repair':
        return Icons.phone_android;
      case 'iPhone Repair':
        return Icons.phone_iphone;
      case 'MacBook Repair':
        return Icons.laptop_mac;
      case 'Printer Repair':
        return Icons.print;
      case 'CCTV Installation':
        return Icons.videocam;
      case 'CCTV Repair':
        return Icons.videocam;
      case 'Home Automation':
        return Icons.hub;
      case 'Smart Home Setup':
        return Icons.settings_remote;
      case 'WiFi Installation':
        return Icons.wifi;
      case 'Network Setup':
        return Icons.wifi;
      case 'Server Installation':
        return Icons.storage;
      case 'Data Recovery':
        return Icons.data_usage;
      case 'Software Installation':
        return Icons.computer;
      case 'Virus Removal':
        return Icons.security;
      case 'Screen Replacement':
        return Icons.phone_android;
      case 'Battery Replacement':
        return Icons.battery_charging_full;

    // ============================================================
    // 🚗 AUTO SERVICES
    // ============================================================
      case 'Mechanic':
        return Icons.car_repair;
      case 'Auto Electrician':
        return Icons.car_repair;
      case 'Car AC Repair':
        return Icons.ac_unit;
      case 'Car Wash':
        return Icons.local_car_wash;
      case 'Car Detailing':
        return Icons.auto_fix_high;
      case 'Ceramic Coating':
        return Icons.shield;
      case 'PPF Installation':
        return Icons.security;
      case 'Car Wrapping':
        return Icons.style;
      case 'Bike Repair':
        return Icons.motorcycle;
      case 'Bike Service':
        return Icons.motorcycle;
      case 'Cycle Repair':
        return Icons.pedal_bike;
      case 'Tyre Puncture':
        return Icons.car_repair;
      case 'Tyre Replacement':
        return Icons.car_repair;
      case 'Engine Repair':
        return Icons.car_repair;
      case 'Brake Repair':
        return Icons.car_repair;
      case 'Clutch Repair':
        return Icons.car_repair;
      case 'Transmission Repair':
        return Icons.car_repair;
      case 'Oil Change':
        return Icons.car_repair;
      case 'Battery Replacement':
        return Icons.car_repair;
      case 'Car Suspension Repair':
        return Icons.car_repair;
      case 'Car Alignment':
        return Icons.car_repair;
      case 'Car Painting':
        return Icons.brush;
      case 'Denting and Painting':
        return Icons.brush;
      case 'Car Interior Cleaning':
        return Icons.cleaning_services;

    // ============================================================
    // 🔨 CONSTRUCTION LABOR (MAZDOOR)
    // ============================================================
      case 'Labor Contractor':
        return Icons.people;
      case 'Construction Labor':
        return Icons.people;
      case 'Building Construction':
        return Icons.apartment;
      case 'House Construction':
        return Icons.house;
      case 'Commercial Building Construction':
        return Icons.business_center;
      case 'Residential Building Construction':
        return Icons.house;
      case 'High-Rise Building Construction':
        return Icons.apartment;
      case 'Boundary Wall Construction':
        return Icons.construction;
      case 'Retaining Wall Construction':
        return Icons.construction;
      case 'Mason (Raj Mistri)':
        return Icons.construction;
      case 'Shuttering Carpenter':
        return Icons.handyman;
      case 'Steel Fixer (Saria)':
        return Icons.construction;
      case 'Plaster Worker (Pala)':
        return Icons.construction;
      case 'Flooring Worker':
        return Icons.square_foot;
      case 'Marble Worker':
        return Icons.construction;
      case 'Granite Worker':
        return Icons.construction;
      case 'Tile Worker':
        return Icons.grid_on;
      case 'Stone Worker':
        return Icons.construction;
      case 'Foundation Work':
        return Icons.apartment;
      case 'Column Casting':
        return Icons.apartment;
      case 'Beam Work':
        return Icons.apartment;
      case 'Slab Casting':
        return Icons.apartment;
      case 'RCC Work':
        return Icons.apartment;
      case 'PCC Work':
        return Icons.apartment;
      case 'Reinforcement Work':
        return Icons.construction;
      case 'Formwork Installation':
        return Icons.handyman;
      case 'Scaffolding Work':
        return Icons.handyman;
      case 'Centering Work':
        return Icons.handyman;
      case 'Concrete Worker':
        return Icons.foundation;
      case 'Rebar Worker':
        return Icons.construction;

    // ============================================================
    // 🏗️ CONSTRUCTION CONTRACTORS (THEQA)
    // ============================================================
      case 'Building Contractor':
        return Icons.apartment;
      case 'Construction Contractor':
        return Icons.apartment;
      case 'Civil Contractor':
        return Icons.apartment;
      case 'Real Estate Developer':
        return Icons.business_center;
      case 'Turnkey Contractor':
        return Icons.apartment;
      case 'EPC Contractor':
        return Icons.apartment;
      case 'Project Manager':
        return Icons.person;
      case 'Construction Management':
        return Icons.person;
      case 'Site Supervisor':
        return Icons.person;
      case 'Construction Manager':
        return Icons.person;
      case 'Electrical Contractor':
        return Icons.electrical_services;
      case 'Plumbing Contractor':
        return Icons.plumbing;
      case 'HVAC Contractor':
        return Icons.ac_unit;
      case 'Fire Safety Contractor':
        return Icons.fire_extinguisher;
      case 'Elevator Contractor':
        return Icons.elevator;
      case 'Solar Contractor':
        return Icons.solar_power;
      case 'Landscaping Contractor':
        return Icons.grass;
      case 'Interior Contractor':
        return Icons.home;
      case 'Exterior Contractor':
        return Icons.home;
      case 'Roofing Contractor':
        return Icons.roofing;
      case 'Government Contractor':
        return Icons.business_center;
      case 'Private Contractor':
        return Icons.business_center;
      case 'Residential Contractor':
        return Icons.house;
      case 'Commercial Contractor':
        return Icons.business_center;
      case 'Industrial Contractor':
        return Icons.factory;
      case 'Infrastructure Contractor':
        return Icons.apartment;
      case 'Road Contractor':
        return Icons.add_road;
      case 'Bridge Contractor':
        return Icons.apartment;
      case 'Dam Contractor':
        return Icons.water;
      case 'Tunnel Contractor':
        return Icons.apartment;
      case 'Project Estimation':
        return Icons.calculate;
      case 'Project Planning':
        return Icons.calculate;
      case 'Project Supervision':
        return Icons.person;
      case 'Quality Control':
        return Icons.check_circle;
      case 'Safety Management':
        return Icons.security;
      case 'Cost Estimation':
        return Icons.calculate;
      case 'Bill of Quantities':
        return Icons.calculate;
      case 'Tendering Service':
        return Icons.calculate;
      case 'Construction Drawings':
        return Icons.architecture;
      case 'Structural Design':
        return Icons.architecture;

    // ============================================================
    // 📦 MATERIAL SUPPLIERS
    // ============================================================
      case 'Building Material Supplier':
        return Icons.store;
      case 'Cement Supplier':
        return Icons.store;
      case 'Steel Supplier':
        return Icons.store;
      case 'Brick Supplier':
        return Icons.store;
      case 'Sand Supplier':
        return Icons.store;
      case 'Aggregate Supplier':
        return Icons.store;
      case 'Tiles Supplier':
        return Icons.store;
      case 'Marble Supplier':
        return Icons.store;
      case 'Granite Supplier':
        return Icons.store;
      case 'Wood Supplier':
        return Icons.store;
      case 'Paint Supplier':
        return Icons.store;
      case 'Electrical Material Supplier':
        return Icons.store;
      case 'Plumbing Material Supplier':
        return Icons.store;
      case 'Hardware Supplier':
        return Icons.store;
      case 'Glass Supplier':
        return Icons.store;
      case 'Aluminum Supplier':
        return Icons.store;
      case 'PVC Supplier':
        return Icons.store;
      case 'Pipe Supplier':
        return Icons.store;
      case 'Water Tank Supplier':
        return Icons.store;
      case 'Solar Panel Supplier':
        return Icons.store;
      case 'Roofing Material Supplier':
        return Icons.store;
      case 'Insulation Material Supplier':
        return Icons.store;
      case 'Flooring Material Supplier':
        return Icons.store;
      case 'Sanitary Supplier':
        return Icons.store;
      case 'Kitchen Cabinet Supplier':
        return Icons.store;

    // ============================================================
    // 🪑 FURNITURE & INTERIOR
    // ============================================================
      case 'Furniture Assembly':
        return Icons.chair;
      case 'Furniture Repair':
        return Icons.chair;
      case 'Furniture Restoration':
        return Icons.chair;
      case 'Upholstery':
        return Icons.chair;
      case 'Curtain Installation':
        return Icons.curtains;
      case 'Blinds Installation':
        return Icons.curtains;
      case 'Wallpaper Installation':
        return Icons.wallpaper;
      case 'Window Repair':
        return Icons.window;
      case 'Door Repair':
        return Icons.door_front_door;
      case 'Garage Door Repair':
        return Icons.garage;
      case 'Kitchen Cabinet Installation':
        return Icons.kitchen;
      case 'Wardrobe Installation':
        return Icons.checkroom;
      case 'Modular Kitchen':
        return Icons.kitchen;
      case 'Interior Design':
        return Icons.design_services;
      case 'Space Planning':
        return Icons.design_services;
      case 'Wall Paneling':
        return Icons.wallpaper;
      case 'Wood Polishing':
        return Icons.brush;
      case 'Laminate Flooring':
        return Icons.square_foot;
      case 'Hardwood Flooring':
        return Icons.square_foot;

    // ============================================================
    // 🌿 OUTDOOR & GARDEN
    // ============================================================
      case 'Gardening':
        return Icons.grass;
      case 'Landscaping':
        return Icons.landscape;
      case 'Tree Trimming':
        return Icons.grass;
      case 'Tree Removal':
        return Icons.grass;
      case 'Lawn Mowing':
        return Icons.grass;
      case 'Garden Design':
        return Icons.landscape;
      case 'Irrigation Installation':
        return Icons.water;
      case 'Fencing':
        return Icons.fence;
      case 'Deck Installation':
        return Icons.home;
      case 'Patio Construction':
        return Icons.home;
      case 'Outdoor Lighting':
        return Icons.light;
      case 'Garden Shed Installation':
        return Icons.home;
      case 'Pond Installation':
        return Icons.water;
      case 'Water Feature Installation':
        return Icons.water;
      case 'Artificial Grass Installation':
        return Icons.grass;
      case 'Pergola Installation':
        return Icons.home;

    // ============================================================
    // 🔥 SPECIALIZED SERVICES
    // ============================================================
      case 'HVAC Technician':
        return Icons.ac_unit;
      case 'Security System Installation':
        return Icons.security;
      case 'Fire Alarm Installation':
        return Icons.fire_extinguisher;
      case 'Fire Extinguisher Service':
        return Icons.fire_extinguisher;
      case 'Elevator Repair':
        return Icons.elevator;
      case 'Escalator Repair':
        return Icons.elevator;
      case 'Water Pump Repair':
        return Icons.water;
      case 'Motor Winding':
        return Icons.electrical_services;
      case 'Generator Repair':
        return Icons.electrical_services;
      case 'Inverter Repair':
        return Icons.electrical_services;
      case 'UPS Repair':
        return Icons.electrical_services;
      case 'Compressor Repair':
        return Icons.build;
      case 'Boiler Installation':
        return Icons.water;
      case 'Boiler Repair':
        return Icons.water;
      case 'Solar Water Heater':
        return Icons.solar_power;
      case 'Heat Pump Installation':
        return Icons.ac_unit;
      case 'Ventilation System':
        return Icons.air;
      case 'Air Purifier Installation':
        return Icons.air;
      case 'Humidifier Installation':
        return Icons.water;
      case 'Dehumidifier Installation':
        return Icons.water;

    // ============================================================
    // 🎉 EVENT & RENTAL SERVICES
    // ============================================================
      case 'Locksmith':
        return Icons.lock;
      case 'Event Setup':
        return Icons.event;
      case 'Tent Installation':
        return Icons.weekend;
      case 'Stage Setup':
        return Icons.stadium;
      case 'Lighting Installation':
        return Icons.light;
      case 'Sound System Setup':
        return Icons.speaker;
      case 'Home Theater Installation':
        return Icons.tv;
      case 'Smart Home Setup':
        return Icons.hub;
      case 'DJ Services':
        return Icons.music_note;
      case 'Event Decoration':
        return Icons.event;
      case 'Catering Setup':
        return Icons.restaurant;
      case 'Party Planning':
        return Icons.celebration;

    // ============================================================
    // 🏠 PROPERTY & MAINTENANCE
    // ============================================================
      case 'Property Management':
        return Icons.business_center;
      case 'Building Maintenance':
        return Icons.apartment;
      case 'Facility Management':
        return Icons.business_center;
      case 'Snow Removal':
        return Icons.ac_unit;
      case 'Gutter Cleaning':
        return Icons.cleaning_services;
      case 'Window Cleaning':
        return Icons.cleaning_services;
      case 'Pressure Washing':
        return Icons.cleaning_services;
      case 'Swimming Pool Installation':
        return Icons.pool;
      case 'Swimming Pool Cleaning':
        return Icons.pool;
      case 'Sauna Installation':
        return Icons.hot_tub;
      case 'Jacuzzi Installation':
        return Icons.hot_tub;
      case 'Playground Equipment Installation':
        return Icons.play_arrow;

    // ============================================================
    // 🏥 HEALTH & WELLNESS
    // ============================================================
      case 'Gym Equipment Installation':
        return Icons.fitness_center;
      case 'Gym Equipment Repair':
        return Icons.fitness_center;
      case 'Home Gym Setup':
        return Icons.fitness_center;
      case 'Treadmill Repair':
        return Icons.fitness_center;
      case 'Exercise Bike Repair':
        return Icons.fitness_center;
      case 'Yoga Studio Setup':
        return Icons.self_improvement;
      case 'Pilates Equipment':
        return Icons.fitness_center;
      case 'Sauna Repair':
        return Icons.hot_tub;

    // ============================================================
    // 🏫 EDUCATIONAL & OFFICE
    // ============================================================
      case 'Office Setup':
        return Icons.work;
      case 'Workstation Installation':
        return Icons.work;
      case 'Whiteboard Installation':
        return Icons.edit_note;
      case 'Projector Installation':
        return Icons.present_to_all;
      case 'Smart Board Installation':
        return Icons.touch_app;
      case 'School Furniture Assembly':
        return Icons.school;
      case 'Library Setup':
        return Icons.local_library;
      case 'Lab Equipment Installation':
        return Icons.science;

    // ============================================================
    // 🐾 PET SERVICES
    // ============================================================
      case 'Pet Grooming':
        return Icons.pets;
      case 'Pet Sitting':
        return Icons.pets;
      case 'Dog Walking':
        return Icons.pets;
      case 'Pet Training':
        return Icons.pets;
      case 'Pet Boarding':
        return Icons.pets;

    // ============================================================
    // 🆕 EMERGING & FUTURE CATEGORIES
    // ============================================================
      case 'EV Charger Installation':
        return Icons.ev_station;
      case 'Electric Vehicle Repair':
        return Icons.ev_station;
      case 'E-Bike Repair':
        return Icons.motorcycle;
      case 'Drone Repair':
        return Icons.flight;
      case '3D Printing Services':
        return Icons.print;
      case 'Laser Cutting':
        return Icons.handyman;
      case 'CNC Machining':
        return Icons.handyman;
      case 'Home Theater Calibration':
        return Icons.tv;
      case 'Acoustic Treatment':
        return Icons.speaker;
      case 'Soundproofing':
        return Icons.speaker;
      case 'Energy Audit':
        return Icons.energy_savings_leaf;
      case 'Smart Meter Installation':
        return Icons.electrical_services;
      case 'Water Softener Installation':
        return Icons.water;
      case 'RO System Installation':
        return Icons.water;
      case 'Rainwater Harvesting':
        return Icons.water;
      case 'Greywater System':
        return Icons.water;
      case 'Composting Setup':
        return Icons.eco;
      case 'Vertical Garden':
        return Icons.grass;
      case 'Hydroponic System':
        return Icons.grass;
      case 'Aquaponics System':
        return Icons.grass;
      case 'Greenhouse Installation':
        return Icons.grass;
      case 'Gym Equipment Installation':
        return Icons.fitness_center;
      case 'Playground Equipment':
        return Icons.play_arrow;
      case 'Trampoline Installation':
        return Icons.play_arrow;
      case 'Pool Table Installation':
        return Icons.sports;
      case 'Bowling Alley Installation':
        return Icons.sports;
      case 'Gaming Console Setup':
        return Icons.sports_esports;
      case 'VR Room Setup':
        return Icons.view_in_ar;
      case 'Home Office Setup':
        return Icons.work;
      case 'Ergonomic Assessment':
        return Icons.work;
      case 'Accessibility Installation':
        return Icons.accessible;
      case 'Smart Lock Installation':
        return Icons.lock;
      case 'Video Doorbell Installation':
        return Icons.videocam;
      case 'Home Security Audit':
        return Icons.security;

    // ============================================================
    // DEFAULT
    // ============================================================
      default:
        return Icons.build_circle;
    }
  }

  // ✅ Get color based on category
  Color _getCategoryColor(String category) {
    if (category.contains('Repair') || category.contains('Service')) {
      return Colors.blue;
    } else if (category.contains('Installation') || category.contains('Setup')) {
      return Colors.green;
    } else if (category.contains('Cleaning')) {
      return Colors.teal;
    } else if (category.contains('Construction') || category.contains('Contractor')) {
      return Colors.orange;
    } else if (category.contains('Auto') || category.contains('Car') || category.contains('Bike')) {
      return Colors.red;
    } else if (category.contains('Tech') || category.contains('Computer') || category.contains('Mobile')) {
      return Colors.purple;
    } else if (category.contains('Home') || category.contains('Furniture')) {
      return Colors.brown;
    } else if (category.contains('Health') || category.contains('Gym')) {
      return Colors.pink;
    } else if (category.contains('Pet')) {
      return Colors.amber;
    } else if (category.contains('Event') || category.contains('Party')) {
      return Colors.deepOrange;
    } else {
      return const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? Colors.white : _getCategoryColor(category);
    final bgColor = isSelected ? const Color(0xFF1A237E) : Colors.grey[100];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              color: iconColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              category,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
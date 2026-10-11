// lib/Presentations/customer_screen/screens/service_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/currency_picker.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/models/task_model.dart';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../data/currencies_data.dart';
import '../../../services/firebase_matching_service.dart';
import '../../../services/one_Signal_Service.dart';
import '../../../services/task_service.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../Auth_Screens/Auth/auth_providers/user_data_provider.dart';
import '../../User_Location/widgets/location_picker_screen.dart';
import '../../ai_screen/ai_matching_screen.dart';
import 'SuccessfulScreen.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String category; // ✅ English name from AppCategories

  const ServiceDetailScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final TaskService _taskService = TaskService();
  final FirebaseMatchingService _matchingService = FirebaseMatchingService();

  // ✅ Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // ✅ Location Variables
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String _selectedAddress = '';
  String _selectedPincode = '';

  // ✅ Currency
  CurrencyModel _selectedCurrency = CurrenciesData.getCurrencyByCode('PKR') ??
      CurrenciesData.currencies.first;

  bool _isLoading = false;
  bool _currencyInitialized = false;
  String? _taskImageUrl;

  // ============================================================
  // ✅ HELPER: Convert English Name to Key
  // ============================================================
  String _getCategoryKey() {
    final keyMap = {
      // Appliance Repair
      'AC Repair': 'ac_repair',
      'AC Installation': 'ac_installation',
      'Refrigerator Repair': 'refrigerator_repair',
      'Refrigerator Gas Filling': 'refrigerator_gas_filling',
      'Washing Machine Repair': 'washing_machine_repair',
      'Dryer Repair': 'dryer_repair',
      'Dishwasher Repair': 'dishwasher_repair',
      'TV Repair': 'tv_repair',
      'LED/LCD TV Repair': 'led_lcd_tv_repair',
      'Microwave Repair': 'microwave_repair',
      'Geyser Repair': 'geyser_repair',
      'Water Purifier Repair': 'water_purifier_repair',
      'Chimney Repair': 'chimney_repair',
      'Gas Stove Repair': 'gas_stove_repair',
      'Mixer Grinder Repair': 'mixer_grinder_repair',
      'Juicer Repair': 'juicer_repair',
      'Oven Repair': 'oven_repair',
      'Air Fryer Repair': 'air_fryer_repair',
      'Coffee Machine Repair': 'coffee_machine_repair',
      'Vacuum Cleaner Repair': 'vacuum_cleaner_repair',
      // Home Services
      'Plumber': 'plumber',
      'Electrician': 'electrician',
      'Carpenter': 'carpenter',
      'Painter': 'painter',
      'Roofing': 'roofing',
      'Tiling': 'tiling',
      'Flooring': 'flooring',
      'Cleaning Services': 'cleaning_services',
      'Deep Cleaning': 'deep_cleaning',
      'Carpet Cleaning': 'carpet_cleaning',
      'Sofa Cleaning': 'sofa_cleaning',
      'Mattress Cleaning': 'mattress_cleaning',
      'Curtain Cleaning': 'curtain_cleaning',
      'Upholstery Cleaning': 'upholstery_cleaning',
      'Pest Control': 'pest_control',
      'Termite Control': 'termite_control',
      'Bed Bug Treatment': 'bed_bug_treatment',
      'Mosquito Control': 'mosquito_control',
      'Waterproofing': 'waterproofing',
      'Damp Proofing': 'damp_proofing',
      'Wall Crack Repair': 'wall_crack_repair',
      'Grouting': 'grouting',
      'Epoxy Flooring': 'epoxy_flooring',
      'Tile Grouting': 'tile_grouting',
      'Bathroom Waterproofing': 'bathroom_waterproofing',
      // Auto Services
      'Mechanic': 'mechanic',
      'Auto Electrician': 'auto_electrician',
      'Car AC Repair': 'car_ac_repair',
      'Car Wash': 'car_wash',
      'Car Detailing': 'car_detailing',
      'Ceramic Coating': 'ceramic_coating',
      'PPF Installation': 'ppf_installation',
      'Car Wrapping': 'car_wrapping',
      'Bike Repair': 'bike_repair',
      'Bike Service': 'bike_service',
      'Cycle Repair': 'cycle_repair',
      'Tyre Puncture': 'tyre_puncture',
      'Tyre Replacement': 'tyre_replacement',
      'Engine Repair': 'engine_repair',
      'Brake Repair': 'brake_repair',
      'Clutch Repair': 'clutch_repair',
      'Transmission Repair': 'transmission_repair',
      'Oil Change': 'oil_change',
      'Battery Replacement': 'battery_replacement',
      'Car Suspension Repair': 'car_suspension_repair',
      'Car Alignment': 'car_alignment',
      'Car Painting': 'car_painting',
      'Denting and Painting': 'denting_and_painting',
      'Car Interior Cleaning': 'car_interior_cleaning',
      // Construction Labor
      'Labor Contractor': 'labor_contractor',
      'Construction Labor': 'construction_labor',
      'Building Construction': 'building_construction',
      'House Construction': 'house_construction',
      'Commercial Building Construction': 'commercial_building_construction',
      'Residential Building Construction': 'residential_building_construction',
      'High-Rise Building Construction': 'high_rise_building_construction',
      'Boundary Wall Construction': 'boundary_wall_construction',
      'Retaining Wall Construction': 'retaining_wall_construction',
      'Mason (Raj Mistri)': 'mason',
      'Shuttering Carpenter': 'shuttering_carpenter',
      'Steel Fixer (Saria)': 'steel_fixer',
      'Plaster Worker (Pala)': 'plaster_worker',
      'Flooring Worker': 'flooring_worker',
      'Marble Worker': 'marble_worker',
      'Granite Worker': 'granite_worker',
      'Tile Worker': 'tile_worker',
      'Stone Worker': 'stone_worker',
      'Foundation Work': 'foundation_work',
      'Column Casting': 'column_casting',
      'Beam Work': 'beam_work',
      'Slab Casting': 'slab_casting',
      'RCC Work': 'rcc_work',
      'PCC Work': 'pcc_work',
      'Reinforcement Work': 'reinforcement_work',
      'Formwork Installation': 'formwork_installation',
      'Scaffolding Work': 'scaffolding_work',
      'Centering Work': 'centering_work',
      'Concrete Worker': 'concrete_worker',
      'Rebar Worker': 'rebar_worker',
      // Contractors
      'Building Contractor': 'building_contractor',
      'Construction Contractor': 'construction_contractor',
      'Civil Contractor': 'civil_contractor',
      'Real Estate Developer': 'real_estate_developer',
      'Turnkey Contractor': 'turnkey_contractor',
      'EPC Contractor': 'epc_contractor',
      'Project Manager': 'project_manager',
      'Construction Management': 'construction_management',
      'Site Supervisor': 'site_supervisor',
      'Construction Manager': 'construction_manager',
      'Electrical Contractor': 'electrical_contractor',
      'Plumbing Contractor': 'plumbing_contractor',
      'HVAC Contractor': 'hvac_contractor',
      'Fire Safety Contractor': 'fire_safety_contractor',
      'Elevator Contractor': 'elevator_contractor',
      'Solar Contractor': 'solar_contractor',
      'Landscaping Contractor': 'landscaping_contractor',
      'Interior Contractor': 'interior_contractor',
      'Exterior Contractor': 'exterior_contractor',
      'Roofing Contractor': 'roofing_contractor',
      'Government Contractor': 'government_contractor',
      'Private Contractor': 'private_contractor',
      'Residential Contractor': 'residential_contractor',
      'Commercial Contractor': 'commercial_contractor',
      'Industrial Contractor': 'industrial_contractor',
      'Infrastructure Contractor': 'infrastructure_contractor',
      'Road Contractor': 'road_contractor',
      'Bridge Contractor': 'bridge_contractor',
      'Dam Contractor': 'dam_contractor',
      'Tunnel Contractor': 'tunnel_contractor',
      'Project Estimation': 'project_estimation',
      'Project Planning': 'project_planning',
      'Project Supervision': 'project_supervision',
      'Quality Control': 'quality_control',
      'Safety Management': 'safety_management',
      'Cost Estimation': 'cost_estimation',
      'Bill of Quantities': 'bill_of_quantities',
      'Tendering Service': 'tendering_service',
      'Construction Drawings': 'construction_drawings',
      'Structural Design': 'structural_design',
      // Material Suppliers
      'Building Material Supplier': 'building_material_supplier',
      'Cement Supplier': 'cement_supplier',
      'Steel Supplier': 'steel_supplier',
      'Brick Supplier': 'brick_supplier',
      'Sand Supplier': 'sand_supplier',
      'Aggregate Supplier': 'aggregate_supplier',
      'Tiles Supplier': 'tiles_supplier',
      'Marble Supplier': 'marble_supplier',
      'Granite Supplier': 'granite_supplier',
      'Wood Supplier': 'wood_supplier',
      'Paint Supplier': 'paint_supplier',
      'Electrical Material Supplier': 'electrical_material_supplier',
      'Plumbing Material Supplier': 'plumbing_material_supplier',
      'Hardware Supplier': 'hardware_supplier',
      'Glass Supplier': 'glass_supplier',
      'Aluminum Supplier': 'aluminum_supplier',
      'PVC Supplier': 'pvc_supplier',
      'Pipe Supplier': 'pipe_supplier',
      'Water Tank Supplier': 'water_tank_supplier',
      'Solar Panel Supplier': 'solar_panel_supplier',
      'Roofing Material Supplier': 'roofing_material_supplier',
      'Insulation Material Supplier': 'insulation_material_supplier',
      'Flooring Material Supplier': 'flooring_material_supplier',
      'Sanitary Supplier': 'sanitary_supplier',
      'Kitchen Cabinet Supplier': 'kitchen_cabinet_supplier',
      // Furniture
      'Furniture Assembly': 'furniture_assembly',
      'Furniture Repair': 'furniture_repair',
      'Furniture Restoration': 'furniture_restoration',
      'Upholstery': 'upholstery',
      'Curtain Installation': 'curtain_installation',
      'Blinds Installation': 'blinds_installation',
      'Wallpaper Installation': 'wallpaper_installation',
      'Window Repair': 'window_repair',
      'Door Repair': 'door_repair',
      'Garage Door Repair': 'garage_door_repair',
      'Kitchen Cabinet Installation': 'kitchen_cabinet_installation',
      'Wardrobe Installation': 'wardrobe_installation',
      'Modular Kitchen': 'modular_kitchen',
      'Interior Design': 'interior_design',
      'Space Planning': 'space_planning',
      'Wall Paneling': 'wall_paneling',
      'Wood Polishing': 'wood_polishing',
      'Laminate Flooring': 'laminate_flooring',
      'Hardwood Flooring': 'hardwood_flooring',
      // Outdoor
      'Gardening': 'gardening',
      'Landscaping': 'landscaping',
      'Tree Trimming': 'tree_trimming',
      'Tree Removal': 'tree_removal',
      'Lawn Mowing': 'lawn_mowing',
      'Garden Design': 'garden_design',
      'Irrigation Installation': 'irrigation_installation',
      'Fencing': 'fencing',
      'Deck Installation': 'deck_installation',
      'Patio Construction': 'patio_construction',
      'Outdoor Lighting': 'outdoor_lighting',
      'Garden Shed Installation': 'garden_shed_installation',
      'Pond Installation': 'pond_installation',
      'Water Feature Installation': 'water_feature_installation',
      'Artificial Grass Installation': 'artificial_grass_installation',
      'Pergola Installation': 'pergola_installation',
      // Specialized
      'HVAC Technician': 'hvac_technician',
      'Security System Installation': 'security_system_installation',
      'Fire Alarm Installation': 'fire_alarm_installation',
      'Fire Extinguisher Service': 'fire_extinguisher_service',
      'Elevator Repair': 'elevator_repair',
      'Escalator Repair': 'escalator_repair',
      'Water Pump Repair': 'water_pump_repair',
      'Motor Winding': 'motor_winding',
      'Generator Repair': 'generator_repair',
      'Inverter Repair': 'inverter_repair',
      'UPS Repair': 'ups_repair',
      'Compressor Repair': 'compressor_repair',
      'Boiler Installation': 'boiler_installation',
      'Boiler Repair': 'boiler_repair',
      'Solar Water Heater': 'solar_water_heater',
      'Heat Pump Installation': 'heat_pump_installation',
      'Ventilation System': 'ventilation_system',
      'Air Purifier Installation': 'air_purifier_installation',
      'Humidifier Installation': 'humidifier_installation',
      'Dehumidifier Installation': 'dehumidifier_installation',
      // Event
      'Locksmith': 'locksmith',
      'Event Setup': 'event_setup',
      'Tent Installation': 'tent_installation',
      'Stage Setup': 'stage_setup',
      'Lighting Installation': 'lighting_installation',
      'Sound System Setup': 'sound_system_setup',
      'Home Theater Installation': 'home_theater_installation',
      'DJ Services': 'dj_services',
      'Event Decoration': 'event_decoration',
      'Catering Setup': 'catering_setup',
      'Party Planning': 'party_planning',
      // Property
      'Property Management': 'property_management',
      'Building Maintenance': 'building_maintenance',
      'Facility Management': 'facility_management',
      'Snow Removal': 'snow_removal',
      'Gutter Cleaning': 'gutter_cleaning',
      'Window Cleaning': 'window_cleaning',
      'Pressure Washing': 'pressure_washing',
      'Swimming Pool Installation': 'swimming_pool_installation',
      'Swimming Pool Cleaning': 'swimming_pool_cleaning',
      'Sauna Installation': 'sauna_installation',
      'Jacuzzi Installation': 'jacuzzi_installation',
      'Playground Equipment Installation': 'playground_equipment_installation',
      // Health
      'Gym Equipment Installation': 'gym_equipment_installation',
      'Gym Equipment Repair': 'gym_equipment_repair',
      'Home Gym Setup': 'home_gym_setup',
      'Treadmill Repair': 'treadmill_repair',
      'Exercise Bike Repair': 'exercise_bike_repair',
      'Yoga Studio Setup': 'yoga_studio_setup',
      'Pilates Equipment': 'pilates_equipment',
      'Sauna Repair': 'sauna_repair',
      // Educational
      'Office Setup': 'office_setup',
      'Workstation Installation': 'workstation_installation',
      'Whiteboard Installation': 'whiteboard_installation',
      'Projector Installation': 'projector_installation',
      'Smart Board Installation': 'smart_board_installation',
      'School Furniture Assembly': 'school_furniture_assembly',
      'Library Setup': 'library_setup',
      'Lab Equipment Installation': 'lab_equipment_installation',
      // Pet
      'Pet Grooming': 'pet_grooming',
      'Pet Sitting': 'pet_sitting',
      'Dog Walking': 'dog_walking',
      'Pet Training': 'pet_training',
      'Pet Boarding': 'pet_boarding',
      // Emerging
      'EV Charger Installation': 'ev_charger_installation',
      'Electric Vehicle Repair': 'electric_vehicle_repair',
      'E-Bike Repair': 'e_bike_repair',
      'Drone Repair': 'drone_repair',
      '3D Printing Services': '3d_printing_services',
      'Laser Cutting': 'laser_cutting',
      'CNC Machining': 'cnc_machining',
      'Home Theater Calibration': 'home_theater_calibration',
      'Acoustic Treatment': 'acoustic_treatment',
      'Soundproofing': 'soundproofing',
      'Energy Audit': 'energy_audit',
      'Smart Meter Installation': 'smart_meter_installation',
      'Water Softener Installation': 'water_softener_installation',
      'RO System Installation': 'ro_system_installation',
      'Rainwater Harvesting': 'rainwater_harvesting',
      'Greywater System': 'greywater_system',
      'Composting Setup': 'composting_setup',
      'Vertical Garden': 'vertical_garden',
      'Hydroponic System': 'hydroponic_system',
      'Aquaponics System': 'aquaponics_system',
      'Greenhouse Installation': 'greenhouse_installation',
      'solar_panel_installation': 'solar_panel_installation',
      'Playground Equipment': 'playground_equipment',
      'Trampoline Installation': 'trampoline_installation',
      'Pool Table Installation': 'pool_table_installation',
      'Bowling Alley Installation': 'bowling_alley_installation',
      'Gaming Console Setup': 'gaming_console_setup',
      'VR Room Setup': 'vr_room_setup',
      'Home Office Setup': 'home_office_setup',
      'Ergonomic Assessment': 'ergonomic_assessment',
      'Accessibility Installation': 'accessibility_installation',
      'Smart Lock Installation': 'smart_lock_installation',
      'Video Doorbell Installation': 'video_doorbell_installation',
      'Home Security Audit': 'home_security_audit',
      'Fuel Delivery': 'fuel_delivery',
      'Emergency Fuel Delivery': 'emergency_fuel_delivery',
      'Car Towing': 'car_towing',
      'Bike Towing': 'bike_towing',
      'Roadside Assistance': 'roadside_assistance',
      'Car Jump Start': 'car_jump_start',
      'Battery Delivery': 'battery_delivery',
      'Flat Tyre Assistance': 'flat_tyre_assistance',
      'Tyre Change Assistance': 'tyre_change_assistance',
      'Mobile Mechanic': 'mobile_mechanic',
      'Lockout Assistance': 'lockout_assistance',
      'Car Key Replacement': 'car_key_replacement',
      'Emergency Car Repair': 'emergency_car_repair',
      'Vehicle Recovery': 'vehicle_recovery',
      'Winch Service': 'winch_service',
    };
    return keyMap[widget.category] ?? widget.category.toLowerCase().replaceAll(' ', '_');
  }

  // ============================================================
  // ✅ CATEGORY LOGIC (Using English Names from AppCategories)
  // ============================================================

  String _getServiceType() {
    final manualCategories = [
      'Plumber', 'Electrician', 'Carpenter', 'Painter', 'Mechanic',
      'Locksmith', 'Roofing', 'Tiling', 'Flooring',
    ];
    return manualCategories.contains(widget.category)
        ? context.tr('manualService')
        : context.tr('autoService');
  }

  IconData _getServiceIcon() {
    switch (widget.category) {
    // ============================================================
    // ❄️ APPLIANCE REPAIR
    // ============================================================
      case 'AC Repair':
      case 'AC Installation':
        return Icons.ac_unit;
      case 'Refrigerator Repair':
      case 'Refrigerator Gas Filling':
        return Icons.kitchen;
      case 'Washing Machine Repair':
      case 'Dryer Repair':
        return Icons.local_laundry_service;
      case 'Dishwasher Repair':
      case 'Oven Repair':
      case 'Air Fryer Repair':
        return Icons.kitchen;
      case 'TV Repair':
      case 'LED/LCD TV Repair':
        return Icons.tv;
      case 'Microwave Repair':
        return Icons.microwave;
      case 'Geyser Repair':
      case 'Water Purifier Repair':
        return Icons.water;
      case 'Chimney Repair':
      case 'Gas Stove Repair':
        return Icons.fireplace;
      case 'Mixer Grinder Repair':
      case 'Juicer Repair':
        return Icons.blender;
      case 'Coffee Machine Repair':
        return Icons.coffee;
      case 'Vacuum Cleaner Repair':
        return Icons.cleaning_services;
      case 'solar_panel_installation':
        return Icons.solar_power;

    // ============================================================
    // 🔨 CONSTRUCTION LABOR
    // ============================================================
      case 'Labor Contractor':
      case 'Construction Labor':
        return Icons.people;
      case 'Building Construction':
      case 'High-Rise Building Construction':
      case 'Foundation Work':
      case 'Column Casting':
      case 'Beam Work':
      case 'Slab Casting':
      case 'RCC Work':
      case 'PCC Work':
        return Icons.apartment;
      case 'House Construction':
      case 'Residential Building Construction':
        return Icons.house;
      case 'Commercial Building Construction':
        return Icons.business_center;
      case 'Boundary Wall Construction':
      case 'Retaining Wall Construction':
      case 'Steel Fixer (Saria)':
      case 'Plaster Worker (Pala)':
      case 'Marble Worker':
      case 'Granite Worker':
      case 'Stone Worker':
      case 'Reinforcement Work':
        return Icons.construction;
      case 'Mason (Raj Mistri)':
        return Icons.construction;
      case 'Shuttering Carpenter':
      case 'Formwork Installation':
      case 'Scaffolding Work':
      case 'Centering Work':
        return Icons.handyman;
      case 'Flooring Worker':
        return Icons.square_foot;
      case 'Tile Worker':
        return Icons.grid_on;
      case 'Concrete Worker':
        return Icons.foundation;

    // ============================================================
    // 💻 TECH & ELECTRONICS
    // ============================================================
      case 'Computer Repair':
      case 'Software Installation':
        return Icons.computer;
      case 'Laptop Repair':
        return Icons.laptop;
      case 'Mobile Repair':
      case 'Smartphone Repair':
      case 'Screen Replacement':
        return Icons.phone_android;
      case 'Tablet Repair':
        return Icons.tablet;
      case 'iPhone Repair':
        return Icons.phone_iphone;
      case 'MacBook Repair':
        return Icons.laptop_mac;
      case 'Printer Repair':
        return Icons.print;
      case 'CCTV Installation':
      case 'CCTV Repair':
        return Icons.videocam;
      case 'Home Automation':
      case 'Smart Home Setup':
        return Icons.hub;
      case 'WiFi Installation':
      case 'Network Setup':
        return Icons.wifi;
      case 'Server Installation':
        return Icons.storage;
      case 'Data Recovery':
        return Icons.data_usage;
      case 'Virus Removal':
        return Icons.security;
      case 'Battery Replacement':
        return Icons.battery_charging_full;

    // ============================================================
    // 🚗 AUTO SERVICES
    // ============================================================
      case 'Mechanic':
      case 'Auto Electrician':
      case 'Engine Repair':
      case 'Brake Repair':
      case 'Clutch Repair':
      case 'Transmission Repair':
      case 'Car Suspension Repair':
      case 'Car Alignment':
      case 'Tyre Puncture':
      case 'Tyre Replacement':
      case 'Oil Change':
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
      case 'Bike Service':
        return Icons.motorcycle;
      case 'Cycle Repair':
        return Icons.pedal_bike;
      case 'Car Painting':
      case 'Denting and Painting':
        return Icons.brush;
      case 'Car Interior Cleaning':
        return Icons.cleaning_services;

    // ============================================================
    // 🏗️ CONSTRUCTION CONTRACTORS
    // ============================================================
      case 'Building Contractor':
      case 'Construction Contractor':
      case 'Civil Contractor':
      case 'Turnkey Contractor':
      case 'EPC Contractor':
      case 'Infrastructure Contractor':
      case 'Tunnel Contractor':
      case 'Bridge Contractor':
        return Icons.apartment;
      case 'Real Estate Developer':
      case 'Government Contractor':
      case 'Commercial Contractor':
        return Icons.business_center;
      case 'Project Manager':
      case 'Construction Management':
      case 'Site Supervisor':
      case 'Construction Manager':
      case 'Project Supervision':
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
        return Icons.landscape;
      case 'Interior Contractor':
      case 'Exterior Contractor':
        return Icons.home;
      case 'Roofing Contractor':
        return Icons.roofing;
      case 'Private Contractor':
      case 'Residential Contractor':
        return Icons.house;
      case 'Industrial Contractor':
        return Icons.factory;
      case 'Road Contractor':
        return Icons.add_road;
      case 'Dam Contractor':
        return Icons.water;
      case 'Project Estimation':
      case 'Project Planning':
      case 'Cost Estimation':
      case 'Bill of Quantities':
      case 'Tendering Service':
        return Icons.calculate;
      case 'Quality Control':
        return Icons.check_circle;
      case 'Safety Management':
        return Icons.security;
      case 'Construction Drawings':
      case 'Structural Design':
        return Icons.architecture;

    // ============================================================
    // 📦 MATERIAL SUPPLIERS
    // ============================================================
      case 'Building Material Supplier':
      case 'Cement Supplier':
      case 'Steel Supplier':
      case 'Brick Supplier':
      case 'Sand Supplier':
      case 'Aggregate Supplier':
      case 'Tiles Supplier':
      case 'Marble Supplier':
      case 'Granite Supplier':
      case 'Wood Supplier':
      case 'Paint Supplier':
      case 'Electrical Material Supplier':
      case 'Plumbing Material Supplier':
      case 'Hardware Supplier':
      case 'Glass Supplier':
      case 'Aluminum Supplier':
      case 'PVC Supplier':
      case 'Pipe Supplier':
      case 'Water Tank Supplier':
      case 'Solar Panel Supplier':
      case 'Roofing Material Supplier':
      case 'Insulation Material Supplier':
      case 'Flooring Material Supplier':
      case 'Sanitary Supplier':
      case 'Kitchen Cabinet Supplier':
        return Icons.store;

    // ============================================================
    // 🏠 HOME SERVICES
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
      case 'Deep Cleaning':
      case 'Carpet Cleaning':
      case 'Sofa Cleaning':
      case 'Mattress Cleaning':
      case 'Curtain Cleaning':
      case 'Upholstery Cleaning':
        return Icons.cleaning_services;
      case 'Pest Control':
      case 'Termite Control':
      case 'Bed Bug Treatment':
      case 'Mosquito Control':
        return Icons.bug_report;
      case 'Waterproofing':
      case 'Damp Proofing':
      case 'Bathroom Waterproofing':
        return Icons.water;
      case 'Wall Crack Repair':
        return Icons.construction;
      case 'Grouting':
      case 'Tile Grouting':
        return Icons.grid_on;
      case 'Epoxy Flooring':
        return Icons.square_foot;

    // ============================================================
    // 🪑 FURNITURE & INTERIOR
    // ============================================================
      case 'Furniture Assembly':
      case 'Furniture Repair':
      case 'Furniture Restoration':
      case 'Upholstery':
        return Icons.chair;
      case 'Curtain Installation':
      case 'Blinds Installation':
        return Icons.curtains;
      case 'Wallpaper Installation':
      case 'Wall Paneling':
        return Icons.wallpaper;
      case 'Window Repair':
        return Icons.window;
      case 'Door Repair':
        return Icons.door_front_door;
      case 'Garage Door Repair':
        return Icons.garage;
      case 'Kitchen Cabinet Installation':
      case 'Modular Kitchen':
        return Icons.kitchen;
      case 'Wardrobe Installation':
        return Icons.checkroom;
      case 'Interior Design':
      case 'Space Planning':
        return Icons.design_services;
      case 'Wood Polishing':
        return Icons.brush;
      case 'Laminate Flooring':
      case 'Hardwood Flooring':
        return Icons.square_foot;

    // ============================================================
    // 🌿 OUTDOOR & GARDEN
    // ============================================================
      case 'Gardening':
      case 'Tree Trimming':
      case 'Tree Removal':
      case 'Lawn Mowing':
      case 'Artificial Grass Installation':
        return Icons.grass;
      case 'Landscaping':
      case 'Garden Design':
        return Icons.landscape;
      case 'Irrigation Installation':
      case 'Pond Installation':
      case 'Water Feature Installation':
        return Icons.water;
      case 'Fencing':
        return Icons.fence;
      case 'Deck Installation':
      case 'Patio Construction':
      case 'Garden Shed Installation':
      case 'Pergola Installation':
        return Icons.home;
      case 'Outdoor Lighting':
        return Icons.light;

    // ============================================================
    // 🔥 SPECIALIZED SERVICES
    // ============================================================
      case 'HVAC Technician':
      case 'Heat Pump Installation':
        return Icons.ac_unit;
      case 'Security System Installation':
      case 'Home Security Audit':
        return Icons.security;
      case 'Fire Alarm Installation':
      case 'Fire Extinguisher Service':
        return Icons.fire_extinguisher;
      case 'Elevator Repair':
      case 'Escalator Repair':
        return Icons.elevator;
      case 'Water Pump Repair':
      case 'Boiler Installation':
      case 'Boiler Repair':
        return Icons.water;
      case 'Motor Winding':
      case 'Generator Repair':
      case 'Inverter Repair':
      case 'UPS Repair':
      case 'Smart Meter Installation':
        return Icons.electrical_services;
      case 'Compressor Repair':
        return Icons.build;
      case 'Solar Water Heater':
        return Icons.solar_power;
      case 'Ventilation System':
      case 'Air Purifier Installation':
        return Icons.air;
      case 'Humidifier Installation':
      case 'Dehumidifier Installation':
        return Icons.water;

    // ============================================================
    // 🎉 EVENT & RENTAL SERVICES
    // ============================================================
      case 'Locksmith':
      case 'Smart Lock Installation':
        return Icons.lock;
      case 'Event Setup':
      case 'Event Decoration':
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
      case 'DJ Services':
        return Icons.music_note;
      case 'Catering Setup':
        return Icons.restaurant;
      case 'Party Planning':
        return Icons.celebration;

    // ============================================================
    // 🏠 PROPERTY & MAINTENANCE
    // ============================================================
      case 'Property Management':
      case 'Facility Management':
        return Icons.business_center;
      case 'Building Maintenance':
        return Icons.apartment;
      case 'Snow Removal':
        return Icons.ac_unit;
      case 'Gutter Cleaning':
      case 'Window Cleaning':
      case 'Pressure Washing':
        return Icons.cleaning_services;
      case 'Swimming Pool Installation':
      case 'Swimming Pool Cleaning':
        return Icons.pool;
      case 'Sauna Installation':
      case 'Jacuzzi Installation':
      case 'Sauna Repair':
        return Icons.hot_tub;
      case 'Playground Equipment Installation':
      case 'Playground Equipment':
        return Icons.play_arrow;

    // ============================================================
    // 🏥 HEALTH & WELLNESS
    // ============================================================
      case 'Gym Equipment Installation':
      case 'Gym Equipment Repair':
      case 'Home Gym Setup':
      case 'Treadmill Repair':
      case 'Exercise Bike Repair':
      case 'Pilates Equipment':
        return Icons.fitness_center;
      case 'Yoga Studio Setup':
        return Icons.self_improvement;

    // ============================================================
    // 🏫 EDUCATIONAL & OFFICE
    // ============================================================
      case 'Office Setup':
      case 'Workstation Installation':
      case 'Home Office Setup':
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
      case 'Pet Sitting':
      case 'Dog Walking':
      case 'Pet Training':
      case 'Pet Boarding':
        return Icons.pets;

    // ============================================================
    // 🆕 EMERGING & FUTURE CATEGORIES
    // ============================================================
      case 'EV Charger Installation':
      case 'Electric Vehicle Repair':
        return Icons.ev_station;
      case 'E-Bike Repair':
        return Icons.motorcycle;
      case 'Drone Repair':
        return Icons.flight;
      case '3D Printing Services':
        return Icons.print;
      case 'Laser Cutting':
      case 'CNC Machining':
        return Icons.handyman;
      case 'Home Theater Calibration':
        return Icons.tv;
      case 'Acoustic Treatment':
      case 'Soundproofing':
        return Icons.speaker;
      case 'Energy Audit':
        return Icons.energy_savings_leaf;
      case 'Water Softener Installation':
      case 'RO System Installation':
      case 'Rainwater Harvesting':
      case 'Greywater System':
        return Icons.water;
      case 'Composting Setup':
        return Icons.eco;
      case 'Vertical Garden':
      case 'Hydroponic System':
      case 'Aquaponics System':
      case 'Greenhouse Installation':
        return Icons.grass;
      case 'Trampoline Installation':
        return Icons.play_arrow;
      case 'Pool Table Installation':
      case 'Bowling Alley Installation':
        return Icons.sports;
      case 'Gaming Console Setup':
        return Icons.sports_esports;
      case 'VR Room Setup':
        return Icons.view_in_ar;
      case 'Ergonomic Assessment':
        return Icons.work;
      case 'Accessibility Installation':
        return Icons.accessible;
      case 'Video Doorbell Installation':
        return Icons.videocam;
      case 'Fuel Delivery':
      case 'Emergency Fuel Delivery':
        return Icons.local_gas_station;
      case 'Car Towing':
      case 'Bike Towing':
      case 'Vehicle Recovery':
        return Icons.local_taxi;
      case 'Roadside Assistance':
      case 'Car Jump Start':
      case 'Flat Tyre Assistance':
      case 'Tyre Change Assistance':
      case 'Mobile Mechanic':
      case 'Lockout Assistance':
      case 'Emergency Car Repair':
      case 'Winch Service':
        return Icons.car_repair;
      case 'Battery Delivery':
        return Icons.battery_charging_full;
      case 'Car Key Replacement':
        return Icons.vpn_key;

      default:
        return Icons.build_circle;
    }
  }

  // ============================================================
  // ✅ MULTI-LANGUAGE: Get Service Description
  // ============================================================
  String _getServiceDescription() {
    final categoryKey = _getCategoryKey();

    // ✅ Try to get translated description
    final descKey = '${categoryKey}_desc';
    final description = context.tr(descKey);

    // ✅ If translation exists, return it
    if (description != descKey) {
      return description;
    }

    // ✅ Fallback: Use translated category name + generic
    final categoryName = context.tr(widget.category);
    return '${context.tr('professional')} $categoryName ${context.tr('servicesAtDoorstep')}';
  }

  // ============================================================
  // ✅ MULTI-LANGUAGE: Get Service Checklist
  // ============================================================
  List<String> _getServiceChecklist() {
    final categoryKey = _getCategoryKey();

    // ✅ Try to get translated checklist
    final checklistKey = '${categoryKey}_checklist';
    final checklist = context.tr(checklistKey);

    // ✅ If translation exists and is not empty, split and return
    if (checklist != checklistKey && checklist.isNotEmpty) {
      return checklist.split('|').map((s) => s.trim()).toList();
    }

    // ✅ Fallback: Return default checklist
    return [
      context.tr('serviceInspection'),
      context.tr('qualityCheck'),
      context.tr('professionalService'),
      context.tr('customerSatisfaction'),
      context.tr('generalAssessment'),
      context.tr('finalInspection'),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _budgetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr(widget.category), // ✅ Translated
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: userDataAsync.when(
        data: (userData) {
          if (userData == null) {
            return _buildErrorState(context.tr('pleaseCompleteProfile'));
          }
          _initializeFields(userData);
          return _buildBody(userData);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        error: (error, stack) => _buildErrorState('${context.tr('errorLoadingProfile')}: $error'),
      ),
    );
  }

  void _initializeFields(UserData userData) {
    if (_nameController.text.isEmpty) {
      _nameController.text = userData.displayName;
    }
    if (_phoneController.text.isEmpty) {
      _phoneController.text = userData.phoneNumber;
    }
    if (_addressController.text.isEmpty && userData.address.isNotEmpty) {
      _addressController.text = userData.address;
    }
    if (_pincodeController.text.isEmpty && userData.pincode.isNotEmpty) {
      _pincodeController.text = userData.pincode;
    }

    if (!_currencyInitialized && userData.countryCode.isNotEmpty) {
      final currency = CurrenciesData.getCurrencyByCountryCode(userData.countryCode);
      if (currency != null) {
        _selectedCurrency = currency;
      }
      _currencyInitialized = true;
    }
  }

  // ============================================================
  // ✅ BUILD BODY
  // ============================================================
  Widget _buildBody(UserData userData) {
    final checklist = _getServiceChecklist();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceHeader(),
          const SizedBox(height: 16),
          _buildServiceDetails(checklist),
          const SizedBox(height: 16),
          _buildPaymentInfo(),
          const SizedBox(height: 24),
          _buildPostButton(),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SERVICE HEADER
  // ============================================================
  Widget _buildServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getServiceIcon(),
                  color: Colors.green[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(widget.category), // ✅ Translated
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      _getServiceDescription(), // ✅ Translated
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getServiceType(), // ✅ Translated
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip('✅ ${context.tr('verifiedTechnicians')}', Colors.green),
              _buildInfoChip('⭐ ${context.tr('qualityService')}', Colors.orange),
              _buildInfoChip('⏰ ${context.tr('onTimeService')}', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SERVICE DETAILS
  // ============================================================
  Widget _buildServiceDetails(List<String> checklist) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('whatWeWillDo'), // ✅ Translated
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...checklist.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_box_outlined,
                  color: Colors.green[700],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item, // ✅ Already translated from checklist
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${context.tr('weWillClean')} ${context.tr(widget.category)} ${context.tr('toEnsureBestPerformance')}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            context.tr('yourDetails'), // ✅ Translated
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: context.tr('customerName'), // ✅ Translated
            controller: _nameController,
            hint: context.tr('enterYourName'), // ✅ Translated
            icon: Icons.person_outline,
          ),
          _buildEditableField(
            label: context.tr('phoneNumber'), // ✅ Translated
            controller: _phoneController,
            hint: context.tr('enterYourPhone'), // ✅ Translated
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          _buildLocationPicker(),
          _buildBudgetField(),
          _buildImagePicker(),
          _buildEditableField(
            label: context.tr('additionalNote'), // ✅ Translated
            controller: _noteController,
            hint: context.tr('describeYourIssue'), // ✅ Translated
            icon: Icons.note_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ LOCATION PICKER
  // ============================================================
  Widget _buildLocationPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('serviceLocation'), // ✅ Translated
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.tr('required'), // ✅ Translated
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedAddress.isNotEmpty
                      ? Colors.green[300]!
                      : Colors.grey[300]!,
                  width: _selectedAddress.isNotEmpty ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedAddress.isNotEmpty
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    color: _selectedAddress.isNotEmpty
                        ? Colors.green[700]
                        : Colors.grey[400],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : context.tr('tapToSelectLocation'), // ✅ Translated
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedAddress.isNotEmpty
                                ? const Color(0xFF1A237E)
                                : Colors.grey[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedPincode.isNotEmpty)
                          Text(
                            '📌 ${context.tr('pincode')}: $_selectedPincode',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        if (_selectedLatitude != 0.0 || _selectedLongitude != 0.0)
                          Text(
                            '📍 ${_selectedLatitude.toStringAsFixed(6)}, ${_selectedLongitude.toStringAsFixed(6)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ BUDGET FIELD
  // ============================================================
  Widget _buildBudgetField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('expectedBudget'), // ✅ Translated
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.tr('required'), // ✅ Translated
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CurrencyPicker(
                  key: ValueKey(_selectedCurrency.code),
                  selectedCurrency: _selectedCurrency,
                  onCurrencySelected: (currency) {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  key: ValueKey(_selectedCurrency.code),
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: context.tr('enterAmount'), // ✅ Translated
                    prefixText: '${_selectedCurrency.symbol} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ IMAGE PICKER
  // ============================================================
  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('serviceImageOptional'), // ✅ Translated
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ImagePickerWidget(
            onImageUploaded: (imageUrl) {
              setState(() {
                _taskImageUrl = imageUrl;
              });
            },
            existingImageUrl: _taskImageUrl,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ PAYMENT INFO
  // ============================================================
  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('paymentInfo'), // ✅ Translated
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.orange[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ POST BUTTON
  // ============================================================
  Widget _buildPostButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _postRequestWithAICheck,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          context.tr('postRequest'), // ✅ Translated
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ OPEN LOCATION PICKER
  // ============================================================
  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: _selectedAddress.isNotEmpty
              ? _selectedAddress
              : _addressController.text,
          initialPincode: _selectedPincode.isNotEmpty
              ? _selectedPincode
              : _pincodeController.text,
          initialLat: _selectedLatitude,
          initialLng: _selectedLongitude,
          onLocationSelected: (lat, lng, address, pincode) {
            setState(() {
              _selectedLatitude = lat;
              _selectedLongitude = lng;
              _selectedAddress = address;
              _selectedPincode = pincode;
              _addressController.text = address;
              _pincodeController.text = pincode;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // ✅ CHECK ONESIGNAL STATUS
  // ============================================================
  Future<void> _checkOneSignalStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final oneSignalId = userDoc.data()?['oneSignalId'];
      if (oneSignalId == null || oneSignalId.toString().isEmpty) {
        await OneSignalNotificationService.saveCurrentUserOneSignalId();
      }
    } catch (e) {
      print('❌ Error checking OneSignal: $e');
    }
  }

  // ============================================================
  // ✅ POST REQUEST WITH AI CHECK
  // ============================================================
  Future<void> _postRequestWithAICheck() async {
    await _checkOneSignalStatus();

    if (_selectedAddress.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pleaseSelectLocation')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_budgetController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pleaseEnterBudget')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login first');

      final String pincode = _selectedPincode.isNotEmpty
          ? _selectedPincode
          : _pincodeController.text.trim();

      final hasMatch = await _matchingService.hasMatchingTechnician(
        category: widget.category, // ✅ English name
        pincode: pincode,
        customerLat: _selectedLatitude,
        customerLng: _selectedLongitude,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (hasMatch) {
        await _createTaskDirectly();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIMatchingScreen(
              category: widget.category, // ✅ English name
              pincode: pincode,
              address: _selectedAddress,
              budget: double.parse(_budgetController.text.trim()),
              customerName: _nameController.text.trim(),
              customerPhone: _phoneController.text.trim(),
              note: _noteController.text.trim(),
              imageUrl: _taskImageUrl,
              currencyCode: _selectedCurrency.code,
              currencySymbol: _selectedCurrency.symbol,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ CREATE TASK DIRECTLY
  // ============================================================
  Future<void> _createTaskDirectly() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      double budget = 0;
      try {
        budget = double.parse(_budgetController.text.trim());
      } catch (e) {
        budget = 1000.0;
      }

      List<String> imageUrls = [];
      if (_taskImageUrl != null) {
        imageUrls = [_taskImageUrl!];
      }

      final task = TaskModel(
        id: '',
        title: widget.category, // ✅ English name
        description: _noteController.text.toString(),
        customerId: user.uid,
        customerName: _nameController.text.trim().isEmpty
            ? user.displayName ?? 'Customer'
            : _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        address: _selectedAddress.isNotEmpty
            ? _selectedAddress
            : _addressController.text.trim(),
        pincode: _selectedPincode.isNotEmpty
            ? _selectedPincode
            : _pincodeController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        category: widget.category, // ✅ English name
        subCategories: _getServiceChecklist(),
        budget: budget,
        currencyCode: _selectedCurrency.code,
        currencySymbol: _selectedCurrency.symbol,
        countryCode: _selectedCurrency.countryCode,
        createdAt: DateTime.now(),
        status: TaskStatus.open,
        isUrgent: false,
        scheduledDate: null,
        acceptedAt: null,
        startedAt: null,
        completedAt: null,
        cancelledAt: null,
        cancellationReason: null,
        technicianId: null,
        technicianName: null,
        technicianPhone: null,
        technicianRating: null,
        customerRating: null,
        customerReview: null,
        images: imageUrls,
        serviceCharge: 0.0,
      );

      final taskId = await _taskService.createTask(task);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessfulScreen(
            taskId: taskId.substring(0, 8).toUpperCase(),
            service: context.tr(widget.category), // ✅ Translated for display
            location: _selectedAddress.isNotEmpty
                ? _selectedAddress
                : _addressController.text.trim(),
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ HELP DIALOG
  // ============================================================
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          context.tr('howItWorks'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1', context.tr('selectServiceLocation'), Icons.location_on),
            const SizedBox(height: 12),
            _buildHelpItem('2', context.tr('setExpectedBudget'), Icons.attach_money),
            const SizedBox(height: 12),
            _buildHelpItem('3', context.tr('describeIssue'), Icons.description),
            const SizedBox(height: 12),
            _buildHelpItem('4', context.tr('postRequestWait'), Icons.send),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('gotIt'),
              style: GoogleFonts.poppins(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ HELPER WIDGETS
  // ============================================================
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF1A237E),
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('goBack')),
            ),
          ],
        ),
      ),
    );
  }
}
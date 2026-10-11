// lib/Presentations/customer_screen/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryCard extends StatelessWidget {
  final String categoryKey;    // ✅ English key for icon
  final String displayName;    // ✅ Translated display name
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.categoryKey,
    required this.displayName,
    required this.onTap,
    this.isSelected = false,
  });

  // ✅ Get icon based on category key
  IconData _getCategoryIcon(String key) {
    switch (key) {
    // ============================================================
    // 🔧 HOME SERVICES
    // ============================================================
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.electrical_services;
      case 'carpenter':
        return Icons.handyman;
      case 'painter':
        return Icons.brush;
      case 'roofing':
        return Icons.roofing;
      case 'tiling':
        return Icons.grid_on;
      case 'flooring':
        return Icons.square_foot;
      case 'cleaning_services':
      case 'deep_cleaning':
      case 'carpet_cleaning':
      case 'sofa_cleaning':
      case 'mattress_cleaning':
      case 'curtain_cleaning':
      case 'upholstery_cleaning':
        return Icons.cleaning_services;
      case 'pest_control':
      case 'termite_control':
      case 'bed_bug_treatment':
      case 'mosquito_control':
        return Icons.bug_report;
      case 'waterproofing':
      case 'damp_proofing':
      case 'bathroom_waterproofing':
        return Icons.water;
      case 'wall_crack_repair':
        return Icons.construction;
      case 'grouting':
      case 'tile_grouting':
        return Icons.grid_on;
      case 'epoxy_flooring':
        return Icons.square_foot;

    // ============================================================
    // ❄️ APPLIANCE REPAIR
    // ============================================================
      case 'ac_repair':
      case 'ac_installation':
      case 'ac_gas_filling':
      case 'ac_duct_cleaning':
        return Icons.ac_unit;
      case 'refrigerator_repair':
      case 'refrigerator_gas_filling':
        return Icons.kitchen;
      case 'washing_machine_repair':
      case 'dryer_repair':
        return Icons.local_laundry_service;
      case 'dishwasher_repair':
      case 'oven_repair':
      case 'air_fryer_repair':
        return Icons.kitchen;
      case 'tv_repair':
      case 'led_lcd_tv_repair':
        return Icons.tv;
      case 'microwave_repair':
        return Icons.microwave;
      case 'geyser_repair':
      case 'water_purifier_repair':
        return Icons.water;
      case 'chimney_repair':
      case 'gas_stove_repair':
        return Icons.fireplace;
      case 'mixer_grinder_repair':
      case 'juicer_repair':
        return Icons.blender;
      case 'coffee_machine_repair':
        return Icons.coffee;
      case 'vacuum_cleaner_repair':
        return Icons.cleaning_services;

    // ============================================================
    // 💻 TECH & ELECTRONICS
    // ============================================================
      case 'computer_repair':
      case 'software_installation':
        return Icons.computer;
      case 'laptop_repair':
        return Icons.laptop;
      case 'mobile_repair':
      case 'smartphone_repair':
      case 'screen_replacement':
        return Icons.phone_android;
      case 'iphone_repair':
        return Icons.phone_iphone;
      case 'macbook_repair':
        return Icons.laptop_mac;
      case 'printer_repair':
        return Icons.print;
      case 'cctv_installation':
      case 'cctv_repair':
        return Icons.videocam;
      case 'home_automation':
      case 'smart_home_setup':
        return Icons.hub;
      case 'wifi_installation':
      case 'network_setup':
        return Icons.wifi;
      case 'server_installation':
        return Icons.storage;
      case 'data_recovery':
        return Icons.data_usage;
      case 'virus_removal':
        return Icons.security;
      case 'battery_replacement':
        return Icons.battery_charging_full;

    // ============================================================
    // 🚗 AUTO SERVICES
    // ============================================================
      case 'mechanic':
      case 'auto_electrician':
      case 'engine_repair':
      case 'brake_repair':
      case 'clutch_repair':
      case 'transmission_repair':
      case 'car_suspension_repair':
      case 'car_alignment':
      case 'tyre_puncture':
      case 'tyre_replacement':
        return Icons.car_repair;
      case 'car_ac_repair':
        return Icons.ac_unit;
      case 'car_wash':
        return Icons.local_car_wash;
      case 'car_detailing':
        return Icons.auto_fix_high;
      case 'ceramic_coating':
        return Icons.shield;
      case 'ppf_installation':
        return Icons.security;
      case 'car_wrapping':
        return Icons.style;
      case 'bike_repair':
      case 'bike_service':
        return Icons.motorcycle;
      case 'cycle_repair':
        return Icons.pedal_bike;
      case 'oil_change':
        return Icons.car_repair;
      case 'car_painting':
      case 'denting_and_painting':
        return Icons.brush;
      case 'car_interior_cleaning':
        return Icons.cleaning_services;

    // ============================================================
    // 🔨 CONSTRUCTION LABOR
    // ============================================================
      case 'labor_contractor':
      case 'construction_labor':
        return Icons.people;
      case 'building_construction':
      case 'high_rise_building_construction':
      case 'foundation_work':
      case 'column_casting':
      case 'beam_work':
      case 'slab_casting':
      case 'rcc_work':
      case 'pcc_work':
        return Icons.apartment;
      case 'house_construction':
      case 'residential_building_construction':
        return Icons.house;
      case 'commercial_building_construction':
        return Icons.business_center;
      case 'boundary_wall_construction':
      case 'retaining_wall_construction':
      case 'steel_fixer':
      case 'plaster_worker':
      case 'marble_worker':
      case 'granite_worker':
      case 'stone_worker':
      case 'reinforcement_work':
      case 'rebar_worker':
        return Icons.construction;
      case 'mason':
      case 'shuttering_carpenter':
      case 'formwork_installation':
      case 'scaffolding_work':
      case 'centering_work':
        return Icons.handyman;
      case 'flooring_worker':
        return Icons.square_foot;
      case 'tile_worker':
        return Icons.grid_on;
      case 'concrete_worker':
        return Icons.foundation;

    // ============================================================
    // 🏗️ CONSTRUCTION CONTRACTORS
    // ============================================================
      case 'building_contractor':
      case 'construction_contractor':
      case 'civil_contractor':
      case 'turnkey_contractor':
      case 'epc_contractor':
      case 'infrastructure_contractor':
      case 'tunnel_contractor':
        return Icons.apartment;
      case 'real_estate_developer':
      case 'government_contractor':
      case 'commercial_contractor':
        return Icons.business_center;
      case 'project_manager':
      case 'construction_management':
      case 'site_supervisor':
      case 'construction_manager':
      case 'project_supervision':
        return Icons.person;
      case 'electrical_contractor':
        return Icons.electrical_services;
      case 'plumbing_contractor':
        return Icons.plumbing;
      case 'hvac_contractor':
        return Icons.ac_unit;
      case 'fire_safety_contractor':
        return Icons.fire_extinguisher;
      case 'elevator_contractor':
        return Icons.elevator;
      case 'solar_contractor':
      case 'solar_panel_installation':
        return Icons.solar_power;
      case 'landscaping_contractor':
        return Icons.landscape;
      case 'interior_contractor':
      case 'exterior_contractor':
        return Icons.home;
      case 'roofing_contractor':
        return Icons.roofing;
      case 'private_contractor':
      case 'residential_contractor':
        return Icons.house;
      case 'industrial_contractor':
        return Icons.factory;
      case 'road_contractor':
        return Icons.add_road;
      case 'bridge_contractor':
        return Icons.apartment;
      case 'dam_contractor':
        return Icons.water;
      case 'project_estimation':
      case 'project_planning':
      case 'cost_estimation':
      case 'bill_of_quantities':
      case 'tendering_service':
        return Icons.calculate;
      case 'quality_control':
        return Icons.check_circle;
      case 'safety_management':
        return Icons.security;
      case 'construction_drawings':
      case 'structural_design':
        return Icons.architecture;

    // ============================================================
    // 📦 MATERIAL SUPPLIERS
    // ============================================================
      case 'building_material_supplier':
      case 'cement_supplier':
      case 'steel_supplier':
      case 'brick_supplier':
      case 'sand_supplier':
      case 'aggregate_supplier':
      case 'tiles_supplier':
      case 'marble_supplier':
      case 'granite_supplier':
      case 'wood_supplier':
      case 'paint_supplier':
      case 'electrical_material_supplier':
      case 'plumbing_material_supplier':
      case 'hardware_supplier':
      case 'glass_supplier':
      case 'aluminum_supplier':
      case 'pvc_supplier':
      case 'pipe_supplier':
      case 'water_tank_supplier':
      case 'solar_panel_supplier':
      case 'roofing_material_supplier':
      case 'insulation_material_supplier':
      case 'flooring_material_supplier':
      case 'sanitary_supplier':
      case 'kitchen_cabinet_supplier':
        return Icons.store;

    // ============================================================
    // 🪑 FURNITURE & INTERIOR
    // ============================================================
      case 'furniture_assembly':
      case 'furniture_repair':
      case 'furniture_restoration':
      case 'upholstery':
        return Icons.chair;
      case 'curtain_installation':
      case 'blinds_installation':
        return Icons.curtains;
      case 'wallpaper_installation':
      case 'wall_paneling':
        return Icons.wallpaper;
      case 'window_repair':
        return Icons.window;
      case 'door_repair':
        return Icons.door_front_door;
      case 'garage_door_repair':
        return Icons.garage;
      case 'kitchen_cabinet_installation':
      case 'modular_kitchen':
        return Icons.kitchen;
      case 'wardrobe_installation':
        return Icons.checkroom;
      case 'interior_design':
      case 'space_planning':
        return Icons.design_services;
      case 'wood_polishing':
        return Icons.brush;
      case 'laminate_flooring':
      case 'hardwood_flooring':
        return Icons.square_foot;

    // ============================================================
    // 🌿 OUTDOOR & GARDEN
    // ============================================================
      case 'gardening':
      case 'tree_trimming':
      case 'tree_removal':
      case 'lawn_mowing':
      case 'artificial_grass_installation':
        return Icons.grass;
      case 'landscaping':
      case 'garden_design':
        return Icons.landscape;
      case 'irrigation_installation':
      case 'pond_installation':
      case 'water_feature_installation':
        return Icons.water;
      case 'fencing':
        return Icons.fence;
      case 'deck_installation':
      case 'patio_construction':
      case 'garden_shed_installation':
      case 'pergola_installation':
        return Icons.home;
      case 'outdoor_lighting':
        return Icons.light;

    // ============================================================
    // 🔥 SPECIALIZED SERVICES
    // ============================================================
      case 'hvac_technician':
      case 'heat_pump_installation':
        return Icons.ac_unit;
      case 'security_system_installation':
      case 'home_security_audit':
        return Icons.security;
      case 'fire_alarm_installation':
      case 'fire_extinguisher_service':
        return Icons.fire_extinguisher;
      case 'elevator_repair':
      case 'escalator_repair':
        return Icons.elevator;
      case 'water_pump_repair':
      case 'boiler_installation':
      case 'boiler_repair':
        return Icons.water;
      case 'motor_winding':
      case 'generator_repair':
      case 'inverter_repair':
      case 'ups_repair':
      case 'smart_meter_installation':
        return Icons.electrical_services;
      case 'compressor_repair':
        return Icons.build;
      case 'solar_water_heater':
        return Icons.solar_power;
      case 'ventilation_system':
      case 'air_purifier_installation':
        return Icons.air;
      case 'humidifier_installation':
      case 'dehumidifier_installation':
        return Icons.water;

    // ============================================================
    // 🎉 EVENT & RENTAL SERVICES
    // ============================================================
      case 'locksmith':
      case 'smart_lock_installation':
        return Icons.lock;
      case 'event_setup':
      case 'event_decoration':
        return Icons.event;
      case 'tent_installation':
        return Icons.weekend;
      case 'stage_setup':
        return Icons.stadium;
      case 'lighting_installation':
        return Icons.light;
      case 'sound_system_setup':
        return Icons.speaker;
      case 'home_theater_installation':
        return Icons.tv;
      case 'dj_services':
        return Icons.music_note;
      case 'catering_setup':
        return Icons.restaurant;
      case 'party_planning':
        return Icons.celebration;

    // ============================================================
    // 🏠 PROPERTY & MAINTENANCE
    // ============================================================
      case 'property_management':
      case 'facility_management':
        return Icons.business_center;
      case 'building_maintenance':
        return Icons.apartment;
      case 'snow_removal':
        return Icons.ac_unit;
      case 'gutter_cleaning':
      case 'window_cleaning':
      case 'pressure_washing':
        return Icons.cleaning_services;
      case 'swimming_pool_installation':
      case 'swimming_pool_cleaning':
        return Icons.pool;
      case 'sauna_installation':
      case 'jacuzzi_installation':
      case 'sauna_repair':
        return Icons.hot_tub;
      case 'playground_equipment_installation':
      case 'playground_equipment':
        return Icons.play_arrow;

    // ============================================================
    // 🏥 HEALTH & WELLNESS
    // ============================================================
      case 'gym_equipment_installation':
      case 'gym_equipment_repair':
      case 'home_gym_setup':
      case 'treadmill_repair':
      case 'exercise_bike_repair':
      case 'pilates_equipment':
        return Icons.fitness_center;
      case 'yoga_studio_setup':
        return Icons.self_improvement;

    // ============================================================
    // 🏫 EDUCATIONAL & OFFICE
    // ============================================================
      case 'office_setup':
      case 'workstation_installation':
      case 'home_office_setup':
        return Icons.work;
      case 'whiteboard_installation':
        return Icons.edit_note;
      case 'projector_installation':
        return Icons.present_to_all;
      case 'smart_board_installation':
        return Icons.touch_app;
      case 'school_furniture_assembly':
        return Icons.school;
      case 'library_setup':
        return Icons.local_library;
      case 'lab_equipment_installation':
        return Icons.science;

    // ============================================================
    // 🐾 PET SERVICES
    // ============================================================
      case 'pet_grooming':
      case 'pet_sitting':
      case 'dog_walking':
      case 'pet_training':
      case 'pet_boarding':
        return Icons.pets;

    // ============================================================
    // 🆕 EMERGING & FUTURE CATEGORIES
    // ============================================================
      case 'ev_charger_installation':
      case 'electric_vehicle_repair':
        return Icons.ev_station;
      case 'e_bike_repair':
        return Icons.motorcycle;
      case 'drone_repair':
        return Icons.flight;
      case '3d_printing_services':
        return Icons.print;
      case 'laser_cutting':
      case 'cnc_machining':
        return Icons.handyman;
      case 'home_theater_calibration':
        return Icons.tv;
      case 'acoustic_treatment':
      case 'soundproofing':
        return Icons.speaker;
      case 'energy_audit':
        return Icons.energy_savings_leaf;
      case 'water_softener_installation':
      case 'ro_system_installation':
      case 'rainwater_harvesting':
      case 'greywater_system':
        return Icons.water;
      case 'composting_setup':
        return Icons.eco;
      case 'vertical_garden':
      case 'hydroponic_system':
      case 'aquaponics_system':
      case 'greenhouse_installation':
        return Icons.grass;
      case 'trampoline_installation':
        return Icons.play_arrow;
      case 'pool_table_installation':
      case 'bowling_alley_installation':
        return Icons.sports;
      case 'gaming_console_setup':
        return Icons.sports_esports;
      case 'vr_room_setup':
        return Icons.view_in_ar;
      case 'ergonomic_assessment':
        return Icons.work;
      case 'accessibility_installation':
        return Icons.accessible;
      case 'video_doorbell_installation':
        return Icons.videocam;
      case 'fuel_delivery':
      case 'emergency_fuel_delivery':
        return Icons.local_gas_station;
      case 'car_towing':
      case 'bike_towing':
      case 'vehicle_recovery':
        return Icons.local_taxi;
      case 'roadside_assistance':
      case 'car_jump_start':
      case 'flat_tyre_assistance':
      case 'tyre_change_assistance':
      case 'mobile_mechanic':
      case 'lockout_assistance':
      case 'emergency_car_repair':
      case 'winch_service':
        return Icons.car_repair;
      case 'battery_delivery':
        return Icons.battery_charging_full;
      case 'car_key_replacement':
        return Icons.vpn_key;

    // ============================================================
    // DEFAULT
    // ============================================================
      default:
        return Icons.build_circle;
    }
  }

  // ✅ Get color based on category key
  Color _getCategoryColor(String key) {
    final repairKeys = ['repair', 'service', 'fix'];
    final installationKeys = ['installation', 'install', 'setup'];
    final cleaningKeys = ['cleaning', 'clean', 'wash'];
    final constructionKeys = ['construction', 'contractor', 'building', 'worker'];
    final autoKeys = ['car', 'auto', 'bike', 'tyre', 'engine', 'brake'];
    final techKeys = ['computer', 'laptop', 'mobile', 'phone', 'tv', 'cctv', 'wifi'];
    final homeKeys = ['furniture', 'interior', 'door', 'window', 'cabinet'];
    final healthKeys = ['gym', 'fitness', 'yoga', 'pilates', 'treadmill'];
    final petKeys = ['pet', 'dog', 'cat'];
    final eventKeys = ['event', 'party', 'dj', 'decoration', 'catering'];
    final solarKeys = ['solar', 'panel', 'solar_panel_installation']; // ✅ Updated

    if (repairKeys.any((k) => key.contains(k))) {
      return Colors.blue;
    } else if (installationKeys.any((k) => key.contains(k))) {
      return Colors.green;
    } else if (cleaningKeys.any((k) => key.contains(k))) {
      return Colors.teal;
    } else if (constructionKeys.any((k) => key.contains(k))) {
      return Colors.orange;
    } else if (autoKeys.any((k) => key.contains(k))) {
      return Colors.red;
    } else if (techKeys.any((k) => key.contains(k))) {
      return Colors.purple;
    } else if (homeKeys.any((k) => key.contains(k))) {
      return Colors.brown;
    } else if (healthKeys.any((k) => key.contains(k))) {
      return Colors.pink;
    } else if (petKeys.any((k) => key.contains(k))) {
      return Colors.amber;
    } else if (eventKeys.any((k) => key.contains(k))) {
      return Colors.deepOrange;
    } else if (solarKeys.any((k) => key.contains(k))) {
      return Colors.orange;
    } else {
      return const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? Colors.white : _getCategoryColor(categoryKey);
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
              _getCategoryIcon(categoryKey),  // ✅ Uses key for icon
              color: iconColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              displayName,  // ✅ Uses translated text
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
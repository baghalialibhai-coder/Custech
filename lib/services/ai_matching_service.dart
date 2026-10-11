// lib/services/ai_matching_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GenerativeModel? _geminiModel;
  String? _apiKey;

  // ✅ Gemini Initialization
  void initializeGemini({required String apiKey}) {
    _apiKey = apiKey;
    try {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Gemini: $e');
    }
  }

  bool get isGeminiInitialized => _geminiModel != null;

  // ✅ Smart pincode matching
  Map<String, dynamic> _getPincodeMatchLevel(String customerPincode, String technicianPincode) {
    String cust = customerPincode.toString().trim();
    String tech = technicianPincode.toString().trim();

    if (cust.isEmpty || tech.isEmpty) {
      return {'level': 'unknown', 'score': 0, 'label': 'Unknown'};
    }

    if (cust == tech) {
      return {'level': 'exact', 'score': 100, 'label': '✅ Exact Match'};
    }

    if (cust.length >= 4 && tech.length >= 4 && cust.substring(0, 4) == tech.substring(0, 4)) {
      return {'level': 'very_nearby', 'score': 80, 'label': '📍 Very Nearby'};
    }

    if (cust.length >= 3 && tech.length >= 3 && cust.substring(0, 3) == tech.substring(0, 3)) {
      return {'level': 'nearby', 'score': 60, 'label': '📍 Nearby Area'};
    }

    if (cust.length >= 2 && tech.length >= 2 && cust.substring(0, 2) == tech.substring(0, 2)) {
      return {'level': 'same_region', 'score': 40, 'label': '📍 Same Region'};
    }

    return {'level': 'far', 'score': 0, 'label': '❌ Other Area'};
  }

  // ✅ Main method
  Future<String> getAIResponse({
    required String command,
    required String category,
    required String pincode,
    required String address,
    required double budget,
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🤖 AI Smart Matching Started');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 Customer Pincode: $pincode');
      print('🏠 Address: $address');
      print('📂 Category: $category');
      print('💰 Budget: PKR $budget');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // ✅ STEP 1: Get technicians by category
      print('🔍 Step 1: Fetching technicians for category: $category');
      final technicians = await _getTechniciansByCategory(category);
      print('✅ Found ${technicians.length} technicians');

      if (technicians.isEmpty) {
        return _buildNoTechniciansResponse(category, pincode, address, budget);
      }

      // ✅ STEP 2: Get user details
      print('👤 Step 2: Fetching user details...');
      final userIds = technicians.map((t) => t['userId'] as String).toList();
      final usersMap = await _getUsersMap(userIds);
      print('✅ Fetched ${usersMap.length} user profiles');

      // ✅ STEP 3: Categorize by pincode match
      print('📍 Step 3: Categorizing by pincode...');

      List<Map<String, dynamic>> exactMatch = [];
      List<Map<String, dynamic>> veryNearby = [];
      List<Map<String, dynamic>> nearby = [];
      List<Map<String, dynamic>> sameRegion = [];
      List<Map<String, dynamic>> otherAreas = [];

      for (var tech in technicians) {
        final user = usersMap[tech['userId'] as String];
        if (user == null) continue;

        final techPincode = user['pincode']?.toString() ?? '';
        final servicePinCodes = List<String>.from(tech['servicePinCodes'] ?? []);

        bool isMatched = false;

        // Check main pincode
        final matchResult = _getPincodeMatchLevel(pincode, techPincode);

        if (matchResult['level'] == 'exact') {
          exactMatch.add({...tech, 'user': user, 'matchLevel': 'exact', 'pincode': techPincode});
          isMatched = true;
        } else if (matchResult['level'] == 'very_nearby') {
          veryNearby.add({...tech, 'user': user, 'matchLevel': 'very_nearby', 'pincode': techPincode});
          isMatched = true;
        } else if (matchResult['level'] == 'nearby') {
          nearby.add({...tech, 'user': user, 'matchLevel': 'nearby', 'pincode': techPincode});
          isMatched = true;
        } else if (matchResult['level'] == 'same_region') {
          sameRegion.add({...tech, 'user': user, 'matchLevel': 'same_region', 'pincode': techPincode});
          isMatched = true;
        }

        // Check service pin codes
        if (!isMatched) {
          for (String servicePincode in servicePinCodes) {
            final serviceMatch = _getPincodeMatchLevel(pincode, servicePincode);
            if (serviceMatch['level'] == 'exact' || serviceMatch['level'] == 'very_nearby') {
              veryNearby.add({...tech, 'user': user, 'matchLevel': 'very_nearby', 'pincode': servicePincode});
              isMatched = true;
              break;
            } else if (serviceMatch['level'] == 'nearby') {
              nearby.add({...tech, 'user': user, 'matchLevel': 'nearby', 'pincode': servicePincode});
              isMatched = true;
              break;
            }
          }
        }

        if (!isMatched) {
          otherAreas.add({...tech, 'user': user, 'matchLevel': 'far', 'pincode': techPincode});
        }
      }

      print('✅ Exact Match: ${exactMatch.length}');
      print('📍 Very Nearby: ${veryNearby.length}');
      print('📍 Nearby: ${nearby.length}');
      print('📍 Same Region: ${sameRegion.length}');
      print('❌ Other Areas: ${otherAreas.length}');

      // ✅ STEP 4: Build response
      return _buildSmartAIResponse(
        exactMatch: exactMatch,
        veryNearby: veryNearby,
        nearby: nearby,
        sameRegion: sameRegion,
        otherAreas: otherAreas,
        category: category,
        pincode: pincode,
        address: address,
        budget: budget,
      );

    } catch (e) {
      print('❌ AI Service Error: $e');
      return _buildErrorResponse(e.toString());
    }
  }

  // ✅ Updated: Fetch technicians using array-contains
  Future<List<Map<String, dynamic>>> _getTechniciansByCategory(String category) async {
    try {
      // ✅ Using arrayContains for categories array
      final snapshot = await _firestore
          .collection('technicians')
          .where('categories', arrayContains: category)
          .get();

      print('📊 Raw technicians found: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'categories': List<String>.from(data['categories'] ?? []),
          'category': category,
          'experience': data['experience']?.toString() ?? 'Not specified',
          'rating': data['rating']?.toString() ?? 'No rating',
          'totalJobs': data['completedJobs'] ?? 0,
          'isVerified': data['isApproved'] ?? false,
          'serviceCharge': data['visitingCharges']?.toString() ?? 'Contact',
          'serviceRadius': data['serviceRadius'] ?? 5,
          'servicePinCodes': List<String>.from(data['servicePinCodes'] ?? []),
          'pincode': data['pincode'] ?? '',
          'isAvailable': data['isAvailable'] ?? true,
          'isOnline': data['isOnline'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching technicians: $e');
      return [];
    }
  }

  // ✅ Fetch user details
  Future<Map<String, Map<String, dynamic>>> _getUsersMap(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final Map<String, Map<String, dynamic>> userMap = {};

    for (var i = 0; i < userIds.length; i += 10) {
      final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      final chunk = userIds.sublist(i, end);

      try {
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          userMap[doc.id] = {
            'name': data['displayName'] ?? data['name'] ?? 'Unknown',
            'phone': data['phoneNumber'] ?? data['phone'] ?? '',
            'address': data['address'] ?? '',
            'city': data['city'] ?? '',
            'pincode': data['pincode']?.toString() ?? '',
            'isVerified': data['isVerified'] ?? false,
          };
        }
      } catch (e) {
        print('❌ Error fetching users chunk: $e');
      }
    }

    return userMap;
  }

  // ✅ Build Smart AI Response
  String _buildSmartAIResponse({
    required List<Map<String, dynamic>> exactMatch,
    required List<Map<String, dynamic>> veryNearby,
    required List<Map<String, dynamic>> nearby,
    required List<Map<String, dynamic>> sameRegion,
    required List<Map<String, dynamic>> otherAreas,
    required String category,
    required String pincode,
    required String address,
    required double budget,
  }) {
    StringBuffer response = StringBuffer();

    response.writeln('🔍 AI Smart Matching Results');
    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('');
    response.writeln('📍 Your Location: $address');
    response.writeln('📌 Your Pincode: $pincode');
    response.writeln('📂 Category: $category');
    response.writeln('💰 Budget: PKR ${budget.toStringAsFixed(0)}');
    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('');

    int totalNearby = exactMatch.length + veryNearby.length + nearby.length + sameRegion.length;

    if (totalNearby > 0) {
      response.writeln('✅ Found $totalNearby technician(s) near you:');
      response.writeln('');

      int index = 1;

      if (exactMatch.isNotEmpty) {
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('⭐ EXACT Pincode Match (${exactMatch.length})');
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('');
        for (var tech in exactMatch) {
          _appendTechnicianDetail(response, tech, index, 'Exact Match ✅');
          index++;
        }
      }

      if (veryNearby.isNotEmpty) {
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('📍 VERY NEARBY (${veryNearby.length})');
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('');
        for (var tech in veryNearby) {
          _appendTechnicianDetail(response, tech, index, 'Very Nearby');
          index++;
        }
      }

      if (nearby.isNotEmpty) {
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('📍 NEARBY AREA (${nearby.length})');
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('');
        for (var tech in nearby) {
          _appendTechnicianDetail(response, tech, index, 'Nearby Area');
          index++;
        }
      }

      if (sameRegion.isNotEmpty) {
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('📍 SAME REGION (${sameRegion.length})');
        response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        response.writeln('');
        for (var tech in sameRegion) {
          _appendTechnicianDetail(response, tech, index, 'Same Region');
          index++;
        }
      }

    } else {
      response.writeln('😕 No technicians found near your area.');
      response.writeln('');

      if (otherAreas.isNotEmpty) {
        response.writeln('📊 Found ${otherAreas.length} technician(s) in other areas:');
        response.writeln('');
        int count = 0;
        for (var tech in otherAreas) {
          if (count >= 5) break;
          final user = tech['user'];
          final name = user?['name'] ?? 'Unknown';
          final techCity = user?['city'] ?? 'N/A';
          final techPincode = tech['pincode'] ?? 'N/A';
          response.writeln('• $name - $techCity (Pincode: $techPincode)');
          count++;
        }
      }

      response.writeln('');
      response.writeln('💡 Suggestions:');
      response.writeln('• Try a different pincode');
      response.writeln('• Broaden your search area');
      response.writeln('• Contact technicians from nearby areas');
    }

    response.writeln('');
    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('💡 Would you like to post this task?');
    response.writeln('Click "Post" to create an open task.');

    return response.toString();
  }

  // ✅ Helper to append technician details
  void _appendTechnicianDetail(
      StringBuffer response,
      Map<String, dynamic> tech,
      int index,
      String status,
      ) {
    final user = tech['user'];
    final name = user?['name'] ?? 'Unknown';
    final techAddress = user?['address'] ?? 'N/A';
    final techCity = user?['city'] ?? 'N/A';
    final techPincode = tech['pincode'] ?? 'N/A';

    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('👤 Technician #$index [$status]');
    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('• Name: $name');
    response.writeln('• Category: ${tech['category']}');
    response.writeln('• Address: $techAddress');
    response.writeln('• City: $techCity');
    response.writeln('• Pincode: $techPincode');
    response.writeln('• Experience: ${tech['experience']} years');
    response.writeln('• Rating: ${tech['rating']} ⭐');
    response.writeln('• Total Jobs: ${tech['totalJobs']}');
    response.writeln('• Service Charge: ${tech['serviceCharge']} PKR');
    response.writeln('• Service Radius: ${tech['serviceRadius']} km');
    response.writeln('• Available: ${tech['isAvailable'] ? '✅ Yes' : '❌ No'}');
    response.writeln('• Verified: ${tech['isVerified'] ? '✅ Yes' : '❌ No'}');
    response.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    response.writeln('');
  }

  // ✅ Build no technicians response
  String _buildNoTechniciansResponse(
      String category,
      String pincode,
      String address,
      double budget,
      ) {
    return '''
🔍 AI Smart Matching Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Location: $address
📂 Category: $category
💰 Budget: PKR ${budget.toStringAsFixed(0)}
📌 Your Pincode: $pincode
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

😕 No technicians found for this category.

💡 Suggestions:
• Try a different category
• Expand your search area
• Check if the category name is correct
    ''';
  }

  // ✅ Build error response
  String _buildErrorResponse(String error) {
    return '''
❌ Error Occurred

$error

💡 Please try again later.
    ''';
  }
}
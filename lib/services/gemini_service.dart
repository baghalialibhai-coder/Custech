import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/models/technician_model.dart';
import '../core/models/user_model.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late GenerativeModel _model;
  bool _isInitialized = false;

  // ✅ Initialize with API key
  void initialize({required String apiKey}) {
    if (!_isInitialized) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1000,
        ),
      );
      _isInitialized = true;
      print('✅ Gemini AI Service initialized');
    }
  }

  // ============================================================
  // ✅ FIND BEST MATCHING TECHNICIANS USING AI
  // ✅ Ignores: Phone Number, Address
  // ✅ Uses: Categories, Experience, About, ServicePinCodes, Rating
  // ============================================================
  Future<List<Map<String, dynamic>>> findBestMatches({
    required String customerCategory,
    required String customerPincode,
    required List<TechnicianModel> technicians,
    required List<UserModel> users, // For technician names
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini AI not initialized. Call initialize() first.');
    }

    if (technicians.isEmpty) {
      return [];
    }

    try {
      // ✅ Build AI Prompt (without phone/address)
      final prompt = _buildAIPrompt(
        customerCategory: customerCategory,
        customerPincode: customerPincode,
        technicians: technicians,
        users: users,
      );

      print('🤖 Sending AI prompt...');
      print('📝 Prompt length: ${prompt.length} characters');

      // ✅ Get AI response
      final response = await _model.generateContent([Content.text(prompt)]);
      final aiText = response.text ?? '';

      print('✅ AI Response received: ${aiText.length} characters');

      // ✅ Parse AI response
      final matchedIds = _parseAIResponse(aiText, technicians);

      // ✅ Return matched technicians with score
      return technicians
          .where((tech) => matchedIds.containsKey(tech.userId))
          .map((tech) {
        final user = users.firstWhere(
              (u) => u.id == tech.userId,
          orElse: () => UserModel(
            id: tech.userId,
            name: 'Technician',
            email: '',
            phone: '',
            profileImage: '',
            role: 'technician',
            country: '',
            city: '',
            address: '',
            pinCode: '',
            isVerified: false,
            isMembershipActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return {
          'userId': tech.userId,
          'name': user.name,
          'categories': tech.categories,
          'experience': tech.experience,
          'about': tech.about,
          'servicePinCodes': tech.servicePinCodes,
          'rating': tech.rating,
          'totalReviews': tech.totalReviews,
          'completedJobs': tech.completedJobs,
          'hourlyRate': tech.hourlyRate,
          'visitingCharges': tech.visitingCharges,
          'isAvailable': tech.isAvailable,
          'isOnline': tech.isOnline,
          'isApproved': tech.isApproved,
          'score': matchedIds[tech.userId] ?? 0,
          'matchReason': _getMatchReason(matchedIds[tech.userId] ?? 0),
        };
      })
          .toList()
        ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    } catch (e) {
      print('❌ Gemini AI Error: $e');
      // Fallback: Return all technicians sorted by pincode proximity
      return _fallbackMatching(technicians, users, customerPincode);
    }
  }

  // ============================================================
  // ✅ BUILD AI PROMPT (Without Phone/Address)
  // ============================================================
  String _buildAIPrompt({
    required String customerCategory,
    required String customerPincode,
    required List<TechnicianModel> technicians,
    required List<UserModel> users,
  }) {
    final techList = technicians.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final tech = entry.value;
      final user = users.firstWhere(
            (u) => u.id == tech.userId,
        orElse: () => UserModel(
          id: tech.userId,
          name: 'Technician $index',
          email: '',
          phone: '',
          profileImage: '',
          role: 'technician',
          country: '',
          city: '',
          address: '',
          pinCode: '',
          isVerified: false,
          isMembershipActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      return '''
Technician #$index:
- ID: ${tech.userId}
- Name: ${user.name}
- Categories: ${tech.categories.join(', ')}
- Service Pin Codes: ${tech.servicePinCodes.join(', ')}
- Experience: ${tech.experience} years
- Rating: ${tech.rating} ★ (${tech.totalReviews} reviews)
- Completed Jobs: ${tech.completedJobs}
- About: ${tech.about.isEmpty ? 'Experienced professional' : tech.about}
- Hourly Rate: PKR ${tech.hourlyRate.toStringAsFixed(0)}
- Visiting Charges: PKR ${tech.visitingCharges.toStringAsFixed(0)}
''';
    }).join('\n');

    return '''
You are a smart matching assistant for "Custech" - a service platform connecting customers with technicians.

Customer Request:
- Service Category: $customerCategory
- Customer Pincode: $customerPincode

Available Technicians:
$techList

Task:
Find the best matching technicians for this customer based on:

1. Category Match (must match customer's category) - HIGH PRIORITY
2. Service Pin Codes (closer to customer pincode is better) - HIGH PRIORITY
3. Experience (more experience is better)
4. Rating (higher rating is better)
5. About/Description (check if they mention relevant services)
6. Completed Jobs (more completed jobs is better)
7. Availability (prefer available technicians)

IMPORTANT: 
- DO NOT use phone numbers or addresses for matching
- ONLY use: categories, servicePinCodes, experience, rating, about, completedJobs, availability

Return ONLY a JSON array with technician IDs and their match score (0-100).
Format: [{"id": "tech_id_1", "score": 95}, {"id": "tech_id_2", "score": 80}]

Only include technicians who match the customer's category.
Sort by score descending (highest first).
Return ONLY the JSON array, nothing else.
''';
  }

  // ============================================================
  // ✅ PARSE AI RESPONSE
  // ============================================================
  Map<String, int> _parseAIResponse(String aiText, List<TechnicianModel> technicians) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(aiText);
      if (jsonMatch == null) {
        return {for (var tech in technicians) tech.userId: 50};
      }

      final jsonString = jsonMatch.group(0)!;
      final List<dynamic> jsonData = json.decode(jsonString);

      final Map<String, int> result = {};
      for (var item in jsonData) {
        final id = item['id']?.toString() ?? '';
        final score = (item['score'] as num?)?.toInt() ?? 50;
        if (id.isNotEmpty) {
          result[id] = score;
        }
      }

      return result;
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      return {for (var tech in technicians) tech.userId: 50};
    }
  }

  // ============================================================
  // ✅ GET MATCH REASON
  // ============================================================
  String _getMatchReason(int score) {
    if (score >= 90) return 'Excellent Match! 🎯';
    if (score >= 70) return 'Great Match! ✅';
    if (score >= 50) return 'Good Match 👍';
    if (score >= 30) return 'Nearby Technician 📍';
    return 'Available Technician 🔧';
  }

  // ============================================================
  // ✅ FALLBACK MATCHING (Without AI)
  // ============================================================
  List<Map<String, dynamic>> _fallbackMatching(
      List<TechnicianModel> technicians,
      List<UserModel> users,
      String customerPincode,
      ) {
    return technicians.map((tech) {
      final user = users.firstWhere(
            (u) => u.id == tech.userId,
        orElse: () => UserModel(
          id: tech.userId,
          name: 'Technician',
          email: '',
          phone: '',
          profileImage: '',
          role: 'technician',
          country: '',
          city: '',
          address: '',
          pinCode: '',
          isVerified: false,
          isMembershipActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final score = _calculateSimpleScore(tech, customerPincode);
      return {
        'userId': tech.userId,
        'name': user.name,
        'categories': tech.categories,
        'experience': tech.experience,
        'about': tech.about,
        'servicePinCodes': tech.servicePinCodes,
        'rating': tech.rating,
        'totalReviews': tech.totalReviews,
        'completedJobs': tech.completedJobs,
        'hourlyRate': tech.hourlyRate,
        'visitingCharges': tech.visitingCharges,
        'isAvailable': tech.isAvailable,
        'isOnline': tech.isOnline,
        'isApproved': tech.isApproved,
        'score': score,
        'matchReason': _getMatchReason(score),
      };
    }).toList()..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  }

  // ============================================================
  // ✅ CALCULATE SIMPLE SCORE
  // ============================================================
  int _calculateSimpleScore(TechnicianModel tech, String customerPincode) {
    int score = 50;

    // Category match (already filtered)
    score += 10;

    // Service Pin Codes match
    if (tech.servicePinCodes.contains(customerPincode)) {
      score += 25;
    } else {
      // Check if any pin code is nearby
      for (var pin in tech.servicePinCodes) {
        if (pin.isNotEmpty && customerPincode.isNotEmpty) {
          if (pin.length >= 4 && customerPincode.length >= 4) {
            if (pin.substring(0, 4) == customerPincode.substring(0, 4)) {
              score += 15;
              break;
            }
          }
        }
      }
    }

    // Experience bonus
    if (tech.experience >= 5) score += 10;
    else if (tech.experience >= 3) score += 5;

    // Rating bonus
    if (tech.rating >= 4.5) score += 10;
    else if (tech.rating >= 4.0) score += 5;

    // Completed jobs bonus
    if (tech.completedJobs >= 50) score += 10;
    else if (tech.completedJobs >= 20) score += 5;

    // Availability bonus
    if (tech.isAvailable) score += 5;

    return score.clamp(0, 100);
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
// ❌ Remove this: import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/constants/country_currency.dart';


// ============================================================
// ✅ USER DATA MODEL
// ============================================================
class UserData {
  final String uid;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String address;
  final String pincode;
  final String profileImageUrl;
  final String role;
  final bool isProfileComplete;
  final String countryCode;
  final String currencyCode;
  final String currencySymbol;

  UserData({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.pincode,
    required this.profileImageUrl,
    required this.role,
    required this.isProfileComplete,
    this.countryCode = 'PK',
    this.currencyCode = 'PKR',
    this.currencySymbol = 'Rs',
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final countryCode = data['countryCode'] ?? 'PK';
    final country = CountriesData.getCountryByCode(countryCode);

    return UserData(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      role: data['role'] ?? 'customer',
      isProfileComplete: data['isProfileComplete'] ?? false,
      countryCode: countryCode,
      currencyCode: country?.currencyCode ?? 'PKR',
      currencySymbol: country?.currencySymbol ?? 'Rs',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'pincode': pincode,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'isProfileComplete': isProfileComplete,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }

  UserData copyWith({
    String? displayName,
    String? phoneNumber,
    String? address,
    String? pincode,
    String? profileImageUrl,
    String? role,
    bool? isProfileComplete,
    String? countryCode,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return UserData(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  String toString() {
    return 'UserData(uid: $uid, displayName: $displayName, countryCode: $countryCode, currencyCode: $currencyCode)';
  }
}

// ============================================================
// ✅ USER PROVIDERS
// ============================================================

// Provider for current user UID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// Provider for current Firebase User
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// ✅ Main User Data Provider
final userDataProvider = FutureProvider<UserData?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;

  return UserData.fromFirestore(doc);
});

// ✅ Provider for user currency code
final userCurrencyProvider = FutureProvider<String>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData?.currencyCode ?? 'PKR';
});

// ✅ Provider for user currency symbol
final userCurrencySymbolProvider = FutureProvider<String>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData?.currencySymbol ?? 'Rs';
});

// ✅ Provider for user country code
final userCountryProvider = FutureProvider<String>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData?.countryCode ?? 'PK';
});

// ✅ Provider for user display name
final userDisplayNameProvider = FutureProvider<String>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData?.displayName ?? 'User';
});

// ✅ Provider for user phone
final userPhoneProvider = FutureProvider<String>((ref) async {
  final userData = await ref.watch(userDataProvider.future);
  return userData?.phoneNumber ?? '';
});

// ============================================================
// ✅ USER NOTIFIER (For updating user data)
// ============================================================

class UserNotifier extends StateNotifier<UserData?> {
  UserNotifier() : super(null);

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = null;
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      state = UserData.fromFirestore(doc);
    } else {
      state = null;
    }
  }

  Future<void> updateUserData({
    String? displayName,
    String? phoneNumber,
    String? address,
    String? pincode,
    String? profileImageUrl,
    String? countryCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['displayName'] = displayName;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (address != null) updateData['address'] = address;
    if (pincode != null) updateData['pincode'] = pincode;
    if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
    if (countryCode != null) {
      final country = CountriesData.getCountryByCode(countryCode);
      updateData['countryCode'] = countryCode;
      updateData['currencyCode'] = country?.currencyCode ?? 'PKR';
      updateData['currencySymbol'] = country?.currencySymbol ?? 'Rs';
    }
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updateData);

    await loadUserData();
  }

  Future<void> updateRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await loadUserData();
  }

  Future<void> completeProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'isProfileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await loadUserData();
  }
}

// ✅ User Notifier Provider
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserData?>((ref) {
  return UserNotifier();
});

// ============================================================
// ✅ AUTH STATE PROVIDER
// ============================================================

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ✅ Check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return FirebaseAuth.instance.currentUser != null;
});
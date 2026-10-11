import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
// ❌ Remove: import 'package:flutter_riverpod/legacy.dart';
import '../repositories/auth_repository.dart';
import 'auth_provider.dart';

// ========== AUTH STATE ==========
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final User? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
      user: user ?? this.user,
    );
  }
}

// ========== AUTH STATE NOTIFIER ==========
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthStateNotifier(this._authRepo) : super(const AuthState());

  // ========== SIGN IN ==========
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await _authRepo.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: userCredential.user,
      );
      print('✅ AuthState: Sign-in success: ${userCredential.user?.email}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      print('❌ AuthState: Sign-in error: $e');
      rethrow;
    }
  }

  // ========== SIGN UP ==========
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await _authRepo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // ✅ Save user to Firestore with basic info
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'userId': userCredential.user!.uid,
          'displayName': displayName,
          'email': email,
          'phoneNumber': '',
          'address': '',
          'pincode': '',
          'profileImageUrl': '',
          'role': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created in Firestore');
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: userCredential.user,
      );
      print('✅ AuthState: Sign-up success: ${userCredential.user?.email}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      print('❌ AuthState: Sign-up error: $e');
      rethrow;
    }
  }

  // ========== GOOGLE SIGN IN ==========
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final UserCredential? userCredential =
      await _authRepo.signInWithGoogle();

      if (userCredential == null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          error: 'Sign-in cancelled',
        );
        return;
      }

      // ✅ Check if user document exists, if not create one
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // New user from Google - create basic document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'userId': userCredential.user!.uid,
          'displayName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phoneNumber': '',
          'address': '',
          'pincode': '',
          'profileImageUrl': userCredential.user!.photoURL ?? '',
          'role': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ New Google user document created');
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: userCredential.user,
      );
      print('✅ AuthState: Google sign-in success: ${userCredential.user?.email}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      print('❌ AuthState: Google sign-in error: $e');
      rethrow;
    }
  }

  // ========== APPLE SIGN IN ==========
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final UserCredential? userCredential =
      await _authRepo.signInWithApple();

      if (userCredential == null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          error: 'Sign-in cancelled',
        );
        return;
      }

      // ✅ Check if user document exists, if not create one
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // New user from Apple - create basic document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'userId': userCredential.user!.uid,
          'displayName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phoneNumber': '',
          'address': '',
          'pincode': '',
          'profileImageUrl': '',
          'role': '',
          'isProfileComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ New Apple user document created');
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: userCredential.user,
      );
      print('✅ AuthState: Apple sign-in success: ${userCredential.user?.email}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      print('❌ AuthState: Apple sign-in error: $e');
      rethrow;
    }
  }

  // ========== FORGOT PASSWORD ==========
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepo.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        error: 'Password reset email sent to $email',
      );
      print('✅ AuthState: Password reset email sent');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
      print('❌ AuthState: Forgot password error: $e');
      rethrow;
    }
  }

  // ========== SIGN OUT ==========
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepo.signOut();
      state = const AuthState(isSuccess: true);
      print('✅ AuthState: Sign-out success');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ AuthState: Sign-out error: $e');
      rethrow;
    }
  }

  // ========== DELETE ACCOUNT ==========
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepo.deleteAccount();
      state = const AuthState(isSuccess: true);
      print('✅ AuthState: Account deleted');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ AuthState: Delete account error: $e');
      rethrow;
    }
  }

  // ========== RESET STATE ==========
  void resetState() {
    state = const AuthState();
    print('✅ AuthState: Reset');
  }
}

// ========== PROVIDERS ==========

// Provider for auth state notifier
final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepo);
});

// Provider for auth operations (sign in, sign up, etc.)
final authOperationsProvider = Provider<AuthStateNotifier>((ref) {
  return ref.watch(authStateNotifierProvider.notifier);
});
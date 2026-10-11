import 'package:firebase_auth/firebase_auth.dart';

import '../../../../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Get current user
  User? get currentUser => _authService.currentUser;

  String? get currentUserId => _authService.currentUserId;

  // Sign up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _authService.signInWithEmail(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    return await _authService.signInWithGoogle();
  }
  Future<UserCredential?> signInWithApple() async {
    return await _authService.signInWithApple();
  }

  // Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }


  // Delete account
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  // Reload user
  Future<void> reloadUser() async {
    await _authService.reloadUser();
  }

  // Check email verification
  bool get isEmailVerified => _authService.isEmailVerified;
}
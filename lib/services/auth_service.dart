import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ YOUR CLIENT IDs (From Google Cloud Console)
  static const String _webClientId =
      '263099472315-h8447jtl93etksqugralsu67kkm6unkf.apps.googleusercontent.com';

  static const String _androidClientId =
      '263099472315-sldng06gsmvaf3t7m52oitsdsocmp7t8.apps.googleusercontent.com';

  static const String _iosClientId =
      '263099472315-62prpjleljk85m594oopf0ahidkpv4bd.apps.googleusercontent.com';

  AuthService() {
    // ✅ Initialize Google Sign-In (Correct for v7.2.0)
    if (!kIsWeb) {
      try {
        // ⚠️ NOTE: iosClientId is NOT a parameter in v7.2.0
        // iOS client ID is auto-detected from GoogleService-Info.plist
        GoogleSignIn.instance.initialize(
          clientId: _androidClientId,     // Android client ID
          serverClientId: _webClientId,   // Web client ID (REQUIRED for Android!)
        );
        print('✅ Google Sign-In initialized successfully');
      } catch (e) {
        print('❌ Google Sign-In initialization failed: $e');
      }
    }
  }

  // ========== STREAMS & GETTERS ==========
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ========== EMAIL SIGN UP ==========
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== EMAIL SIGN IN ==========
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }


// ✅ GOOGLE SIGN IN - Returns UserCredential
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        return await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser =
        await GoogleSignIn.instance.authenticate();

        if (googleUser == null) {
          print('❌ Google sign-in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        print('✅ Google sign-in successful: ${userCredential.user?.email}');
        return userCredential;
      }
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      return null;
    }
  }

  // ✅ APPLE SIGN IN
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        AppleAuthProvider authProvider = AppleAuthProvider();
        authProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        return await _auth.signInWithPopup(authProvider);
      } else {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.baghirabi.custech',
            redirectUri: Uri.parse(
              'https://custech-c938f.firebaseapp.com/__/auth/handler',
            ),
          ),
        );

        final AuthCredential credential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print('❌ Apple Sign-In Error: $e');
      return null;
    }
  }

  // ========== FORGOT PASSWORD ==========
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== SIGN OUT ==========
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  // ========== DELETE ACCOUNT ==========
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== EMAIL VERIFICATION ==========
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== RELOAD USER ==========
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ========== ERROR HANDLER ==========
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found. Please check your email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
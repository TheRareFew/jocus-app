import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _devBypass = false;

  AuthProvider() {
    // In debug mode, allow dev bypass
    if (kDebugMode) {
      _devBypass = true;
      // Auto sign in with test account in debug mode
      _autoDevSignIn();
    }

    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> _autoDevSignIn() async {
    if (!_devBypass) return;
    
    try {
      await signInWithEmailAndPassword(
        'test@example.com',
        'password123'
      );
    } catch (e) {
      // If test account doesn't exist, create it
      try {
        await createUserWithEmailAndPassword(
          'test@example.com',
          'password123'
        );
      } catch (e) {
        debugPrint('Failed to create test account: $e');
      }
    }
  }

  // Toggle dev bypass for testing
  void toggleDevBypass() {
    if (!kDebugMode) return;
    _devBypass = !_devBypass;
    if (_devBypass) {
      _autoDevSignIn();
    } else {
      signOut();
    }
    notifyListeners();
  }

  bool get isDevBypassEnabled => _devBypass;

  User? get currentUser => _user;
  bool get isAuthenticated => _devBypass || (_user != null && _user!.emailVerified);

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!credential.user!.emailVerified) {
        throw Exception('Please verify your email before signing in.');
      }
      return credential;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.sendEmailVerification();
      return credential;
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _user?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  Future<void> reloadUser() async {
    try {
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }
} 
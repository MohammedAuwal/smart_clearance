import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  // Singleton pattern so we only ever have one instance
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Current User ────────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream that emits whenever auth state changes
  // We listen to this in main.dart to redirect to login or dashboard
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Register With Email and Password ────────────────────────────────────────
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult(
        success: true,
        user: credential.user,
        message: 'Account created successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ─── Login With Email and Password ───────────────────────────────────────────
  Future<AuthResult> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult(
        success: true,
        user: credential.user,
        message: 'Login successful',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ─── Send Password Reset Email ────────────────────────────────────────────────
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return AuthResult(
        success: true,
        message: 'Password reset email sent successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send reset email. Please try again.',
      );
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────────
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult(
        success: true,
        message: 'Signed out successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign out. Please try again.',
      );
    }
  }

  // ─── Update Display Name ──────────────────────────────────────────────────────
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // ─── Update Email ─────────────────────────────────────────────────────────────
  Future<AuthResult> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
      return AuthResult(
        success: true,
        message: 'Verification email sent to $newEmail',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update email. Please try again.',
      );
    }
  }

  // ─── Update Password ──────────────────────────────────────────────────────────
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return AuthResult(
        success: true,
        message: 'Password updated successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update password. Please try again.',
      );
    }
  }

  // ─── Reload Current User ──────────────────────────────────────────────────────
  // Call this after updating profile to get fresh data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ─── Get Firebase ID Token ────────────────────────────────────────────────────
  // Used when making authenticated API calls
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      return null;
    }
  }

  // ─── Delete Account ───────────────────────────────────────────────────────────
  Future<AuthResult> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to delete account. Please try again.',
      );
    }
  }

  // ─── Firebase Error Code to Human Readable Message ───────────────────────────
  // These are all the common Firebase Auth error codes
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters';
      case 'invalid-email':
        return 'The email address format is invalid';
      case 'user-disabled':
        return 'This account has been disabled. Contact support';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'requires-recent-login':
        return 'Please log out and log in again before making this change';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      default:
        return 'Authentication failed. Please try again (Code: $code)';
    }
  }
}

// ─── Result Wrapper Class ─────────────────────────────────────────────────────
// Instead of throwing exceptions everywhere, we return this clean result object
// Every auth call returns this so the UI always knows exactly what happened
class AuthResult {
  final bool success;
  final User? user;
  final String message;
  final String? errorCode;

  const AuthResult({
    required this.success,
    this.user,
    required this.message,
    this.errorCode,
  });

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message)';
  }
}

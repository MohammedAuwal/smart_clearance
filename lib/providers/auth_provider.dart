import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../core/services/firebase_auth_service.dart';
import '../core/services/supabase_service.dart';

// ─── Raw Firebase Auth Stream Provider ───────────────────────────────────────
// This listens to Firebase auth state changes in real time
// It emits User? every time someone logs in or logs out
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuthService().authStateChanges;
});

// ─── Current App User Provider ────────────────────────────────────────────────
// This fetches the full UserModel from Supabase once Firebase confirms login
// It depends on firebaseAuthStateProvider so it re-runs when auth changes
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(firebaseAuthStateProvider);

  return authState.when(
    data: (firebaseUser) async {
      if (firebaseUser == null) return null;

      final result = await SupabaseService()
          .getUserByFirebaseUid(firebaseUser.uid);

      if (result.success) return result.data;
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── Auth Notifier State ──────────────────────────────────────────────────────
// This holds the current state of any auth operation in progress
// (loading, success, error) so the UI can react properly
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? user,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      user: user ?? this.user,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────
// This is where all the auth LOGIC lives
// UI calls methods here and reads the state to know what to show
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final SupabaseService _supabaseService;

  AuthNotifier({
    required FirebaseAuthService authService,
    required SupabaseService supabaseService,
  })  : _authService = authService,
        _supabaseService = supabaseService,
        super(const AuthState());

  // ─── Register New Student ───────────────────────────────────────────────
  Future<bool> registerStudent({
    required String fullName,
    required String matricNumber,
    required String email,
    required String password,
    required String phoneNumber,
    required String department,
    required String faculty,
    required String level,
  }) async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Step 1: Create Firebase Auth account
      final authResult = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!authResult.success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: authResult.message,
        );
        return false;
      }

      final firebaseUser = authResult.user!;

      // Step 2: Update Firebase display name
      await _authService.updateDisplayName(fullName);

      // Step 3: Create user profile in Supabase
      final userModel = UserModel(
        id: firebaseUser.uid, // Use Firebase UID as Supabase id for simplicity
        firebaseUid: firebaseUser.uid,
        fullName: fullName,
        matricNumber: matricNumber.trim().toUpperCase(),
        email: email.trim().toLowerCase(),
        phoneNumber: phoneNumber.trim(),
        department: department,
        faculty: faculty,
        currentLevel: level,
        role: 'student', // All self-registered users are students
        isActive: true,
        createdAt: DateTime.now(),
      );

      final supabaseResult =
          await _supabaseService.createUserProfile(userModel);

      if (!supabaseResult.success) {
        // Firebase account was created but Supabase failed
        // Sign out of Firebase to keep things consistent
        await _authService.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: supabaseResult.error ??
              'Failed to create profile. Please try again.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Account created successfully! Welcome to SmartClearance.',
        user: supabaseResult.data,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  // ─── Login ──────────────────────────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Step 1: Login with Firebase
      final authResult = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!authResult.success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: authResult.message,
        );
        return null;
      }

      // Step 2: Fetch user profile from Supabase
      final userResult = await _supabaseService
          .getUserByFirebaseUid(authResult.user!.uid);

      if (!userResult.success || userResult.data == null) {
        await _authService.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Your profile was not found. Please contact support.',
        );
        return null;
      }

      final user = userResult.data!;

      // Step 3: Check if account is still active
      if (!user.isActive) {
        await _authService.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Your account has been deactivated. Please contact your department.',
        );
        return null;
      }

      state = state.copyWith(
        isLoading: false,
        user: user,
        clearError: true,
      );

      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
      return null;
    }
  }

  // ─── Send Password Reset Email ──────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result =
        await _authService.sendPasswordResetEmail(email: email);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        successMessage:
            'Password reset link sent to $email. Check your inbox.',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message,
      );
      return false;
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState(); // Reset state completely on logout
  }

  // ─── Update User Profile ────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _supabaseService.updateUserProfile(
      userId: userId,
      updates: updates,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.data,
        successMessage: 'Profile updated successfully',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error ?? 'Failed to update profile.',
      );
      return false;
    }
  }

  // ─── Clear Error ────────────────────────────────────────────────────────
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Clear Success ──────────────────────────────────────────────────────
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

// ─── Auth Provider (the one UI widgets will watch) ────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authService: FirebaseAuthService(),
    supabaseService: SupabaseService(),
  );
});

// ─── Convenience Providers ────────────────────────────────────────────────────
// Smaller derived providers so widgets only rebuild when they need to

// Is the auth operation currently loading?
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// Is there an auth error right now?
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});

// The currently logged-in user from auth state
final authUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

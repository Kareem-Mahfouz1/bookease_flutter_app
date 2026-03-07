import 'dart:convert';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/core/services/firebase_auth_service.dart';
import 'package:appointment_booking/features/auth/data/models/user_model.dart';

/// Repository for handling authentication business logic
///
/// Acts as an intermediary between the UI layer (Cubit) and the data layer (Firebase)
/// Handles result mapping, error handling, and user persistence
class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository({FirebaseAuthService? authService})
    : _authService = authService ?? FirebaseAuthService();

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges {
    return _authService.authStateChanges.map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  /// Returns the currently authenticated user from cache or Firebase
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final firebaseUser = _authService.currentUser;

      if (firebaseUser != null) {
        final user = UserModel.fromFirebaseUser(firebaseUser);
        await _cacheUser(user);
        return Success(user);
      }

      // Try to get user from cache if Firebase user is null
      final cachedUser = await _getCachedUser();
      return Success(cachedUser);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs up a new user with email and password
  Future<Result<UserModel>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Cache the user data and auth state
      await _cacheUser(user);
      await _setAuthState(isAuthenticated: true);

      return Success(user);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs in an existing user with email and password
  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cache the user data and auth state
      await _cacheUser(user);
      await _setAuthState(isAuthenticated: true);
      return Success(user);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs in a user with Google
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();

      // Cache the user data and auth state
      await _cacheUser(user);
      await _setAuthState(isAuthenticated: true);
      return Success(user);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs out the current user
  Future<Result<void>> signOut() async {
    try {
      await _authService.signOut();

      // Clear cached user data and auth state
      await _clearUserCache();
      await _setAuthState(isAuthenticated: false);

      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Sends a password reset email
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _authService.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Sends email verification to the current user
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Updates the current user's profile
  Future<Result<UserModel>> updateProfile({String? displayName}) async {
    try {
      if (displayName != null) {
        await _authService.updateDisplayName(displayName);
      }

      await _authService.reloadUser();
      final firebaseUser = _authService.currentUser;

      if (firebaseUser == null) {
        return const Failure(AuthException('User not found after update'));
      }

      final user = UserModel.fromFirebaseUser(firebaseUser);
      await _cacheUser(user);

      return Success(user);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Checks if user is authenticated
  Future<bool> isAuthenticated() async {
    final firebaseUser = _authService.currentUser;
    return firebaseUser != null;
  }

  // Private helper methods for caching

  /// Caches user data securely
  Future<void> _cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await SharedPrefHelper.setSecuredString(SharedPrefKeys.userToken, userJson);
  }

  /// Retrieves cached user data
  Future<UserModel?> _getCachedUser() async {
    try {
      final userJson = await SharedPrefHelper.getSecuredString(
        SharedPrefKeys.userToken,
      );

      if (userJson.isEmpty) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  /// Clears cached user data
  Future<void> _clearUserCache() async {
    await SharedPrefHelper.clearAllSecuredData();
  }

  /// Sets authentication state in SharedPreferences
  Future<void> _setAuthState({required bool isAuthenticated}) async {
    await SharedPrefHelper.setData(SharedPrefKeys.isLoggedIn, isAuthenticated);
  }
}

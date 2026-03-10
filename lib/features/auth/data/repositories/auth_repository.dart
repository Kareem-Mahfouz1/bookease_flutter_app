import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/core/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for handling Firebase Authentication operations.
///
/// Responsible only for auth actions (sign-in, sign-up, sign-out, password
/// reset). All Firestore user-profile logic lives in [ProfileRepository].
class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository({FirebaseAuthService? authService})
    : _authService = authService ?? FirebaseAuthService();

  /// The currently authenticated Firebase user, or `null`.
  User? get currentUser => _authService.currentUser;

  /// Signs up a new user with email and password.
  ///
  /// Returns the raw [User] on success so the caller can create the Firestore
  /// profile afterwards.
  Future<Result<User>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final firebaseUser = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Success(firebaseUser);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs in an existing user with email and password.
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Success(firebaseUser);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs in a user with Google.
  Future<Result<User>> signInWithGoogle() async {
    try {
      final firebaseUser = await _authService.signInWithGoogle();
      return Success(firebaseUser);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Signs out the current user and clears local state.
  Future<Result<void>> signOut() async {
    try {
      await _authService.signOut();
      await SharedPrefHelper.clearAllSecuredData();
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Sends a password reset email.
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

  /// Sends email verification to the current user.
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

  /// Updates the current user's Firebase Auth display name.
  ///
  /// Call [ProfileRepository.updateProfile] afterwards to sync the change to
  /// Firestore.
  Future<Result<void>> updateDisplayName(String displayName) async {
    try {
      await _authService.updateDisplayName(displayName);
      await _authService.reloadUser();
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';

/// Service for handling Firebase Authentication operations
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Returns the current authenticated user, null if not authenticated
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream of user changes (including token refresh, email verification, etc.)
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  /// Signs up a new user with email and password
  ///
  /// Throws [EmailAlreadyInUseException] if email is already registered
  /// Throws [WeakPasswordException] if password is too weak
  /// Throws [InvalidEmailException] if email format is invalid
  /// Throws [NetworkException] if there's a network error
  /// Throws [ServerException] for server-side errors
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.reload();
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const ServerException('User creation succeeded but user is null');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Signs in an existing user with email and password
  ///
  /// Throws [InvalidCredentialsException] if credentials are invalid
  /// Throws [UserNotFoundException] if user doesn't exist
  /// Throws [UserDisabledException] if user account is disabled
  /// Throws [TooManyRequestsException] if too many failed attempts
  /// Throws [NetworkException] if there's a network error
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const ServerException('Sign in succeeded but user is null');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Signs in a user using their Google account
  ///
  /// Signs in a user using their Google account
  ///
  /// Throws [AuthException] if sign in is aborted or fails
  Future<User> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      try {
        await googleSignIn.initialize();
      } catch (_) {
        // May already be initialized
      }

      // Trigger the interactive authentication flow
      final GoogleSignInAccount account = await googleSignIn.authenticate(
        scopeHint: ['email'],
      );

      // Obtain auth details
      final authz = await account.authorizationClient.authorizationForScopes([
        'email',
      ]);
      final authentication = account.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: authentication.idToken,
      );

      // Sign in to Firebase with the new credential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw const ServerException(
          'Google sign in succeeded but user is null',
        );
      }

      return user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException(
          'Google sign in cancelled',
          code: 'google-sign-in-cancelled',
        );
      }

      throw AuthException(
        e.description ?? 'Google sign in failed',
        code: 'google-sign-in-failed',
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Sends a password reset email
  ///
  /// Throws [UserNotFoundException] if user doesn't exist
  /// Throws [InvalidEmailException] if email format is invalid
  /// Throws [NetworkException] if there's a network error
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Sends email verification to the current user
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Reloads the current user's data
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Updates the current user's email
  ///
  /// Throws [EmailAlreadyInUseException] if email is already in use
  /// Throws [InvalidEmailException] if email format is invalid
  Future<void> updateEmail(String email) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }
      await user.verifyBeforeUpdateEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Updates the current user's password
  ///
  /// Throws [WeakPasswordException] if password is too weak
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Deletes the current user's account
  Future<void> deleteUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('No authenticated user found');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Maps Firebase Auth exception codes to app-specific exceptions
  AppException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return const NetworkException();
      default:
        return AuthException.fromCode(e.code, e.message);
    }
  }
}

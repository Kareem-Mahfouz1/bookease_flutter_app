import 'dart:io';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/core/services/firestore_service.dart';
import 'package:appointment_booking/core/services/storage_service.dart';
import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Repository for managing user profile documents in Firestore.
///
/// All operations target the `users/{uid}` collection.
class ProfileRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static const _collection = 'users';

  ProfileRepository({
    FirestoreService? firestoreService,
    StorageService? storageService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _storageService = storageService ?? StorageService();

  /// Creates a new user profile document at `users/{firebaseUser.uid}`.
  ///
  /// Provide [displayName] to override the value coming from Firebase Auth
  /// (useful for email sign-up where the user typed their name in the form).
  /// [role] defaults to [UserRole.customer].
  ///
  /// Uses [merge: false] to avoid accidentally overwriting an existing profile.
  /// Call [getUser] first when you need an upsert-style write.
  Future<Result<AppUser>> createUser(
    firebase_auth.User firebaseUser, {
    String? displayName,
    UserRole role = UserRole.customer,
    required AuthProvider authProvider,
  }) async {
    try {
      final now = DateTime.now();

      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: displayName ?? firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        role: role,
        authProvider: authProvider,
        createdAt: now,
      );

      // Override createdAt with a server-side timestamp for accuracy
      await _firestoreService.setDocument(
        documentPath: '$_collection/${firebaseUser.uid}',
        data: {
          ...appUser.toMap(),
          'createdAt': FirestoreService.serverTimestamp,
        },
        merge: false,
      );
      return Success(appUser);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Reads the user profile document from `users/{uid}`.
  ///
  /// Returns [Failure] with code `not-found` when the document does not exist.
  Future<Result<AppUser>> getUser(String uid) async {
    try {
      final data = await _firestoreService.getDocument(
        documentPath: '$_collection/$uid',
      );

      if (data == null) {
        return const Failure(
          FirestoreException('User profile not found', code: 'not-found'),
        );
      }

      return Success(AppUser.fromFirestore(data));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Updates specific fields on the user profile document at `users/{uid}`.
  Future<Result<void>> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateDocument(
        documentPath: '$_collection/$uid',
        data: data,
      );
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Updates the user's profile information handling name change and image upload.
  Future<Result<(AppUser, String?)>> updateProfileInfo({
    required String uid,
    required AppUser currentUser,
    String? newName,
    File? imageFile,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (newName != null && newName != currentUser.displayName) {
        updateData['displayName'] = newName;
      }

      // Update basic profile details first
      if (updateData.isNotEmpty) {
        await _firestoreService.updateDocument(
          documentPath: '$_collection/$uid',
          data: updateData,
        );
      }

      AppUser updatedUser = currentUser.copyWith(
        displayName: newName ?? currentUser.displayName,
      );

      String? partialError;

      // Image upload phase
      if (imageFile != null) {
        try {
          final downloadUrl = await _storageService.uploadProfileImage(
            userId: uid,
            imageFile: imageFile,
          );

          // Save the new URL to Firestore
          await _firestoreService.updateDocument(
            documentPath: '$_collection/$uid',
            data: {'photoUrl': downloadUrl},
          );

          updatedUser = updatedUser.copyWith(photoUrl: downloadUrl);
        } catch (e) {
          partialError = 'Image upload failed: $e';
        }
      }

      return Success((updatedUser, partialError));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Change user password
  Future<Result<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        return const Failure(
          AuthException('No authenticated user found', code: 'no-user'),
        );
      }

      // Re-authenticate user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);

      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? 'Authentication failed';
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMessage =
            'The current password you entered is incorrect. Please try again.';
      }
      return Failure(AuthException(errorMessage, code: e.code));
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }
}

import 'dart:convert';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/helpers/constants.dart';
import 'package:appointment_booking/core/helpers/shared_pref_helper.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/core/services/firestore_service.dart';
import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Repository for managing user profile documents in Firestore.
///
/// All operations target the `users/{uid}` collection.
class ProfileRepository {
  final FirestoreService _firestoreService;

  static const _collection = 'users';

  ProfileRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

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

      await _cacheUser(appUser);
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

  /// Returns the locally-cached [AppUser], or `null` if none is stored.
  Future<AppUser?> getCachedUser() async {
    try {
      final json = await SharedPrefHelper.getSecuredString(
        SharedPrefKeys.userToken,
      );
      if (json.isEmpty) return null;
      return AppUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cache helpers
  // ---------------------------------------------------------------------------

  Future<void> _cacheUser(AppUser user) async {
    await SharedPrefHelper.setSecuredString(
      SharedPrefKeys.userToken,
      jsonEncode(user.toJson()),
    );
  }
}

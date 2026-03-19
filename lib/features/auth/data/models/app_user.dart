import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The role of the user within the application.
enum UserRole {
  customer,
  staff;

  factory UserRole.fromString(String value) {
    return switch (value) {
      'staff' => UserRole.staff,
      _ => UserRole.customer,
    };
  }
}

/// The authentication provider used to create the account.
enum AuthProvider {
  google,
  email;

  factory AuthProvider.fromString(String value) {
    return switch (value) {
      'google' => AuthProvider.google,
      _ => AuthProvider.email,
    };
  }
}

/// Represents a user profile document stored in Firestore (`users/{uid}`).
///
/// Distinct from the Firebase Auth user – this model holds application-level
/// data such as role and the original authentication provider.
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? fcmToken;
  final UserRole role;
  final AuthProvider authProvider;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
    required this.role,
    required this.authProvider,
    required this.createdAt,
  });

  /// Creates an [AppUser] from a Firestore document data map.
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'customer'),
      authProvider: AuthProvider.fromString(
        data['authProvider'] as String? ?? 'email',
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [AppUser] to a Firestore-compatible data map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'role': role.name,
      'authProvider': authProvider.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this [AppUser] with updated fields.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? fcmToken,
    UserRole? role,
    AuthProvider? authProvider,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    fcmToken,
    role,
    authProvider,
    createdAt,
  ];
}

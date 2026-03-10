/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  /// Factory constructor that returns appropriate exception based on error code
  factory AuthException.fromCode(String code, [String? customMessage]) {
    return switch (code) {
      'user-not-found' => const AuthException(
        'No user found with this email',
        code: 'user-not-found',
      ),
      'wrong-password' || 'invalid-credential' => const AuthException(
        'Invalid email or password',
        code: 'invalid-credential',
      ),
      'email-already-in-use' => const AuthException(
        'An account already exists with this email',
        code: 'email-already-in-use',
      ),
      'weak-password' => const AuthException(
        'Password should be at least 6 characters',
        code: 'weak-password',
      ),
      'invalid-email' => const AuthException(
        'The email address is not valid',
        code: 'invalid-email',
      ),
      'user-disabled' => const AuthException(
        'This account has been disabled',
        code: 'user-disabled',
      ),
      'too-many-requests' => const AuthException(
        'Too many attempts. Please try again later',
        code: 'too-many-requests',
      ),
      'operation-not-allowed' => const AuthException(
        'This operation is not allowed',
        code: 'operation-not-allowed',
      ),
      _ => AuthException(
        customMessage ?? 'Authentication error occurred',
        code: code,
      ),
    };
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException()
    : super(
        'Network error. Please check your internet connection',
        code: 'network-error',
      );
}

/// Server related exceptions
class ServerException extends AppException {
  const ServerException([String? message])
    : super(
        message ?? 'Server error. Please try again later',
        code: 'server-error',
      );
}

/// Unknown exceptions
class UnknownException extends AppException {
  const UnknownException([String? message])
    : super(message ?? 'An unexpected error occurred', code: 'unknown-error');
}

/// Firestore related exceptions
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code});

  /// Factory constructor that returns appropriate exception based on Firestore error code
  factory FirestoreException.fromCode(String code, [String? customMessage]) {
    return switch (code) {
      'permission-denied' => const FirestoreException(
        'You do not have permission to perform this action',
        code: 'permission-denied',
      ),
      'not-found' => const FirestoreException(
        'The requested document was not found',
        code: 'not-found',
      ),
      'already-exists' => const FirestoreException(
        'The document already exists',
        code: 'already-exists',
      ),
      'resource-exhausted' => const FirestoreException(
        'Quota exceeded. Please try again later',
        code: 'resource-exhausted',
      ),
      'failed-precondition' => const FirestoreException(
        'Operation was rejected due to a conflict',
        code: 'failed-precondition',
      ),
      'aborted' => const FirestoreException(
        'Operation was aborted. Please try again',
        code: 'aborted',
      ),
      'unavailable' => const FirestoreException(
        'Service is currently unavailable. Please try again later',
        code: 'unavailable',
      ),
      'deadline-exceeded' => const FirestoreException(
        'Operation timed out. Please try again',
        code: 'deadline-exceeded',
      ),
      'cancelled' => const FirestoreException(
        'Operation was cancelled',
        code: 'cancelled',
      ),
      'data-loss' => const FirestoreException(
        'Unrecoverable data loss occurred',
        code: 'data-loss',
      ),
      _ => FirestoreException(
        customMessage ?? 'A database error occurred',
        code: code,
      ),
    };
  }
}

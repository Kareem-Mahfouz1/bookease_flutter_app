import 'package:appointment_booking/features/auth/data/repositories/auth_repository.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_state.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/profile/data/repo/profile_repository.dart';
import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  AuthCubit(this._authRepository, this._profileRepository)
    : super(const AuthInitial());

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());

    final authResult = await _authRepository.signIn(
      email: email,
      password: password,
    );

    switch (authResult) {
      case Failure(:final exception):
        emit(AuthFailure(exception.message));
      case Success():
        emit(AuthSuccess());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const GoogleSignInLoading());

    final authResult = await _authRepository.signInWithGoogle();

    switch (authResult) {
      case Failure(:final exception):
        if (exception.code == 'google-sign-in-cancelled') {
          emit(const AuthInitial());
          return;
        }
        emit(AuthFailure(exception.message));
      case Success(data: final firebaseUser):
        // Check whether a Firestore profile already exists (returning user)
        final existingResult = await _profileRepository.getUser(
          firebaseUser.uid,
        );

        switch (existingResult) {
          case Success():
            emit(AuthSuccess());
          case Failure():
            // New Google user – create the Firestore profile
            final createResult = await _profileRepository.createUser(
              firebaseUser,
              authProvider: AuthProvider.google,
            );
            createResult.when(
              success: (appUser) => emit(AuthSuccess()),
              failure: (exception) => emit(AuthFailure(exception.message)),
            );
        }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    emit(const AuthLoading());

    final authResult = await _authRepository.signUp(
      email: email,
      password: password,
      displayName: fullName,
    );

    switch (authResult) {
      case Failure(:final exception):
        emit(AuthFailure(exception.message));
      case Success(data: final firebaseUser):
        final profileResult = await _profileRepository.createUser(
          firebaseUser,
          displayName: fullName,
          role: UserRole.customer,
          authProvider: AuthProvider.email,
        );
        profileResult.when(
          success: (appUser) => emit(AuthSuccess()),
          failure: (exception) => emit(AuthFailure(exception.message)),
        );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(const AuthLoading());

    final result = await _authRepository.sendPasswordResetEmail(email: email);

    result.when(
      success: (_) => emit(const PasswordResetEmailSent()),
      failure: (exception) => emit(AuthFailure(exception.message)),
    );
  }

  Future<void> signOut() async {
    final result = await _authRepository.signOut();
    result.when(
      success: (_) => emit(const AuthSignedOut()),
      failure: (exception) => emit(AuthFailure(exception.message)),
    );
  }
}

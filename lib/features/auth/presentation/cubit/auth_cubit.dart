import 'package:appointment_booking/data/repositories/auth_repository.dart';
import 'package:appointment_booking/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    result.when(
      success: (_) => emit(const AuthSuccess()),
      failure: (exception) => emit(AuthFailure(exception.message)),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      displayName: fullName,
    );

    result.when(
      success: (_) => emit(const AuthSuccess()),
      failure: (exception) => emit(AuthFailure(exception.message)),
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    emit(const AuthLoading());

    final result = await _authRepository.sendPasswordResetEmail(email: email);

    result.when(
      success: (_) => emit(const PasswordResetEmailSent()),
      failure: (exception) => emit(AuthFailure(exception.message)),
    );
  }
}

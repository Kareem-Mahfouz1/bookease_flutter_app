import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  /// Whether any auth operation is currently in progress
  bool get isLoading => this is AuthLoading || this is GoogleSignInLoading;

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class GoogleSignInLoading extends AuthState {
  const GoogleSignInLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetEmailSent extends AuthState {
  const PasswordResetEmailSent();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

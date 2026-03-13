import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'package:equatable/equatable.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileSuccess extends ProfileState {
  final AppUser user;
  final String? partialErrorMessage;

  const ProfileSuccess(this.user, {this.partialErrorMessage});

  @override
  List<Object?> get props => [user, partialErrorMessage];
}

class ProfileFailure extends ProfileState {
  final String message;

  const ProfileFailure(this.message);

  @override
  List<Object?> get props => [message];
}

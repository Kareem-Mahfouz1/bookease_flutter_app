import 'package:appointment_booking/features/profile/data/profile_repository.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/features/auth/data/models/app_user.dart';
import 'dart:io';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  final FirebaseAuth _firebaseAuth;

  ProfileCubit(this._profileRepository, this._firebaseAuth)
    : super(const ProfileInitial());

  /// Resets the profile state back to initial (e.g. after sign-out).
  void reset() => emit(const ProfileInitial());

  /// Fetches the current user's profile from Firestore.
  Future<void> loadProfile() async {
    final uid = _firebaseAuth.currentUser?.uid;

    if (uid == null) {
      emit(const ProfileFailure('No authenticated user found.'));
      return;
    }

    emit(const ProfileLoading());

    final result = await _profileRepository.getUser(uid);

    result.when(
      success: (user) => emit(ProfileSuccess(user)),
      failure: (exception) => emit(ProfileFailure(exception.message)),
    );
  }

  /// Updates the user's profile information.
  ///
  /// The [newName] is updated in Firestore first.
  /// If [imageFile] is provided, it attempts to upload to Firebase Storage and update the [photoUrl].
  Future<void> updateProfile({
    String? newName,
    File? imageFile,
    required AppUser currentUser,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      emit(const ProfileFailure('No authenticated user found.'));
      return;
    }

    emit(const ProfileLoading());

    final result = await _profileRepository.updateProfileInfo(
      uid: uid,
      currentUser: currentUser,
      newName: newName,
      imageFile: imageFile,
    );

    result.when(
      success: (data) {
        final (updatedUser, partialError) = data;
        emit(ProfileSuccess(updatedUser, partialErrorMessage: partialError));
      },
      failure: (exception) => emit(ProfileFailure(exception.message)),
    );
  }
}

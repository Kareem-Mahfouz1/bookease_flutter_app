import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile_photo.jpg');

      final TaskSnapshot uploadTask;
      uploadTask = await ref.putData(
        await imageFile.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const NetworkException();
      }
      throw UnknownException(e.message ?? 'Failed to upload image');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}

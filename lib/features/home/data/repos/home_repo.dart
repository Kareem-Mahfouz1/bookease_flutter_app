import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/core/models/service_model.dart';
import 'package:appointment_booking/core/services/firestore_service.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';

class HomeRepository {
  final FirestoreService _firestoreService;

  const HomeRepository({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  Future<Result<List<ServiceModel>>> getActiveServices() async {
    try {
      final docs = await _firestoreService.queryCollection(
        collectionPath: 'services',
        queryBuilder: (query) => query.where('isActive', isEqualTo: true),
      );

      final services = docs.map((doc) => ServiceModel.fromJson(doc)).toList();
      return Success(services);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }
}

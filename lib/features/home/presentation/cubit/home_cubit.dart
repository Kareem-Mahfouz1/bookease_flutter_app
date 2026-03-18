import 'package:appointment_booking/core/models/service_model.dart';
import 'package:appointment_booking/features/home/data/repos/home_repo.dart';
import 'package:appointment_booking/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _homeRepository;

  // Cache of all active services fetched from the repository
  List<ServiceModel> _allServices = [];

  HomeCubit(this._homeRepository) : super(HomeInitial());

  Future<void> getServices() async {
    emit(HomeLoading());

    final result = await _homeRepository.getActiveServices();

    if (result.isSuccess) {
      _allServices = result.dataOrNull ?? [];
      emit(HomeSuccess(_allServices));
    } else if (result.isFailure) {
      emit(
        HomeFailure(
          result.exceptionOrNull?.message ?? 'Unknown error occurred',
        ),
      );
    }
  }

  Future<void> refreshServices() async {
    await getServices();
  }

  void searchServices(String query) {
    if (query.isEmpty) {
      emit(HomeSuccess(_allServices));
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredServices = _allServices.where((service) {
      return service.name.toLowerCase().contains(lowerQuery);
    }).toList();

    emit(HomeSuccess(filteredServices));
  }
}

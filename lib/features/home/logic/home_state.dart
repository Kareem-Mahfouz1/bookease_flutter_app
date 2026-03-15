import 'package:appointment_booking/core/models/service_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeSuccess extends HomeState {
  final List<ServiceModel> services;

  HomeSuccess(this.services);
}

class HomeFailure extends HomeState {
  final String message;

  HomeFailure(this.message);
}

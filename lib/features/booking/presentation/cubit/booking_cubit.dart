import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/data/repositories/booking_repository.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:appointment_booking/data/models/time_slot_model.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;

  // Selected state we need to hold onto throughout the flow
  DateTime? selectedDate;
  TimeSlotModel? selectedTimeSlot;
  Map<String, dynamic>? selectedServiceData;

  BookingCubit(this._bookingRepository) : super(const BookingInitial());

  void setServiceData(Map<String, dynamic> serviceData) {
    selectedServiceData = serviceData;
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    fetchAvailableSlots(date);
  }

  void selectTimeSlot(TimeSlotModel slot) {
    selectedTimeSlot = slot;
  }

  Future<void> fetchAvailableSlots(DateTime date) async {
    if (selectedServiceData == null) {
      emit(const BookingErrorFetchingSlots('Service data missing.'));
      return;
    }

    emit(const BookingLoadingSlots());

    final serviceId =
        selectedServiceData!['serviceId'] as String? ?? 'custom-id-fallback';

    final result = await _bookingRepository.getAvailableTimeSlots(
      date: date,
      serviceId: serviceId,
    );

    result.when(
      success: (slots) => emit(BookingLoadedSlots(slots)),
      failure: (exception) =>
          emit(BookingErrorFetchingSlots(exception.message)),
    );
  }

  Future<void> submitBooking({
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
  }) async {
    if (selectedServiceData == null || selectedTimeSlot == null) {
      emit(const BookingErrorSubmitting('Missing required booking details.'));
      return;
    }

    emit(const BookingSubmitting());

    final serviceId =
        selectedServiceData!['serviceId'] as String? ?? 'custom-id-fallback';
    final serviceName =
        selectedServiceData!['serviceName'] as String? ?? 'Service';

    final result = await _bookingRepository.submitBooking(
      serviceId: serviceId,
      serviceName: serviceName,
      timeSlot: selectedTimeSlot!,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      notes: notes,
    );

    result.when(
      success: (booking) => emit(BookingSuccess(booking)),
      failure: (exception) => emit(BookingErrorSubmitting(exception.message)),
    );
  }
}

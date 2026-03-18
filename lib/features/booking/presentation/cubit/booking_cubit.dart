import 'package:appointment_booking/features/booking/domain/booking_details.dart';
import 'package:appointment_booking/features/booking/utils/slot_generator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:appointment_booking/core/models/service_model.dart';
import 'package:intl/intl.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _bookingRepository;

  DateTime? selectedDate;
  String? selectedTimeSlot;
  ServiceModel? selectedServiceData;

  BookingCubit(this._bookingRepository) : super(BookingInitial());

  void setServiceData(ServiceModel serviceData) {
    selectedServiceData = serviceData;
  }

  void selectTimeSlot(String slot) {
    selectedTimeSlot = slot;
  }

  Future<void> init() async {
    emit(BookingLoading());
    final result = await _bookingRepository.getAllClinicSchedules();
    result.when(
      success: (schedules) => emit(BookingScheduleLoaded(schedules)),
      failure: (exception) => emit(BookingFailure(exception.message)),
    );
  }

  Future<void> loadAvailableSlots(DateTime date, int durationMinutes) async {
    selectedDate = date;
    emit(BookingLoading());

    final scheduleResult = await _bookingRepository.getClinicSchedule(date);

    await scheduleResult.when(
      success: (schedule) async {
        if (!schedule.isWorkingDay) {
          emit(BookingSlotsLoaded(const [], date));
          return;
        }

        final dateString = DateFormat('yyyy-MM-dd').format(date);
        final bookingsResult = await _bookingRepository.getBookingsForDate(
          dateString,
        );

        bookingsResult.when(
          success: (bookings) {
            final availableSlots = SlotGenerator.generateAvailableSlots(
              schedule: schedule,
              existingBookings: bookings,
              durationMinutes: durationMinutes,
              selectedDate: date,
            );
            emit(BookingSlotsLoaded(availableSlots, date));
          },
          failure: (exception) => emit(BookingFailure(exception.message)),
        );
      },
      failure: (exception) {
        emit(BookingFailure(exception.message));
      },
    );
  }

  Future<void> confirmBooking({
    required String userId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
  }) async {
    if (selectedServiceData == null ||
        selectedTimeSlot == null ||
        selectedDate == null) {
      emit(BookingFailure('Missing required booking details.'));
      return;
    }

    emit(BookingLoading());

    final details = BookingDetails(
      serviceId: selectedServiceData!.id,
      serviceName: selectedServiceData!.name,
      serviceDurationMinutes: selectedServiceData!.durationMinutes,
      price: selectedServiceData!.price,
      date: DateFormat('yyyy-MM-dd').format(selectedDate!),
      startTime: selectedTimeSlot!,
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      notes: notes,
    );

    final result = await _bookingRepository.createBooking(details);

    result.when(
      success: (booking) => emit(BookingSuccess(booking)),
      failure: (exception) {
        if (exception.message == 'Slot no longer available') {
          emit(
            BookingFailure(
              'This slot was just taken, please select another time',
            ),
          );
        } else {
          emit(BookingFailure(exception.message));
        }
      },
    );
  }

  Future<void> getUserBookings(String userId) async {
    emit(BookingLoading());
    final result = await _bookingRepository.getUserBookings(userId);
    result.when(
      success: (bookings) => emit(UserBookingsLoaded(bookings)),
      failure: (exception) => emit(BookingFailure(exception.message)),
    );
  }

  Future<void> cancelBooking(String bookingId, String userId) async {
    emit(BookingLoading());
    final result = await _bookingRepository.cancelBooking(bookingId);

    result.when(
      success: (_) {
        getUserBookings(userId);
      },
      failure: (exception) => emit(BookingFailure(exception.message)),
    );
  }
}

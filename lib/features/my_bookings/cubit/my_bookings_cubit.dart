import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';
import 'package:appointment_booking/features/my_bookings/cubit/my_bookings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingRepository _bookingRepository;

  MyBookingsCubit(this._bookingRepository) : super(const MyBookingsInitial());

  Future<void> loadBookings(String userId) async {
    emit(const MyBookingsLoading());
    final result = await _bookingRepository.getUserBookings(userId);

    switch (result) {
      case Success<List<Booking>>(:final data):
        final now = DateTime.now();

        // Upcoming: confirmed AND start is in the future.
        final upcoming =
            data
                .where(
                  (b) =>
                      b.status == 'confirmed' &&
                      b.appointmentStart.isAfter(now),
                )
                .toList()
              ..sort(
                (a, b) => a.appointmentStart.compareTo(b.appointmentStart),
              ); // soonest first

        // Past: start is in the past OR status is not confirmed.
        final past =
            data
                .where(
                  (b) =>
                      b.appointmentStart.isBefore(now) ||
                      b.status != 'confirmed',
                )
                .toList()
              ..sort(
                (a, b) => b.appointmentStart.compareTo(a.appointmentStart),
              ); // most recent first

        emit(MyBookingsSuccess(upcomingBookings: upcoming, pastBookings: past));

      case Failure<List<Booking>>(:final exception):
        emit(MyBookingsFailure(exception.message));
    }
  }

  Future<void> cancelBooking(String bookingId, String userId) async {
    emit(const MyBookingsLoading());
    final result = await _bookingRepository.cancelBooking(bookingId);

    switch (result) {
      case Success<void>():
        await loadBookings(userId);
      case Failure<void>(:final exception):
        emit(MyBookingsFailure(exception.message));
    }
  }
}

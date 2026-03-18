import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';
import 'package:appointment_booking/features/my_bookings/presentation/cubit/my_bookings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingRepository _bookingRepository;

  MyBookingsCubit(this._bookingRepository) : super(const MyBookingsInitial());

  Future<void> loadBookings(String userId) async {
    emit(const MyBookingsLoading());
    final result = await _bookingRepository.getUserBookings(userId);

    switch (result) {
      case Success<List<Booking>>(:final data):
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Upcoming: confirmed AND date is today or in the future
        final upcoming =
            data
                .where(
                  (b) =>
                      b.status == 'confirmed' && b.date.compareTo(today) >= 0,
                )
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date)); // soonest first

        // Past: date is in the past OR status is not confirmed (cancelled/completed)
        final past =
            data
                .where(
                  (b) => b.date.compareTo(today) < 0 || b.status != 'confirmed',
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)); // most recent first

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

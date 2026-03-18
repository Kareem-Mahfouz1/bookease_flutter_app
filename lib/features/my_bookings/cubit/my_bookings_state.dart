import 'package:appointment_booking/core/models/booking.dart';

sealed class MyBookingsState {
  const MyBookingsState();
}

class MyBookingsInitial extends MyBookingsState {
  const MyBookingsInitial();
}

class MyBookingsLoading extends MyBookingsState {
  const MyBookingsLoading();
}

class MyBookingsSuccess extends MyBookingsState {
  final List<Booking> upcomingBookings;
  final List<Booking> pastBookings;

  const MyBookingsSuccess({
    required this.upcomingBookings,
    required this.pastBookings,
  });
}

class MyBookingsFailure extends MyBookingsState {
  final String message;

  const MyBookingsFailure(this.message);
}

import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/data/models/clinic_schedule.dart';

sealed class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingScheduleLoaded extends BookingState {
  final List<ClinicSchedule> schedules;
  BookingScheduleLoaded(this.schedules);
}

class BookingSlotsLoaded extends BookingState {
  final List<DateTime> availableSlots;
  final DateTime selectedDate;
  BookingSlotsLoaded(this.availableSlots, this.selectedDate);
}

class BookingSuccess extends BookingState {
  final Booking booking;
  BookingSuccess(this.booking);
}

class BookingFailure extends BookingState {
  final String message;
  BookingFailure(this.message);
}

class UserBookingsLoaded extends BookingState {
  final List<Booking> bookings;
  UserBookingsLoaded(this.bookings);
}

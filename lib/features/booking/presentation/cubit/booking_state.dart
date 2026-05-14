import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/data/models/clinic_schedule.dart';

sealed class BookingState {}

class BookingMethodChanged extends BookingState {}

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

class BookingPaymentReady extends BookingState {
  final String paymentToken;
  final String bookingId;
  BookingPaymentReady(this.paymentToken, this.bookingId);
}

class BookingKioskReady extends BookingState {
  final String referenceNumber;
  final String bookingId;
  BookingKioskReady(this.referenceNumber, this.bookingId);
}

class BookingWalletReady extends BookingState {
  final String redirectUrl;
  final String bookingId;
  BookingWalletReady(this.redirectUrl, this.bookingId);
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

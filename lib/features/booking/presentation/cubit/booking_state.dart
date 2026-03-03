import 'package:appointment_booking/data/models/booking_model.dart';
import 'package:appointment_booking/data/models/time_slot_model.dart';

abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoadingSlots extends BookingState {
  const BookingLoadingSlots();
}

class BookingLoadedSlots extends BookingState {
  final List<TimeSlotModel> timeSlots;
  const BookingLoadedSlots(this.timeSlots);
}

class BookingErrorFetchingSlots extends BookingState {
  final String message;
  const BookingErrorFetchingSlots(this.message);
}

class BookingSubmitting extends BookingState {
  const BookingSubmitting();
}

class BookingSuccess extends BookingState {
  final BookingModel booking;
  const BookingSuccess(this.booking);
}

class BookingErrorSubmitting extends BookingState {
  final String message;
  const BookingErrorSubmitting(this.message);
}

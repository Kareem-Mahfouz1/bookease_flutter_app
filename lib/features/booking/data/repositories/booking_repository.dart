import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/booking/data/models/booking_model.dart';
import 'package:appointment_booking/features/booking/data/models/time_slot_model.dart';
import 'package:uuid/uuid.dart';

/// Repository for handling booking business logic
///
/// Handles fetching available time slots and submitting a final booking.
/// Currently uses mock delays and data.
class BookingRepository {
  BookingRepository();

  /// Fetches available time slots for a given date and service
  Future<Result<List<TimeSlotModel>>> getAvailableTimeSlots({
    required DateTime date,
    required String serviceId,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate some mock time slots between 9 AM and 5 PM
      final List<TimeSlotModel> slots = [];
      final startHour = 9;
      final endHour = 17;

      for (int hour = startHour; hour < endHour; hour++) {
        final startTime = DateTime(date.year, date.month, date.day, hour, 0);
        final endTime = startTime.add(const Duration(hours: 1));

        // Randomly make some slots unavailable for realistic UI testing
        final isAvailable = (hour % 3 != 0);

        slots.add(
          TimeSlotModel(
            startTime: startTime,
            endTime: endTime,
            isAvailable: isAvailable,
          ),
        );
      }

      return Success(slots);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  /// Submits a new booking to the backend
  Future<Result<BookingModel>> submitBooking({
    required String serviceId,
    required String serviceName,
    required TimeSlotModel timeSlot,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? notes,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate a network failure very occasionally for testing error states (e.g 10% chance)
      // if (DateTime.now().second % 10 == 0) {
      //   return const Failure(ServerException('Failed to process booking on the server.'));
      // }

      // Create a mocked confirmed booking
      final booking = BookingModel(
        id: const Uuid().v4(),
        serviceId: serviceId,
        serviceName: serviceName,
        timeSlot: timeSlot,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        notes: notes,
        createdAt: DateTime.now(),
      );

      return Success(booking);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }
}

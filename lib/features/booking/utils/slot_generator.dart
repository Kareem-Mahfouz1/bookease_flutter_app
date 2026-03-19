import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/data/models/clinic_schedule.dart';

class SlotGenerator {
  static List<DateTime> generateAvailableSlots({
    required ClinicSchedule schedule,
    required List<Booking> existingBookings,
    required int durationMinutes,
    required DateTime selectedDate,
  }) {
    if (!schedule.isWorkingDay) {
      return [];
    }

    final scheduleStart = _timeStringToMinutes(schedule.startTime);
    final scheduleEnd = _timeStringToMinutes(schedule.endTime);

    final availableSlots = <DateTime>[];

    final now = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday =
        selectedDay.year == now.year &&
        selectedDay.month == now.month &&
        selectedDay.day == now.day;

    for (
      int slotStart = scheduleStart;
      slotStart <= scheduleEnd - durationMinutes;
      slotStart += durationMinutes
    ) {
      final slotStartDateTime = selectedDay.add(Duration(minutes: slotStart));
      if (isToday && slotStartDateTime.isBefore(now)) continue;

      final slotEnd = slotStart + durationMinutes;
      final slotEndDateTime = selectedDay.add(Duration(minutes: slotEnd));
      bool hasOverlap = false;

      for (final booking in existingBookings) {
        if (booking.status != 'confirmed') continue;

        if (slotStartDateTime.isBefore(booking.appointmentEnd) &&
            slotEndDateTime.isAfter(booking.appointmentStart)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        availableSlots.add(slotStartDateTime);
      }
    }

    return availableSlots;
  }

  static int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }
}

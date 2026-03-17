import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/domain/clinic_schedule.dart';

class SlotGenerator {
  static List<String> generateAvailableSlots({
    required ClinicSchedule schedule,
    required List<Booking> existingBookings,
    required int durationMinutes,
    DateTime? selectedDate,
  }) {
    if (!schedule.isWorkingDay) {
      return [];
    }

    final scheduleStart = _timeStringToMinutes(schedule.startTime);
    final scheduleEnd = _timeStringToMinutes(schedule.endTime);

    final availableSlots = <String>[];

    final now = DateTime.now();
    final isToday =
        selectedDate != null &&
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final currentMinutes = isToday ? now.hour * 60 + now.minute : 0;

    for (
      int slotStart = scheduleStart;
      slotStart <= scheduleEnd - durationMinutes;
      slotStart += durationMinutes
    ) {
      if (isToday && slotStart <= currentMinutes) continue;

      final slotEnd = slotStart + durationMinutes;
      bool hasOverlap = false;

      for (final booking in existingBookings) {
        if (booking.status != 'confirmed') continue;

        if (slotStart < booking.endMinutes && slotEnd > booking.startMinutes) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        availableSlots.add(_minutesToTimeString(slotStart));
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

  static String _minutesToTimeString(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

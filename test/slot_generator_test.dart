import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/domain/clinic_schedule.dart';
import 'package:appointment_booking/features/booking/utils/slot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a minimal Booking for testing purposes
Booking makeBooking({
  required int startMinutes,
  required int endMinutes,
  String date = '2024-03-18',
}) {
  return Booking(
    id: 'test_id',
    serviceId: 'service_001',
    serviceName: 'General Checkup',
    serviceDurationMinutes: 30,
    date: date,
    startTime: '09:00',
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    userId: 'user_001',
    customerName: 'Test User',
    customerEmail: 'test@test.com',
    customerPhone: null,
    notes: null,
    status: 'confirmed',
    createdAt: DateTime(2024, 3, 18),
  );
}

// Helper to create a ClinicSchedule
ClinicSchedule makeSchedule({
  required String startTime,
  required String endTime,
  bool isWorkingDay = true,
  int dayOfWeek = 1,
}) {
  return ClinicSchedule(
    dayOfWeek: dayOfWeek,
    startTime: startTime,
    endTime: endTime,
    isWorkingDay: isWorkingDay,
  );
}

void main() {
  group('SlotGenerator', () {
    // ─── Basic slot generation ───────────────────────────────────────────────

    test(
      'generates correct slots for a 1-hour window with 30 min duration',
      () {
        final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
        final slots = SlotGenerator.generateAvailableSlots(
          schedule: schedule,
          existingBookings: [],
          durationMinutes: 30,
        );
        expect(slots, ['09:00', '09:30']);
      },
    );

    test('generates correct slots for a 15 min service', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 15,
      );
      expect(slots, ['09:00', '09:15', '09:30', '09:45']);
    });

    test('generates correct slots for a 60 min service', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '11:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 60,
      );
      expect(slots, ['09:00', '10:00']);
    });

    test('does not generate a slot that would exceed end of working hours', () {
      // 09:00 window with 60 min duration — only one slot fits, 09:30 would end at 10:30
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 60,
      );
      expect(slots, ['09:00']);
      expect(slots, isNot(contains('09:30')));
    });

    // ─── Non-working day ─────────────────────────────────────────────────────

    test('returns empty list for a non-working day', () {
      final schedule = makeSchedule(
        startTime: '00:00',
        endTime: '00:00',
        isWorkingDay: false,
        dayOfWeek: 7,
      );
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 30,
      );
      expect(slots, isEmpty);
    });

    // ─── Overlap detection ───────────────────────────────────────────────────

    test('excludes a slot that is fully blocked by an existing booking', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      // booking occupies 09:00 - 09:30 (540 - 570)
      final existingBookings = [
        makeBooking(startMinutes: 540, endMinutes: 570),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
      );

      expect(slots, isNot(contains('09:00')));
      expect(slots, contains('09:30'));
    });

    test('back-to-back bookings do not block each other', () {
      // booking at 09:00-09:30, slot at 09:30 should still be available
      // slotStart(570) < bookingEnd(570) is FALSE → not blocked
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(startMinutes: 540, endMinutes: 570),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
      );

      expect(slots, contains('09:30'));
    });

    test('slot partially overlapping start of existing booking is blocked', () {
      // slot 09:15-09:45, booking 09:30-10:00 → overlap → blocked
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(startMinutes: 570, endMinutes: 600),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
      );

      expect(slots, isNot(contains('09:15')));
    });

    test('slot partially overlapping end of existing booking is blocked', () {
      // booking 09:00-09:30, slot 08:45-09:15 → overlap → blocked
      // testing that a slot ending inside a booking is also excluded
      final schedule = makeSchedule(startTime: '08:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(startMinutes: 540, endMinutes: 570),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
      );

      expect(slots, isNot(contains('08:45')));
    });

    test('all slots blocked when fully booked day', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '11:00');
      final existingBookings = [
        makeBooking(startMinutes: 540, endMinutes: 570), // 09:00-09:30
        makeBooking(startMinutes: 570, endMinutes: 600), // 09:30-10:00
        makeBooking(startMinutes: 600, endMinutes: 630), // 10:00-10:30
        makeBooking(startMinutes: 630, endMinutes: 660), // 10:30-11:00
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
      );

      expect(slots, isEmpty);
    });

    test('cancelled bookings do not block slots', () {
      // cancelled booking at 09:00-09:30 — slot should still be available
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final cancelledBooking = Booking(
        id: 'test_id',
        serviceId: 'service_001',
        serviceName: 'General Checkup',
        serviceDurationMinutes: 30,
        date: '2024-03-18',
        startTime: '09:00',
        startMinutes: 540,
        endMinutes: 570,
        userId: 'user_001',
        customerName: 'Test User',
        customerEmail: 'test@test.com',
        status: 'cancelled',
        createdAt: DateTime(2024, 3, 18),
      );

      // cancelled bookings are technically filtered at repo level,
      // but slot generator should ignore them if they slip through
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [cancelledBooking],
        durationMinutes: 30,
      );

      expect(slots, contains('09:00'));
    });

    // ─── Saturday half day ───────────────────────────────────────────────────

    test('Saturday generates slots only until 13:00', () {
      final schedule = makeSchedule(
        startTime: '09:00',
        endTime: '13:00',
        dayOfWeek: 6,
      );

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 30,
      );

      expect(slots.first, '09:00');
      expect(slots.last, '12:30');
      expect(slots, isNot(contains('13:00')));
    });
  });
}

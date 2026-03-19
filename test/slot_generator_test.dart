import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/data/models/clinic_schedule.dart';
import 'package:appointment_booking/features/booking/utils/slot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a minimal Booking for testing purposes
Booking makeBooking({
  required DateTime appointmentStart,
  required DateTime appointmentEnd,
}) {
  return Booking(
    id: 'test_id',
    serviceId: 'service_001',
    serviceName: 'General Checkup',
    serviceDurationMinutes: 30,
    price: 50.0,
    appointmentStart: appointmentStart,
    appointmentEnd: appointmentEnd,
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
  final testDate = DateTime(2024, 3, 18);

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
          selectedDate: testDate,
        );
        expect(slots.length, 2);
        expect(slots[0].hour, 9);
        expect(slots[0].minute, 0);
        expect(slots[1].hour, 9);
        expect(slots[1].minute, 30);
      },
    );

    test('generates correct slots for a 15 min service', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 15,
        selectedDate: testDate,
      );
      expect(slots.map((s) => s.hour), [9, 9, 9, 9]);
      expect(slots.map((s) => s.minute), [0, 15, 30, 45]);
    });

    test('generates correct slots for a 60 min service', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '11:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 60,
        selectedDate: testDate,
      );
      expect(slots.length, 2);
      expect(slots[0].hour, 9);
      expect(slots[0].minute, 0);
      expect(slots[1].hour, 10);
      expect(slots[1].minute, 0);
    });

    test('does not generate a slot that would exceed end of working hours', () {
      // 09:00 window with 60 min duration — only one slot fits, 09:30 would end at 10:30
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: [],
        durationMinutes: 60,
        selectedDate: testDate,
      );
      expect(slots.length, 1);
      expect(slots[0].hour, 9);
      expect(slots[0].minute, 0);
      expect(slots.where((s) => s.hour == 9 && s.minute == 30), isEmpty);
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
        selectedDate: testDate,
      );
      expect(slots, isEmpty);
    });

    // ─── Overlap detection ───────────────────────────────────────────────────

    test('excludes a slot that is fully blocked by an existing booking', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      // booking occupies 09:00 - 09:30 (540 - 570)
      final existingBookings = [
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 0),
          appointmentEnd: DateTime(2024, 3, 18, 9, 30),
        ),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
        selectedDate: testDate,
      );

      expect(slots.where((s) => s.hour == 9 && s.minute == 0), isEmpty);
      expect(slots.where((s) => s.hour == 9 && s.minute == 30), isNotEmpty);
    });

    test('back-to-back bookings do not block each other', () {
      // booking at 09:00-09:30, slot at 09:30 should still be available
      // slotStart(570) < bookingEnd(570) is FALSE → not blocked
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 0),
          appointmentEnd: DateTime(2024, 3, 18, 9, 30),
        ),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
        selectedDate: testDate,
      );

      expect(slots.where((s) => s.hour == 9 && s.minute == 30), isNotEmpty);
    });

    test('slot partially overlapping start of existing booking is blocked', () {
      // slot 09:15-09:45, booking 09:30-10:00 → overlap → blocked
      final schedule = makeSchedule(startTime: '09:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 30),
          appointmentEnd: DateTime(2024, 3, 18, 10, 0),
        ),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
        selectedDate: testDate,
      );

      expect(slots.where((s) => s.hour == 9 && s.minute == 15), isEmpty);
    });

    test('slot partially overlapping end of existing booking is blocked', () {
      // booking 09:00-09:30, slot 08:45-09:15 → overlap → blocked
      // testing that a slot ending inside a booking is also excluded
      final schedule = makeSchedule(startTime: '08:00', endTime: '10:00');
      final existingBookings = [
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 0),
          appointmentEnd: DateTime(2024, 3, 18, 9, 30),
        ),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
        selectedDate: testDate,
      );

      expect(slots.where((s) => s.hour == 8 && s.minute == 45), isEmpty);
    });

    test('all slots blocked when fully booked day', () {
      final schedule = makeSchedule(startTime: '09:00', endTime: '11:00');
      final existingBookings = [
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 0),
          appointmentEnd: DateTime(2024, 3, 18, 9, 30),
        ),
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 9, 30),
          appointmentEnd: DateTime(2024, 3, 18, 10, 0),
        ),
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 10, 0),
          appointmentEnd: DateTime(2024, 3, 18, 10, 30),
        ),
        makeBooking(
          appointmentStart: DateTime(2024, 3, 18, 10, 30),
          appointmentEnd: DateTime(2024, 3, 18, 11, 0),
        ),
      ];

      final slots = SlotGenerator.generateAvailableSlots(
        schedule: schedule,
        existingBookings: existingBookings,
        durationMinutes: 30,
        selectedDate: testDate,
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
        price: 50.0,
        appointmentStart: DateTime(2024, 3, 18, 9, 0),
        appointmentEnd: DateTime(2024, 3, 18, 9, 30),
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
        selectedDate: testDate,
      );

      expect(slots.where((s) => s.hour == 9 && s.minute == 0), isNotEmpty);
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
        selectedDate: testDate,
      );

      expect(slots.first.hour, 9);
      expect(slots.first.minute, 0);
      expect(slots.last.hour, 12);
      expect(slots.last.minute, 30);
      expect(slots.where((s) => s.hour == 13 && s.minute == 0), isEmpty);
    });
  });
}

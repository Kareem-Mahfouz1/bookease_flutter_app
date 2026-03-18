import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/booking/domain/booking_details.dart';
import 'package:appointment_booking/features/booking/domain/clinic_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Result<ClinicSchedule>> getClinicSchedule(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('clinic_schedule')
          .doc(date.weekday.toString())
          .get();
      if (!doc.exists) {
        return const Failure(
          ServerException('Clinic schedule not found for this day.'),
        );
      }
      return Success(ClinicSchedule.fromFirestore(doc));
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<List<ClinicSchedule>>> getAllClinicSchedules() async {
    try {
      final snapshot = await _firestore.collection('clinic_schedule').get();
      final schedules = snapshot.docs
          .map((doc) => ClinicSchedule.fromFirestore(doc))
          .toList();
      return Success(schedules);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<List<Booking>>> getBookingsForDate(String date) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'confirmed')
          .get();
      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
      return Success(bookings);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<Booking>> createBooking(BookingDetails details) async {
    try {
      final docRef = _firestore.collection('daily_slots').doc(details.date);
      final bookingRef = _firestore.collection('bookings').doc();

      final newStart = _timeStringToMinutes(details.startTime);
      final newEnd = newStart + details.serviceDurationMinutes;

      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);

        final intervals = snapshot.exists
            ? List<Map<String, dynamic>>.from(
                snapshot.data()?['bookedIntervals'] ?? [],
              )
            : <Map<String, dynamic>>[];

        final hasOverlap = intervals.any((i) {
          final iStart = i['startMinutes'] as int;
          final iEnd = i['endMinutes'] as int;
          return newStart < iEnd && newEnd > iStart;
        });

        if (hasOverlap) {
          throw const ServerException('Slot no longer available');
        }

        intervals.add({'startMinutes': newStart, 'endMinutes': newEnd});

        tx.set(docRef, {'bookedIntervals': intervals}, SetOptions(merge: true));

        final bookingData = Booking(
          id: bookingRef.id,
          serviceId: details.serviceId,
          serviceName: details.serviceName,
          serviceDurationMinutes: details.serviceDurationMinutes,
          price: details.price,
          date: details.date,
          startTime: details.startTime,
          startMinutes: newStart,
          endMinutes: newEnd,
          userId: details.userId,
          customerName: details.customerName,
          customerEmail: details.customerEmail,
          customerPhone: details.customerPhone,
          notes: details.notes,
          status: 'confirmed',
          createdAt: DateTime.now(),
        ).toMap();

        tx.set(bookingRef, bookingData);
      });

      final createdDoc = await bookingRef.get();
      return Success(Booking.fromFirestore(createdDoc));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<void>> cancelBooking(String bookingId) async {
    try {
      final bookingRef = _firestore.collection('bookings').doc(bookingId);

      await _firestore.runTransaction((tx) async {
        final bookingSnapshot = await tx.get(bookingRef);
        if (!bookingSnapshot.exists) {
          throw const ServerException('Booking not found');
        }

        final booking = Booking.fromFirestore(bookingSnapshot);
        if (booking.status == 'cancelled' || booking.status == 'completed') {
          throw ServerException('Booking is already ${booking.status}');
        }

        final now = DateTime.now();
        final bookingDate = DateTime.parse(booking.date);
        final today = DateTime(now.year, now.month, now.day);

        if (bookingDate.isBefore(today)) {
          throw const ServerException('Cannot cancel a past booking');
        }

        final slotsDocRef = _firestore
            .collection('daily_slots')
            .doc(booking.date);
        final slotsSnapshot = await tx.get(slotsDocRef);

        if (slotsSnapshot.exists) {
          final intervals = List<Map<String, dynamic>>.from(
            slotsSnapshot.data()?['bookedIntervals'] ?? [],
          );

          intervals.removeWhere(
            (i) =>
                i['startMinutes'] == booking.startMinutes &&
                i['endMinutes'] == booking.endMinutes,
          );

          tx.set(slotsDocRef, {
            'bookedIntervals': intervals,
          }, SetOptions(merge: true));
        }

        tx.update(bookingRef, {'status': 'cancelled'});
      });

      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<List<Booking>>> getUserBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
      return Success(bookings);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  int _timeStringToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }
}

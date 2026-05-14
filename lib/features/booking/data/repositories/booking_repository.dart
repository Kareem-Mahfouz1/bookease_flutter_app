import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/core/models/result.dart';
import 'package:appointment_booking/features/booking/data/models/booking_details.dart';
import 'package:appointment_booking/features/booking/data/models/clinic_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:intl/intl.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

  Future<Result<List<Booking>>> getBookingsForDate(DateTime date) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('bookings')
          .where(
            'appointmentStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
          )
          .where('appointmentStart', isLessThan: Timestamp.fromDate(dayEnd))
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
      final slotsDateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(details.appointmentStart);
      final docRef = _firestore.collection('daily_slots').doc(slotsDateKey);
      final bookingRef = _firestore.collection('bookings').doc();

      final newStart =
          details.appointmentStart.hour * 60 + details.appointmentStart.minute;
      final newEnd =
          details.appointmentEnd.hour * 60 + details.appointmentEnd.minute;

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
          appointmentStart: details.appointmentStart,
          appointmentEnd: details.appointmentEnd,
          userId: details.userId,
          customerName: details.customerName,
          customerEmail: details.customerEmail,
          customerPhone: details.customerPhone,
          notes: details.notes,
          status: 'confirmed',
          paymentStatus: 'pending',
          paymentMethod: 'online',
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
        final today = DateTime(now.year, now.month, now.day);
        final bookingDate = DateTime(
          booking.appointmentStart.year,
          booking.appointmentStart.month,
          booking.appointmentStart.day,
        );

        if (bookingDate.isBefore(today)) {
          throw const ServerException('Cannot cancel a past booking');
        }

        final bookingStartMinutes =
            booking.appointmentStart.hour * 60 +
            booking.appointmentStart.minute;
        final bookingEndMinutes =
            booking.appointmentEnd.hour * 60 + booking.appointmentEnd.minute;
        final slotsDateKey = DateFormat(
          'yyyy-MM-dd',
        ).format(booking.appointmentStart);

        final slotsDocRef = _firestore
            .collection('daily_slots')
            .doc(slotsDateKey);
        final slotsSnapshot = await tx.get(slotsDocRef);

        if (slotsSnapshot.exists) {
          final intervals = List<Map<String, dynamic>>.from(
            slotsSnapshot.data()?['bookedIntervals'] ?? [],
          );

          intervals.removeWhere(
            (i) =>
                i['startMinutes'] == bookingStartMinutes &&
                i['endMinutes'] == bookingEndMinutes,
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
          .orderBy('appointmentStart', descending: true)
          .get();
      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
      return Success(bookings);
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<
    Result<
      ({
        String paymentToken,
        String bookingId,
        String? kioskReferenceNumber,
        String? walletRedirectUrl,
      })
    >
  >
  initiateOnlinePayment(
    BookingDetails details, {
    required String onlinePaymentMethod,
    String? walletPhoneNumber,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymobOrder');
      final response = await callable.call<Map<String, dynamic>>({
        'serviceId': details.serviceId,
        'serviceName': details.serviceName,
        'serviceDurationMinutes': details.serviceDurationMinutes,
        'price': details.price,
        'appointmentStart': details.appointmentStart.toUtc().toIso8601String(),
        'appointmentEnd': details.appointmentEnd.toUtc().toIso8601String(),
        'customerName': details.customerName,
        'customerEmail': details.customerEmail,
        'customerPhone': details.customerPhone,
        'walletPhoneNumber': walletPhoneNumber,
        'notes': details.notes,
        'paymentMethod': 'online',
        'onlinePaymentMethod': onlinePaymentMethod,
      });

      final data = response.data;
      return Success((
        paymentToken: data['payment_token'] as String,
        bookingId: data['bookingId'] as String,
        kioskReferenceNumber: data['kioskReferenceNumber'] as String?,
        walletRedirectUrl: data['walletRedirectUrl'] as String?,
      ));
    } on FirebaseFunctionsException catch (e) {
      return Failure(
        ServerException(e.message ?? 'Payment initiation failed.'),
      );
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<Booking>> createCashBooking(BookingDetails details) async {
    try {
      final callable = _functions.httpsCallable('createCashBooking');
      final response = await callable.call<Map<String, dynamic>>({
        'serviceId': details.serviceId,
        'serviceName': details.serviceName,
        'serviceDurationMinutes': details.serviceDurationMinutes,
        'price': details.price,
        'appointmentStart': details.appointmentStart.toUtc().toIso8601String(),
        'appointmentEnd': details.appointmentEnd.toUtc().toIso8601String(),
        'customerName': details.customerName,
        'customerEmail': details.customerEmail,
        'customerPhone': details.customerPhone,
        'notes': details.notes,
        'paymentMethod': 'cash',
      });

      final bookingId = response.data['bookingId'] as String;
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return Success(Booking.fromFirestore(doc));
    } on FirebaseFunctionsException catch (e) {
      return Failure(ServerException(e.message ?? 'Cash booking failed.'));
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Future<Result<void>> cancelPendingPaymobBooking(String bookingId) async {
    try {
      final callable = _functions.httpsCallable('cancelPendingPaymobBooking');
      await callable.call<Map<String, dynamic>>({'bookingId': bookingId});
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Failure(
        ServerException(e.message ?? 'Payment cancellation failed.'),
      );
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }

  Stream<Booking> streamBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((doc) => Booking.fromFirestore(doc));
  }
}

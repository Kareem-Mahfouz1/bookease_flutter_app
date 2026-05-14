import 'dart:async';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';

enum PaymentStatus { processing, success }

class PaymentRepository {
  final BookingRepository _bookingRepository;

  PaymentRepository(this._bookingRepository);

  /// Streams the payment status, yielding [PaymentStatus.success] on completion,
  /// or throwing a [PaymentException] on failure cases.
  Stream<PaymentStatus> streamPaymentStatus(String bookingId) async* {
    await for (final booking in _bookingRepository.streamBooking(bookingId)) {
      if (booking.paymentStatus == 'paid') {
        yield PaymentStatus.success;
      } else if (booking.paymentStatus != 'pending') {
        throw PaymentException.fromStatus(booking.paymentStatus);
      }
    }
  }

  Future<void> cancelPayment(String bookingId) async {
    final result = await _bookingRepository.cancelPendingPaymobBooking(
      bookingId,
    );

    result.when(
      success: (_) {},
      failure: (exception) => throw PaymentException(exception.message),
    );
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';
import 'package:appointment_booking/features/payment/data/repositories/payment_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _paymentRepository;
  StreamSubscription? _paymentSubscription;

  PaymentCubit(this._paymentRepository) : super(PaymentInitial());

  void startListening(String bookingId) {
    emit(PaymentProcessing());
    _paymentSubscription?.cancel();
    _paymentSubscription = _paymentRepository
        .streamPaymentStatus(bookingId)
        .listen(
          (status) {
            if (status == PaymentStatus.success) {
              emit(PaymentSuccess());
              _paymentSubscription?.cancel();
            }
          },
          onError: (error) {
            String errorMessage;
            if (error is PaymentException) {
              errorMessage = error.message;
            } else if (error is AppException) {
              errorMessage = error.message;
            } else {
              errorMessage = error.toString();
            }
            emit(PaymentFailed(errorMessage));
          },
        );
  }

  Future<bool> cancelPendingPayment(String bookingId) async {
    try {
      await _paymentRepository.cancelPayment(bookingId);
      return true;
    } catch (e) {
      String errorMessage = e is AppException ? e.message : e.toString();
      emit(PaymentFailed(errorMessage));
      return false;
    }
  }

  @override
  Future<void> close() {
    _paymentSubscription?.cancel();
    return super.close();
  }
}

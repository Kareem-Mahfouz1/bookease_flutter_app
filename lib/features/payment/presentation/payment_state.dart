sealed class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentProcessing extends PaymentState {}

class PaymentSuccess extends PaymentState {}

class PaymentFailed extends PaymentState {
  final String message;

  PaymentFailed(this.message);
}

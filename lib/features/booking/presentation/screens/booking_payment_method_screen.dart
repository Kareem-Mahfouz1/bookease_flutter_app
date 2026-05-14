import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/core/widgets/app_text_form_field.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:appointment_booking/features/booking/presentation/widgets/payment_method_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingPaymentMethodScreen extends StatefulWidget {
  const BookingPaymentMethodScreen({super.key});

  @override
  State<BookingPaymentMethodScreen> createState() =>
      _BookingPaymentMethodScreenState();
}

class _BookingPaymentMethodScreenState
    extends State<BookingPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _walletPhoneController = TextEditingController();

  @override
  void dispose() {
    _walletPhoneController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    final cubit = context.read<BookingCubit>();
    if (cubit.selectedOnlinePaymentMethod == 'wallet' &&
        !_formKey.currentState!.validate()) {
      return;
    }

    final walletPhone = _walletPhoneController.text.trim();
    cubit.initiatePendingBooking(
      walletPhoneNumber: walletPhone.isEmpty ? null : walletPhone,
    );
  }

  String? _validateWalletPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Wallet phone number is required';
    if (!RegExp(r'^01\d{9}$').hasMatch(phone)) {
      return 'Use Egyptian wallet format 01XXXXXXXXX';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = context.read<BookingCubit>().pendingBookingDetails;

    if (details == null) {
      return const Scaffold(
        body: Center(child: Text('Missing booking details')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            context.go(Routes.bookingSuccess);
          } else if (state is BookingPaymentReady) {
            context.push(
              Routes.payment,
              extra: {
                'paymentToken': state.paymentToken,
                'bookingId': state.bookingId,
              },
            );
          } else if (state is BookingKioskReady) {
            context.push(
              Routes.kiosk,
              extra: {
                'referenceNumber': state.referenceNumber,
                'bookingId': state.bookingId,
              },
            );
          } else if (state is BookingWalletReady) {
            context.push(
              Routes.wallet,
              extra: {
                'redirectUrl': state.redirectUrl,
                'bookingId': state.bookingId,
              },
            );
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is BookingLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 120.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PaymentSummaryCard(
                        serviceName: details.serviceName,
                        appointmentStart: details.appointmentStart,
                        appointmentEnd: details.appointmentEnd,
                        price: details.price,
                      ),
                      SizedBox(height: 24.h),
                      const PaymentMethodSelector(),
                      const _WalletPhoneFieldGap(),
                      _WalletPhoneField(
                        controller: _walletPhoneController,
                        validator: _validateWalletPhone,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                final isLoading = state is BookingLoading;
                final selectedMethod = context.select<BookingCubit, String>(
                  (cubit) => cubit.selectedPaymentMethod,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 8,
                      ),
                      child: Text(
                        selectedMethod == 'cash'
                            ? 'Confirm Booking'
                            : 'Continue to Pay',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final String serviceName;
  final DateTime appointmentStart;
  final DateTime appointmentEnd;
  final double price;

  const _PaymentSummaryCard({
    required this.serviceName,
    required this.appointmentStart,
    required this.appointmentEnd,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('EEE, d MMM yyyy').format(appointmentStart);
    final time =
        '${DateFormat('h:mm a').format(appointmentStart)} - ${DateFormat('h:mm a').format(appointmentEnd)}';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Total',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24),
          _SummaryRow(label: 'Service', value: serviceName),
          SizedBox(height: 8.h),
          _SummaryRow(label: 'Date', value: date),
          SizedBox(height: 8.h),
          _SummaryRow(label: 'Time', value: time),
          SizedBox(height: 8.h),
          _SummaryRow(
            label: 'Total',
            value: '\$${price.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _WalletPhoneFieldGap extends StatelessWidget {
  const _WalletPhoneFieldGap();

  @override
  Widget build(BuildContext context) {
    final isWallet = context.select<BookingCubit, bool>(
      (cubit) =>
          cubit.selectedPaymentMethod == 'online' &&
          cubit.selectedOnlinePaymentMethod == 'wallet',
    );

    return isWallet ? SizedBox(height: 16.h) : const SizedBox.shrink();
  }
}

class _WalletPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;

  const _WalletPhoneField({required this.controller, required this.validator});

  @override
  Widget build(BuildContext context) {
    final isWallet = context.select<BookingCubit, bool>(
      (cubit) =>
          cubit.selectedPaymentMethod == 'online' &&
          cubit.selectedOnlinePaymentMethod == 'wallet',
    );

    if (!isWallet) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AppTextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      hintText: 'Wallet Phone Number',
      prefixIcon: Icon(
        Icons.account_balance_wallet_outlined,
        color: theme.disabledColor,
      ),
      validator: validator,
      isFinal: true,
      textInputAction: TextInputAction.done,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTotal
                ? theme.textTheme.bodyLarge?.color
                : theme.disabledColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? theme.primaryColor
                : theme.textTheme.bodyLarge?.color,
            fontSize: isTotal ? 16 : null,
          ),
        ),
      ],
    );
  }
}

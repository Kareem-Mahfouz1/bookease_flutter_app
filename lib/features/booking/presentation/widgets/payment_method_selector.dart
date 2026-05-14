import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMethod = context.select<BookingCubit, String>(
      (cubit) => cubit.selectedPaymentMethod,
    );
    final selectedOnlineMethod = context.select<BookingCubit, String>(
      (cubit) => cubit.selectedOnlinePaymentMethod,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'online',
              icon: Icon(Icons.credit_card),
              label: Text('Pay Online'),
            ),
            ButtonSegment(
              value: 'cash',
              icon: Icon(Icons.money),
              label: Text('Pay at Clinic'),
            ),
          ],
          selected: {selectedMethod},
          onSelectionChanged: (Set<String> newSelection) {
            context.read<BookingCubit>().setPaymentMethod(newSelection.first);
          },
        ),
        if (selectedMethod == 'online') ...[
          const SizedBox(height: 16),
          Text(
            'Online Payment Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _OnlinePaymentMethodSelector(selectedMethod: selectedOnlineMethod),
        ],
      ],
    );
  }
}

class _OnlinePaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;

  const _OnlinePaymentMethodSelector({required this.selectedMethod});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'card',
          icon: Icon(Icons.credit_card),
          label: Text('Card'),
        ),
        ButtonSegment(
          value: 'wallet',
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: Text('Wallet'),
        ),
        ButtonSegment(
          value: 'kiosk',
          icon: Icon(Icons.storefront_outlined),
          label: Text('Kiosk'),
        ),
      ],
      selected: {selectedMethod},
      onSelectionChanged: (Set<String> newSelection) {
        context.read<BookingCubit>().setSelectedOnlinePaymentMethod(
          newSelection.first,
        );
      },
    );
  }
}

import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/payment/presentation/payment_cubit.dart';
import 'package:appointment_booking/features/payment/presentation/payment_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class KioskReferenceScreen extends StatefulWidget {
  final String referenceNumber;
  final String bookingId;

  const KioskReferenceScreen({
    super.key,
    required this.referenceNumber,
    required this.bookingId,
  });

  @override
  State<KioskReferenceScreen> createState() => _KioskReferenceScreenState();
}

class _KioskReferenceScreenState extends State<KioskReferenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCubit>().startListening(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          context.go(Routes.bookingSuccess);
        } else if (state is PaymentFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fawry Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReferenceCard(referenceNumber: widget.referenceNumber),
                const SizedBox(height: 24),
                const _InstructionsCard(),
                const Spacer(),
                const _WaitingForPayment(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  final String referenceNumber;

  const _ReferenceCard({required this.referenceNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'Reference Number',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            referenceNumber,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: referenceNumber));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference number copied')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Number'),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to pay',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _InstructionRow(
            icon: Icons.storefront_outlined,
            text: 'Visit any Fawry kiosk or supported Fawry outlet.',
          ),
          const SizedBox(height: 12),
          _InstructionRow(
            icon: Icons.confirmation_number_outlined,
            text: 'Use the reference number above to complete payment.',
          ),
          const SizedBox(height: 12),
          _InstructionRow(
            icon: Icons.verified_outlined,
            text: 'This screen will update automatically after confirmation.',
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _WaitingForPayment extends StatelessWidget {
  const _WaitingForPayment();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Waiting for payment confirmation',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

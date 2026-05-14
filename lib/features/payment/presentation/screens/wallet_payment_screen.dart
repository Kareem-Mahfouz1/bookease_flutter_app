import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/payment/presentation/payment_cubit.dart';
import 'package:appointment_booking/features/payment/presentation/payment_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletPaymentScreen extends StatefulWidget {
  final String redirectUrl;
  final String bookingId;

  const WalletPaymentScreen({
    super.key,
    required this.redirectUrl,
    required this.bookingId,
  });

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  bool _hasLaunchedWallet = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCubit>().startListening(widget.bookingId);
      _launchWalletPayment();
    });
  }

  Future<void> _launchWalletPayment() async {
    if (_hasLaunchedWallet) return;
    _hasLaunchedWallet = true;

    final uri = Uri.parse(widget.redirectUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open wallet payment page.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _cancelAndPop() async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
    });

    final cancelled = await context.read<PaymentCubit>().cancelPendingPayment(
      widget.bookingId,
    );
    if (!mounted) return;

    setState(() {
      _isCancelling = false;
    });

    if (cancelled) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancelAndPop();
        }
      },
      child: BlocListener<PaymentCubit, PaymentState>(
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
            title: const Text('Wallet Payment'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _isCancelling ? null : _cancelAndPop,
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _WalletStatusCard(),
                      const SizedBox(height: 24),
                      _WalletActionCard(onOpenPayment: _launchWalletPayment),
                      const Spacer(),
                      const _WaitingForWalletConfirmation(),
                    ],
                  ),
                ),
              ),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletStatusCard extends StatelessWidget {
  const _WalletStatusCard();

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
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Approve Wallet Payment',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Complete the payment on the Paymob wallet page that opened. Return here after approval.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.disabledColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WalletActionCard extends StatelessWidget {
  final VoidCallback onOpenPayment;

  const _WalletActionCard({required this.onOpenPayment});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Waiting for Paymob confirmation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If the wallet page did not open, use the button below to try again.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onOpenPayment,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Wallet Payment'),
          ),
        ],
      ),
    );
  }
}

class _WaitingForWalletConfirmation extends StatelessWidget {
  const _WaitingForWalletConfirmation();

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
          'Waiting for wallet confirmation',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

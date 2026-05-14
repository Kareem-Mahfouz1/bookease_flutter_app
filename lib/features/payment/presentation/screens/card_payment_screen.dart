import 'package:appointment_booking/features/payment/presentation/payment_cubit.dart';
import 'package:appointment_booking/features/payment/presentation/payment_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:appointment_booking/core/routing/route_names.dart';

class CardPaymentScreen extends StatefulWidget {
  final String paymentToken;
  final String bookingId;

  const CardPaymentScreen({
    super.key,
    required this.paymentToken,
    required this.bookingId,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCubit>().startListening(widget.bookingId);
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://accept.paymob.com/api/acceptance/iframes/917362?payment_token=${widget.paymentToken}',
        ),
      );
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
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    // Optionally reload or let user go back manually
                  },
                ),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Complete Payment'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _isCancelling ? null : _cancelAndPop,
            ),
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading || _isCancelling)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

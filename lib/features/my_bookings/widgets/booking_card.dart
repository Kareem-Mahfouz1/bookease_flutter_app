import 'package:appointment_booking/core/models/booking.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final String userId;
  final void Function(String bookingId, String userId) onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.userId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming =
        booking.status == 'confirmed' &&
        booking.appointmentStart.isAfter(DateTime.now());

    // Format date: "Mon, 17 Mar 2026"
    final dateLabel = DateFormat(
      'EEE, d MMM yyyy',
    ).format(booking.appointmentStart);
    final startLabel = DateFormat('h:mm a').format(booking.appointmentStart);
    final endLabel = DateFormat('h:mm a').format(booking.appointmentEnd);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.serviceDurationMinutes} min • \$${booking.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Date and time row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.disabledColor,
                ),
                const SizedBox(width: 6),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: theme.disabledColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$startLabel – $endLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Payment info row
            Row(
              children: [
                Icon(_getPaymentIcon(), size: 16, color: theme.disabledColor),
                const SizedBox(width: 6),
                Text(
                  _getPaymentLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const Spacer(),
                _PaymentStatusBadge(status: booking.paymentStatus),
              ],
            ),

            // Cancel button — only for upcoming confirmed bookings
            if (isUpcoming) ...[
              const SizedBox(height: 12),
              Skeleton.ignore(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final hasPaidOnline =
        booking.paymentMethod == 'online' && booking.paymentStatus == 'paid';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your "${booking.serviceName}" appointment?',
            ),
            if (hasPaidOnline) ...[
              const SizedBox(height: 16),
              Text(
                'Since you paid online, your refund will be processed within 5-7 business days.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onCancel(booking.id, userId);
    }
  }

  IconData _getPaymentIcon() {
    if (booking.paymentMethod == 'cash') return Icons.money;
    return switch (booking.onlinePaymentMethod) {
      'card' => Icons.credit_card,
      'wallet' => Icons.account_balance_wallet_outlined,
      'kiosk' => Icons.storefront_outlined,
      _ => Icons.payment,
    };
  }

  String _getPaymentLabel() {
    if (booking.paymentMethod == 'cash') return 'Cash at Clinic';
    return switch (booking.onlinePaymentMethod) {
      'card' => 'Credit/Debit Card',
      'wallet' => 'Mobile Wallet',
      'kiosk' => 'Kiosk Payment',
      _ => 'Online Payment',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (Colors.green, 'Confirmed'),
      'completed' => (Colors.blueGrey, 'Completed'),
      'cancelled' => (Colors.red, 'Cancelled'),
      'no_show' => (Colors.deepOrange, 'No Show'),
      _ => (Colors.orange, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status.toLowerCase()) {
      'paid' => (Colors.green, 'Paid'),
      'pending' => (Colors.orange, 'Pending'),
      'refunded' => (Colors.blueGrey, 'Refunded'),
      'failed' => (Colors.red, 'Failed'),
      'expired' => (Colors.red, 'Expired'),
      _ => (Colors.grey, status.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

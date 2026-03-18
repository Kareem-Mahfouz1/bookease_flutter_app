import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/my_bookings/presentation/widgets/booking_card.dart';
import 'package:appointment_booking/features/my_bookings/presentation/widgets/empty_bookings_widget.dart';
import 'package:flutter/material.dart';

class BookingsSection extends StatelessWidget {
  final String title;
  final List<Booking> bookings;
  final String userId;
  final void Function(String bookingId, String userId) onCancel;
  final VoidCallback? onViewAll;

  const BookingsSection({
    super.key,
    required this.title,
    required this.bookings,
    required this.userId,
    required this.onCancel,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedBookings = bookings.take(3).toList();
    final hasMore = bookings.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasMore && onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All (${bookings.length})',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (bookings.isEmpty)
          EmptyBookingsWidget(
            message: title == 'Upcoming'
                ? 'No upcoming appointments.\nBook a service to get started.'
                : 'No past appointments yet.',
          )
        else
          ...displayedBookings.map(
            (b) => BookingCard(booking: b, userId: userId, onCancel: onCancel),
          ),
      ],
    );
  }
}

import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/my_bookings/presentation/widgets/bookings_section.dart';
import 'package:flutter/material.dart';

class MyBookingsBody extends StatelessWidget {
  final List<Booking> upcomingBookings;
  final List<Booking> pastBookings;
  final String userId;
  final void Function(String bookingId, String userId) onCancel;
  final void Function(String title, List<Booking> bookings) onViewAll;

  const MyBookingsBody({
    super.key,
    required this.upcomingBookings,
    required this.pastBookings,
    required this.userId,
    required this.onCancel,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Bookings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          BookingsSection(
            title: 'Upcoming',
            bookings: upcomingBookings,
            userId: userId,
            onCancel: onCancel,
            onViewAll: upcomingBookings.length > 3
                ? () => onViewAll('Upcoming Bookings', upcomingBookings)
                : null,
          ),
          const SizedBox(height: 32),
          BookingsSection(
            title: 'Past',
            bookings: pastBookings,
            userId: userId,
            onCancel: onCancel,
            onViewAll: pastBookings.length > 3
                ? () => onViewAll('Past Bookings', pastBookings)
                : null,
          ),
        ],
      ),
    );
  }
}

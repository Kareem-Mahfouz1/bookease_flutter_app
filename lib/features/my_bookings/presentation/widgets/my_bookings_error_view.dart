import 'package:appointment_booking/features/my_bookings/presentation/cubit/my_bookings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyBookingsErrorView extends StatelessWidget {
  final String message;
  final String? userId;

  const MyBookingsErrorView({
    super.key,
    required this.message,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: userId != null
                ? () => context.read<MyBookingsCubit>().loadBookings(userId!)
                : null,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

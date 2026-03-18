import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/my_bookings/presentation/cubit/my_bookings_cubit.dart';
import 'package:appointment_booking/features/my_bookings/presentation/cubit/my_bookings_state.dart';
import 'package:appointment_booking/features/my_bookings/presentation/widgets/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllBookingsScreen extends StatelessWidget {
  final String title;
  final List<Booking> bookings;
  final String userId;
  final void Function(String bookingId, String userId) onCancel;

  const AllBookingsScreen({
    super.key,
    required this.title,
    required this.bookings,
    required this.userId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<MyBookingsCubit, MyBookingsState>(
        listenWhen: (previous, current) => current is MyBookingsSuccess,
        listener: (context, state) {
          if (state is MyBookingsSuccess) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state is MyBookingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return bookings.isEmpty
              ? const Center(child: Text('No bookings to show.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) => BookingCard(
                    booking: bookings[index],
                    userId: userId,
                    onCancel: onCancel,
                  ),
                );
        },
      ),
    );
  }
}

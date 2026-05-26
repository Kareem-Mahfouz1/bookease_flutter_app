import 'package:appointment_booking/core/models/booking.dart';
import 'package:appointment_booking/features/booking/data/repositories/booking_repository.dart';
import 'package:appointment_booking/features/my_bookings/screens/all_bookings_screen.dart';
import 'package:appointment_booking/features/my_bookings/cubit/my_bookings_cubit.dart';
import 'package:appointment_booking/features/my_bookings/cubit/my_bookings_state.dart';
import 'package:appointment_booking/features/my_bookings/widgets/my_bookings_body.dart';
import 'package:appointment_booking/features/my_bookings/widgets/my_bookings_empty_view.dart';
import 'package:appointment_booking/features/my_bookings/widgets/my_bookings_error_view.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:appointment_booking/features/my_bookings/widgets/booking_card.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyBookingsCubit(BookingRepository()),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatefulWidget {
  const _MyBookingsView();

  @override
  State<_MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<_MyBookingsView> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileSuccess) {
      _userId = profileState.user.uid;
      context.read<MyBookingsCubit>().loadBookings(_userId!);
    }
  }

  void _onCancel(String bookingId, String userId) {
    context.read<MyBookingsCubit>().cancelBooking(bookingId, userId);
  }

  void _navigateToAll(String title, List<Booking> bookings) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (newContext) => BlocProvider.value(
          value: context.read<MyBookingsCubit>(),
          child: AllBookingsScreen(
            title: title,
            bookings: bookings,
            userId: _userId ?? '',
            onCancel: _onCancel,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            return switch (state) {
              MyBookingsInitial() || MyBookingsLoading() => Skeletonizer(
                enabled: false,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => BookingCard(
                    booking: Booking.mock(),
                    userId: _userId ?? '',
                    onCancel: _onCancel,
                  ),
                ),
              ),
              MyBookingsFailure(:final message) => MyBookingsErrorView(
                message: message,
                userId: _userId,
              ),
              MyBookingsSuccess(:final upcomingBookings, :final pastBookings) =>
                RefreshIndicator(
                  onRefresh: () async {
                    if (_userId != null) {
                      await context.read<MyBookingsCubit>().loadBookings(
                        _userId!,
                      );
                    }
                  },
                  child: upcomingBookings.isEmpty && pastBookings.isEmpty
                      ? const MyBookingsEmptyView()
                      : MyBookingsBody(
                          upcomingBookings: upcomingBookings,
                          pastBookings: pastBookings,
                          userId: _userId ?? '',
                          onCancel: _onCancel,
                          onViewAll: _navigateToAll,
                        ),
                ),
            };
          },
        ),
      ),
    );
  }
}

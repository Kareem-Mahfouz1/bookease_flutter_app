import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';

class BookingCalendarScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;

  const BookingCalendarScreen({super.key, required this.serviceData});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Initialize standard state in Cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingCubit>().setServiceData(widget.serviceData);

      // Select today by default
      _selectedDay = DateTime.now();
      context.read<BookingCubit>().selectDate(_selectedDay!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceName =
        widget.serviceData['serviceName'] as String? ?? 'Booking';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Date & Time',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Native Calendar Widget
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CalendarDatePicker(
                      initialDate: _selectedDay ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      onDateChanged: (newDate) {
                        setState(() {
                          _selectedDay = newDate;
                        });
                        context.read<BookingCubit>().selectDate(newDate);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Available Time Slots',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                if (state is BookingLoadingSlots) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is BookingErrorFetchingSlots) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }

                if (state is BookingLoadedSlots) {
                  if (state.timeSlots.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No slots available for this date.'),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: state.timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = state.timeSlots[index];
                        final isSelected =
                            context.read<BookingCubit>().selectedTimeSlot ==
                            slot;

                        return InkWell(
                          onTap: slot.isAvailable
                              ? () {
                                  setState(() {
                                    context.read<BookingCubit>().selectTimeSlot(
                                      slot,
                                    );
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : (slot.isAvailable
                                        ? theme.cardColor
                                        : theme.disabledColor.withValues(
                                            alpha: 0.2,
                                          )),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : (slot.isAvailable
                                          ? theme.dividerColor
                                          : Colors.transparent),
                              ),
                            ),
                            child: Text(
                              '${slot.startTime.hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (slot.isAvailable
                                          ? theme.textTheme.bodyLarge?.color
                                          : theme.disabledColor),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // Bottom padding
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final isSlotSelected =
              context.read<BookingCubit>().selectedTimeSlot != null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSlotSelected
                    ? () {
                        context.push(
                          Routes.bookingDetails,
                          extra: context.read<BookingCubit>(),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 8,
                  shadowColor: theme.primaryColor.withValues(alpha: 0.5),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

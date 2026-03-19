import 'package:appointment_booking/core/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:intl/intl.dart';

class BookingCalendarScreen extends StatefulWidget {
  final ServiceModel service;

  const BookingCalendarScreen({super.key, required this.service});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime? _selectedDay;
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingCubit>().setServiceData(widget.service);
      context.read<BookingCubit>().init();

      _selectedDay = DateTime.now();
      context.read<BookingCubit>().loadAvailableSlots(
        _selectedDay!,
        widget.service.durationMinutes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceName = widget.service.name;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Select Date & Time',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                    child: BlocBuilder<BookingCubit, BookingState>(
                      buildWhen: (previous, current) =>
                          current is BookingScheduleLoaded ||
                          current is BookingInitial,
                      builder: (context, state) {
                        final today = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        );
                        DateTime initial = _selectedDay != null
                            ? DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day,
                              )
                            : today;

                        bool isSelectable(DateTime date) {
                          if (state is BookingScheduleLoaded) {
                            if (state.schedules.isEmpty) return true;
                            try {
                              final daySchedule = state.schedules.firstWhere(
                                (s) => s.dayOfWeek == date.weekday,
                              );
                              return daySchedule.isWorkingDay;
                            } catch (e) {
                              return false;
                            }
                          }
                          return true;
                        }

                        bool found = isSelectable(initial);
                        if (!found) {
                          for (int i = 1; i <= 90; i++) {
                            final nextDay = initial.add(Duration(days: i));
                            if (isSelectable(nextDay)) {
                              initial = nextDay;
                              found = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    _selectedDay?.day != initial.day) {
                                  setState(() {
                                    _selectedDay = initial;
                                  });
                                  context
                                      .read<BookingCubit>()
                                      .loadAvailableSlots(
                                        initial,
                                        widget.service.durationMinutes,
                                      );
                                }
                              });
                              break;
                            }
                          }
                        }

                        return CalendarDatePicker(
                          initialDate: initial,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 90)),
                          selectableDayPredicate: (date) {
                            // If we didn't find ANY valid day, we must allow the initial date to pass the layout assertion
                            if (!found &&
                                date.year == initial.year &&
                                date.month == initial.month &&
                                date.day == initial.day) {
                              return true;
                            }
                            return isSelectable(date);
                          },
                          onDateChanged: (newDate) {
                            setState(() {
                              _selectedDay = newDate;
                            });
                            context.read<BookingCubit>().loadAvailableSlots(
                              newDate,
                              widget.service.durationMinutes,
                            );
                          },
                        );
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
                if (state is BookingLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is BookingFailure) {
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

                if (state is BookingSlotsLoaded &&
                    _isSameDate(state.selectedDate, _selectedDay)) {
                  if (state.availableSlots.isEmpty) {
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
                      itemCount: state.availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = state.availableSlots[index];
                        final slotLabel = _timeFormat.format(slot);
                        final isSelected =
                            context.read<BookingCubit>().selectedTimeSlot ==
                            slot;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              context.read<BookingCubit>().selectTimeSlot(slot);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Text(
                              slotLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyLarge?.color,
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                        context.push(Routes.bookingDetails);
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

  bool _isSameDate(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

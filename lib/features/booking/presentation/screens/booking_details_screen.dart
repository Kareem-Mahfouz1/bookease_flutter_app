import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:appointment_booking/core/widgets/app_text_form_field.dart';
import 'package:appointment_booking/core/helpers/validators.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  String? userId;

  @override
  void initState() {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileSuccess) {
      final user = (cubit.state as ProfileSuccess).user;
      userId = user.uid;
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email;
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();

    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      context.read<BookingCubit>().confirmBooking(
        userId: userId ?? '', // user must be logged in in reality
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      );
    }
  }

  String _calculateEndTimeString(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;
    final hours = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;

    final totalMins = hours * 60 + mins + durationMinutes;
    final endHr = (totalMins ~/ 60).toString().padLeft(2, '0');
    final endMin = (totalMins % 60).toString().padLeft(2, '0');
    return '$endHr:$endMin';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cubit = context.read<BookingCubit>();
    if (cubit.selectedServiceData == null || cubit.selectedTimeSlot == null) {
      return const Scaffold(
        body: Center(child: Text('Missing booking details')),
      );
    }

    final serviceName = cubit.selectedServiceData!.name;
    final price = cubit.selectedServiceData!.price;
    final slot = cubit.selectedTimeSlot!;
    final date = cubit.selectedDate ?? DateTime.now();

    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final endTimeStr = _calculateEndTimeString(
      slot,
      cubit.selectedServiceData!.durationMinutes,
    );
    final timeStr = '$slot - $endTimeStr';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            context.go(Routes.bookingSuccess);
          } else if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is BookingLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow('Service', serviceName, theme),
                            SizedBox(height: 8.h),
                            _buildSummaryRow('Date', dateStr, theme),
                            SizedBox(height: 8.h),
                            _buildSummaryRow('Time', timeStr, theme),
                            SizedBox(height: 8.h),
                            _buildSummaryRow(
                              'Total',
                              '\$${price.toStringAsFixed(2)}',
                              theme,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Personal Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Theme(
                        data: theme.copyWith(
                          inputDecorationTheme: _buildInputDecorationTheme(
                            theme,
                          ),
                        ),
                        child: Column(
                          children: [
                            AppTextFormField(
                              controller: _nameController,
                              hintText: 'Full Name',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _emailFocusNode.requestFocus(),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: theme.disabledColor,
                              ),
                              validator: Validators.name,
                            ),
                            SizedBox(height: 16.h),
                            AppTextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Email Address',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _phoneFocusNode.requestFocus(),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: theme.disabledColor,
                              ),
                              validator: Validators.email,
                            ),
                            SizedBox(height: 16.h),
                            AppTextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              hintText: 'Phone Number (Optional)',
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _notesFocusNode.requestFocus(),
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: theme.disabledColor,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            AppTextFormField(
                              controller: _notesController,
                              focusNode: _notesFocusNode,
                              maxLines: 3,
                              hintText: 'Additional Notes (Optional)',
                              isFinal: true,
                              textInputAction: TextInputAction.done,
                              prefixIcon: Icon(
                                Icons.note_alt_outlined,
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                final isLoading = state is BookingLoading;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 8,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.r,
                              width: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTotal
                ? theme.textTheme.bodyLarge?.color
                : theme.disabledColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? theme.primaryColor
                : theme.textTheme.bodyLarge?.color,
            fontSize: isTotal ? 16 : null,
          ),
        ),
      ],
    );
  }

  InputDecorationTheme _buildInputDecorationTheme(ThemeData theme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
    );
  }
}

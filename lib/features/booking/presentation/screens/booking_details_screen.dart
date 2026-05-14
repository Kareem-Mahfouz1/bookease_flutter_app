import 'package:appointment_booking/core/helpers/validators.dart';
import 'package:appointment_booking/core/routing/route_names.dart';
import 'package:appointment_booking/core/widgets/app_text_form_field.dart';
import 'package:appointment_booking/features/booking/data/models/booking_details.dart';
import 'package:appointment_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:appointment_booking/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<BookingCubit>();
    final service = cubit.selectedServiceData;
    final slot = cubit.selectedTimeSlot;
    if (service == null || slot == null) return;

    final phone = _phoneController.text.trim();
    cubit.setPendingBookingDetails(
      BookingDetails(
        serviceId: service.id,
        serviceName: service.name,
        serviceDurationMinutes: service.durationMinutes,
        price: service.price,
        appointmentStart: slot,
        appointmentEnd: slot.add(Duration(minutes: service.durationMinutes)),
        userId: userId ?? '',
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: phone.isEmpty ? null : phone,
        notes: _notesController.text.trim(),
      ),
    );

    context.push(Routes.paymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BookingCubit>();
    final service = cubit.selectedServiceData;
    final appointmentStart = cubit.selectedTimeSlot;

    if (service == null || appointmentStart == null) {
      return const Scaffold(
        body: Center(child: Text('Missing booking details')),
      );
    }

    final appointmentEnd = appointmentStart.add(
      Duration(minutes: service.durationMinutes),
    );
    final dateStr = DateFormat('EEE, d MMM yyyy').format(appointmentStart);
    final timeStr =
        '${DateFormat('h:mm a').format(appointmentStart)} - ${DateFormat('h:mm a').format(appointmentEnd)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 120.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookingSummaryCard(
                serviceName: service.name,
                date: dateStr,
                time: timeStr,
                price: service.price,
              ),
              SizedBox(height: 24.h),
              Text(
                'Personal Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Theme(
                data: theme.copyWith(
                  inputDecorationTheme: _buildInputDecorationTheme(theme),
                ),
                child: Column(
                  children: [
                    AppTextFormField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
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
                      onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
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
                      onFieldSubmitted: (_) => _notesFocusNode.requestFocus(),
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
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 8,
                  ),
                  child: Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
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

class _BookingSummaryCard extends StatelessWidget {
  final String serviceName;
  final String date;
  final String time;
  final double price;

  const _BookingSummaryCard({
    required this.serviceName,
    required this.date,
    required this.time,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
          _SummaryRow(label: 'Service', value: serviceName),
          SizedBox(height: 8.h),
          _SummaryRow(label: 'Date', value: date),
          SizedBox(height: 8.h),
          _SummaryRow(label: 'Time', value: time),
          SizedBox(height: 8.h),
          _SummaryRow(
            label: 'Total',
            value: '\$${price.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
}

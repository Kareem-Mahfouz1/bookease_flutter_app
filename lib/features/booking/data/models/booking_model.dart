import 'package:appointment_booking/features/booking/data/models/time_slot_model.dart';

class BookingModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final TimeSlotModel timeSlot;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? notes;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.timeSlot,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.notes,
    required this.createdAt,
  });
}

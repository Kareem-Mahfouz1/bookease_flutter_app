import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String serviceId;
  final String serviceName;
  final int serviceDurationMinutes;
  final String date;
  final String startTime;
  final int startMinutes;
  final int endMinutes;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? notes;
  final String status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDurationMinutes,
    required this.date,
    required this.startTime,
    required this.startMinutes,
    required this.endMinutes,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Booking document data was null');

    return Booking(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceDurationMinutes: data['serviceDurationMinutes'] ?? 0,
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      startMinutes: data['startMinutes'] ?? 0,
      endMinutes: data['endMinutes'] ?? 0,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'],
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDurationMinutes': serviceDurationMinutes,
      'date': date,
      'startTime': startTime,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String serviceId;
  final String serviceName;
  final int serviceDurationMinutes;
  final double price;
  final DateTime appointmentStart;
  final DateTime appointmentEnd;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? notes;
  final String status;
  final String paymentStatus;
  final String? paymobOrderId;
  final String paymentMethod;
  final String? onlinePaymentMethod;
  final String? kioskReferenceNumber;
  final String? walletPhoneNumber;
  final String? walletRedirectUrl;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDurationMinutes,
    required this.price,
    required this.appointmentStart,
    required this.appointmentEnd,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.notes,
    required this.status,
    required this.paymentStatus,
    this.paymobOrderId,
    required this.paymentMethod,
    this.onlinePaymentMethod,
    this.kioskReferenceNumber,
    this.walletPhoneNumber,
    this.walletRedirectUrl,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Booking document data was null');

    final appointmentStart =
        (data['appointmentStart'] as Timestamp?)?.toDate() ?? DateTime.now();
    final appointmentEnd =
        (data['appointmentEnd'] as Timestamp?)?.toDate() ??
        appointmentStart.add(const Duration(minutes: 30));

    return Booking(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceDurationMinutes: data['serviceDurationMinutes'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      appointmentStart: appointmentStart,
      appointmentEnd: appointmentEnd,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'],
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymobOrderId: data['paymobOrderId'],
      paymentMethod: data['paymentMethod'] ?? 'online',
      onlinePaymentMethod: data['onlinePaymentMethod'],
      kioskReferenceNumber: data['kioskReferenceNumber'],
      walletPhoneNumber: data['walletPhoneNumber'],
      walletRedirectUrl: data['walletRedirectUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDurationMinutes': serviceDurationMinutes,
      'price': price,
      'appointmentStart': Timestamp.fromDate(appointmentStart),
      'appointmentEnd': Timestamp.fromDate(appointmentEnd),
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymobOrderId': paymobOrderId,
      'paymentMethod': paymentMethod,
      'onlinePaymentMethod': onlinePaymentMethod,
      'kioskReferenceNumber': kioskReferenceNumber,
      'walletPhoneNumber': walletPhoneNumber,
      'walletRedirectUrl': walletRedirectUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

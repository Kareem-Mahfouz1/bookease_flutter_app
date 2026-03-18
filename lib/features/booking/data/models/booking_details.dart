class BookingDetails {
  final String serviceId;
  final String serviceName;
  final int serviceDurationMinutes;
  final double price;
  final String date;
  final String startTime;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? notes;

  const BookingDetails({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDurationMinutes,
    required this.price,
    required this.date,
    required this.startTime,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.notes,
  });
}

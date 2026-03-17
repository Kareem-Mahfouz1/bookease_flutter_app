import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicSchedule {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isWorkingDay;

  const ClinicSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isWorkingDay,
  });

  factory ClinicSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('ClinicSchedule document data was null');

    return ClinicSchedule(
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      isWorkingDay: data['isWorkingDay'] ?? false,
    );
  }
}

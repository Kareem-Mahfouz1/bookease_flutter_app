class TimeSlotModel {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  const TimeSlotModel({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  TimeSlotModel copyWith({
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
  }) {
    return TimeSlotModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Shared time formatting utilities used across the app.
class TimeFormatter {
  TimeFormatter._();

  /// Converts a 24-hour time string "HH:MM" to 12-hour AM/PM format.
  /// e.g. "09:00" → "9:00 am", "13:30" → "1:30 pm"
  static String to12Hour(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    final hours = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;
    final period = hours < 12 ? 'am' : 'pm';
    final displayHour = hours % 12 == 0 ? 12 : hours % 12;
    final mStr = mins.toString().padLeft(2, '0');
    return '$displayHour:$mStr $period';
  }

  /// Adds [durationMinutes] to a 24-hour time string and returns AM/PM result.
  /// e.g. "09:00", 30 → "9:30 am"
  static String endTime24(String startTime24, int durationMinutes) {
    final parts = startTime24.split(':');
    if (parts.length != 2) return startTime24;
    final hours = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;
    final totalMins = hours * 60 + mins + durationMinutes;
    final endHours = totalMins ~/ 60;
    final endMins = totalMins % 60;
    final period = endHours < 12 ? 'am' : 'pm';
    final displayHour = endHours % 12 == 0 ? 12 : endHours % 12;
    final mStr = endMins.toString().padLeft(2, '0');
    return '$displayHour:$mStr $period';
  }
}

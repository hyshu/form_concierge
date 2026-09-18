/// Formats dates for compact display without converting time zones.
extension DateFormatExtension on DateTime {
  /// Formats the date as the year, month, and day separated by hyphens.
  String toIsoDateString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Formats the date and time for display through minutes without a time zone suffix.
  String toIsoDateTimeString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

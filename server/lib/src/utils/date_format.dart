extension DateFormatExtension on DateTime {
  String toIsoDateString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}

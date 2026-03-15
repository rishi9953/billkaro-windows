import 'package:intl/intl.dart';

// Common UTC to local date formatting function
String _formatUtcDate(String? utcString, String format) {
  if (utcString == null) return '';
  try {
    final DateTime utcDateTime = DateTime.parse(
      utcString,
    ).toLocal(); // Convert to local
    return DateFormat(format).format(utcDateTime);
  } catch (e) {
    return '';
  }
}

// Wrapper functions for common formats
String formatDate(String? utcString, {String format = 'dd MMM yyyy'}) {
  return _formatUtcDate(utcString, format);
}

String formatTime(String? utcString, {String format = 'hh:mm a'}) {
  return _formatUtcDate(utcString, format);
}

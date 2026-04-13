import 'package:intl/intl.dart';

const _istOffset = Duration(hours: 5, minutes: 30);

String _formatUtcDate(String? utcString, String format) {
  if (utcString == null || utcString.isEmpty) return '';
  try {
    final parsed = DateTime.parse(utcString);
    final DateTime toFormat =
        parsed.isUtc ? parsed.add(_istOffset) : parsed;
    return DateFormat(format).format(toFormat);
  } catch (e) {
    return '';
  }
}

/// Formats an ISO-8601 string: UTC instants → IST wall clock; local unchanged.
String formatDate(String? utcString, {String format = 'dd MMM yyyy'}) {
  return _formatUtcDate(utcString, format);
}

/// Formats an ISO-8601 string: UTC instants → IST wall clock; local unchanged.
String formatTime(String? utcString, {String format = 'hh:mm a'}) {
  return _formatUtcDate(utcString, format);
}

/// Formats a [DateTime] for display: UTC instants → IST wall clock; local unchanged.
String formatDateTimeForDisplay(DateTime dt, String format) {
  try {
    final df = DateFormat(format);
    if (dt.isUtc) {
      return df.format(dt.add(_istOffset));
    }
    return df.format(dt);
  } catch (e) {
    return '';
  }
}

/// Calendar "today" in IST (date-only).
DateTime todayIstDateOnly() {
  final utc = DateTime.now().toUtc();
  final shifted = utc.add(_istOffset);
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// Order `createdAt` ISO (UTC) → IST calendar date only.
DateTime orderCreatedAtToIstDateOnly(String createdAt) {
  final utc = DateTime.parse(createdAt).toUtc();
  final shifted = utc.add(_istOffset);
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// Start of IST calendar day [istYmd] as a UTC instant (midnight IST).
DateTime startOfIstDayAsUtcInstant(DateTime istYmd) {
  return DateTime.utc(istYmd.year, istYmd.month, istYmd.day)
      .subtract(_istOffset);
}

/// First instant that is not in IST calendar day [istYmd] (exclusive range end).
DateTime endOfIstDayExclusiveUtc(DateTime istYmd) {
  return startOfIstDayAsUtcInstant(istYmd).add(const Duration(days: 1));
}

/// Monday 00:00 IST (date-only) of the week containing [istDateOnly].
DateTime istMondayOfWeek(DateTime istDateOnly) {
  final d = istDateOnly.weekday;
  return istDateOnly.subtract(Duration(days: d - 1));
}

/// Whether API [createdAt] (UTC) falls in the IST calendar range from the date picker.
bool isOrderCreatedAtInIstRange(
  String createdAt,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final orderUtc = DateTime.parse(createdAt).toUtc();
  final startIst = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final endIst = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  final startUtc = startOfIstDayAsUtcInstant(startIst);
  final endUtcExclusive = endOfIstDayExclusiveUtc(endIst);
  return !orderUtc.isBefore(startUtc) && orderUtc.isBefore(endUtcExclusive);
}

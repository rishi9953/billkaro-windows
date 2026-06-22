/// Canonical seating-capacity keys stored on outlets and sent to the API.
const seatingCapacityValueKeys = [
  '0',
  '0-10',
  '10-20',
  '20-50',
  '50-100',
  '100+',
];

/// Normalizes API / UI labels (e.g. "Less than 10") to canonical values (e.g. "0-10").
String normalizeSeatingCapacityValue(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '0';
  final trimmed = raw.trim();

  if (seatingCapacityValueKeys.contains(trimmed)) return trimmed;

  final lower = trimmed.toLowerCase();
  if (lower == '0' || lower.contains('no seating')) return '0';
  if (lower.contains('less') && lower.contains('10')) return '0-10';
  if (lower.contains('more') && lower.contains('100')) return '100+';
  if (lower == '10-20' || (lower.contains('10') && lower.contains('20'))) {
    return '10-20';
  }
  if (lower == '20-50' || (lower.contains('20') && lower.contains('50'))) {
    return '20-50';
  }
  if (lower == '50-100' || (lower.contains('50') && lower.contains('100'))) {
    return '50-100';
  }

  final numeric = int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
  if (numeric != null && numeric > 0) {
    if (numeric <= 10) return '0-10';
    if (numeric <= 20) return '10-20';
    if (numeric <= 50) return '20-50';
    if (numeric <= 100) return '50-100';
    return '100+';
  }

  return '0';
}

/// Max total guest seats for the outlet's seating range.
int parseSeatingCapacityLimit(String? raw) {
  final value = normalizeSeatingCapacityValue(raw);
  return switch (value) {
    '0' => 0,
    '0-10' => 9,
    '10-20' => 20,
    '20-50' => 50,
    '50-100' => 100,
    '100+' => 999,
    _ => 0,
  };
}

/// Sum of per-table seat counts (primary tables only).
int sumTableSeats(Iterable<int> seatCounts) {
  var total = 0;
  for (final seats in seatCounts) {
    if (seats > 0) total += seats;
  }
  return total;
}

int remainingOutletSeats(int usedSeats, int outletMaxSeats) {
  if (outletMaxSeats <= 0) return 0;
  return (outletMaxSeats - usedSeats).clamp(0, outletMaxSeats);
}

bool canFitTableSeats({
  required int usedSeats,
  required int outletMaxSeats,
  required int newTableSeats,
}) {
  if (outletMaxSeats <= 0 || newTableSeats < 1) return false;
  if (newTableSeats > outletMaxSeats) return false;
  return usedSeats + newTableSeats <= outletMaxSeats;
}

/// Default seats per table when auto-creating tables for an outlet.
const defaultTableSeats = 4;

/// Human-readable label for the outlet seating range.
String seatingCapacityDisplayLabel(String? raw) {
  final value = normalizeSeatingCapacityValue(raw);
  return switch (value) {
    '0' => 'No Seating',
    '0-10' => 'Less than 10',
    '10-20' => '10-20',
    '20-50' => '20-50',
    '50-100' => '50-100',
    '100+' => 'More than 100',
    _ => 'No Seating',
  };
}

/// False when outlet is "No seating" / capacity [parseSeatingCapacityLimit] is 0.
bool outletHasTableSeating(String? seatingCapacity) {
  return parseSeatingCapacityLimit(seatingCapacity) > 0;
}

/// Parses per-table seat count from API (int, num, or string).
int parseTableSeatingCapacity(dynamic raw, {int defaultValue = 4}) {
  if (raw == null) return defaultValue;
  if (raw is int) return raw > 0 ? raw : defaultValue;
  if (raw is num) {
    final n = raw.toInt();
    return n > 0 ? n : defaultValue;
  }
  if (raw is String) {
    final n = int.tryParse(raw.trim());
    return (n != null && n > 0) ? n : defaultValue;
  }
  return defaultValue;
}

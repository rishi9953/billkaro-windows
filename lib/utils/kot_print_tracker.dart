import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks kitchen-printed item quantities and KOT sequence per order (Petpooja-style).
class KotPrintTracker {
  static String _printedKey(String outletId, String orderId) =>
      'kot_printed_${outletId}_$orderId';

  static String _sequenceKey(String outletId, String billNumber) =>
      'kot_seq_${outletId}_$billNumber';

  static Future<Map<String, int>> loadPrintedQuantities(
    String outletId,
    String orderId,
  ) async {
    if (outletId.isEmpty || orderId.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_printedKey(outletId, orderId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> savePrintedQuantities(
    String outletId,
    String orderId,
    Map<String, int> quantities,
  ) async {
    if (outletId.isEmpty || orderId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _printedKey(outletId, orderId),
      jsonEncode(quantities),
    );
  }

  /// Returns a Petpooja-style KOT label: `{billNumber}-{sequence}` (e.g. `42-1`, `42-2`).
  static Future<String> nextKotLabel(
    String outletId,
    String billNumber,
  ) async {
    final bill = billNumber.trim().isEmpty ? '0' : billNumber.trim();
    if (outletId.isEmpty) return '$bill-1';

    final prefs = await SharedPreferences.getInstance();
    final key = _sequenceKey(outletId, bill);
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return '$bill-$next';
  }
}

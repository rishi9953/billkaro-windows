part of 'inventory_dialogs.dart';

double? _parseNonNegativeNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final value = double.tryParse(trimmed);
  if (value == null || value < 0) return null;
  return value;
}

double? _parsePositiveNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) return null;
  return value;
}

final _numberInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
];

final _phoneInputFormatters = [FilteringTextInputFormatter.digitsOnly];

final _pinCodeInputFormatters = [FilteringTextInputFormatter.digitsOnly];

/// Strips non-digits and keeps the last 10 digits (handles +91 / 91 prefix).
String _normalizePhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length > 10) return digits.substring(digits.length - 10);
  return digits;
}

Widget _optionalLabel(String label) {
  return Text(
    '$label (optional)',
    style: const TextStyle(color: Colors.black87, fontSize: 16),
  );
}

Widget _requiredLabel(String label) {
  return RichText(
    text: TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _supplierSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    ),
  );
}

Widget _supplierFieldGap() => const SizedBox(height: 12);

String? _fileNameFromUrl(String? url) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }
  return value.split('/').last;
}

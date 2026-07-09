import 'dart:io';

import 'package:billkaro/config/config.dart';

const _accent = AppColor.secondaryPrimary;

bool _isDesktopPlatform(BuildContext context) {
  if (kIsWeb) {
    return MediaQuery.sizeOf(context).width >= 900;
  }
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

ThemeData _buildPickerTheme(ThemeData base, {required bool isRange}) {
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: _accent,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
    ),
    datePickerTheme: DatePickerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      headerBackgroundColor: _accent.withValues(alpha: 0.1),
      headerForegroundColor: const Color(0xFF111827),
      headerHeadlineStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      headerHelpStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
      weekdayStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
      dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      yearStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      todayForegroundColor: WidgetStateProperty.all(_accent),
      todayBackgroundColor: WidgetStateProperty.all(
        _accent.withValues(alpha: 0.08),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade400;
        }
        return const Color(0xFF111827);
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _accent;
        return null;
      }),
      rangePickerHeaderHelpStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
      rangeSelectionBackgroundColor: _accent.withValues(alpha: 0.14),
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        _accent.withValues(alpha: 0.12),
      ),
      dividerColor: Colors.grey.shade200,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.18),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

Widget _wrapPickerDialog(
  BuildContext context,
  Widget? child, {
  required bool isRange,
}) {
  if (child == null) return const SizedBox.shrink();

  final theme = Theme.of(context);
  final desktop = _isDesktopPlatform(context);

  return Theme(
    data: _buildPickerTheme(theme, isRange: isRange),
    child: desktop
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isRange ? 780 : 440,
                maxHeight: isRange ? 680 : 540,
              ),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                ),
              ),
            ),
          )
        : child,
  );
}

AppLocalizations? _loc(BuildContext context) {
  return AppLocalizations.of(context);
}

/// Shows a styled single-date picker used across the app.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  bool useRootNavigator = true,
}) {
  final loc = _loc(context);
  return showDatePicker(
    context: context,
    useRootNavigator: useRootNavigator,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText ?? loc?.select_date ?? 'Select Date',
    cancelText: cancelText ?? loc?.cancel ?? 'Cancel',
    confirmText: confirmText ?? loc?.ok ?? 'OK',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (dialogContext, child) =>
        _wrapPickerDialog(dialogContext, child, isRange: false),
  );
}

/// Shows a styled date-range picker used across the app.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String? helpText,
  String? cancelText,
  String? confirmText,
  bool useRootNavigator = true,
}) {
  final loc = _loc(context);
  return showDateRangePicker(
    context: context,
    useRootNavigator: useRootNavigator,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    helpText: helpText ?? loc?.select_date_range ?? 'Select Date Range',
    cancelText: cancelText ?? loc?.cancel ?? 'Cancel',
    confirmText: confirmText ?? loc?.ok ?? 'OK',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (dialogContext, child) =>
        _wrapPickerDialog(dialogContext, child, isRange: true),
  );
}

/// Convenience wrapper when only [Get.context] is available.
Future<DateTime?> showAppDatePickerFromGet({
  BuildContext? context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  bool useRootNavigator = true,
}) {
  final pickerContext = context ?? Get.context;
  if (pickerContext == null) return Future.value();
  return showAppDatePicker(
    context: pickerContext,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    useRootNavigator: useRootNavigator,
  );
}

/// Convenience wrapper when only [Get.context] is available.
Future<DateTimeRange?> showAppDateRangePickerFromGet({
  BuildContext? context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String? helpText,
  String? cancelText,
  String? confirmText,
  bool useRootNavigator = true,
}) {
  final pickerContext = context ?? Get.context;
  if (pickerContext == null) return Future.value();
  return showAppDateRangePicker(
    context: pickerContext,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    useRootNavigator: useRootNavigator,
  );
}

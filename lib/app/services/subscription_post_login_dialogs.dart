import 'package:billkaro/app/Widgets/access_mode_selection_dialog.dart';
import 'package:billkaro/config/config.dart';

/// Post-login owner dialogs for Windows (access mode selection first).
/// Profile / wallet refresh runs inside the dialog on confirm.
Future<void> showPostLoginSubscriptionDialogsIfNeeded() async {
  final appPref = Get.find<AppPref>();
  if (appPref.isStaffSession) return;

  final user = appPref.user;
  if (user == null) return;

  await showAccessModeSelectionIfNeeded();
}

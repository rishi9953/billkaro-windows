import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/config/config.dart';

void showLogoutDialog(BuildContext context, AppLocalizations loc) {
  var loc = AppLocalizations.of(Get.context!)!;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.logout, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Text(loc.logout, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Text(loc.are_you_sure_you_want_to_logout_from_your_account, style: TextStyle(fontSize: 14, color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            loc.cancel,
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Handle logout logic
            onLogOut();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(loc.logout, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

void onLogOut() async {
  final appPref = Get.find<AppPref>();

  // Clear user token first
  appPref.token = '';

  // Clear all database data
  final db = AppDatabase();
  await db.clearAllData();

  // Clear all SharedPreferences data
  await appPref.clearAllData();

  // Navigate to main screen (or wherever you want after manual logout)
  Get.offAllNamed(AppRoute.main);
}

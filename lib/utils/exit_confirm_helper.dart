import 'dart:io';

import 'package:billkaro/config/config.dart';

/// Exit confirmation used by the custom Windows title bar [CloseWindowButton]
/// (which otherwise bypasses [PopScope]) and by root [PopScope] for back/exit routes.
class ExitConfirmHelper {
  ExitConfirmHelper._();

  static const String skipExitConfirmKey = 'skip_exit_confirm_dialog';

  /// Returns `true` if the app should exit (user confirmed or opted out of prompts).
  static Future<bool> shouldExitAfterPrompt(BuildContext context) async {
    if (kIsWeb ||
        (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return true;
    }

    final prefs = Get.isRegistered<SharedPreferences>()
        ? Get.find<SharedPreferences>()
        : null;
    if (prefs?.getBool(skipExitConfirmKey) ?? false) {
      return true;
    }

    bool dontAskAgain = false;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: AppColor.transparent,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: Colors.white,
              elevation: 0,
              titlePadding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
              contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'BillKaro  ChillKaro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ],
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                side: BorderSide(color: Color(0xFFD0D7E2), width: 1),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Assets.logo.image(width: 36, height: 36),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Are you sure you want to quit the app?',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: () =>
                            setState(() => dontAskAgain = !dontAskAgain),
                        borderRadius: BorderRadius.circular(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: dontAskAgain,
                                side: const BorderSide(
                                  color: Color(0xFF6B7280),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (value) {
                                  setState(() => dontAskAgain = value ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Don't ask again",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        autofocus: true,
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(84, 30),
                          ),
                          maximumSize: const WidgetStatePropertyAll(
                            Size(84, 30),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                          backgroundColor: const WidgetStatePropertyAll(
                            Colors.white,
                          ),
                          side: WidgetStateProperty.resolveWith((states) {
                            final focused = states.contains(
                              WidgetState.focused,
                            );
                            return BorderSide(
                              color: focused
                                  ? const Color(0xFF2F7DFF)
                                  : const Color(0xFFD1D5DB),
                              width: focused ? 1.2 : 1,
                            );
                          }),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(84, 30),
                          ),
                          maximumSize: const WidgetStatePropertyAll(
                            Size(84, 30),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                          backgroundColor: const WidgetStatePropertyAll(
                            Colors.white,
                          ),
                          side: WidgetStateProperty.resolveWith((states) {
                            final focused = states.contains(
                              WidgetState.focused,
                            );
                            return BorderSide(
                              color: focused
                                  ? const Color(0xFF2F7DFF)
                                  : const Color(0xFFD1D5DB),
                              width: focused ? 1.2 : 1,
                            );
                          }),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text(
                          'No',
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [],
            );
          },
        );
      },
    );

    if (shouldExit == true && dontAskAgain && prefs != null) {
      await prefs.setBool(skipExitConfirmKey, true);
    }

    return shouldExit == true;
  }
}

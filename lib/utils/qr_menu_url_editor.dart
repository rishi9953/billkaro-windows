import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:flutter/material.dart';

/// Dialog to set the customer QR menu base URL (dev tunnel, production, etc.).
Future<bool> showQrMenuUrlEditor(BuildContext context) async {
  final appPref = Get.find<AppPref>();
  final saved = appPref.qrMenuBaseUrl.trim();
  final effective = QrMenuUrlConfig.effectiveBaseUrl(appPref);
  final apiDefault = QrMenuUrlConfig.defaultBaseFromApi();

  final controller = TextEditingController(
    text: saved.isNotEmpty ? saved : apiDefault,
  );

  final savedOk = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('QR Menu URL'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Customers scan table QR and open this URL in the browser.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Menu base URL',
                  hintText: 'https://your-tunnel.inc1.devtunnels.ms/api/qr-menu/menu',
                  border: OutlineInputBorder(),
                  helperText:
                      'You can paste tunnel origin, /api, or full /api/qr-menu/menu path',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Active: $effective',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              appPref.qrMenuBaseUrl = '';
              controller.text = apiDefault;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Use API URL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final normalized = QrMenuUrlConfig.normalizeBaseUrl(
                controller.text,
              );
              appPref.qrMenuBaseUrl = normalized;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  controller.dispose();
  if (savedOk == true) {
    showSuccess(description: 'QR menu URL updated. Re-print table QR codes.');
  }
  return savedOk == true;
}

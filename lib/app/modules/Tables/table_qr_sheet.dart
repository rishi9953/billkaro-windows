import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shows a table QR menu code with copy, share, and print actions.
Future<void> showTableQrSheet({
  required BuildContext context,
  required String businessName,
  required String tableDisplayName,
  required String menuUrl,
  Future<void> Function()? onPrint,
}) async {
  if (menuUrl.trim().isEmpty) return;
  final loc = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      var printing = false;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> handlePrint() async {
            if (onPrint == null || printing) return;
            setState(() => printing = true);
            try {
              await onPrint();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            } catch (_) {
              if (ctx.mounted) {
                setState(() => printing = false);
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.qr_menu,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: printing
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: loc.cancel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tableDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColor.black12),
                      ),
                      child: QrImageView(
                        data: menuUrl,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      menuUrl,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.qr_menu_description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: printing
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: menuUrl),
                                    );
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Link copied to clipboard',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.link),
                            label: const Text('Copy link'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: printing
                                ? null
                                : () {
                                    Share.share(
                                      '${loc.qr_menu} — $tableDisplayName\n$menuUrl',
                                      subject:
                                          '$businessName · $tableDisplayName',
                                    );
                                  },
                            icon: const Icon(Icons.share_outlined),
                            label: Text(loc.share),
                          ),
                        ),
                      ],
                    ),
                    if (onPrint != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: printing ? null : handlePrint,
                          icon: printing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.print_outlined),
                          label: Text(loc.print_qr_menu),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

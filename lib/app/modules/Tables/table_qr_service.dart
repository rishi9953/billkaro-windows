import 'package:billkaro/app/modules/Tables/table_qr_sheet.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:get/get.dart';

class TableQrService {
  static AppPref get _pref => Get.find<AppPref>();

  static String menuUrlForTable(TableModel table) {
    return QrMenuUrlConfig.buildForTable(table, _pref);
  }

  static Future<void> showTableQr({
    required BuildContext context,
    required String businessName,
    required TableModel table,
    required String menuUrl,
    Future<void> Function()? onPrint,
  }) {
    return showTableQrSheet(
      context: context,
      businessName: businessName,
      tableDisplayName: table.displayName,
      menuUrl: menuUrl,
      onPrint: onPrint,
    );
  }

  static Future<void> showAllTableQrs({
    required BuildContext context,
    required String businessName,
    required List<TableModel> tables,
    Future<void> Function()? onPrintAll,
    required Future<void> Function(TableModel table) onPrintTable,
  }) async {
    final withUrls = tables
        .map((t) => (table: t, url: menuUrlForTable(t)))
        .where((e) => e.url.isNotEmpty)
        .toList();
    if (withUrls.isEmpty) return;

    if (withUrls.length == 1) {
      final entry = withUrls.first;
      await showTableQr(
        context: context,
        businessName: businessName,
        table: entry.table,
        menuUrl: entry.url,
        onPrint: () => onPrintTable(entry.table),
      );
      return;
    }

    final loc = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.print_all_table_qr,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: withUrls.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final entry = withUrls[index];
                      return ListTile(
                        leading: const Icon(Icons.qr_code_2),
                        title: Text(entry.table.displayName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          if (!context.mounted) return;
                          await showTableQr(
                            context: context,
                            businessName: businessName,
                            table: entry.table,
                            menuUrl: entry.url,
                            onPrint: () => onPrintTable(entry.table),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (onPrintAll != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await onPrintAll();
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: Text(loc.print_all_table_qr),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

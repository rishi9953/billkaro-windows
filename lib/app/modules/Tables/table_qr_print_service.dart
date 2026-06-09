import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:get/get.dart';

class TableQrPrintService {
  static AppPref get _pref => Get.find<AppPref>();

  static String menuUrlForTable(TableModel table) {
    return QrMenuUrlConfig.buildForTable(table, _pref);
  }

  static Future<void> printTableQr({
    required String businessName,
    required TableModel table,
    required String menuUrl,
  }) async {
    await ThermalPrinterService.instance.printTableQrMenu(
      businessName: businessName,
      tableDisplayName: table.displayName,
      menuUrl: menuUrl,
    );
  }

  static Future<void> printAllTableQrs({
    required String businessName,
    required List<TableModel> tables,
  }) async {
    final entries = tables
        .where((t) => menuUrlForTable(t).isNotEmpty)
        .map(
          (t) => (
            tableDisplayName: t.displayName,
            menuUrl: menuUrlForTable(t),
          ),
        )
        .toList(growable: false);

    await ThermalPrinterService.instance.printAllTableQrMenus(
      businessName: businessName,
      tables: entries,
    );
  }
}

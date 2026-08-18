import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/config/app_pref.dart';

/// Reads the last-known outlet table layout from SharedPreferences.
class OfflineTableLoader {
  const OfflineTableLoader._();

  static List<TableModel> loadCached(
    AppPref appPref,
    String outletId, {
    bool excludeMergedSecondary = false,
  }) {
    final cached = appPref.getCachedOutletTables(outletId);
    if (cached == null || cached.isEmpty) return const [];

    final models = cached.map(TableModel.fromTableData);
    if (!excludeMergedSecondary) return models.toList(growable: false);

    return models.where((t) => !t.isMergedSecondary).toList(growable: false);
  }
}

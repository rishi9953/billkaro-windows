import 'dart:async';

import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/sync/item_sync_util.dart';
import 'package:billkaro/utils/connectivity/connectivity_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Local-first catalog writes + pending item push + background pull.
class ItemCatalogSync {
  ItemCatalogSync({required this.apiClient, AppDatabase? db})
    : db = db ?? AppDatabase();

  final ApiClient apiClient;
  final AppDatabase db;

  static bool _hydrating = false;
  static final Set<String> _hydratedOutlets = <String>{};

  static void invalidate([String? outletId]) {
    if (outletId == null || outletId.isEmpty) {
      _hydratedOutlets.clear();
      return;
    }
    _hydratedOutlets.remove(outletId);
  }

  Future<ItemData> saveItemLocally({
    required ItemRequest request,
    String? existingId,
    bool deleted = false,
  }) async {
    final existing = (existingId != null && existingId.isNotEmpty)
        ? await db.getItemById(existingId)
        : null;
    final id = existingId?.trim().isNotEmpty == true
        ? existingId!.trim()
        : newLocalItemId();
    final item = itemDataFromRequest(
      request: request,
      id: id,
      createdAt: existing?.createdAt,
    );
    await db.upsertLocalItem(item, isSynced: false, isDeleted: deleted);
    return item;
  }

  Future<ItemData?> saveItemOnlineOrOffline({
    required ItemRequest request,
    String? existingId,
  }) async {
    final local = await saveItemLocally(
      request: request,
      existingId: existingId,
    );
    if (!await NetworkUtils.hasInternetConnection()) return local;

    try {
      return await _pushOne(
        PendingCatalogItem(item: local, isDeleted: false),
      );
    } catch (e) {
      debugPrint('⚠️ [CATALOG] Item save stayed pending: $e');
      return local;
    }
  }

  Future<void> deleteItemOnlineOrOffline(String itemId) async {
    final id = itemId.trim();
    if (id.isEmpty) return;

    if (isLocalItemId(id)) {
      await db.deleteItemCompletely(id);
      return;
    }

    await db.markItemDeleted(id);
    if (!await NetworkUtils.hasInternetConnection()) return;

    try {
      await _deleteRemote(id);
    } catch (e) {
      debugPrint('⚠️ [CATALOG] Item delete stayed pending: $e');
    }
  }

  Future<ItemSyncResult> pushPendingItems() async {
    if (!await NetworkUtils.hasInternetConnection()) {
      return ItemSyncResult(pending: await db.countPendingItems());
    }

    final pending = await db.getPendingItems();
    var synced = 0;
    var failed = 0;

    for (final row in pending) {
      try {
        await _pushOne(row);
        synced++;
      } on DioException catch (e) {
        failed++;
        final status = e.response?.statusCode;
        if (status != null && status >= 400 && status < 500) {
          await db.markItemSyncFailed(row.item.id);
        }
        debugPrint('⚠️ [CATALOG] Pending item ${row.item.id} failed: $e');
      } catch (e) {
        failed++;
        debugPrint('⚠️ [CATALOG] Pending item ${row.item.id} failed: $e');
      }
      await Future<void>.delayed(Duration.zero);
    }

    return ItemSyncResult(
      synced: synced,
      failed: failed,
      pending: await db.countPendingItems(),
    );
  }

  Future<void> pullCatalogInBackground(String outletId) async {
    if (outletId.isEmpty || _hydrating || _hydratedOutlets.contains(outletId)) {
      return;
    }
    if (!await NetworkUtils.hasInternetConnection()) return;

    _hydrating = true;
    try {
      const pageSize = 200;
      var page = 1;
      var saved = 0;

      while (page <= 2000) {
        if (!await NetworkUtils.hasInternetConnection()) break;

        final response = await apiClient.getItems(
          outletId,
          page,
          pageSize,
          null,
          null,
          null,
          null,
        );
        if (response.status != 'success' || response.data.isEmpty) break;

        await db.saveItems(response.data, outletId);
        saved += response.data.length;
        await Future<void>.delayed(Duration.zero);

        final hasNext =
            response.pagination?.hasNextPage ??
            response.data.length >= pageSize;
        if (!hasNext) break;
        page++;
      }

      _hydratedOutlets.add(outletId);
      debugPrint('💾 [CATALOG] Cached $saved items for $outletId');
    } catch (e, st) {
      debugPrint('⚠️ [CATALOG] Background pull failed: $e\n$st');
    } finally {
      _hydrating = false;
    }
  }

  Future<ItemData> _pushOne(PendingCatalogItem row) async {
    if (row.isDeleted) {
      if (isLocalItemId(row.item.id)) {
        await db.deleteItemCompletely(row.item.id);
        return row.item;
      }
      await _deleteRemote(row.item.id);
      return row.item;
    }

    final request = itemRequestFromItem(row.item);
    final response = isLocalItemId(row.item.id)
        ? await apiClient.addItem(request)
        : await apiClient.updateItem(request, row.item.id);

    final serverItem = parseItemFromResponse(response, row.item);
    if (serverItem == null) {
      if (response is Map && response['status']?.toString() == 'success') {
        await db.markItemAsSynced(row.item.id);
        return row.item;
      }
      throw FormatException('Invalid item sync response for ${row.item.id}');
    }

    if (serverItem.id != row.item.id) {
      await db.replaceItemId(row.item.id, serverItem);
    } else {
      await db.upsertLocalItem(serverItem, isSynced: true);
    }
    return serverItem;
  }

  Future<void> _deleteRemote(String itemId) async {
    final response = await apiClient.deleteItem(itemId);
    if (response is Map && response['status']?.toString() != 'success') {
      throw FormatException('Item delete failed for $itemId: $response');
    }
    await db.deleteItemCompletely(itemId);
  }
}

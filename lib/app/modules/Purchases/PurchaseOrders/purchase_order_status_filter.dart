import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:flutter/material.dart';

/// Status values used by purchase-order list filters.
class PurchaseOrderStatusFilter {
  PurchaseOrderStatusFilter._();

  static const all = 'ALL';
  static const draft = 'DRAFT';
  static const pending = 'PENDING';
  static const received = 'RECEIVED';
  static const cancelled = 'CANCELLED';

  static const values = <String>[
    all,
    draft,
    pending,
    received,
    cancelled,
  ];

  static String labelOf(String status) {
    switch (status.toUpperCase()) {
      case all:
        return 'All';
      case draft:
        return 'Draft';
      case pending:
        return 'Pending';
      case received:
        return 'Received';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color colorOf(String status) {
    switch (status.toUpperCase()) {
      case pending:
        return const Color(0xFFEF8819);
      case draft:
        return const Color(0xFF546E7A);
      case received:
        return const Color(0xFF2E7D32);
      case cancelled:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static List<PurchaseOrderData> apply({
    required List<PurchaseOrderData> source,
    required String query,
    required String status,
  }) {
    final q = query.trim().toLowerCase();
    final selected = status.toUpperCase();

    return source.where((po) {
      if (selected != all && po.status.toUpperCase() != selected) {
        return false;
      }
      if (q.isEmpty) return true;

      final matchesMeta = po.orderNumber.toLowerCase().contains(q) ||
          po.supplierName.toLowerCase().contains(q) ||
          po.status.toLowerCase().contains(q);
      if (matchesMeta) return true;

      return po.items.any(
        (line) => line.rawMaterialName.toLowerCase().contains(q),
      );
    }).toList();
  }
}

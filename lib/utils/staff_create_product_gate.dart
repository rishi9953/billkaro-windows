import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';

/// Hides [child] unless the current session may create products/items.
class StaffCreateProductGate extends StatelessWidget {
  const StaffCreateProductGate({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (!StaffAccess.canCreateProducts) return fallback;
    return child;
  }
}

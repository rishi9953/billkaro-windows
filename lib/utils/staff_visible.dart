import 'package:flutter/widgets.dart';

/// Hides [child] when [allowed] is false. Prefer this over scattered `if`s
/// for simple leaf widgets; keep `if` for list/collection construction.
class StaffVisible extends StatelessWidget {
  const StaffVisible({
    super.key,
    required this.allowed,
    required this.child,
    this.replacement = const SizedBox.shrink(),
  });

  final bool allowed;
  final Widget child;
  final Widget replacement;

  @override
  Widget build(BuildContext context) {
    return allowed ? child : replacement;
  }
}

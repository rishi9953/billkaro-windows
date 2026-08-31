import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/AddOrder/widgets/cart_line_offer_details.dart';
import 'package:billkaro/app/utils/cart_line_display.dart';
import 'package:billkaro/app/utils/combo_display.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

/// Review dialog shown before committing a Save/Bill action.
///
/// Rendered as a dialog (not a bottom sheet) so the list keeps a stable,
/// centred layout on both desktop and small windows.
class ConfirmOrderDialog extends StatefulWidget {
  const ConfirmOrderDialog({
    super.key,
    required this.action,
    required this.controller,
  });

  final PosOrderAction action;
  final AddOrderController controller;

  static Future<void> show(
    PosOrderAction action, {
    required AddOrderController controller,
  }) {
    return Get.dialog<void>(
      ConfirmOrderDialog(action: action, controller: controller),
      barrierDismissible: true,
    );
  }

  @override
  State<ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends State<ConfirmOrderDialog> {
  /// Guards against a double tap firing the POS action twice.
  bool _submitted = false;

  Future<void> _confirm(AddOrderController controller) async {
    if (_submitted) return;
    _submitted = true;
    Navigator.of(context).pop();
    await controller.executeConfirmedPosAction(widget.action);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final maxWidth = min(760.0, size.width - 48);
    final maxHeight = min(size.height * 0.86, 760.0);
    final compact = maxWidth < 620;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Obx(() {
          // Every observable the dialog depends on must be read here: GetX only
          // tracks reads made while this builder runs, not reads inside the
          // child widgets it returns.
          final lines = controller.cartLines;
          final totals = _Totals.of(controller);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(
                title: loc.order_summary,
                subtitle: _subtitleFor(lines, loc),
                onClose: () => Navigator.of(context).pop(),
              ),
              if (!compact && lines.isNotEmpty) _ColumnHeaders(loc: loc),
              Divider(height: 1, color: theme.dividerColor),
              Flexible(
                child: lines.isEmpty
                    ? _EmptyState(message: loc.add_items)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: lines.length,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (context, index) => _OrderLineTile(
                          position: index + 1,
                          line: lines[index],
                          compact: compact,
                          onRemark: lines[index].isPromo
                              ? () {}
                              : () => controller.showItemRemarkDialog(
                                    lines[index].lineKey,
                                    lines[index].name,
                                  ),
                          onIncrement: lines[index].isPromo
                              ? () {}
                              : () => controller.incrementItemQuantity(
                                    lines[index].lineKey,
                                  ),
                          onDecrement: () => controller.decrementItemQuantity(
                            lines[index].lineKey,
                          ),
                          onDelete: () => controller.removeItemCompletely(
                            lines[index].lineKey,
                          ),
                        ),
                      ),
              ),
              _SummaryFooter(
                totals: totals,
                loc: loc,
                canConfirm: lines.isNotEmpty,
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: () async => _confirm(controller),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _subtitleFor(List<CartLineDisplay> lines, AppLocalizations loc) {
    if (lines.isEmpty) return loc.add_items;
    final units = lines.fold<int>(0, (sum, line) => sum + line.quantity);
    return '${lines.length} ${loc.items} · $units ${loc.quantity}';
  }
}

/// Snapshot of the bill totals, read eagerly inside the reactive builder.
class _Totals {
  const _Totals({
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.discount,
    required this.total,
  });

  factory _Totals.of(AddOrderController controller) {
    // `orderDetails` is a plain map; this counter is what signals edits to it.
    controller.orderDetailsVersion.value;
    return _Totals(
      subtotal: controller.subtotal.value,
      tax: controller.totalTax.value,
      serviceCharge: controller.serviceChargeAmount(),
      discount: controller.appliedDiscountAmount(),
      total: controller.totalAmount.value,
    );
  }

  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double discount;
  final double total;
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text('#', style: style)),
          const SizedBox(width: 8),
          Expanded(child: Text(loc.items.toUpperCase(), style: style)),
          SizedBox(
            width: _OrderLineTile.stepperWidth,
            child: Text(
              loc.quantity.toUpperCase(),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: _OrderLineTile.amountWidth,
            child: Text(
              loc.amount.toUpperCase(),
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: _OrderLineTile.actionsWidth),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({
    required this.position,
    required this.line,
    required this.compact,
    required this.onRemark,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  static const double stepperWidth = 112;
  static const double amountWidth = 86;
  static const double actionsWidth = 76;

  final int position;
  final CartLineDisplay line;
  final bool compact;
  final VoidCallback onRemark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildWide(context);
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IndexLabel(position: position),
        const SizedBox(width: 8),
        _ItemThumb(imageUrl: line.imageUrl),
        const SizedBox(width: 12),
        Expanded(child: _ItemDescription(line: line)),
        const SizedBox(width: 8),
        SizedBox(
          width: stepperWidth,
          child: Center(
            child: _QuantityStepper(
              quantity: line.quantity,
              onIncrement: line.isPromo ? null : onIncrement,
              onDecrement: onDecrement,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: amountWidth,
          child: _AmountLabel(line: line),
        ),
        SizedBox(
          width: actionsWidth,
          child: _LineActions(
            hasRemark: !line.isPromo && line.remark.trim().isNotEmpty,
            showRemark: !line.isPromo,
            onRemark: onRemark,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IndexLabel(position: position),
            const SizedBox(width: 8),
            _ItemThumb(imageUrl: line.imageUrl),
            const SizedBox(width: 12),
            Expanded(child: _ItemDescription(line: line)),
            const SizedBox(width: 8),
            _AmountLabel(line: line),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuantityStepper(
              quantity: line.quantity,
              onIncrement: line.isPromo ? null : onIncrement,
              onDecrement: onDecrement,
            ),
            const Spacer(),
            _LineActions(
              hasRemark: !line.isPromo && line.remark.trim().isNotEmpty,
              showRemark: !line.isPromo,
              onRemark: onRemark,
              onDelete: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _IndexLabel extends StatelessWidget {
  const _IndexLabel({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(
        '$position',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ItemDescription extends StatelessWidget {
  const _ItemDescription({required this.line});

  final CartLineDisplay line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remark = line.remark.trim();
    final showRemark = remark.isNotEmpty && !remark.startsWith('Promo: ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                line.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (line.isPromo)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColor.success,
                  ),
                ),
              ),
          ],
        ),
        if (line.comboIncludes != null) ...[
          const SizedBox(height: 2),
          ComboIncludesLabel(text: line.comboIncludes!),
        ],
        const SizedBox(height: 2),
        Text(
          line.isPromo
              ? 'Offer item × ${line.quantity}'
              : '₹${line.unitPrice.toStringAsFixed(2)} × ${line.quantity}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (line.hasOfferInfo) ...[
          const SizedBox(height: 4),
          CartLineOfferDetails(
            offerName: line.offerName,
            offerDetail: line.offerDetail,
          ),
        ],
        if (showRemark)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 13,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    remark,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColor.primary,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.imageUrl});

  final String imageUrl;

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    final url = resolvedMediaUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _size,
        height: _size,
        child: url.isEmpty
            ? const _ThumbPlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbPlaceholder(),
              ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.restaurant_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  /// Mirrors the cap enforced by [AddOrderController.incrementItemQuantity].
  static const int maxQuantity = 100;

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: onIncrement == null || quantity >= maxQuantity
                ? null
                : onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColor.primary
          : AppColor.primary.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 16, color: AppColor.white),
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.line});

  final CartLineDisplay line;

  @override
  Widget build(BuildContext context) {
    if (line.isPromo) {
      return const Text(
        'FREE',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColor.success,
        ),
      );
    }
    return Text(
      '₹${line.lineTotal.toStringAsFixed(2)}',
      textAlign: TextAlign.right,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _LineActions extends StatelessWidget {
  const _LineActions({
    required this.hasRemark,
    required this.showRemark,
    required this.onRemark,
    required this.onDelete,
  });

  final bool hasRemark;
  final bool showRemark;
  final VoidCallback onRemark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showRemark)
          IconButton(
            onPressed: onRemark,
            icon: Icon(
              hasRemark ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: 18,
            ),
            color: hasRemark
                ? AppColor.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            tooltip: loc.remark,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        if (showRemark) const SizedBox(width: 4),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColor.error,
          tooltip: loc.delete,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({
    required this.totals,
    required this.loc,
    required this.canConfirm,
    required this.onCancel,
    required this.onConfirm,
  });

  final _Totals totals;
  final AppLocalizations loc;
  final bool canConfirm;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = totals.subtotal;
    final tax = totals.tax;
    final discount = totals.discount;
    final serviceCharge = totals.serviceCharge;
    final total = totals.total;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          if (tax != 0) _SummaryRow(label: 'Tax', value: tax),
          if (serviceCharge != 0)
            _SummaryRow(label: 'Service Charge', value: serviceCharge),
          if (discount != 0)
            _SummaryRow(
              label: loc.discount,
              value: -discount,
              highlight: theme.colorScheme.error,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          _SummaryRow(label: loc.total_amount, value: total, strong: true),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(loc.cancel),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canConfirm ? onConfirm : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(150, 44),
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '${loc.confirm} · ₹${total.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlight,
  });

  final String label;
  final double value;
  final bool strong;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = strong
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
    final valueStyle = strong
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: highlight,
          );
    final prefix = value < 0 ? '-₹' : '₹';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text('$prefix${value.abs().toStringAsFixed(2)}', style: valueStyle),
        ],
      ),
    );
  }
}

import 'package:billkaro/app/modules/StoreSession/store_session_controller.dart';
import 'package:billkaro/app/services/Modals/store_session/store_session_model.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class StoreCloseDialog extends StatefulWidget {
  const StoreCloseDialog({super.key});

  @override
  State<StoreCloseDialog> createState() => _StoreCloseDialogState();
}

class _StoreCloseDialogState extends State<StoreCloseDialog> {
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  late final StoreSessionController _controller =
      Get.find<StoreSessionController>();
  LiveDaySummary? _summary;
  bool _loadingSummary = true;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await _controller.fetchLiveSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loadingSummary = false;
      if (summary != null) {
        _cashController.text =
            summary.expectedCash.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final closingCash = double.tryParse(_cashController.text.trim());
    if (closingCash == null || closingCash < 0) {
      showError(description: loc.enter_valid_closing_cash);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(loc.close_store_confirm_title),
        content: Text(loc.close_store_confirm_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: Text(loc.close_store),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _controller.closeStore(
      closingCash: closingCash,
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSuccess(description: loc.store_closed_success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Color(0xFFC62828),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.close_store,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          loc.close_store_subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loadingSummary)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_summary != null) ...[
                _summaryCard(_summary!, loc),
                const SizedBox(height: 14),
              ],
              Text(
                loc.closing_cash,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cashController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColor.backGroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_summary != null) ...[
                const SizedBox(height: 8),
                _varianceRow(_summary!),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.notes_optional,
                  filled: true,
                  fillColor: AppColor.backGroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final loading = _controller.isActionLoading.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(loc.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            loading || _loadingSummary ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                loc.close_store,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(LiveDaySummary data, AppLocalizations loc) {
    final s = data.summary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.backGroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statTile(loc.total_orders, '${s.totalOrders}'),
              _statTile(loc.total_sales, _currency.format(s.totalSales)),
            ],
          ),
          if (data.session.openedByName != null &&
              data.session.openedByName!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _staffInfoTile(
              loc.opened_by,
              data.session.openedByName!.trim(),
            ),
          ],
          const SizedBox(height: 10),
          if (s.paymentBreakdown.isNotEmpty) ...[
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...s.paymentBreakdown.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPaymentMethod(e.key),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      _currency.format(e.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.expected_cash,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _currency.format(data.expectedCash),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF083C6B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _staffInfoTile(String label, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, size: 18, color: AppColor.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _varianceRow(LiveDaySummary data) {
    final closing = double.tryParse(_cashController.text.trim());
    if (closing == null) return const SizedBox.shrink();
    final variance = closing - data.expectedCash;
    final color = variance.abs() < 0.01
        ? const Color(0xFF1B7F4B)
        : variance > 0
            ? const Color(0xFF1B7F4B)
            : const Color(0xFFC62828);

    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!.cash_variance,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const Spacer(),
        Text(
          _currency.format(variance),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String key) {
    if (key.isEmpty) return 'Other';
    return key[0].toUpperCase() + key.substring(1);
  }
}

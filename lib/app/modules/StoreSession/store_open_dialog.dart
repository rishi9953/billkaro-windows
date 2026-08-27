import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StoreOpenDialog extends StatefulWidget {
  const StoreOpenDialog({super.key});

  @override
  State<StoreOpenDialog> createState() => _StoreOpenDialogState();
}

class _StoreOpenDialogState extends State<StoreOpenDialog> {
  final _cashController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  late final StoreSessionController _controller =
      Get.find<StoreSessionController>();

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cash = double.tryParse(_cashController.text.trim()) ?? 0;
    if (cash < 0) {
      showError(description: 'Opening cash cannot be negative');
      return;
    }

    final ok = await _controller.openStore(
      openingCash: cash,
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSuccess(description: AppLocalizations.of(context)!.store_opened_success);
    }
  }

  void _onCancel() {
    Navigator.pop(context);
    Modular.to.navigate(HomeMainRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                      color: const Color(0xFF1B7F4B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFF1B7F4B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.open_store,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          loc.open_store_subtitle,
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
              const SizedBox(height: 20),
              Text(
                loc.opening_cash,
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
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppColor.backGroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 22),
              Obx(() {
                final loading = _controller.isActionLoading.value;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading ? null : _onCancel,
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
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7F4B),
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
                                loc.open_store,
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
}

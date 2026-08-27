import 'dart:async';
import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_display.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_pdf_service.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_terms.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

const _poAccent = Color(0xFFEF8819);
const _poBg = Color(0xFFF3F5F9);
const _poInk = Color(0xFF111827);
const _poMuted = Color(0xFF6B7280);
const _poLine = Color(0xFFE5E7EB);
const _poSoft = Color(0xFFFFF8F1);

Future<bool> confirmDiscardPurchaseOrderForm(
  BuildContext context,
  AppLocalizations loc, {
  required bool isEdit,
}) async {
  final shouldDiscard = await showPoAwareDialog<bool>(
    builder: (dialogContext, close) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        constraints: const BoxConstraints(maxWidth: 360),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(isEdit ? 'Discard changes?' : 'Discard purchase order?'),
        content: Text(
          isEdit
              ? 'You have unsaved changes. Are you sure you want to close without saving?'
              : 'You have unsaved purchase order details. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(onPressed: () => close(false), child: Text(loc.stay)),
          ElevatedButton(
            onPressed: () => close(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.leave),
          ),
        ],
      );
    },
  );

  return shouldDiscard ?? false;
}

Widget _poDrawerNavigatorShell({
  required BuildContext context,
  required GlobalKey<NavigatorState> navigatorKey,
  required Widget Function(
    BuildContext context,
    void Function(void Function()) setState,
    VoidCallback closeDrawer,
  )
  builder,
  required VoidCallback closeDrawer,
}) {
  final width = math.min(1200.0, MediaQuery.sizeOf(context).width * 0.85);
  return SizedBox(
    width: width,
    child: Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (navContext, __, ___) => StatefulBuilder(
          builder: (context, setState) =>
              builder(navContext, setState, closeDrawer),
        ),
      ),
    ),
  );
}

void _runAfterRoutePop(VoidCallback action) {
  WidgetsBinding.instance.addPostFrameCallback((_) => action());
}

void _closeDialogThen(VoidCallback action) {
  Get.back();
  _runAfterRoutePop(action);
}

InputDecoration _poInputDecoration({
  required String label,
  String? hint,
  int maxLines = 1,
  bool readOnly = false,
  bool required = false,
  Widget? prefixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    label: required ? _poRequiredLabel(label) : null,
    labelText: required ? null : label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixText: suffixText,
    filled: true,
    fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
    alignLabelWithHint: maxLines > 1,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _poLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _poAccent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

Widget _poRequiredLabel(String label) {
  return RichText(
    text: TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

double? _poParsePositiveNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) return null;
  return value;
}

double? _poParseNonNegativeNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value < 0) return null;
  return value;
}

bool _poLineIsActive(_PoLineDraft line) {
  return line.materialNameCtrl.text.trim().isNotEmpty ||
      line.rawMaterialId.isNotEmpty ||
      line.qtyCtrl.text.trim().isNotEmpty ||
      line.priceCtrl.text.trim().isNotEmpty ||
      line.hsnSacCtrl.text.trim().isNotEmpty;
}

bool _poHasCompleteLine(List<_PoLineDraft> lines) {
  return lines.any((line) {
    if (line.materialNameCtrl.text.trim().isEmpty &&
        line.rawMaterialId.isEmpty) {
      return false;
    }
    final qty = _poParsePositiveNumber(line.qtyCtrl.text);
    final price = _poParseNonNegativeNumber(line.priceCtrl.text);
    return qty != null && price != null;
  });
}

Widget _poSectionTitle(String title, IconData icon, {String? step}) {
  return Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1E3), Color(0xFFFFE0C2)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD7AE)),
        ),
        child: step != null
            ? Text(
                step,
                style: const TextStyle(
                  color: _poAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              )
            : Icon(icon, size: 18, color: _poAccent),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: _poInk,
            letterSpacing: -0.2,
          ),
        ),
      ),
    ],
  );
}

Widget _poSectionCard({required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _poLine),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A111827),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

Widget _poSupplierInfoCard(List<Widget> chips) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _poSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFE0C2)),
    ),
    child: Wrap(spacing: 8, runSpacing: 8, children: chips),
  );
}

Widget _poDatePickerTile({
  required String label,
  required DateTime? value,
  required VoidCallback onPick,
  VoidCallback? onClear,
}) {
  final hasValue = value != null;
  return SizedBox(
    height: 56,
    child: InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Optional — pick a date',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(
            Icons.event_outlined,
            size: 20,
            color: hasValue ? _poAccent : _poMuted,
          ),
          suffixIcon: hasValue && onClear != null
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18, color: _poMuted),
                )
              : const Icon(Icons.chevron_right, color: _poMuted),
          filled: true,
          fillColor: hasValue ? _poSoft : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasValue ? const Color(0xFFFFD7AE) : _poLine,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _poAccent, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        child: Text(
          hasValue ? DateFormat('dd MMM yyyy').format(value) : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: hasValue ? _poInk : _poMuted,
          ),
        ),
      ),
    ),
  );
}

const _poLineInputStyle = TextStyle(
  fontSize: 14,
  height: 1.25,
  fontWeight: FontWeight.w500,
  color: _poInk,
);

InputDecoration _poLineFieldDecoration({
  String? hint,
  String? prefixText,
  String? suffixText,
  Color? fillColor,
}) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    prefixText: prefixText,
    suffixText: suffixText,
    filled: true,
    fillColor: fillColor ?? Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _poLine),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _poLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _poAccent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    errorStyle: const TextStyle(fontSize: 10, height: 1),
    errorMaxLines: 2,
  );
}

Widget _poLineFieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _poMuted,
        letterSpacing: 0.1,
      ),
    ),
  );
}

Widget _poReadonlyAmount(String value) {
  return TextFormField(
    key: ValueKey(value),
    initialValue: value,
    readOnly: true,
    enableInteractiveSelection: false,
    canRequestFocus: false,
    style: _poLineInputStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: _poAccent,
    ),
    decoration: _poLineFieldDecoration(fillColor: const Color(0xFFF8FAFC)),
  );
}

Future<void> _showPoEndDrawer({
  required Widget Function(
    BuildContext context,
    void Function(void Function()) setState,
    VoidCallback closeDrawer,
  )
  builder,
  double extraTopInset = 0,
  String? ownerTabId,
}) async {
  OverlayState? overlay = resolveRootOverlay();
  if (overlay == null) {
    final drawerNavigatorKey = GlobalKey<NavigatorState>();
    activePoDrawerNavigatorKey = drawerNavigatorKey;
    activePoDrawerTabId = ownerTabId;
    visiblePoDrawerTabId = ownerTabId;
    activePoDrawerCloser = () {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    };
    await Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final topInset = desktopOverlayTopInset() + extraTopInset;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Stack(
          children: [
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: curved,
                child: const ModalBarrier(
                  dismissible: false,
                  color: Colors.black54,
                ),
              ),
            ),
            Positioned(
              top: topInset,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: _poDrawerNavigatorShell(
                  context: context,
                  navigatorKey: drawerNavigatorKey,
                  builder: builder,
                  closeDrawer: Get.back,
                ),
              ),
            ),
          ],
        );
      },
    );
    activePoDrawerTabId = null;
    visiblePoDrawerTabId = null;
    activePoDrawerNavigatorKey = null;
    activePoDrawerCloser = null;
    return;
  }
  final completer = Completer<void>();
  final topInset = desktopOverlayTopInset() + extraTopInset;
  final drawerNavigatorKey = GlobalKey<NavigatorState>();
  late OverlayEntry entry;
  var isClosed = false;

  void closeDrawer() {
    if (isClosed) return;
    isClosed = true;
    entry.remove();
    if (activePoDrawerCloser == closeDrawer) {
      activePoDrawerCloser = null;
    }
    if (activePoDrawerOverlayRefresh != null) {
      activePoDrawerOverlayRefresh = null;
    }
    activePoDrawerTabId = null;
    visiblePoDrawerTabId = null;
    activePoDrawerNavigatorKey = null;
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  entry = OverlayEntry(
    builder: (context) {
      final isVisibleForTab =
          activePoDrawerTabId == null ||
          visiblePoDrawerTabId == activePoDrawerTabId;
      return Stack(
        children: [
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !isVisibleForTab,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                color: isVisibleForTab ? Colors.black54 : Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: topInset,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !isVisibleForTab,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                offset: isVisibleForTab ? Offset.zero : const Offset(1.05, 0),
                child: _poDrawerNavigatorShell(
                  context: context,
                  navigatorKey: drawerNavigatorKey,
                  builder: builder,
                  closeDrawer: closeDrawer,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
  activePoDrawerTabId = ownerTabId;
  visiblePoDrawerTabId = ownerTabId;
  activePoDrawerNavigatorKey = drawerNavigatorKey;
  activePoDrawerCloser = closeDrawer;
  activePoDrawerOverlayRefresh = entry.markNeedsBuild;
  await completer.future;
  if (activePoDrawerCloser == closeDrawer) {
    activePoDrawerCloser = null;
  }
  if (activePoDrawerOverlayRefresh == entry.markNeedsBuild) {
    activePoDrawerOverlayRefresh = null;
  }
}

Widget _poDrawerShell({
  required String title,
  required VoidCallback onClose,
  required Widget body,
  required Widget footer,
  required BuildContext context,
  ScrollController? scrollController,
  String? subtitle,
}) {
  final width = math.min(1180.0, MediaQuery.of(context).size.width * 0.86);
  return Material(
    color: _poBg,
    elevation: 24,
    shadowColor: const Color(0x33000000),
    child: SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _poLine)),
            ),
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEF8819),
                        Color(0xFFF5B56B),
                        Color(0xFFEF8819),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF1E3), Color(0xFFFFD7AE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD7AE)),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_checkout_rounded,
                          color: _poAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _poInk,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _poMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: _poMuted,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: body,
              ),
            ),
          ),
          footer,
        ],
      ),
    ),
  );
}

Widget _poDrawerFooter({
  required Widget totals,
  required List<Widget> actions,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: _poLine)),
      boxShadow: [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(child: totals),
        const SizedBox(width: 12),
        ...actions,
      ],
    ),
  );
}

void _disposePoForm({
  required List<_PoLineDraft> lines,
  required TextEditingController notesCtrl,
  required TextEditingController paymentTermsCtrl,
  required TextEditingController referenceCtrl,
  required TextEditingController termsCtrl,
  required _PoAddressFields billingFields,
  required _PoAddressFields shippingFields,
}) {
  for (final l in lines) {
    l.dispose();
  }
  notesCtrl.dispose();
  paymentTermsCtrl.dispose();
  referenceCtrl.dispose();
  termsCtrl.dispose();
  billingFields.dispose();
  shippingFields.dispose();
}

/// Defers controller disposal until this widget is unmounted (after route pop
/// animation), so [TextField]s are not rebuilt against disposed controllers.
class _PoDrawerLifecycle extends StatefulWidget {
  const _PoDrawerLifecycle({
    super.key,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_PoDrawerLifecycle> createState() => _PoDrawerLifecycleState();
}

class _PoDrawerLifecycleState extends State<_PoDrawerLifecycle> {
  @override
  void dispose() {
    final onDispose = widget.onDispose;
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => onDispose());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PoLineDraft {
  _PoLineDraft({
    required this.rawMaterialId,
    String materialName = '',
    String hsnSac = '',
    String description = '',
    double qty = 0,
    double price = 0,
    double? taxRate,
    double? stock,
  }) : materialNameCtrl = TextEditingController(text: materialName),
       hsnSacCtrl = TextEditingController(text: hsnSac),
       descriptionCtrl = TextEditingController(text: description),
       qtyCtrl = TextEditingController(
         text: qty > 0 ? _PoLineDraft._num(qty) : '',
       ),
       priceCtrl = TextEditingController(
         text: price > 0 ? _PoLineDraft._num(price) : '',
       ),
       taxRateCtrl = TextEditingController(
         text: taxRate != null ? _PoLineDraft._num(taxRate) : '',
       ),
       stockCtrl = TextEditingController(
         text: stock != null ? _PoLineDraft._num(stock) : '',
       );

  String rawMaterialId;
  final TextEditingController materialNameCtrl;
  final TextEditingController hsnSacCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController stockCtrl;

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get lineTotal {
    final q = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
    return q * p;
  }

  double get taxRateValue {
    return double.tryParse(taxRateCtrl.text.trim()) ?? 18;
  }

  void dispose() {
    materialNameCtrl.dispose();
    hsnSacCtrl.dispose();
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    taxRateCtrl.dispose();
    stockCtrl.dispose();
  }
}

class _PoAddressFields {
  _PoAddressFields({
    String name = '',
    String line1 = '',
    String line2 = '',
    String pinCode = '',
    String state = '',
    String contact = '',
    String gst = '',
  }) : nameCtrl = TextEditingController(text: name),
       line1Ctrl = TextEditingController(text: line1),
       line2Ctrl = TextEditingController(text: line2),
       pinCtrl = TextEditingController(text: pinCode),
       stateCtrl = TextEditingController(text: state),
       contactCtrl = TextEditingController(text: contact),
       gstCtrl = TextEditingController(text: gst);

  final TextEditingController nameCtrl;
  final TextEditingController line1Ctrl;
  final TextEditingController line2Ctrl;
  final TextEditingController pinCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController contactCtrl;
  final TextEditingController gstCtrl;

  factory _PoAddressFields.fromOutlet(OutletData? outlet) {
    final parts = PurchaseOrderDisplay.splitAddress(
      outlet?.outletAddress ?? '',
    );
    return _PoAddressFields(
      name: outlet?.businessName ?? '',
      line1: parts.line1,
      line2: parts.line2,
      pinCode: parts.pinCode,
      state: parts.state,
      contact: outlet?.phoneNumber ?? '',
      gst: outlet?.gstinNumber ?? '',
    );
  }

  factory _PoAddressFields.fromPoBilling(PurchaseOrderData po) {
    return _PoAddressFields(
      name: po.billingName ?? '',
      line1: po.billingAddressLine1 ?? '',
      line2: po.billingAddressLine2 ?? '',
      pinCode: po.billingPinCode ?? '',
      state: po.billingState ?? '',
      contact: po.billingContact ?? '',
      gst: po.billingGstNo ?? '',
    );
  }

  factory _PoAddressFields.fromPoShipping(PurchaseOrderData po) {
    return _PoAddressFields(
      name: po.shippingName ?? '',
      line1: po.shippingAddressLine1 ?? '',
      line2: po.shippingAddressLine2 ?? '',
      pinCode: po.shippingPinCode ?? '',
      state: po.shippingState ?? '',
      contact: po.shippingContact ?? '',
      gst: po.shippingGstNo ?? '',
    );
  }

  void copyFrom(_PoAddressFields other) {
    nameCtrl.text = other.nameCtrl.text;
    line1Ctrl.text = other.line1Ctrl.text;
    line2Ctrl.text = other.line2Ctrl.text;
    pinCtrl.text = other.pinCtrl.text;
    stateCtrl.text = other.stateCtrl.text;
    contactCtrl.text = other.contactCtrl.text;
    gstCtrl.text = other.gstCtrl.text;
  }

  Map<String, String> toPayload() => {
    'name': nameCtrl.text.trim(),
    'line1': line1Ctrl.text.trim(),
    'line2': line2Ctrl.text.trim(),
    'pinCode': pinCtrl.text.trim(),
    'state': stateCtrl.text.trim(),
    'contact': contactCtrl.text.trim(),
    'gst': gstCtrl.text.trim(),
  };

  void dispose() {
    nameCtrl.dispose();
    line1Ctrl.dispose();
    line2Ctrl.dispose();
    pinCtrl.dispose();
    stateCtrl.dispose();
    contactCtrl.dispose();
    gstCtrl.dispose();
  }
}

bool _poShippingMatchesBilling(PurchaseOrderData po) {
  final billing = _PoAddressFields.fromPoBilling(po).toPayload();
  final shipping = _PoAddressFields.fromPoShipping(po).toPayload();
  for (final key in billing.keys) {
    if (billing[key] != shipping[key]) return false;
  }
  return true;
}

Future<void> showEditPurchaseOrderDialog(
  PurchaseOrderController po,
  PurchaseOrderData order, {
  double drawerTopInset = 0,
  String? drawerTabId,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final status = order.status.toUpperCase();
  if (status != 'PENDING' && status != 'DRAFT') {
    showError(description: loc.po_cannot_edit);
    return;
  }
  await showCreatePurchaseOrderDialog(
    po,
    editPo: order,
    drawerTopInset: drawerTopInset,
    drawerTabId: drawerTabId,
  );
}

Future<void> showCreatePurchaseOrderDialog(
  PurchaseOrderController po, {
  String? preselectedSupplierId,
  PurchaseOrderData? editPo,
  double drawerTopInset = 0,
  String? drawerTabId,
}) async {
  final c = po.inventory;
  final loc = AppLocalizations.of(Get.context!)!;
  final formKey = GlobalKey<FormState>();
  final isEdit = editPo != null;
  if (c.suppliers.isEmpty || c.rawMaterials.isEmpty) {
    await Future.wait([c.loadSuppliers(), c.loadRawMaterials()]);
  }

  final notesCtrl = TextEditingController();
  final paymentTermsCtrl = TextEditingController(text: 'Within 25 days');
  final referenceCtrl = TextEditingController();
  final outlet = Get.find<AppPref>().selectedOutlet;
  final appPref = Get.find<AppPref>();
  final termsCtrl = TextEditingController(
    text: appPref.poDefaultTermsForOutlet(outlet?.id ?? ''),
  );
  late final _PoAddressFields billingFields;
  late final _PoAddressFields shippingFields;
  var shippingSameAsBilling = true;
  var supplierId = preselectedSupplierId ?? '';
  DateTime? expectedDate;
  final lines = <_PoLineDraft>[];

  if (editPo != null) {
    final po = editPo;
    supplierId = po.supplierId;
    paymentTermsCtrl.text = po.paymentTerms;
    referenceCtrl.text = po.referenceNo ?? '';
    notesCtrl.text = po.notes ?? '';
    termsCtrl.text = po.termsAndConditions?.trim().isNotEmpty == true
        ? po.termsAndConditions!
        : appPref.poDefaultTermsForOutlet(outlet?.id ?? '');
    billingFields = _PoAddressFields.fromPoBilling(po);
    shippingFields = _PoAddressFields.fromPoShipping(po);
    shippingSameAsBilling = _poShippingMatchesBilling(po);
    if (po.expectedDate?.isNotEmpty == true) {
      try {
        expectedDate = DateTime.parse(po.expectedDate!).toLocal();
      } catch (_) {}
    }
    for (final item in po.items) {
      final material = c.rawMaterials.firstWhereOrNull(
        (x) => x.id == item.rawMaterialId,
      );
      lines.add(
        _PoLineDraft(
          rawMaterialId: item.rawMaterialId,
          materialName: material?.name ?? item.description,
          hsnSac: item.hsnSacCode,
          description: item.description,
          qty: item.quantity,
          price: item.unitPrice,
          taxRate: item.taxRate,
          stock: material?.currentStock,
        ),
      );
    }
    if (lines.isEmpty) {
      lines.add(_PoLineDraft(rawMaterialId: ''));
    }
  } else {
    billingFields = _PoAddressFields.fromOutlet(outlet);
    shippingFields = _PoAddressFields.fromOutlet(outlet);
    lines.add(_PoLineDraft(rawMaterialId: ''));
  }

  var formDisposed = false;
  final scrollController = ScrollController();
  void disposeFormIfNeeded() {
    if (formDisposed) return;
    formDisposed = true;
    scrollController.dispose();
    _disposePoForm(
      lines: lines,
      notesCtrl: notesCtrl,
      paymentTermsCtrl: paymentTermsCtrl,
      referenceCtrl: referenceCtrl,
      termsCtrl: termsCtrl,
      billingFields: billingFields,
      shippingFields: shippingFields,
    );
  }

  await _showPoEndDrawer(
    extraTopInset: drawerTopInset,
    ownerTabId: drawerTabId,
    builder: (context, setState, closeDrawer) {
      final supplier = c.suppliers.firstWhereOrNull((s) => s.id == supplierId);
      RawMaterialData? resolveLineMaterial(_PoLineDraft line) {
        if (line.rawMaterialId.isNotEmpty) {
          final byId = c.rawMaterials.firstWhereOrNull(
            (m) => m.id == line.rawMaterialId,
          );
          if (byId != null) return byId;
        }
        final name = line.materialNameCtrl.text.trim().toLowerCase();
        if (name.isEmpty) return null;
        return c.rawMaterials.firstWhereOrNull(
          (m) => m.name.toLowerCase() == name,
        );
      }

      double lineTaxRate(_PoLineDraft line) {
        return line.taxRateValue;
      }

      var subTotal = 0.0;
      var totalTax = 0.0;
      for (final line in lines) {
        subTotal += line.lineTotal;
        totalTax += line.lineTotal * lineTaxRate(line) / 100;
      }
      final grandTotal = subTotal + totalTax;

      void closePoForm() {
        closeDrawer();
      }

      Future<void> requestClosePoForm() async {
        final shouldClose = await confirmDiscardPurchaseOrderForm(
          context,
          loc,
          isEdit: isEdit,
        );
        if (shouldClose) {
          closePoForm();
        }
      }

      Future<void> savePo({String status = 'PENDING'}) async {
        // Draft: save with whatever is filled (even a single field / empty lines).
        // Create PO / edit: enforce supplier, payment terms, addresses, and items.
        final isDraftSave = status == 'DRAFT' && editPo == null;

        if (!isDraftSave) {
          if (!(formKey.currentState?.validate() ?? false)) return;
          if (supplierId.isEmpty) {
            showError(description: loc.select_supplier_required);
            return;
          }
          if (!_poHasCompleteLine(lines)) {
            showError(description: loc.po_items_required);
            return;
          }
        }

        final items = <Map<String, dynamic>>[];
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final materialName = line.materialNameCtrl.text.trim();
          if (materialName.isEmpty && line.rawMaterialId.isEmpty) continue;
          final qty = _poParsePositiveNumber(line.qtyCtrl.text.trim());
          final price = _poParseNonNegativeNumber(line.priceCtrl.text.trim());
          final material = resolveLineMaterial(line);

          if (isDraftSave) {
            // Draft: keep only complete resolvable lines; ignore partial ones.
            if (material == null || qty == null || price == null) continue;
          } else {
            if (qty == null || price == null) continue;
            if (material == null) {
              showError(description: loc.po_line_material_required);
              return;
            }
          }

          line.rawMaterialId = material.id;
          final hsn = line.hsnSacCtrl.text.trim();
          final desc = line.descriptionCtrl.text.trim();
          items.add({
            'rawMaterialId': material.id,
            'quantity': qty,
            'unitPrice': price,
            'taxRate': line.taxRateValue,
            'lineNumber': i + 1,
            'description': desc.isNotEmpty ? desc : material.name,
            if (hsn.isNotEmpty)
              'hsnSacCode': hsn
            else if (material.hsnSacCode.isNotEmpty)
              'hsnSacCode': material.hsnSacCode,
          });
        }

        if (!isDraftSave && items.isEmpty) {
          showError(description: loc.po_items_required);
          return;
        }

        if (shippingSameAsBilling) {
          shippingFields.copyFrom(billingFields);
        }
        final billing = billingFields.toPayload();
        final shipping = shippingFields.toPayload();
        final ok = editPo != null
            ? await po.updatePurchaseOrder(
                poId: editPo.id,
                supplierId: supplierId,
                items: items,
                notes: notesCtrl.text.trim(),
                expectedDate: expectedDate,
                paymentTerms: paymentTermsCtrl.text.trim(),
                referenceNo: referenceCtrl.text.trim(),
                documentType: 'Purchase Order',
                billingName: billing['name'],
                billingAddressLine1: billing['line1'],
                billingAddressLine2: billing['line2'],
                billingPinCode: billing['pinCode'],
                billingState: billing['state'],
                billingContact: billing['contact'],
                billingGstNo: billing['gst'],
                shippingName: shipping['name'],
                shippingAddressLine1: shipping['line1'],
                shippingAddressLine2: shipping['line2'],
                shippingPinCode: shipping['pinCode'],
                shippingState: shipping['state'],
                shippingContact: shipping['contact'],
                shippingGstNo: shipping['gst'],
                termsAndConditions: termsCtrl.text.trim(),
              )
            : await po.createPurchaseOrder(
                supplierId: supplierId.isEmpty ? null : supplierId,
                items: items,
                notes: notesCtrl.text.trim(),
                expectedDate: expectedDate,
                paymentTerms: paymentTermsCtrl.text.trim(),
                referenceNo: referenceCtrl.text.trim(),
                documentType: 'Purchase Order',
                billingName: billing['name'],
                billingAddressLine1: billing['line1'],
                billingAddressLine2: billing['line2'],
                billingPinCode: billing['pinCode'],
                billingState: billing['state'],
                billingContact: billing['contact'],
                billingGstNo: billing['gst'],
                shippingName: shipping['name'],
                shippingAddressLine1: shipping['line1'],
                shippingAddressLine2: shipping['line2'],
                shippingPinCode: shipping['pinCode'],
                shippingState: shipping['state'],
                shippingContact: shipping['contact'],
                shippingGstNo: shipping['gst'],
                termsAndConditions: termsCtrl.text.trim(),
                status: status,
              );
        if (ok) {
          if (editPo != null) {
            showSuccess(description: loc.po_updated);
          } else if (status == 'DRAFT') {
            showSuccess(description: loc.po_draft_saved);
          }
          closePoForm();
        }
      }

      return _PoDrawerLifecycle(
        key: const ValueKey('po_drawer_lifecycle'),
        onDispose: disposeFormIfNeeded,
        child: _poDrawerShell(
          context: context,
          title: isEdit ? loc.edit_purchase_order : loc.create_purchase_order,
          subtitle: isEdit
              ? 'Update supplier, addresses, and line items'
              : 'Supplier → addresses → line items → save',
          onClose: () => requestClosePoForm(),
          scrollController: scrollController,
          body: Form(
            key: formKey,
            // Only validate when Create PO / Save runs — Draft must not block.
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _poSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _poSectionTitle(
                        loc.po_header_section,
                        Icons.info_outline,
                        step: '1',
                      ),
                      const SizedBox(height: 16),
                      AppDropdownFormField2<String>(
                        key: const ValueKey('po_supplier'),
                        value: supplierId.isEmpty ? null : supplierId,
                        decoration: _poInputDecoration(
                          label: loc.select_supplier,
                          required: true,
                          prefixIcon: const Icon(
                            Icons.storefront_outlined,
                            size: 20,
                          ),
                        ),
                        items: c.suppliers
                            .map(
                              (s) => DropdownItem(
                                value: s.id,
                                child: Text(s.name.capitalize ?? ''),
                              ),
                            )
                            .toList(),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return loc.select_supplier_required;
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() => supplierId = v ?? ''),
                      ),
                      if (supplier != null) ...[
                        const SizedBox(height: 12),
                        _poSupplierInfoCard([
                          _infoChip(Icons.phone, supplier.phone ?? '—'),
                          if (supplier.gstNumber?.isNotEmpty == true)
                            _infoChip(Icons.receipt_long, supplier.gstNumber!),
                          if (supplier.address?.isNotEmpty == true)
                            _infoChip(
                              Icons.location_on_outlined,
                              supplier.address!,
                            ),
                        ]),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _poDatePickerTile(
                              label: loc.delivery_date,
                              value: expectedDate,
                              onPick: () async {
                                final picked = await showAppDatePicker(
                                  context: context,
                                  useRootNavigator: false,
                                  initialDate:
                                      expectedDate ??
                                      DateTime.now().add(
                                        const Duration(days: 3),
                                      ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => expectedDate = picked);
                                }
                              },
                              onClear: expectedDate == null
                                  ? null
                                  : () => setState(() => expectedDate = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: paymentTermsCtrl,
                              decoration: _poInputDecoration(
                                label: loc.po_payment_terms,
                                required: true,
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return loc.po_payment_terms_required;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: referenceCtrl,
                        decoration: _poInputDecoration(
                          label: loc.po_reference_no,
                          prefixIcon: const Icon(Icons.tag_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: _poInputDecoration(
                          label: loc.notes_label,
                          hint: loc.po_notes_hint,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: termsCtrl,
                        maxLines: 4,
                        decoration: _poInputDecoration(
                          label: loc.po_terms_and_conditions,
                          hint: loc.po_terms_and_conditions_hint,
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                _poSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _poSectionTitle(
                        loc.po_billing_address_section,
                        Icons.receipt_outlined,
                        step: '2',
                      ),
                      const SizedBox(height: 14),
                      _buildPoAddressForm(
                        loc,
                        billingFields,
                        setState,
                        onChanged: () {
                          if (shippingSameAsBilling) {
                            shippingFields.copyFrom(billingFields);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _poSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _poSectionTitle(
                              loc.po_shipping_address_section,
                              Icons.local_shipping_outlined,
                              step: '3',
                            ),
                          ),
                          FilterChip(
                            label: Text(loc.po_same_as_billing),
                            selected: shippingSameAsBilling,
                            selectedColor: _poAccent.withValues(alpha: 0.15),
                            backgroundColor: Colors.white,
                            checkmarkColor: _poAccent,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: shippingSameAsBilling ? _poAccent : _poInk,
                            ),
                            side: BorderSide(
                              color: shippingSameAsBilling
                                  ? _poAccent
                                  : _poLine,
                            ),
                            onSelected: (v) {
                              setState(() {
                                shippingSameAsBilling = v;
                                if (v) shippingFields.copyFrom(billingFields);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildPoAddressForm(
                        loc,
                        shippingFields,
                        setState,
                        readOnly: shippingSameAsBilling,
                        validate: !shippingSameAsBilling,
                      ),
                    ],
                  ),
                ),
                _poSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _poSectionTitle(
                              loc.po_line_items_section,
                              Icons.list_alt_outlined,
                              step: '4',
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _poAccent,
                              side: const BorderSide(color: _poAccent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    lines.add(_PoLineDraft(rawMaterialId: '')),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(loc.add_line),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...lines.asMap().entries.map((entry) {
                        final i = entry.key;
                        final line = entry.value;
                        final taxRate = line.taxRateValue;
                        final taxAmount = line.lineTotal * taxRate / 100;
                        final grossAmount = line.lineTotal + taxAmount;
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: i == lines.length - 1 ? 0 : 12,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _poLine),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _poSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD7AE),
                                      ),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: _poAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Line item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _poInk,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Remove line',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: lines.length <= 1
                                          ? Colors.grey.shade400
                                          : Colors.red.shade400,
                                    ),
                                    onPressed: lines.length <= 1
                                        ? null
                                        : () {
                                            setState(() {
                                              line.dispose();
                                              lines.removeAt(i);
                                            });
                                          },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.material_column),
                                        TextFormField(
                                          controller: line.materialNameCtrl,
                                          decoration: _poLineFieldDecoration(
                                            hint: 'Material name',
                                          ),
                                          validator: (v) {
                                            if (!_poLineIsActive(line)) {
                                              return null;
                                            }
                                            if ((v ?? '').trim().isEmpty) {
                                              return loc
                                                  .po_line_material_required;
                                            }
                                            return null;
                                          },
                                          onChanged: (v) {
                                            final m = c.rawMaterials
                                                .firstWhereOrNull(
                                                  (x) =>
                                                      x.name.toLowerCase() ==
                                                      v.trim().toLowerCase(),
                                                );
                                            setState(() {
                                              line.rawMaterialId = m?.id ?? '';
                                              if (m != null) {
                                                if (line
                                                    .priceCtrl
                                                    .text
                                                    .isEmpty) {
                                                  line.priceCtrl.text =
                                                      _PoLineDraft._num(
                                                        m.purchasePrice,
                                                      );
                                                }
                                                if (line
                                                        .hsnSacCtrl
                                                        .text
                                                        .isEmpty &&
                                                    m.hsnSacCode.isNotEmpty) {
                                                  line.hsnSacCtrl.text =
                                                      m.hsnSacCode;
                                                }
                                                if (line.descriptionCtrl.text
                                                    .trim()
                                                    .isEmpty) {
                                                  line.descriptionCtrl.text =
                                                      m.name;
                                                }
                                                if (line.taxRateCtrl.text
                                                    .trim()
                                                    .isEmpty) {
                                                  line.taxRateCtrl.text =
                                                      _PoLineDraft._num(
                                                        m.taxRate,
                                                      );
                                                }
                                                if (line.stockCtrl.text
                                                    .trim()
                                                    .isEmpty) {
                                                  line.stockCtrl.text =
                                                      _PoLineDraft._num(
                                                        m.currentStock,
                                                      );
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.po_description),
                                        TextFormField(
                                          controller: line.descriptionCtrl,
                                          decoration: _poLineFieldDecoration(),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.po_hsn_sac),
                                        TextFormField(
                                          controller: line.hsnSacCtrl,
                                          decoration: _poLineFieldDecoration(),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.stock),
                                        TextFormField(
                                          controller: line.stockCtrl,
                                          style: _poLineInputStyle,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          decoration: _poLineFieldDecoration(),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.po_order_qty),
                                        TextFormField(
                                          controller: line.qtyCtrl,
                                          style: _poLineInputStyle,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          decoration: _poLineFieldDecoration(),
                                          validator: (v) {
                                            if (!_poLineIsActive(line)) {
                                              return null;
                                            }
                                            if (_poParsePositiveNumber(
                                                  v ?? '',
                                                ) ==
                                                null) {
                                              return loc.po_line_qty_required;
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.po_rate),
                                        TextFormField(
                                          controller: line.priceCtrl,
                                          style: _poLineInputStyle,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          decoration: _poLineFieldDecoration(
                                            prefixText: '₹',
                                          ),
                                          validator: (v) {
                                            if (!_poLineIsActive(line)) {
                                              return null;
                                            }
                                            if (_poParseNonNegativeNumber(
                                                  v ?? '',
                                                ) ==
                                                null) {
                                              return loc.po_line_rate_required;
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.po_amount),
                                        _poReadonlyAmount(
                                          '₹${line.lineTotal.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel('Tax'),
                                        TextFormField(
                                          controller: line.taxRateCtrl,
                                          style: _poLineInputStyle,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          decoration: _poLineFieldDecoration(
                                            suffixText: '%',
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _poLineFieldLabel(loc.total),
                                        _poReadonlyAmount(
                                          '₹${grossAmount.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          footer: _poDrawerFooter(
            totals: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _poSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD7AE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Subtotal  ₹${subTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _poMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tax  ₹${totalTax.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _poMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Grand total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _poMuted,
                        ),
                      ),
                      Text(
                        '₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _poAccent,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => requestClosePoForm(),
                style: TextButton.styleFrom(
                  foregroundColor: _poMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(loc.cancel),
              ),
              if (!isEdit) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _poAccent,
                    side: const BorderSide(color: _poAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => savePo(status: 'DRAFT'),
                  child: Text(loc.save_as_draft),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _poAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => savePo(),
                child: Text(isEdit ? loc.save_po_changes : loc.create_po),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showPurchaseOrderDetailDialog(
  PurchaseOrderController po,
  PurchaseOrderData order,
) async {
  final c = po.inventory;
  final loc = AppLocalizations.of(Get.context!)!;
  final outlet = Get.find<AppPref>().selectedOutlet;
  final appPref = Get.find<AppPref>();
  final supplierFallback = c.suppliers.firstWhereOrNull(
    (s) => s.id == order.supplierId,
  );
  final display = PurchaseOrderDisplay.resolve(
    order,
    outlet: outlet,
    supplierFallback: supplierFallback,
    termsFallback: appPref.poDefaultTermsForOutlet(outlet?.id ?? ''),
  );
  final isDraft =
      display.po.status == 'PENDING' || display.po.status == 'DRAFT';
  final canEdit = isDraft;
  final effectiveDate = _poFmtDate(display.po.createdAt);
  final dash = '—';

  final vendorRows = [
    ['Vendor No', PurchaseOrderDisplay.dashIfEmpty(display.supplier.vendorNo)],
    ['Vendor Name', display.po.supplierName],
    [
      'Vendor Address 1',
      PurchaseOrderDisplay.dashIfEmpty(display.supplier.addressLine1),
    ],
    [
      'Vendor Address 2',
      PurchaseOrderDisplay.dashIfEmpty(display.supplier.addressLine2),
    ],
    [
      'Vendor GST No',
      PurchaseOrderDisplay.dashIfEmpty(display.supplier.gstNumber),
    ],
    [
      'Contact Person',
      PurchaseOrderDisplay.dashIfEmpty(display.supplier.contactPerson),
    ],
    [
      'Contact Number',
      PurchaseOrderDisplay.dashIfEmpty(display.supplier.phone),
    ],
  ];
  final poRows = [
    ['PO Number', display.po.orderNumber],
    ['Effective Date', effectiveDate],
    ['Currency', display.po.currency],
    ['Payment Terms', display.po.paymentTerms],
    [
      'Validity Date',
      display.po.validityDate != null
          ? _poFmtDate(display.po.validityDate!)
          : dash,
    ],
  ];
  final billingRows = [
    ['Name', display.businessName],
    ['Address Line 1', PurchaseOrderDisplay.dashIfEmpty(display.billing.line1)],
    ['Address Line 2', PurchaseOrderDisplay.dashIfEmpty(display.billing.line2)],
    ['Pin code', PurchaseOrderDisplay.dashIfEmpty(display.billing.pinCode)],
    ['State', PurchaseOrderDisplay.dashIfEmpty(display.billing.state)],
    ['Contact No', PurchaseOrderDisplay.dashIfEmpty(display.billingContact)],
    ['GST No', PurchaseOrderDisplay.dashIfEmpty(display.billingGst)],
  ];
  final shippingRows = [
    ['Name', display.businessName],
    [
      'Address Line 1',
      PurchaseOrderDisplay.dashIfEmpty(display.shipping.line1),
    ],
    [
      'Address Line 2',
      PurchaseOrderDisplay.dashIfEmpty(display.shipping.line2),
    ],
    ['Pin Code', PurchaseOrderDisplay.dashIfEmpty(display.shipping.pinCode)],
    ['State', PurchaseOrderDisplay.dashIfEmpty(display.shipping.state)],
    ['Contact No', PurchaseOrderDisplay.dashIfEmpty(display.shippingContact)],
    ['GST No', PurchaseOrderDisplay.dashIfEmpty(display.shippingGst)],
  ];

  final screenH = MediaQuery.of(Get.context!).size.height;
  final screenW = MediaQuery.of(Get.context!).size.width;

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: _poBg,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(screenW - 48, 1100),
          maxHeight: screenH * 0.92,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _poHeaderLogo(
                        logoUrl: display.logoUrl,
                        businessName: display.businessName,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Purchase Order',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              display.po.orderNumber,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _poAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _poStatusChip(display.po.status),
                          if (isDraft) ...[
                            const SizedBox(height: 4),
                            Text(
                              'DRAFT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _poInfoBox(
                                  'Vendor Information',
                                  vendorRows,
                                  minRows: 7,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _poInfoBox(
                                  'PO Details',
                                  poRows,
                                  minRows: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _poInfoBox(
                                  loc.po_billing_address_section,
                                  billingRows,
                                  minRows: 7,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _poInfoBox(
                                  'Shipping Address',
                                  shippingRows,
                                  minRows: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _poLineItemsTable(display, effectiveDate),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Sub Total: ₹${_poFmtMoney(display.subTotal)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Total Tax: ₹${_poFmtMoney(display.totalTax)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Grand Total: ₹${_poFmtMoney(display.grossTotal)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _poAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (display.po.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${loc.notes_label}: ${display.po.notes}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (display.termsAndConditions.trim().isNotEmpty) ...[
                          buildPoDocumentFooter(display.registeredOffice),
                          buildPoTermsDocumentPage(
                            loc: loc,
                            termsText: display.termsAndConditions,
                            orderNumber: display.po.orderNumber,
                            headerLogo: _poHeaderLogo(
                              logoUrl: display.logoUrl,
                              businessName: display.businessName,
                            ),
                            registeredOffice: display.registeredOffice,
                            pageNumber: 2,
                          ),
                        ] else ...[
                          buildPoDocumentFooter(display.registeredOffice),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canEdit)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: _poAccent,
                          ),
                          onPressed: () {
                            final orderData = display.po;
                            _closeDialogThen(() {
                              showEditPurchaseOrderDialog(po, orderData);
                            });
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(loc.edit_po),
                        ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: _poAccent),
                        onPressed: () {
                          final poData = display.po;
                          final outletData = outlet;
                          final supplier = supplierFallback;
                          final resolvedDisplay = display;
                          _closeDialogThen(() {
                            PurchaseOrderPdfService.printOrPreview(
                              poData,
                              outlet: outletData,
                              supplierFallback: supplier,
                              display: resolvedDisplay,
                            );
                          });
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                        ),
                        label: Text(loc.print_po),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _poAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(loc.close),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDraft)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Text(
                        'DRAFT',
                        style: TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _poHeaderLogo({required String? logoUrl, required String businessName}) {
  final url = logoUrl?.trim();
  if (url != null && url.isNotEmpty) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 100, maxWidth: 140),
      child: AppCachedNetworkImage(
        imageUrl: resolvedMediaUrl(url),
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        placeholder: (_, __) => const SizedBox(
          height: 40,
          width: 40,
          child: Center(
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Text(
          businessName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
      ),
    );
  }
  return Text(
    businessName,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1565C0),
    ),
  );
}

Widget _poStatusChip(String status) {
  Color color;
  switch (status.toUpperCase()) {
    case 'RECEIVED':
      color = Colors.green;
    case 'CANCELLED':
      color = Colors.red;
    case 'PENDING':
    case 'DRAFT':
      color = Colors.orange;
    default:
      color = Colors.blueGrey;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      status,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

Widget _poInfoBox(String title, List<List<String>> rows, {int minRows = 0}) {
  final padded = List<List<String>>.from(rows);
  while (padded.length < minRows) {
    padded.add(['', '']);
  }
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: _poAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...padded.map((r) {
          if (r[0].isEmpty && r[1].isEmpty) {
            return const SizedBox(height: 17);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    r[0],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r[1].isEmpty ? '—' : r[1],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

Widget _poLineItemsTable(PurchaseOrderDisplay display, String effectiveDate) {
  const headers = [
    'Sl. No',
    'Item',
    'Description',
    'HSN/SAC\nCode',
    'Qty',
    'UOM',
    'Delivery\nDate',
    'Rate Per\nUnit',
    'Basic\nAmount',
    'Tax\nRate',
    'Tax\nAmount',
    'Gross\nAmount',
  ];

  // Relative widths so the table fills the dialog width.
  const columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(0.7),
    1: FlexColumnWidth(1.5),
    2: FlexColumnWidth(2.0),
    3: FlexColumnWidth(1.0),
    4: FlexColumnWidth(0.7),
    5: FlexColumnWidth(0.7),
    6: FlexColumnWidth(1.1),
    7: FlexColumnWidth(1.1),
    8: FlexColumnWidth(1.1),
    9: FlexColumnWidth(0.8),
    10: FlexColumnWidth(1.0),
    11: FlexColumnWidth(1.1),
  };

  Widget cell(
    String text, {
    bool header = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: header ? 9.5 : 9,
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      const minTableWidth = 900.0;
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final tableWidth = math.max(available, minTableWidth);

      final table = SizedBox(
        width: tableWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Table(
              defaultColumnWidth: const FlexColumnWidth(1),
              border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
              columnWidths: columnWidths,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _poAccent.withOpacity(0.12)),
                  children: headers.map((h) => cell(h, header: true)).toList(),
                ),
                ...display.lines.map((line) {
                  final desc = line.description.isNotEmpty
                      ? line.description
                      : line.rawMaterialName;
                  final delivery = line.deliveryDate != null
                      ? _poFmtShortDate(line.deliveryDate!)
                      : effectiveDate;
                  return TableRow(
                    children: [
                      cell('${line.lineNumber}'),
                      cell(line.rawMaterialName),
                      cell(desc),
                      cell(line.hsnSacCode.isEmpty ? '—' : line.hsnSacCode),
                      cell(_poFmtNum(line.quantity)),
                      cell(line.unit),
                      cell(delivery),
                      cell(_poFmtMoney(line.unitPrice)),
                      cell(_poFmtMoney(line.basicAmount)),
                      cell('${line.taxRate.toStringAsFixed(0)}%'),
                      cell(_poFmtMoney(line.taxAmount)),
                      cell(_poFmtMoney(line.grossAmount)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      );

      if (available >= minTableWidth) return table;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: table,
      );
    },
  );
}

String _poFmtMoney(double v) {
  final fmt = NumberFormat('#,##0.00', 'en_IN');
  return fmt.format(v);
}

String _poFmtNum(double v) {
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

String _poFmtDate(String iso) {
  try {
    return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

String _poFmtShortDate(String iso) {
  try {
    return DateFormat('dd-MMM-yy').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

Widget _buildPoAddressForm(
  AppLocalizations loc,
  _PoAddressFields fields,
  void Function(void Function()) setState, {
  bool readOnly = false,
  bool validate = true,
  VoidCallback? onChanged,
}) {
  void handleChanged(String _) {
    setState(() {});
    onChanged?.call();
  }

  Widget field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: readOnly ? null : handleChanged,
      decoration: _poInputDecoration(
        label: label,
        readOnly: readOnly,
        maxLines: maxLines,
        required: required && validate && !readOnly,
      ).copyWith(counterText: maxLength != null ? '' : null),
      validator: readOnly || !validate ? null : validator,
    );
  }

  return Column(
    children: [
      field(
        fields.nameCtrl,
        loc.po_address_name,
        required: true,
        validator: (v) =>
            (v ?? '').trim().isEmpty ? loc.po_address_name_required : null,
      ),
      const SizedBox(height: 10),
      field(
        fields.line1Ctrl,
        loc.po_address_line1,
        required: true,
        validator: (v) =>
            (v ?? '').trim().isEmpty ? loc.please_enter_address : null,
      ),
      const SizedBox(height: 10),
      field(fields.line2Ctrl, loc.po_address_line2),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: field(
              fields.pinCtrl,
              loc.po_pin_code,
              required: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final pin = (v ?? '').trim();
                if (pin.isEmpty) return loc.po_pin_code_required;
                if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                  return loc.please_enter_valid_pincode;
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: field(
              fields.stateCtrl,
              loc.po_state,
              required: true,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? loc.po_state_required : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: field(
              fields.contactCtrl,
              loc.po_contact_no,
              required: true,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final phone = (v ?? '').trim();
                if (phone.isEmpty) return loc.please_enter_phone_number;
                if (phone.length != 10) {
                  return loc.please_enter_valid_10_digit_phone;
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: field(fields.gstCtrl, loc.po_gst_no)),
        ],
      ),
    ],
  );
}

Widget _infoChip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFFFD7AE)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _poAccent),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _poInk,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> showPoDefaultTermsSettingsDialog() async {
  final loc = AppLocalizations.of(Get.context!)!;
  final appPref = Get.find<AppPref>();
  final outlet = appPref.selectedOutlet;
  if (outlet == null) {
    showError(description: loc.please_select_outlet_first);
    return;
  }

  final ctrl = TextEditingController(
    text: appPref.poDefaultTermsForOutlet(outlet.id ?? ''),
  );

  await Get.dialog(
    AlertDialog(
      title: Text(loc.settings_po_terms),
      content: SizedBox(
        width: math.min(560, MediaQuery.of(Get.context!).size.width - 48),
        child: TextField(
          controller: ctrl,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: loc.po_terms_and_conditions_hint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ctrl.dispose();
            Get.back();
          },
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            appPref.setPoDefaultTermsForOutlet(outlet.id ?? '', ctrl.text);
            ctrl.dispose();
            Get.back();
            showSuccess(description: loc.po_terms_saved);
          },
          child: Text(loc.save),
        ),
      ],
    ),
  );
}

import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';

class PoAddressParts {
  final String line1;
  final String line2;
  final String pinCode;
  final String state;

  const PoAddressParts({
    this.line1 = '',
    this.line2 = '',
    this.pinCode = '',
    this.state = '',
  });
}

class PurchaseOrderDisplay {
  final PurchaseOrderData po;
  final List<PurchaseOrderLineData> lines;
  final double subTotal;
  final double totalTax;
  final double grossTotal;
  final String businessName;
  final String logoUrl;
  final String registeredOffice;
  final PoSupplierInfo supplier;
  final PoAddressParts billing;
  final PoAddressParts shipping;
  final String billingContact;
  final String billingGst;
  final String shippingContact;
  final String shippingGst;
  final String termsAndConditions;

  const PurchaseOrderDisplay({
    required this.po,
    required this.lines,
    required this.subTotal,
    required this.totalTax,
    required this.grossTotal,
    required this.businessName,
    this.logoUrl = '',
    required this.registeredOffice,
    required this.supplier,
    required this.billing,
    required this.shipping,
    required this.billingContact,
    required this.billingGst,
    required this.shippingContact,
    required this.shippingGst,
    this.termsAndConditions = '',
  });

  static PurchaseOrderDisplay resolve(
    PurchaseOrderData po, {
    OutletData? outlet,
    SupplierData? supplierFallback,
    String? termsFallback,
  }) {
    final outletParts = splitAddress(outlet?.outletAddress ?? '');
    final supplier = _resolveSupplier(po, supplierFallback);
    final lines = _resolveLines(po.items);

    var subTotal = po.subTotal;
    var totalTax = po.totalTax;
    if (subTotal <= 0) {
      subTotal = _round(lines.fold(0.0, (s, l) => s + l.basicAmount));
    }
    if (totalTax <= 0) {
      totalTax = _round(lines.fold(0.0, (s, l) => s + l.taxAmount));
    }
    final grossTotal = po.grossTotal > 0
        ? po.grossTotal
        : po.totalAmount > 0
            ? po.totalAmount
            : _round(subTotal + totalTax);

    final businessName = _pick(po.billingName, outlet?.businessName);
    final billing = PoAddressParts(
      line1: _pick(po.billingAddressLine1, outletParts.line1),
      line2: _pick(po.billingAddressLine2, outletParts.line2),
      pinCode: _pick(po.billingPinCode, outletParts.pinCode),
      state: _pick(po.billingState, outletParts.state),
    );
    final shipping = PoAddressParts(
      line1: _pick(po.shippingAddressLine1, billing.line1),
      line2: _pick(po.shippingAddressLine2, billing.line2),
      pinCode: _pick(po.shippingPinCode, billing.pinCode),
      state: _pick(po.shippingState, billing.state),
    );
    final billingContact = _pick(po.billingContact, outlet?.phoneNumber);
    final billingGst = _pick(po.billingGstNo, outlet?.gstinNumber);
    final registeredOffice = _pick(
      po.registeredOfficeAddress,
      [outlet?.businessName, outlet?.outletAddress]
          .where((e) => e != null && e.trim().isNotEmpty)
          .join(', '),
    );

    return PurchaseOrderDisplay(
      po: po,
      lines: lines,
      subTotal: subTotal,
      totalTax: totalTax,
      grossTotal: grossTotal,
      businessName: businessName.isEmpty ? 'Billkaro' : businessName,
      logoUrl: outlet?.logo?.trim() ?? '',
      registeredOffice: registeredOffice.isEmpty ? businessName : registeredOffice,
      supplier: supplier,
      billing: billing,
      shipping: shipping,
      billingContact: billingContact,
      billingGst: billingGst,
      shippingContact: _pick(po.shippingContact, billingContact),
      shippingGst: _pick(po.shippingGstNo, billingGst),
      termsAndConditions: _pick(po.termsAndConditions, termsFallback),
    );
  }

  static PoSupplierInfo _resolveSupplier(
    PurchaseOrderData po,
    SupplierData? fallback,
  ) {
    final existing = po.supplier;
    if (existing != null &&
        (existing.addressLine1.isNotEmpty ||
            existing.vendorNo.isNotEmpty ||
            existing.gstNumber.isNotEmpty)) {
      return existing;
    }
    return PoSupplierInfo(
      vendorNo: existing?.vendorNo ?? '',
      name: po.supplierName,
      addressLine1: existing?.addressLine1.isNotEmpty == true
          ? existing!.addressLine1
          : (fallback?.address ?? ''),
      addressLine2: existing?.addressLine2 ?? '',
      gstNumber: existing?.gstNumber.isNotEmpty == true
          ? existing!.gstNumber
          : (fallback?.gstNumber ?? ''),
      contactPerson: existing?.contactPerson ?? '',
      phone: existing?.phone.isNotEmpty == true
          ? existing!.phone
          : (fallback?.phone ?? ''),
    );
  }

  static List<PurchaseOrderLineData> _resolveLines(
    List<PurchaseOrderLineData> items,
  ) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final line = entry.value;
      final qty = line.quantity;
      final rate = line.unitPrice;
      final taxRate = line.taxRate;
      var basic = line.basicAmount;
      if (basic <= 0 && qty * rate > 0) basic = _round(qty * rate);
      var tax = line.taxAmount;
      if (tax <= 0 && basic > 0) tax = _round(basic * taxRate / 100);
      var gross = line.grossAmount;
      if (gross <= 0 && basic > 0) gross = _round(basic + tax);
      final lineNo = line.lineNumber > 0 ? line.lineNumber : (index + 1) * 10;
      return PurchaseOrderLineData(
        id: line.id,
        rawMaterialId: line.rawMaterialId,
        rawMaterialName: line.rawMaterialName,
        unit: line.unit,
        quantity: qty,
        unitPrice: rate,
        receivedQuantity: line.receivedQuantity,
        lineNumber: lineNo,
        materialCode: line.materialCode,
        description: line.description.isNotEmpty
            ? line.description
            : line.rawMaterialName,
        hsnSacCode: line.hsnSacCode,
        taxRate: taxRate,
        basicAmount: basic,
        taxAmount: tax,
        grossAmount: gross,
        deliveryDate: line.deliveryDate,
        plant: line.plant,
      );
    }).toList();
  }

  static String _pick(String? primary, String? fallback) {
    final a = primary?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = fallback?.trim();
    if (b != null && b.isNotEmpty) return b;
    return '';
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  static PoAddressParts splitAddress(String address) {
    if (address.trim().isEmpty) return const PoAddressParts();
    final parts = address
        .split(RegExp(r'[\n,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final pinMatch = RegExp(r'\b(\d{6})\b').firstMatch(address);
    final pinCode = pinMatch?.group(1) ?? '';
    const states = [
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
      'Delhi',
      'Jammu and Kashmir',
      'Ladakh',
      'Puducherry',
      'Chandigarh',
    ];
    var state = '';
    for (final part in parts.reversed) {
      if (part == pinCode) continue;
      final match = states.where(
        (s) =>
            part.toLowerCase() == s.toLowerCase() ||
            part.toLowerCase().contains(s.toLowerCase()),
      );
      if (match.isNotEmpty) {
        state = part;
        break;
      }
    }
    final line1 = parts.isNotEmpty ? parts.first : address.trim();
    final middle = parts.skip(1).where((p) => p != pinCode && p != state);
    return PoAddressParts(
      line1: line1,
      line2: middle.join(', '),
      pinCode: pinCode,
      state: state,
    );
  }

  static String dashIfEmpty(String value) => value.trim().isEmpty ? '—' : value;
}

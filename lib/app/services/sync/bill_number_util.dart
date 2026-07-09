import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/config/app_pref.dart';

/// Offline-only fallback when the preview API is unavailable.
int computeNextBillNumber({
  required int outletLastBillNumber,
  required Iterable<String> orderBillNumbers,
}) {
  var maxOrderBill = 0;
  for (final raw in orderBillNumbers) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed > maxOrderBill) {
      maxOrderBill = parsed;
    }
  }

  final lastIssued = outletLastBillNumber > maxOrderBill
      ? outletLastBillNumber
      : maxOrderBill;
  return lastIssued + 1;
}

/// POST /orders — server always assigns billNumber.
Map<String, dynamic> buildOrderCreatePayload(Map<String, dynamic> payload) {
  final copy = Map<String, dynamic>.from(payload);
  copy.remove('billNumber');
  if (copy['id'] != null &&
      (copy['id'].toString().startsWith('temp_') ||
          copy['id'].toString().startsWith('local_'))) {
    copy.remove('id');
  }
  return copy;
}

/// Clone request with the server-assigned bill number (e.g. for invoice screen).
CreateorderRequest copyRequestWithBillNumber(
  CreateorderRequest source,
  String billNumber,
) {
  return CreateorderRequest(
    billNumber: billNumber,
    userId: source.userId,
    outletId: source.outletId,
    tableNumber: source.tableNumber,
    customerName: source.customerName,
    phoneNumber: source.phoneNumber,
    subtotal: source.subtotal,
    totalTax: source.totalTax,
    discount: source.discount,
    serviceCharge: source.serviceCharge,
    totalAmount: source.totalAmount,
    paymentReceivedIn: source.paymentReceivedIn,
    splitPayments: source.splitPayments,
    status: source.status,
    orderFrom: source.orderFrom,
    items: source.items,
    specialInstructions: source.specialInstructions,
  );
}

/// Keeps local outlet counter aligned with the server after a successful save.
void syncLocalOutletBillNumber(AppPref appPref, String billNumber) {
  final parsed = int.tryParse(billNumber.trim());
  if (parsed == null) return;

  final outlet = appPref.selectedOutlet;
  if (outlet?.id == null) return;

  appPref.selectedOutlet = outlet!.withBillNumber(parsed);

  final user = appPref.user;
  final outlets = user?.outletData;
  if (user == null || outlets == null) return;

  final updatedOutlets = outlets
      .map((o) => o.id == outlet.id ? o.withBillNumber(parsed) : o)
      .toList();

  appPref.user = User(
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    id: user.id,
    brandName: user.brandName,
    email: user.email,
    address: user.address,
    city: user.city,
    state: user.state,
    zipcode: user.zipcode,
    country: user.country,
    firstName: user.firstName,
    lastName: user.lastName,
    title: user.title,
    mobile: user.mobile,
    isTrial: user.isTrial,
    outletData: updatedOutlets,
    role: user.role,
    staffRole: user.staffRole,
    permissions: user.permissions,
    userId: user.userId,
  );
}

extension OutletDataBillNumber on OutletData {
  OutletData withBillNumber(int value) {
    final copy = OutletData(
      id: id,
      businessName: businessName,
      businessType: businessType,
      businessCategory: businessCategory,
      outletAddress: outletAddress,
      upiId: upiId,
      taxSlab: taxSlab,
      googleProfileLink: googleProfileLink,
      swiggyLink: swiggyLink,
      zomatoLink: zomatoLink,
      gstinNumber: gstinNumber,
      fssaiNumber: fssaiNumber,
      outletAge: outletAge,
      logo: logo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      phoneNumber: phoneNumber,
      seatingCapacity: seatingCapacity,
      billNumber: value,
    );
    copy.subscriptions = subscriptions;
    return copy;
  }
}

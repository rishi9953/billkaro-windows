import 'package:billkaro/app/services/Modals/Categories/bulk_delete_categories_request.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/PrinterOrderRequest/printer_order_request.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/app/services/Modals/activites/activities_response.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/bulk_delete_request.dart';
import 'package:billkaro/app/services/Modals/addItem/bulk_item_request.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/customer/customerRequest.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/Modals/kds/kds_bump_events_response.dart';
import 'package:billkaro/app/services/Modals/kds/kds_response.dart';
import 'package:billkaro/app/services/Modals/login_modal.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/outlets/outlet_request.dart';
import 'package:billkaro/app/services/Modals/registration_modal.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/app/services/Modals/user/user_response.dart';
import 'package:billkaro/app/services/Modals/whatsapp/whatsapp_marketing_request.dart';
import 'package:billkaro/app/services/Modals/whatsapp/whatsapp_marketing_response.dart';
import 'package:billkaro/app/services/Network/urls.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // -------------------- AUTH --------------------

  @POST(register)
  Future<dynamic> registration(@Body() RegistrationModel registrationReqest);

  @POST(login)
  Future<LoginResponse> onLogin(@Body() LoginModel loginRequest);

  @POST(staffLogin)
  Future<LoginResponse> onStaffLogin(@Body() LoginModel loginRequest);

  @POST(sendPhoneOtpPath)
  Future<dynamic> sendPhoneOtp(@Body() Map<String, dynamic> body);

  @POST(verifyPhoneOtpPath)
  Future<LoginResponse> verifyPhoneOtp(@Body() Map<String, dynamic> body);

  @POST(sendStaffPhoneOtpPath)
  Future<dynamic> sendStaffPhoneOtp(@Body() Map<String, dynamic> body);

  @POST(verifyStaffPhoneOtpPath)
  Future<LoginResponse> verifyStaffPhoneOtp(@Body() Map<String, dynamic> body);

  @POST(forgotPass)
  Future<dynamic> forgotPassword(@Body() Map<String, dynamic> body);

  @POST(staffForgotPass)
  Future<dynamic> staffForgotPassword(@Body() Map<String, dynamic> body);

  @POST(verifyEmail)
  Future<dynamic> verifyAuthEmail(@Body() Map<String, dynamic> body);

  @POST(checkEmail)
  Future<dynamic> checkAuthEmail(@Body() Map<String, dynamic> body);

  @POST(checkMobile)
  Future<dynamic> checkAuthMobile(@Body() Map<String, dynamic> body);

  @POST(resendActivation)
  Future<dynamic> resendAuthActivation(@Body() Map<String, dynamic> body);

  @POST('$user/{id}/choose-access-mode')
  Future<dynamic> chooseAccessMode(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  // -------------------- USER --------------------

  @GET('$user/{id}')
  Future<UserResponse> getUserDetails(@Path('id') String id);

  @PATCH('$user/{id}')
  Future<dynamic> updateUser(
    @Path('id') String id,
    @Body() Map<String, dynamic> user,
  );

  // -------------------- ITEMS --------------------

  @POST(items)
  Future<dynamic> addItem(@Body() ItemRequest itemRequest);

  @POST(bulkItems)
  Future<dynamic> addBulkItem(@Body() BulkItemRequest bulkItemRequest);

  @GET('$items/outlet/{outletId}')
  Future<ItemResponse> getItems(
    @Path('outletId') String outletId,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('category') String? category,
    @Query('search') String? search,
    @Query('showItem') bool? showItem,
    @Query('isRecommended') bool? isRecommended,
  );

  @PATCH('$items/{id}')
  Future<dynamic> updateItem(@Body() ItemRequest item, @Path('id') String id);

  @DELETE('$items/{id}')
  Future<dynamic> deleteItem(@Path('id') String id);

  @DELETE(bulkItems)
  Future<dynamic> deleteBulkItems(@Body() BulkDeleteRequest bulkDeleteRequest);

  // -------------------- CATEGORIES --------------------

  // ✅ Get categories by outlet
  @GET('$outlets/{outletId}/categories')
  Future<CategoryResponse> getCategories(@Path('outletId') String outletId);

  // ✅ Add category
  @POST('$outlets/{outletId}/categories')
  Future<dynamic> addCategory(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  // ✅ Update category
  @PATCH('$outlets/{outletId}/categories/{id}')
  Future<dynamic> updateCategory(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  // ✅ Delete category
  @DELETE('$outlets/{outletId}/categories/{id}')
  Future<dynamic> deleteCategory(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  // ✅ Bulk delete categories
  @DELETE('$outlets/{outletId}/categories/bulk')
  Future<dynamic> deleteBulkCategories(
    @Path('outletId') String outletId,
    @Body() BulkDeleteCategoriesRequest request,
  );

  // -------------------- RAW MATERIAL CATEGORIES --------------------

  @GET('$outlets/{outletId}/raw-material-categories')
  Future<dynamic> getRawMaterialCategories(
    @Path('outletId') String outletId,
  );

  @POST('$outlets/{outletId}/raw-material-categories')
  Future<dynamic> addRawMaterialCategory(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/raw-material-categories/{id}')
  Future<dynamic> updateRawMaterialCategory(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$outlets/{outletId}/raw-material-categories/{id}')
  Future<dynamic> deleteRawMaterialCategory(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  // -------------------- REGULAR CUSTOMER --------------------

  @POST('$outlets/{outletId}/regular-customers')
  Future<dynamic> addRegularCustomer(
    @Path('outletId') String outletId,
    @Body() CustomerRequest customerRequest,
  );

  @GET('$outlets/{outletId}/regular-customers')
  Future<CustomerResponse> getRegularCustomer(
    @Path('outletId') String outletId,
  );

  @GET('$outlets/{outletId}/regular-customers/lookup')
  Future<CustomerLookupResponse> lookupRegularCustomerByPhone(
    @Path('outletId') String outletId,
    @Query('phone') String phone,
  );

  @GET('$outlets/{outletId}/regular-customers/{id}')
  Future<CustomerDetailsResponse> getRegularCustomerDetails(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Query('page') int? page,
    @Query('limit') int? limit,
  );

  @PATCH('$outlets/{outletId}/regular-customers/{id}')
  Future<dynamic> updateRegularCustomer(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() CustomerRequest customerRequest,
  );

  @DELETE('$outlets/{outletId}/regular-customers/{id}')
  Future<dynamic> deleteRegularCustomer(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  // -------------------- WHATSAPP MARKETING --------------------

  @POST('$outlets/{outletId}/whatsapp-marketing/send-bulk')
  Future<WhatsappMarketingResponse> sendBulkWhatsappMarketing(
    @Path('outletId') String outletId,
    @Body() WhatsappMarketingRequest request,
  );

  // -------------------- Orders --------------------

  @POST(orders)
  Future<dynamic> addOrder(@Body() Map<String, dynamic> orderRequest);

  @GET('$orders/best-selling-items')
  Future<dynamic> getBestSellingItems(
    @Query('userId') String userId,
    @Query('outletId') String outletId,
    @Query('limit') int? limit,
  );

  @GET('$orders/next-bill-number')
  Future<dynamic> getNextBillNumber(@Query('outletId') String outletId);

  @GET(orders)
  Future<OrderResponse> getOrders(
    @Query('userId') String userId,
    @Query('outletId') String outletId,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('category') String? category,
    @Query('paymentReceivedIn') String? paymentReceivedIn,
    @Query('startDate') String? startDate,
    @Query('endDate') String? endDate,
  );

  @PATCH('$orders/{id}')
  Future<dynamic> updateOrder(
    @Path('id') String id,
    @Body() Map<String, dynamic> orderRequest,
  );

  @PATCH('$orders/{id}/soft-delete')
  Future<dynamic> softDeleteOrder(@Path('id') String id);

  @PATCH('$orders/{id}/restore')
  Future<dynamic> restoreOrder(@Path('id') String id);

  @GET(orders)
  Future<OrderResponse> getOrdersByStatus(
    @Query('userId') String userId,
    @Query('outletId') String outletId,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('status') String status,
  );

  @DELETE('$orders/{id}')
  Future<dynamic> deleteOrder(@Path('id') String id);

  // -------------------- Outlet --------------------
  @POST('$user/{id}/outlet')
  Future<dynamic> addOutlet(
    @Path('id') String id,
    @Body() OutletRequest outletRequest,
  );

  @POST('$user/{userId}/outlet/{outletId}/delete')
  Future<dynamic> deleteOutlet(
    @Path('userId') String userId,
    @Path('outletId') String outletId,
  );

  @PATCH('$user/{id}/outlet/{outletId}')
  Future<dynamic> updateOutlet(
    @Path('id') String id,
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> outletRequest,
  );

  //== ------------------ Subscriptions --------------------

  @GET(subscriptions)
  Future<SubscriptionResponse> getSubscription(
    @Query('platform') String? platform,
  );

  //== ------------------ Payment --------------------

  @POST(createPaymentOrder)
  Future<dynamic> createRazorPaymentOrder(@Body() Map<String, dynamic> body);

  @POST(subscribe)
  Future<dynamic> subscribeToPlan(@Body() Map<String, dynamic> body);

  @GET(businessTypes)
  Future<BusinesstTypeResponse> getBusinessTypes(@Query('active') bool? status);

  // -------------------- Outlet Tables (POS) --------------------

  @GET(outletTables)
  Future<TablesResponse> getOutletTables(@Query('outletId') String outletId);

  @POST(outletTables)
  Future<dynamic> createTable(@Body() Map<String, dynamic> body);

  @PATCH('$outletTables/{id}')
  Future<dynamic> updateTable(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$outletTables/{id}')
  Future<dynamic> deleteTable(@Path('id') String id);

  @GET(outletTableSections)
  Future<dynamic> getOutletTableSections(@Query('outletId') String outletId);

  @POST(outletTableSections)
  Future<dynamic> createOutletTableSection(@Body() Map<String, dynamic> body);

  @DELETE('$outletTableSections/{id}')
  Future<dynamic> deleteOutletTableSection(@Path('id') String id);

  // Update table status (Available/Occupied/Billing/Paid)
  @PATCH('$outletTables/{tableId}/status')
  Future<dynamic> updateTableStatus(
    @Path('tableId') String tableId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outletTables/reset/{outletId}')
  Future<dynamic> resetAllTable(@Path('outletId') String outletId);

  @GET('$outletTables/{id}/qr')
  Future<dynamic> getTableQr(@Path('id') String id);

  @POST('$outletTables/{id}/qr/generate')
  Future<dynamic> generateTableQr(@Path('id') String id);

  @POST('$outletTables/qr/generate-all/{outletId}')
  Future<dynamic> generateAllTableQr(@Path('outletId') String outletId);

  @POST('$outletTables/merge')
  Future<dynamic> mergeTables(@Body() Map<String, dynamic> body);

  @POST('$outletTables/unmerge/{primaryTableId}')
  Future<dynamic> unmergeTables(
    @Path('primaryTableId') String primaryTableId,
    @Query('outletId') String outletId,
  );

  // -------------------- Table Reservations --------------------

  @GET(tableReservations)
  Future<dynamic> getTableReservations(
    @Query('outletId') String outletId, {
    @Query('date') String? date,
  });

  @POST(tableReservations)
  Future<dynamic> createTableReservation(@Body() Map<String, dynamic> body);

  @PATCH('$tableReservations/{id}')
  Future<dynamic> updateTableReservation(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$tableReservations/{id}')
  Future<dynamic> cancelTableReservation(@Path('id') String id);

  @POST('$tableReservations/{id}/seat')
  Future<dynamic> seatTableReservation(@Path('id') String id);

  @POST(printerOrder)
  Future<dynamic> printerOrderRequest(
    @Body() PrinterOrderRequest printerOrderRequest,
  );

  @POST('outlets/{outletId}/$staff')
  Future<dynamic> addStaff(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @POST('outlets/{outletId}/$staff/$checkStaffEmails')
  Future<dynamic> checkStaffEmail(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @GET('outlets/{outletId}/$staff')
  Future<dynamic> getStaffList(@Path('outletId') String outletId);

  @PATCH('outlets/{outletId}/$staff/{staffId}')
  Future<dynamic> updateStaff(
    @Path('outletId') String outletId,
    @Path('staffId') String staffId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('outlets/{outletId}/$staff/{staffId}')
  Future<dynamic> deleteStaff(
    @Path('outletId') String outletId,
    @Path('staffId') String staffId,
  );

  @PATCH('outlets/{outletId}/$staff/{staffId}/activation')
  Future<dynamic> setStaffActivation(
    @Path('outletId') String outletId,
    @Path('staffId') String staffId,
    @Body() Map<String, dynamic> body,
  );

  @POST('outlets/{outletId}/$staff/{staffId}/reinvite')
  Future<dynamic> reinviteStaff(
    @Path('outletId') String outletId,
    @Path('staffId') String staffId,
  );

  @GET('$staffProfile/{staffId}')
  Future<UserResponse> getStaffProfile(@Path('staffId') String staffId);

  @PATCH('$staffProfile/{staffId}')
  Future<dynamic> updateStaffProfile(
    @Path('staffId') String staffId,
    @Body() Map<String, dynamic> body,
  );

  @GET(activities)
  Future<ActivityResponseModel> getActivities(
    @Query('outletId') String outletId, {
    @Query('userId') String? staffId,
    @Query('type') String? type,
    @Query('startDate') String? startDate,
    @Query('endDate') String? endDate,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  // -------------------- Kitchen Display (KDS) --------------------

  @GET('$kds/queue')
  Future<KdsQueueResponse> getKdsQueue(@Query('outletId') String outletId);

  @GET('$kds/bump-events')
  Future<KdsBumpEventsResponse> getKdsBumpEvents(
    @Query('outletId') String outletId,
    @Query('since') String? since,
  );

  @PATCH('$kds/orders/{id}/status')
  Future<dynamic> updateKdsOrderStatus(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$kds/orders/{id}/items/{itemId}/status')
  Future<dynamic> updateKdsItemStatus(
    @Path('id') String id,
    @Path('itemId') String itemId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$kds/orders/{id}/bump')
  Future<dynamic> bumpKdsTicket(@Path('id') String id);

  // -------------------- INVENTORY --------------------

  @GET('$outlets/{outletId}/$inventory/dashboard')
  Future<dynamic> getInventoryDashboard(@Path('outletId') String outletId);

  @GET('$outlets/{outletId}/$inventory/low-stock')
  Future<dynamic> getInventoryLowStock(@Path('outletId') String outletId);

  @GET('$outlets/{outletId}/$inventory/raw-materials')
  Future<dynamic> getRawMaterials(
    @Path('outletId') String outletId,
    @Query('search') String? search,
    @Query('category') String? category,
    @Query('lowStockOnly') bool? lowStockOnly,
  );

  @POST('$outlets/{outletId}/$inventory/raw-materials')
  Future<dynamic> createRawMaterial(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/raw-materials/{id}')
  Future<dynamic> updateRawMaterial(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$outlets/{outletId}/$inventory/raw-materials/{id}')
  Future<dynamic> deleteRawMaterial(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  @GET('$outlets/{outletId}/$inventory/suppliers')
  Future<dynamic> getSuppliers(
    @Path('outletId') String outletId,
    @Query('search') String? search,
  );

  @POST('$outlets/{outletId}/$inventory/suppliers')
  Future<dynamic> createSupplier(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outlets/{outletId}/$inventory/$supplierCheckEmail')
  Future<dynamic> checkSupplierEmail(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outlets/{outletId}/$inventory/$supplierCheckPhone')
  Future<dynamic> checkSupplierPhone(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/suppliers/{id}')
  Future<dynamic> updateSupplier(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$outlets/{outletId}/$inventory/suppliers/{id}')
  Future<dynamic> deleteSupplier(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  @GET('$outlets/{outletId}/$inventory/stock-transactions')
  Future<dynamic> getStockTransactions(
    @Path('outletId') String outletId,
    @Query('rawMaterialId') String? rawMaterialId,
    @Query('type') String? type,
    @Query('page') int? page,
    @Query('limit') int? limit,
  );

  @POST('$outlets/{outletId}/$inventory/stock-transactions')
  Future<dynamic> createStockTransaction(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @GET('$outlets/{outletId}/$inventory/purchase-orders')
  Future<dynamic> getPurchaseOrders(
    @Path('outletId') String outletId,
    @Query('status') String? status,
  );

  @POST('$outlets/{outletId}/$inventory/purchase-orders')
  Future<dynamic> createPurchaseOrder(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/purchase-orders/{id}')
  Future<dynamic> updatePurchaseOrder(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/purchase-orders/{id}/receive')
  Future<dynamic> receivePurchaseOrder(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/purchase-orders/{id}/cancel')
  Future<dynamic> cancelPurchaseOrder(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  @GET('$outlets/{outletId}/$inventory/recipes')
  Future<dynamic> getRecipes(
    @Path('outletId') String outletId,
    @Query('itemId') String? itemId,
  );

  @POST('$outlets/{outletId}/$inventory/recipes')
  Future<dynamic> createRecipe(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('$outlets/{outletId}/$inventory/recipes/{id}')
  Future<dynamic> updateRecipe(
    @Path('outletId') String outletId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('$outlets/{outletId}/$inventory/recipes/{id}')
  Future<dynamic> deleteRecipe(
    @Path('outletId') String outletId,
    @Path('id') String id,
  );

  @GET('$outlets/{outletId}/$inventory/product-stock')
  Future<dynamic> getProductStock(
    @Path('outletId') String outletId,
    @Query('search') String? search,
    @Query('trackedOnly') bool? trackedOnly,
    @Query('lowStockOnly') bool? lowStockOnly,
  );

  @PATCH('$outlets/{outletId}/$inventory/product-stock/{itemId}')
  Future<dynamic> adjustProductStock(
    @Path('outletId') String outletId,
    @Path('itemId') String itemId,
    @Body() Map<String, dynamic> body,
  );

  @GET('$outlets/{outletId}/$inventory/product-stock/{itemId}/movements')
  Future<dynamic> getProductStockMovements(
    @Path('outletId') String outletId,
    @Path('itemId') String itemId,
    @Query('type') String? type,
  );

  // -------------------- STORE DAY SESSIONS --------------------

  @GET('$outlets/{outletId}/$daySessions/current')
  Future<dynamic> getCurrentDaySession(@Path('outletId') String outletId);

  @GET('$outlets/{outletId}/$daySessions')
  Future<dynamic> getDaySessionHistory(
    @Path('outletId') String outletId,
    @Query('startDate') String? startDate,
    @Query('endDate') String? endDate,
  );

  @GET('$outlets/{outletId}/$daySessions/summary')
  Future<dynamic> getDaySessionSummary(@Path('outletId') String outletId);

  @POST('$outlets/{outletId}/$daySessions/open')
  Future<dynamic> openDaySession(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outlets/{outletId}/$daySessions/close')
  Future<dynamic> closeDaySession(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  // -------------------- Wallet --------------------

  @GET(walletCards)
  Future<dynamic> getWalletCards(@Query('active') bool? active);

  @GET('$outlets/{outletId}/wallet')
  Future<dynamic> getOutletWallet(
    @Path('outletId') String outletId,
    @Query('userId') String userId,
  );

  @POST('$outlets/{outletId}/wallet/recharge/create-order')
  Future<dynamic> createWalletRechargeOrder(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outlets/{outletId}/wallet/recharge/confirm')
  Future<dynamic> confirmWalletRecharge(
    @Path('outletId') String outletId,
    @Body() Map<String, dynamic> body,
  );
}

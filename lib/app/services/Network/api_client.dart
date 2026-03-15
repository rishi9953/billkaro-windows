import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/PrinterOrderRequest/printer_order_request.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/businessType/businesst_type_response.dart';
import 'package:billkaro/app/services/Modals/customer/customerRequest.dart';
import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/app/services/Modals/login_modal.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/outlets/outlet_request.dart';
import 'package:billkaro/app/services/Modals/registration_modal.dart';
import 'package:billkaro/app/services/Modals/tables/tables_response.dart';
import 'package:billkaro/app/services/Modals/user/user_response.dart';
import 'package:billkaro/app/services/Network/urls.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: baseURL)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // -------------------- AUTH --------------------

  @POST(register)
  Future<dynamic> registration(@Body() RegistrationModel registrationReqest);

  @POST(login)
  Future<LoginResponse> onLogin(@Body() LoginModel loginRequest);

  @POST(forgotPass)
  Future<dynamic> forgotPassword(@Body() Map<String, dynamic> body);

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

  @GET('$items/outlet/{outletId}')
  Future<ItemResponse> getItems(
    @Path('outletId') String outletId,
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('category') String? category,
    @Query('search') String? search,
    @Query('showItem') bool? showItem,
  );

  @PATCH('$items/{id}')
  Future<dynamic> updateItem(@Body() ItemRequest item, @Path('id') String id);

  @DELETE('$items/{id}')
  Future<dynamic> deleteItem(@Path('id') String id);

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

  // -------------------- Orders --------------------

  @POST(orders)
  Future<dynamic> addOrder(@Body() Map<String, dynamic> orderRequest);

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
  Future<SubscriptionResponse> getSubscription();

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
  Future<dynamic> updateTable(@Path('id') String id);

  @DELETE('$outletTables/{id}')
  Future<dynamic> deleteTable(@Path('id') String id);

  // Update table status (Available/Occupied/Billing/Paid)
  @PATCH('$outletTables/{tableId}/status')
  Future<dynamic> updateTableStatus(
    @Path('tableId') String tableId,
    @Body() Map<String, dynamic> body,
  );

  @POST('$outletTables/reset/{outletId}')
  Future<dynamic> resetAllTable(@Path('outletId') String outletId);

  @POST(printerOrder)

  Future<dynamic> printerOrderRequest(
    @Body() PrinterOrderRequest printerOrderRequest,
  );
}

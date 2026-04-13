import 'package:billkaro/app/modules/AddOrder/AddCategory/add_category_screen.dart';
import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_screen.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_screen.dart';
import 'package:billkaro/app/modules/Address/add_address_screen.dart';
import 'package:billkaro/app/modules/BusinessDetails/business_details_screen.dart';
import 'package:billkaro/app/modules/BusinessOverview/business_overview_screen.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_screen.dart';
import 'package:billkaro/app/modules/Invoice/KOT/kot_preview_screen.dart';
import 'package:billkaro/app/modules/Invoice/invoice_screen.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_screen.dart';
import 'package:billkaro/app/modules/Language/language_screen.dart';
import 'package:billkaro/app/modules/AppSettings/app_settings_screen.dart';
import 'package:billkaro/app/modules/Login/login_screen.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_screen.dart';
import 'package:billkaro/app/modules/Main/main_screen.dart';
import 'package:billkaro/app/modules/Menu/menu_screen.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_screen.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_screen.dart';
import 'package:billkaro/app/modules/Tables/table_screen.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_screen.dart';
import 'package:billkaro/app/modules/Outlets/outlet_screen.dart';
import 'package:billkaro/app/modules/Primary_contact/primary_contact_screen.dart';
import 'package:billkaro/app/modules/Printer/printer_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/customer_list_Screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/customer_tracking_screen.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_screen.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_screen.dart';
import 'package:billkaro/app/modules/Signup/signup_screen.dart';
import 'package:billkaro/app/modules/Staff/add_staff_screen.dart';
import 'package:billkaro/app/modules/Staff/staff_details_screen.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/bulk_Whatsapp_screen.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_screen.dart';
import 'package:billkaro/app/modules/map/map_screen.dart';
import 'package:billkaro/app/modules/splash/splash_binding.dart';
import 'package:billkaro/app/modules/splash/splash_screen.dart';
import 'package:billkaro/app/modules/subscription/Form/subscription_form_controller.dart';
import 'package:billkaro/app/modules/subscription/Form/subscription_form.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_controller.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_screen.dart';
import 'package:billkaro/app/modules/subscription/subscription_screen.dart';
import 'package:get/get.dart';

const transition = Transition.rightToLeft;
const transitionDuration = Duration(milliseconds: 300);

abstract class AppRoute {
  static String get initial => splash;
  static const splash = '/splash';
  static const main = '/main';
  static const register = '/register';
  static const map = '/map';
  static const addAddress = '/addAddress';
  static const primaryContact = '/primaryContact';
  static const login = '/login';
  static const homeMain = '/homeMain';
  static const businessOverView = '/businessOverView';
  static const menu = '/menu';
  static const businessDetails = '/businessDetails';
  static const customerTrackingScreen = '/customerTrackingScreen';
  static const addRegularCustomer = '/addRegularCustomer';
  static const bulkWhatssMessage = '/bulkWhatssMessage';
  static const whatsappMarketing = '/whatsappMarketing';
  static const printerScreen = '/printerScreen';
  static const addMenuItem = '/addMenuItem';
  static const addOrder = '/addOrder';
  static const orderPreferences = '/orderPreferences';
  static const orderReports = '/orderReports';
  static const itemReports = '/itemReports';
  static const changeLanguage = '/changeLanguage';
  static const appSettings = '/appSettings';
  static const staffDetailsScreen = '/staffDetailsScreen';
  static const addStaff = '/addStaff';
  static const holdOrders = '/holdOrders';
  static const closedOrders = '/closedOrders';
  static const pdfPreview = '/pdfPreview';
  static const addCategory = '/addCategory';
  static const regularCustomer = '/regularCustomer';
  static const regularCustomerDetails = '/regularCustomerDetails';
  static const orderDetails = '/orderDetails';
  static const subscriptions = '/subscriptions';
  static const KOTInvoice = '/kotInvoice';
  static const kotHistory = '/kotHistory';
  static const tables = '/tables';
  static const createOutlet = '/createOutlet';
  static const subscriptionReview = '/subscriptionReview';
  static const subscriptionForm = '/subscriptionForm';

  static final pages = <GetPage>[
    GetPage(
      name: AppRoute.splash,
      page: () => SplashScreen(),
      binding: SplashBinding(),
    ),

    GetPage(name: main, page: MainScreen.new, transition: transition),
    GetPage(name: register, page: SignupScreen.new, transition: transition),
    GetPage(
      name: addAddress,
      page: AddAddressScreen.new,
      transition: transition,
    ),
    GetPage(name: map, page: MapScreen.new, transition: transition),
    GetPage(
      name: primaryContact,
      page: PrimaryContactScreen.new,
      transition: transition,
    ),
    GetPage(name: login, page: LoginScreen.new, transition: transition),
    GetPage(name: homeMain, page: HomeMainScreen.new, transition: transition),
    GetPage(
      name: businessOverView,
      page: BusinessOverviewScreen.new,
      transition: transition,
    ),
    GetPage(name: menu, page: MenuScreen.new, transition: transition),
    GetPage(
      name: businessDetails,
      page: BusinessDetailsScreen.new,
      transition: transition,
    ),
    GetPage(
      name: customerTrackingScreen,
      page: CustomerTrackingScreen.new,
      transition: transition,
    ),
    GetPage(
      name: addRegularCustomer,
      page: AddRegularCustomerScreen.new,
      transition: transition,
    ),
    GetPage(
      name: bulkWhatssMessage,
      page: BulkwhatsappScreen.new,
      transition: transition,
    ),
    GetPage(
      name: whatsappMarketing,
      page: WhatsappMarketingScreen.new,
      transition: transition,
    ),
    GetPage(
      name: printerScreen,
      page: PrinterScreen.new,
      transition: transition,
    ),
    GetPage(
      name: addMenuItem,
      page: AddMenuItemScreen.new,
      transition: transition,
    ),
    GetPage(name: addOrder, page: AddOrderScreen.new, transition: transition),
    GetPage(
      name: orderPreferences,
      page: OrderPreferencesScreen.new,
      transition: transition,
    ),
    GetPage(
      name: orderReports,
      page: OrderReportsScreen.new,
      transition: transition,
    ),
    GetPage(
      name: itemReports,
      page: ItemReportsScreen.new,
      transition: transition,
    ),
    GetPage(
      name: changeLanguage,
      page: LanguageScreen.new,
      transition: transition,
    ),
    GetPage(
      name: appSettings,
      page: AppSettingsScreen.new,
      transition: transition,
    ),
    GetPage(
      name: staffDetailsScreen,
      page: StaffDetailsScreen.new,
      transition: transition,
    ),
    GetPage(name: addStaff, page: AddStaffScreen.new, transition: transition),
    GetPage(
      name: holdOrders,
      page: HoldOrdersScreen.new,
      transition: transition,
    ),
    GetPage(
      name: closedOrders,
      page: ClosedOrdersScreen.new,
      transition: transition,
    ),
    GetPage(
      name: pdfPreview,
      page: InvoicePreviewScreen.new,
      transition: transition,
    ),
    GetPage(
      name: addCategory,
      page: AddCategoryScreen.new,
      transition: transition,
    ),
    GetPage(
      name: regularCustomer,
      page: CustomerListScreen.new,
      transition: transition,
    ),

    GetPage(
      name: regularCustomerDetails,
      page: CustomerDetailsScreen.new,
      transition: transition,
    ),
    GetPage(
      name: orderDetails,
      page: OrderDetailsScreen.new,
      transition: transition,
    ),

    GetPage(
      name: subscriptions,
      page: SubscriptionScreen.new,
      transition: transition,
    ),

    GetPage(
      name: KOTInvoice,
      page: ThermalKOTReceipt.new,
      transition: transition,
    ),

    GetPage(
      name: kotHistory,
      page: KotHistoryScreen.new,
      transition: transition,
    ),
    GetPage(name: tables, page: TableScreen.new, transition: transition),
    GetPage(
      name: createOutlet,
      page: CreateOutletScreen.new,
      transition: transition,
    ),
    GetPage(
      name: subscriptionReview,
      page: SubscriptionReviewScreen.new,
      transition: transition,
      binding: BindingsBuilder(() => Get.put(SubscriptionReviewController())),
    ),
    GetPage(
      name: subscriptionForm,
      page: () => SubscriptionFormScreen(),
      transition: transition,
      binding: BindingsBuilder(() => Get.put(SubscriptionFormController())),
    ),
  ];
}

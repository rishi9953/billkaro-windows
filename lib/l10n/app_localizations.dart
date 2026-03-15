import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @closedOrders.
  ///
  /// In en, this message translates to:
  /// **'Closed Orders'**
  String get closedOrders;

  /// No description provided for @onHoldOrders.
  ///
  /// In en, this message translates to:
  /// **'On Hold Orders'**
  String get onHoldOrders;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get addItems;

  /// No description provided for @businessOverview.
  ///
  /// In en, this message translates to:
  /// **'Business Overview'**
  String get businessOverview;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get todaysSales;

  /// No description provided for @todaysOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s orders'**
  String get todaysOrders;

  /// No description provided for @featuresForYou.
  ///
  /// In en, this message translates to:
  /// **'FEATURES FOR YOU'**
  String get featuresForYou;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @select_language_title.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language_title;

  /// No description provided for @choose_preferred_language.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choose_preferred_language;

  /// No description provided for @change_anytime.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime'**
  String get change_anytime;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @language_hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get language_hindi;

  /// No description provided for @addStaffSecurely_title.
  ///
  /// In en, this message translates to:
  /// **'Add Staff Securely'**
  String get addStaffSecurely_title;

  /// No description provided for @addStaffSecurely_desc.
  ///
  /// In en, this message translates to:
  /// **'Add staff with roles;\nbill anywhere;\nstay in sync.'**
  String get addStaffSecurely_desc;

  /// No description provided for @addStaffSecurely_btn.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaffSecurely_btn;

  /// No description provided for @printKOT_title.
  ///
  /// In en, this message translates to:
  /// **'Print KOT'**
  String get printKOT_title;

  /// No description provided for @printKOT_desc.
  ///
  /// In en, this message translates to:
  /// **'Auto-print KOT\nfaster and reduce\nerrors.'**
  String get printKOT_desc;

  /// No description provided for @printKOT_btn.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get printKOT_btn;

  /// No description provided for @yesterdaySales.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s'**
  String get yesterdaySales;

  /// No description provided for @maintain_your_menu_items_effortlessly.
  ///
  /// In en, this message translates to:
  /// **'Maintain your menu items\neffortlessly'**
  String get maintain_your_menu_items_effortlessly;

  /// No description provided for @addMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Menu Item'**
  String get addMenuItem;

  /// No description provided for @scan_Menu_to_Add_Items_via_AI.
  ///
  /// In en, this message translates to:
  /// **'Scan Menu to Add Items via AI'**
  String get scan_Menu_to_Add_Items_via_AI;

  /// No description provided for @feature_scanMenu_title.
  ///
  /// In en, this message translates to:
  /// **'Scan Menu to Add Items'**
  String get feature_scanMenu_title;

  /// No description provided for @feature_scanMenu_desc.
  ///
  /// In en, this message translates to:
  /// **'Scan your menu and let the app create items for you—effortless and quick.'**
  String get feature_scanMenu_desc;

  /// No description provided for @feature_aiImages_title.
  ///
  /// In en, this message translates to:
  /// **'Add Images with AI'**
  String get feature_aiImages_title;

  /// No description provided for @feature_aiImages_desc.
  ///
  /// In en, this message translates to:
  /// **'Enhance your menu with AI-powered images for a professional look.'**
  String get feature_aiImages_desc;

  /// No description provided for @feature_manageFavourites_title.
  ///
  /// In en, this message translates to:
  /// **'Manage favourites & Categories'**
  String get feature_manageFavourites_title;

  /// No description provided for @feature_manageFavourites_desc.
  ///
  /// In en, this message translates to:
  /// **'Automatically get best selling items & organize items through categories for easy access.'**
  String get feature_manageFavourites_desc;

  /// No description provided for @add_images_ai_title.
  ///
  /// In en, this message translates to:
  /// **'Add Images with AI'**
  String get add_images_ai_title;

  /// No description provided for @add_images_ai_description.
  ///
  /// In en, this message translates to:
  /// **'Enhance your menu with AI-powered images for a professional look.'**
  String get add_images_ai_description;

  /// No description provided for @manage_favourites_title.
  ///
  /// In en, this message translates to:
  /// **'Manage favourites & Categories'**
  String get manage_favourites_title;

  /// No description provided for @manage_favourites_description.
  ///
  /// In en, this message translates to:
  /// **'Automatically get best selling items & organize items through categories for easy access.'**
  String get manage_favourites_description;

  /// No description provided for @enter_restaurant_name.
  ///
  /// In en, this message translates to:
  /// **'Enter Restaurant Name'**
  String get enter_restaurant_name;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'+91 9350413656'**
  String get phone_number;

  /// No description provided for @regular_customers.
  ///
  /// In en, this message translates to:
  /// **'Regular Customers'**
  String get regular_customers;

  /// No description provided for @whatsapp_marketing.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Marketing'**
  String get whatsapp_marketing;

  /// No description provided for @sync_devices.
  ///
  /// In en, this message translates to:
  /// **'Sync / Use on other devices'**
  String get sync_devices;

  /// No description provided for @manage_staff.
  ///
  /// In en, this message translates to:
  /// **'Manage Staff'**
  String get manage_staff;

  /// No description provided for @printer.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @buy_table_gold.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Table Gold'**
  String get buy_table_gold;

  /// No description provided for @business_Overview.
  ///
  /// In en, this message translates to:
  /// **'Business Overview'**
  String get business_Overview;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @view_Order_Reports.
  ///
  /// In en, this message translates to:
  /// **'View Order Reports'**
  String get view_Order_Reports;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @lAST_MONTH.
  ///
  /// In en, this message translates to:
  /// **'LAST MONTH'**
  String get lAST_MONTH;

  /// No description provided for @tHIS_MONTH.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH'**
  String get tHIS_MONTH;

  /// No description provided for @most_Selling_Items.
  ///
  /// In en, this message translates to:
  /// **'Most Selling Items'**
  String get most_Selling_Items;

  /// No description provided for @lAST_7_DAYS.
  ///
  /// In en, this message translates to:
  /// **'LAST 7 DAYS'**
  String get lAST_7_DAYS;

  /// No description provided for @lAST_30_DAYS.
  ///
  /// In en, this message translates to:
  /// **'LAST 30 DAYS'**
  String get lAST_30_DAYS;

  /// No description provided for @avg_daily_order.
  ///
  /// In en, this message translates to:
  /// **'avg daily order'**
  String get avg_daily_order;

  /// No description provided for @avg_daily_sale.
  ///
  /// In en, this message translates to:
  /// **'avg daily sale'**
  String get avg_daily_sale;

  /// No description provided for @no_Data_Available.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get no_Data_Available;

  /// No description provided for @you_havent_added_any_orders_yet_Add_an_order_to_see_most_selling_items.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any orders yet.\nAdd an order to see most selling items.'**
  String get you_havent_added_any_orders_yet_Add_an_order_to_see_most_selling_items;

  /// No description provided for @view_Item_Reports.
  ///
  /// In en, this message translates to:
  /// **'View Item Reports'**
  String get view_Item_Reports;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @order_Reports.
  ///
  /// In en, this message translates to:
  /// **'Order Reports'**
  String get order_Reports;

  /// No description provided for @no_Orders_Available.
  ///
  /// In en, this message translates to:
  /// **'No Orders Available'**
  String get no_Orders_Available;

  /// No description provided for @you_havent_added_any_orders_Please_add_an_order_to_see_their_reports.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any orders.\nPlease add an order to see their reports.'**
  String get you_havent_added_any_orders_Please_add_an_order_to_see_their_reports;

  /// No description provided for @add_Order.
  ///
  /// In en, this message translates to:
  /// **'Add Order'**
  String get add_Order;

  /// No description provided for @item_Reports.
  ///
  /// In en, this message translates to:
  /// **'Item Reports'**
  String get item_Reports;

  /// No description provided for @you_havent_added_any_orders_Please_add_an_order_to_see_item_reports.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any orders.\nPlease add an order to see item reports.'**
  String get you_havent_added_any_orders_Please_add_an_order_to_see_item_reports;

  /// No description provided for @add_your_menu_using_photos.
  ///
  /// In en, this message translates to:
  /// **'Add Your\nMenu using\nPhotos'**
  String get add_your_menu_using_photos;

  /// No description provided for @save_and_hold.
  ///
  /// In en, this message translates to:
  /// **'Save & Hold'**
  String get save_and_hold;

  /// No description provided for @save_and_bill.
  ///
  /// In en, this message translates to:
  /// **'Save & Bill'**
  String get save_and_bill;

  /// No description provided for @quick_add_item.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Item'**
  String get quick_add_item;

  /// No description provided for @item_name.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get item_name;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @dine_in.
  ///
  /// In en, this message translates to:
  /// **'Dine In'**
  String get dine_in;

  /// No description provided for @swiggy.
  ///
  /// In en, this message translates to:
  /// **'Swiggy'**
  String get swiggy;

  /// No description provided for @takeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get takeaway;

  /// No description provided for @zomato.
  ///
  /// In en, this message translates to:
  /// **'Zomato'**
  String get zomato;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @manage_your_loyal_customers.
  ///
  /// In en, this message translates to:
  /// **'Manage your loyal customers'**
  String get manage_your_loyal_customers;

  /// No description provided for @send_bulk_messages.
  ///
  /// In en, this message translates to:
  /// **'Send bulk messages'**
  String get send_bulk_messages;

  /// No description provided for @sync_across_multiple_devices.
  ///
  /// In en, this message translates to:
  /// **'Sync across multiple devices'**
  String get sync_across_multiple_devices;

  /// No description provided for @add_and_manage_staff_members.
  ///
  /// In en, this message translates to:
  /// **'Add and manage staff members'**
  String get add_and_manage_staff_members;

  /// No description provided for @configure_printer_settings.
  ///
  /// In en, this message translates to:
  /// **'Configure printer settings'**
  String get configure_printer_settings;

  /// No description provided for @change_app_language.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get change_app_language;

  /// No description provided for @support_and_account.
  ///
  /// In en, this message translates to:
  /// **'Support & Account'**
  String get support_and_account;

  /// No description provided for @get_help_and_support.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get get_help_and_support;

  /// No description provided for @sign_out_of_your_account.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get sign_out_of_your_account;

  /// No description provided for @unlock_premium_features.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features'**
  String get unlock_premium_features;

  /// No description provided for @are_you_sure_you_want_to_logout_from_your_account.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get are_you_sure_you_want_to_logout_from_your_account;

  /// No description provided for @keep_track_of_your_best_customers.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your best\ncustomers'**
  String get keep_track_of_your_best_customers;

  /// No description provided for @whatsapp_marketing_and_offers.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Marketing and Offers'**
  String get whatsapp_marketing_and_offers;

  /// No description provided for @engage_customers_whatsapp_customised_offers.
  ///
  /// In en, this message translates to:
  /// **'Engage your customers via WhatsApp with customised offers and promotions'**
  String get engage_customers_whatsapp_customised_offers;

  /// No description provided for @loyalty_discounts.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Discounts'**
  String get loyalty_discounts;

  /// No description provided for @boost_repeat_business_loyalty_discount.
  ///
  /// In en, this message translates to:
  /// **'Boost repeat business with loyalty discounts that keep customers returning'**
  String get boost_repeat_business_loyalty_discount;

  /// No description provided for @business_insights_and_growth.
  ///
  /// In en, this message translates to:
  /// **'Business Insights and Growth'**
  String get business_insights_and_growth;

  /// No description provided for @unlock_powerful_insights_smart_decisions.
  ///
  /// In en, this message translates to:
  /// **'Unlock powerful insights to drive smarter decisions and accelerate growth.'**
  String get unlock_powerful_insights_smart_decisions;

  /// No description provided for @add_regular_customer.
  ///
  /// In en, this message translates to:
  /// **'Add Regular Customer'**
  String get add_regular_customer;

  /// No description provided for @send_bulk_whatsapp_to_all_your_visitors.
  ///
  /// In en, this message translates to:
  /// **'Send bulk Whatsapp to all\nyour visitors'**
  String get send_bulk_whatsapp_to_all_your_visitors;

  /// No description provided for @greeting_offers_new_launches.
  ///
  /// In en, this message translates to:
  /// **'Greeting, offers & New Launches'**
  String get greeting_offers_new_launches;

  /// No description provided for @send_messages_about_greetings_offers_new_launches.
  ///
  /// In en, this message translates to:
  /// **'Send messages about greetings, offers and new launches to your visitors with our pre-approved templates.'**
  String get send_messages_about_greetings_offers_new_launches;

  /// No description provided for @boost_repeat_business.
  ///
  /// In en, this message translates to:
  /// **'Boost Repeat Business'**
  String get boost_repeat_business;

  /// No description provided for @get_visitors_back_targeted_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'Get visitors back to your restaurant with targeted WhatsApp messages.'**
  String get get_visitors_back_targeted_whatsapp;

  /// No description provided for @send_bulk_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send Bulk WhatsApp'**
  String get send_bulk_whatsapp;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get usb;

  /// No description provided for @paired_devices.
  ///
  /// In en, this message translates to:
  /// **'Paired Devices'**
  String get paired_devices;

  /// No description provided for @no_new_devices_found.
  ///
  /// In en, this message translates to:
  /// **'No new devices found'**
  String get no_new_devices_found;

  /// No description provided for @scanning_for_devices.
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices'**
  String get scanning_for_devices;

  /// No description provided for @unknown_device.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get unknown_device;

  /// No description provided for @scan_for_new_devices.
  ///
  /// In en, this message translates to:
  /// **'Scan for New Devices'**
  String get scan_for_new_devices;

  /// No description provided for @usb_device_not_connected.
  ///
  /// In en, this message translates to:
  /// **'USB device not connected'**
  String get usb_device_not_connected;

  /// No description provided for @usb_device_not_found_message.
  ///
  /// In en, this message translates to:
  /// **'We could not find any USB device.\nPlease check the cable connection or try reconnecting.'**
  String get usb_device_not_found_message;

  /// No description provided for @get_support.
  ///
  /// In en, this message translates to:
  /// **'Get Support'**
  String get get_support;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @support_request.
  ///
  /// In en, this message translates to:
  /// **'Support Request'**
  String get support_request;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @tap_to_enter.
  ///
  /// In en, this message translates to:
  /// **'Tap to Enter'**
  String get tap_to_enter;

  /// No description provided for @item_image.
  ///
  /// In en, this message translates to:
  /// **'Item Image'**
  String get item_image;

  /// No description provided for @upload_item_image.
  ///
  /// In en, this message translates to:
  /// **'Upload Item Image'**
  String get upload_item_image;

  /// No description provided for @item_category.
  ///
  /// In en, this message translates to:
  /// **'Item Category'**
  String get item_category;

  /// No description provided for @sale_price.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get sale_price;

  /// No description provided for @with_tax.
  ///
  /// In en, this message translates to:
  /// **'With Tax'**
  String get with_tax;

  /// No description provided for @without_tax.
  ///
  /// In en, this message translates to:
  /// **'Without Tax'**
  String get without_tax;

  /// No description provided for @tax_percentage.
  ///
  /// In en, this message translates to:
  /// **'Tax Percentage'**
  String get tax_percentage;

  /// No description provided for @make_this_items_tax_the_default_firm_tax.
  ///
  /// In en, this message translates to:
  /// **'Make this item\'s tax the default firm tax'**
  String get make_this_items_tax_the_default_firm_tax;

  /// No description provided for @mark_this_item_as_favourite.
  ///
  /// In en, this message translates to:
  /// **'Mark this item as favourite'**
  String get mark_this_item_as_favourite;

  /// No description provided for @save_and_new.
  ///
  /// In en, this message translates to:
  /// **'Save & New'**
  String get save_and_new;

  /// No description provided for @save_item.
  ///
  /// In en, this message translates to:
  /// **'Save Item'**
  String get save_item;

  /// No description provided for @business_details.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get business_details;

  /// No description provided for @business_name.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get business_name;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @upload_business_logo.
  ///
  /// In en, this message translates to:
  /// **'Upload Business Logo'**
  String get upload_business_logo;

  /// No description provided for @outlet_address.
  ///
  /// In en, this message translates to:
  /// **'Outlet Address'**
  String get outlet_address;

  /// No description provided for @upi_id.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upi_id;

  /// No description provided for @this_will_be_used_to_print_qr_on_bills.
  ///
  /// In en, this message translates to:
  /// **'This will be used to print QR on bills'**
  String get this_will_be_used_to_print_qr_on_bills;

  /// No description provided for @custom_footer_message_on_bills.
  ///
  /// In en, this message translates to:
  /// **'Custom Footer Message on Bills'**
  String get custom_footer_message_on_bills;

  /// No description provided for @fssai_number.
  ///
  /// In en, this message translates to:
  /// **'FSSAI Number'**
  String get fssai_number;

  /// No description provided for @tax_slab.
  ///
  /// In en, this message translates to:
  /// **'Tax Slab'**
  String get tax_slab;

  /// No description provided for @seating_capacity.
  ///
  /// In en, this message translates to:
  /// **'Seating Capacity'**
  String get seating_capacity;

  /// No description provided for @business_type.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get business_type;

  /// No description provided for @business_category_question.
  ///
  /// In en, this message translates to:
  /// **'What is your business category?'**
  String get business_category_question;

  /// No description provided for @gstin_number.
  ///
  /// In en, this message translates to:
  /// **'GSTIN Number'**
  String get gstin_number;

  /// No description provided for @business_address.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get business_address;

  /// No description provided for @google_profile_link.
  ///
  /// In en, this message translates to:
  /// **'Google Profile Link'**
  String get google_profile_link;

  /// No description provided for @swiggy_link.
  ///
  /// In en, this message translates to:
  /// **'Swiggy Link'**
  String get swiggy_link;

  /// No description provided for @zomato_link.
  ///
  /// In en, this message translates to:
  /// **'Zomato Link'**
  String get zomato_link;

  /// No description provided for @delete_outlet.
  ///
  /// In en, this message translates to:
  /// **'Delete Outlet'**
  String get delete_outlet;

  /// No description provided for @update_details.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get update_details;

  /// No description provided for @tap_to_select.
  ///
  /// In en, this message translates to:
  /// **'Tap to Select'**
  String get tap_to_select;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @order_preferences.
  ///
  /// In en, this message translates to:
  /// **'Order Preferences'**
  String get order_preferences;

  /// No description provided for @how_does_this_work.
  ///
  /// In en, this message translates to:
  /// **'HOW DOES THIS WORK?'**
  String get how_does_this_work;

  /// No description provided for @payment_modes.
  ///
  /// In en, this message translates to:
  /// **'Payment modes'**
  String get payment_modes;

  /// No description provided for @quickly_choose_payment_mode.
  ///
  /// In en, this message translates to:
  /// **'Quickly choose payment mode while creating an order'**
  String get quickly_choose_payment_mode;

  /// No description provided for @kot_mode.
  ///
  /// In en, this message translates to:
  /// **'KOT Mode'**
  String get kot_mode;

  /// No description provided for @choose_your_language.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get choose_your_language;

  /// No description provided for @select_preferred_language_for_app.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for the app'**
  String get select_preferred_language_for_app;

  /// No description provided for @work_smarter_together.
  ///
  /// In en, this message translates to:
  /// **'Work Smarter, Together\nFrom Any Device'**
  String get work_smarter_together;

  /// No description provided for @access_anytime_anywhere.
  ///
  /// In en, this message translates to:
  /// **'Access Anytime, Anywhere'**
  String get access_anytime_anywhere;

  /// No description provided for @your_outlet_always_with_you.
  ///
  /// In en, this message translates to:
  /// **'Your outlet is always with you — sync once and manage billing from any device.'**
  String get your_outlet_always_with_you;

  /// No description provided for @add_staff_share_work.
  ///
  /// In en, this message translates to:
  /// **'Add Staff, Share Work'**
  String get add_staff_share_work;

  /// No description provided for @let_team_take_orders.
  ///
  /// In en, this message translates to:
  /// **'Let your team take orders, print bills, and collect payments from their own devices — no more crowding at the counter.'**
  String get let_team_take_orders;

  /// No description provided for @safe_cloud_data.
  ///
  /// In en, this message translates to:
  /// **'Safe, Cloud-Backed Data'**
  String get safe_cloud_data;

  /// No description provided for @even_if_phone_lost.
  ///
  /// In en, this message translates to:
  /// **'Even if your phone is lost or damaged, your data stays protected in the cloud — always up to date, always recoverable.'**
  String get even_if_phone_lost;

  /// No description provided for @invite_staff.
  ///
  /// In en, this message translates to:
  /// **'Invite Staff'**
  String get invite_staff;

  /// No description provided for @add_staff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get add_staff;

  /// No description provided for @user_name.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get user_name;

  /// No description provided for @user_phone_number.
  ///
  /// In en, this message translates to:
  /// **'User Phone Number'**
  String get user_phone_number;

  /// No description provided for @user_role.
  ///
  /// In en, this message translates to:
  /// **'User Role'**
  String get user_role;

  /// No description provided for @secondary_admin.
  ///
  /// In en, this message translates to:
  /// **'Secondary Admin'**
  String get secondary_admin;

  /// No description provided for @biller.
  ///
  /// In en, this message translates to:
  /// **'Biller'**
  String get biller;

  /// No description provided for @staff_access_info.
  ///
  /// In en, this message translates to:
  /// **'Staff can access everything except sync settings and WhatsApp templates.'**
  String get staff_access_info;

  /// No description provided for @send_invite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get send_invite;

  /// No description provided for @welcome_to_billkaro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BillKaro\n Chill Karo'**
  String get welcome_to_billkaro;

  /// No description provided for @manage_business_ease.
  ///
  /// In en, this message translates to:
  /// **'Manage your business with ease'**
  String get manage_business_ease;

  /// No description provided for @register_new_business.
  ///
  /// In en, this message translates to:
  /// **'Register a new business'**
  String get register_new_business;

  /// No description provided for @already_registered.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get already_registered;

  /// No description provided for @business_registration.
  ///
  /// In en, this message translates to:
  /// **'Business Registration'**
  String get business_registration;

  /// No description provided for @enter_business_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get enter_business_name;

  /// No description provided for @brand_name.
  ///
  /// In en, this message translates to:
  /// **'Brand Name'**
  String get brand_name;

  /// No description provided for @enter_brand_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your brand name'**
  String get enter_brand_name;

  /// No description provided for @enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enter_email;

  /// No description provided for @activation_details_sent.
  ///
  /// In en, this message translates to:
  /// **'Activation details will be sent to the email address'**
  String get activation_details_sent;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter your Password'**
  String get enter_password;

  /// No description provided for @enter_business_address.
  ///
  /// In en, this message translates to:
  /// **'Specify address for your business'**
  String get enter_business_address;

  /// No description provided for @primary_contact.
  ///
  /// In en, this message translates to:
  /// **'Primary Contact'**
  String get primary_contact;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @specify_primary_contact.
  ///
  /// In en, this message translates to:
  /// **'Specify primary contact for your business'**
  String get specify_primary_contact;

  /// No description provided for @payment_successful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get payment_successful;

  /// No description provided for @payment_successful_description.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been activated successfully!'**
  String get payment_successful_description;

  /// No description provided for @payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get payment_failed;

  /// No description provided for @payment_failed_description.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed. Please try again.'**
  String get payment_failed_description;

  /// No description provided for @wallet_selected.
  ///
  /// In en, this message translates to:
  /// **'You have selected {walletName}'**
  String wallet_selected(String walletName);

  /// No description provided for @payment_gateway_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to open payment gateway. Please try again.'**
  String get payment_gateway_error;

  /// No description provided for @bill_number.
  ///
  /// In en, this message translates to:
  /// **'Bill Number'**
  String get bill_number;

  /// No description provided for @bill_number_required.
  ///
  /// In en, this message translates to:
  /// **'Bill number is required'**
  String get bill_number_required;

  /// No description provided for @bill_number_invalid.
  ///
  /// In en, this message translates to:
  /// **'Bill number must be a valid integer'**
  String get bill_number_invalid;

  /// No description provided for @bill_number_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Bill number {billNumber} already exists. Please use a different bill number.'**
  String bill_number_duplicate(String billNumber);

  /// No description provided for @failed_to_load_orders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failed_to_load_orders;

  /// No description provided for @no_outlet_selected.
  ///
  /// In en, this message translates to:
  /// **'No outlet selected'**
  String get no_outlet_selected;

  /// No description provided for @order_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get order_details;

  /// No description provided for @add_details.
  ///
  /// In en, this message translates to:
  /// **'Add Details'**
  String get add_details;

  /// No description provided for @order_summary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get order_summary;

  /// No description provided for @item_selected.
  ///
  /// In en, this message translates to:
  /// **'Item Selected'**
  String get item_selected;

  /// No description provided for @items_selected.
  ///
  /// In en, this message translates to:
  /// **'Items Selected'**
  String get items_selected;

  /// No description provided for @total_quantity.
  ///
  /// In en, this message translates to:
  /// **'Total Qty'**
  String get total_quantity;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total_amount;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get all;

  /// No description provided for @none_category.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none_category;

  /// No description provided for @kot_and_hold.
  ///
  /// In en, this message translates to:
  /// **'KOT & Hold'**
  String get kot_and_hold;

  /// No description provided for @kot_and_bill.
  ///
  /// In en, this message translates to:
  /// **'KOT & Bill'**
  String get kot_and_bill;

  /// No description provided for @order_saved.
  ///
  /// In en, this message translates to:
  /// **'Order saved'**
  String get order_saved;

  /// No description provided for @order_saved_offline.
  ///
  /// In en, this message translates to:
  /// **'Order saved offline'**
  String get order_saved_offline;

  /// No description provided for @order_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get order_created_successfully;

  /// No description provided for @order_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully'**
  String get order_updated_successfully;

  /// No description provided for @order_failed.
  ///
  /// In en, this message translates to:
  /// **'Order failed'**
  String get order_failed;

  /// No description provided for @failed_to_save_order_offline.
  ///
  /// In en, this message translates to:
  /// **'Failed to save order offline'**
  String get failed_to_save_order_offline;

  /// No description provided for @add_items.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get add_items;

  /// No description provided for @purchasing_plan.
  ///
  /// In en, this message translates to:
  /// **'Purchasing {plan} plan...'**
  String purchasing_plan(String plan);

  /// No description provided for @sync_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Sync already in progress'**
  String get sync_in_progress;

  /// No description provided for @internet_connection_restored.
  ///
  /// In en, this message translates to:
  /// **'Internet connection restored'**
  String get internet_connection_restored;

  /// No description provided for @internet_connection_lost.
  ///
  /// In en, this message translates to:
  /// **'Internet connection lost'**
  String get internet_connection_lost;

  /// No description provided for @sync_task_scheduled.
  ///
  /// In en, this message translates to:
  /// **'Sync task scheduled'**
  String get sync_task_scheduled;

  /// No description provided for @sync_completed.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get sync_completed;

  /// No description provided for @sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get sync_failed;

  /// No description provided for @retrying_sync.
  ///
  /// In en, this message translates to:
  /// **'Retrying sync after failure...'**
  String get retrying_sync;

  /// No description provided for @all_sync_operations_cancelled.
  ///
  /// In en, this message translates to:
  /// **'All sync operations cancelled'**
  String get all_sync_operations_cancelled;

  /// No description provided for @please_enter_item_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter item name'**
  String get please_enter_item_name;

  /// No description provided for @please_enter_valid_sale_price.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid sale price'**
  String get please_enter_valid_sale_price;

  /// No description provided for @item_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Item added successfully'**
  String get item_added_successfully;

  /// No description provided for @failed_to_add_item.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item'**
  String get failed_to_add_item;

  /// No description provided for @please_add_items_to_order.
  ///
  /// In en, this message translates to:
  /// **'Please add items to the order'**
  String get please_add_items_to_order;

  /// No description provided for @please_add_details_to_order.
  ///
  /// In en, this message translates to:
  /// **'Please add details to the order'**
  String get please_add_details_to_order;

  /// No description provided for @save_remark.
  ///
  /// In en, this message translates to:
  /// **'Save Remark'**
  String get save_remark;

  /// No description provided for @print_kot.
  ///
  /// In en, this message translates to:
  /// **'Print KOT'**
  String get print_kot;

  /// No description provided for @print_bill.
  ///
  /// In en, this message translates to:
  /// **'Print Bill'**
  String get print_bill;

  /// No description provided for @table_number.
  ///
  /// In en, this message translates to:
  /// **'Table Number'**
  String get table_number;

  /// No description provided for @customer_name.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customer_name;

  /// No description provided for @phone_number_field.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number_field;

  /// No description provided for @service_charge.
  ///
  /// In en, this message translates to:
  /// **'Service Charge'**
  String get service_charge;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @payment_received_in.
  ///
  /// In en, this message translates to:
  /// **'Payment Received In'**
  String get payment_received_in;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @save_order_details.
  ///
  /// In en, this message translates to:
  /// **'Save Order Details'**
  String get save_order_details;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enter_valid_10_digit_number.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit number'**
  String get enter_valid_10_digit_number;

  /// No description provided for @enter_discount.
  ///
  /// In en, this message translates to:
  /// **'Enter discount'**
  String get enter_discount;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @email_support.
  ///
  /// In en, this message translates to:
  /// **'Email (support@billkro.com)'**
  String get email_support;

  /// No description provided for @enter_table_number.
  ///
  /// In en, this message translates to:
  /// **'Enter Table Number'**
  String get enter_table_number;

  /// No description provided for @enter_customer_name.
  ///
  /// In en, this message translates to:
  /// **'Enter Customer Name'**
  String get enter_customer_name;

  /// No description provided for @enter_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get enter_phone_number;

  /// No description provided for @enter_service_charge.
  ///
  /// In en, this message translates to:
  /// **'Enter Service Charge'**
  String get enter_service_charge;

  /// No description provided for @enter_bill_number.
  ///
  /// In en, this message translates to:
  /// **'Enter Bill Number'**
  String get enter_bill_number;

  /// No description provided for @menu_items.
  ///
  /// In en, this message translates to:
  /// **'Menu Items'**
  String get menu_items;

  /// No description provided for @search_items.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get search_items;

  /// No description provided for @failed_to_load_items.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get failed_to_load_items;

  /// No description provided for @edit_menu_item.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get edit_menu_item;

  /// No description provided for @edit_category.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get edit_category;

  /// No description provided for @add_category.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get add_category;

  /// No description provided for @category_name.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_name;

  /// No description provided for @enter_category_name.
  ///
  /// In en, this message translates to:
  /// **'Enter the category name'**
  String get enter_category_name;

  /// No description provided for @items_shown_by_category.
  ///
  /// In en, this message translates to:
  /// **'Items are shown by category while entering order.'**
  String get items_shown_by_category;

  /// No description provided for @all_categories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get all_categories;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @update_category.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get update_category;

  /// No description provided for @category_name_cannot_be_empty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get category_name_cannot_be_empty;

  /// No description provided for @category_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully'**
  String get category_added_successfully;

  /// No description provided for @failed_to_add_category.
  ///
  /// In en, this message translates to:
  /// **'Failed to add category'**
  String get failed_to_add_category;

  /// No description provided for @error_adding_category.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while adding category'**
  String get error_adding_category;

  /// No description provided for @failed_to_load_categories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failed_to_load_categories;

  /// No description provided for @invalid_category_selection.
  ///
  /// In en, this message translates to:
  /// **'Invalid category selection'**
  String get invalid_category_selection;

  /// No description provided for @category_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully'**
  String get category_deleted_successfully;

  /// No description provided for @failed_to_delete_category.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get failed_to_delete_category;

  /// No description provided for @error_deleting_category.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting category'**
  String get error_deleting_category;

  /// No description provided for @category_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully'**
  String get category_updated_successfully;

  /// No description provided for @failed_to_update_category.
  ///
  /// In en, this message translates to:
  /// **'Failed to update category'**
  String get failed_to_update_category;

  /// No description provided for @error_updating_category.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while updating category'**
  String get error_updating_category;

  /// No description provided for @invalid_date.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get invalid_date;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get select_date;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @order_from.
  ///
  /// In en, this message translates to:
  /// **'Order From'**
  String get order_from;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @no_of_txns.
  ///
  /// In en, this message translates to:
  /// **'No of Txns'**
  String get no_of_txns;

  /// No description provided for @total_sale.
  ///
  /// In en, this message translates to:
  /// **'Total Sale'**
  String get total_sale;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get this_week;

  /// No description provided for @this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get this_month;

  /// No description provided for @this_quarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get this_quarter;

  /// No description provided for @this_year.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get this_year;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @phonepe.
  ///
  /// In en, this message translates to:
  /// **'PhonePe'**
  String get phonepe;

  /// No description provided for @googlepay.
  ///
  /// In en, this message translates to:
  /// **'GooglePay'**
  String get googlepay;

  /// No description provided for @customer_filter_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Customer filter coming soon'**
  String get customer_filter_coming_soon;

  /// No description provided for @delete_order.
  ///
  /// In en, this message translates to:
  /// **'Delete Order'**
  String get delete_order;

  /// No description provided for @are_you_sure_delete_order.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this order?'**
  String get are_you_sure_delete_order;

  /// No description provided for @order_removed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Order removed successfully'**
  String get order_removed_successfully;

  /// No description provided for @no_orders_to_export.
  ///
  /// In en, this message translates to:
  /// **'No orders to export'**
  String get no_orders_to_export;

  /// No description provided for @orders_report.
  ///
  /// In en, this message translates to:
  /// **'Orders Report'**
  String get orders_report;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @order_type.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get order_type;

  /// No description provided for @payment_type.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get payment_type;

  /// No description provided for @order_id.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get order_id;

  /// No description provided for @date_time.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get date_time;

  /// No description provided for @customer_id.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customer_id;

  /// No description provided for @customer_phone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customer_phone;

  /// No description provided for @service_charge_rupee.
  ///
  /// In en, this message translates to:
  /// **'Service Charge (₹)'**
  String get service_charge_rupee;

  /// No description provided for @payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payment_method;

  /// No description provided for @amount_rupee.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amount_rupee;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @total_transactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get total_transactions;

  /// No description provided for @total_sales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get total_sales;

  /// No description provided for @orders_report_generated.
  ///
  /// In en, this message translates to:
  /// **'Orders Report - Generated on {date}'**
  String orders_report_generated(String date);

  /// No description provided for @failed_to_generate_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF'**
  String get failed_to_generate_pdf;

  /// No description provided for @orders_report_pdf.
  ///
  /// In en, this message translates to:
  /// **'Orders Report PDF'**
  String get orders_report_pdf;

  /// No description provided for @choose_an_option.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get choose_an_option;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pdf_saved_to_downloads.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to Downloads'**
  String get pdf_saved_to_downloads;

  /// No description provided for @failed_to_save_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PDF'**
  String get failed_to_save_pdf;

  /// No description provided for @failed_to_share_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to share PDF'**
  String get failed_to_share_pdf;

  /// No description provided for @pdf_opened_successfully.
  ///
  /// In en, this message translates to:
  /// **'PDF opened successfully'**
  String get pdf_opened_successfully;

  /// No description provided for @no_app_found_to_open_pdf.
  ///
  /// In en, this message translates to:
  /// **'No app found to open PDF'**
  String get no_app_found_to_open_pdf;

  /// No description provided for @failed_to_open_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to open PDF'**
  String get failed_to_open_pdf;

  /// No description provided for @failed_to_print_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to print PDF'**
  String get failed_to_print_pdf;

  /// No description provided for @excel_saved_to_downloads.
  ///
  /// In en, this message translates to:
  /// **'Excel saved to Downloads'**
  String get excel_saved_to_downloads;

  /// No description provided for @failed_to_export.
  ///
  /// In en, this message translates to:
  /// **'Failed to export'**
  String get failed_to_export;

  /// No description provided for @orders_report_exported.
  ///
  /// In en, this message translates to:
  /// **'Orders Report Exported'**
  String get orders_report_exported;

  /// No description provided for @printed_order.
  ///
  /// In en, this message translates to:
  /// **'Printed order {orderId}'**
  String printed_order(String orderId);

  /// No description provided for @shared_order.
  ///
  /// In en, this message translates to:
  /// **'Shared order {orderId}'**
  String shared_order(String orderId);

  /// No description provided for @order_quantity.
  ///
  /// In en, this message translates to:
  /// **'Order Quantity'**
  String get order_quantity;

  /// No description provided for @order_amount.
  ///
  /// In en, this message translates to:
  /// **'Order Amount'**
  String get order_amount;

  /// No description provided for @unknown_item.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknown_item;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @no_items_to_export.
  ///
  /// In en, this message translates to:
  /// **'No items to export'**
  String get no_items_to_export;

  /// No description provided for @storage_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Storage permission needed to save Excel file'**
  String get storage_permission_needed;

  /// No description provided for @item_reports.
  ///
  /// In en, this message translates to:
  /// **'Item Reports'**
  String get item_reports;

  /// No description provided for @item_reports_exported.
  ///
  /// In en, this message translates to:
  /// **'Item Reports Exported'**
  String get item_reports_exported;

  /// No description provided for @item_reports_pdf.
  ///
  /// In en, this message translates to:
  /// **'Item Reports PDF'**
  String get item_reports_pdf;

  /// No description provided for @item_reports_generated.
  ///
  /// In en, this message translates to:
  /// **'Item Reports - Generated on {date}'**
  String item_reports_generated(String date);

  /// No description provided for @total_items.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get total_items;

  /// No description provided for @contact_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Contact permission is needed to fetch contacts'**
  String get contact_permission_needed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

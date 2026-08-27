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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
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

  /// No description provided for @item_image_ai_chat_assistant.
  ///
  /// In en, this message translates to:
  /// **'BillKaro AI'**
  String get item_image_ai_chat_assistant;

  /// No description provided for @item_image_ai_chat_message.
  ///
  /// In en, this message translates to:
  /// **'AI creates a professional food photo for your menu item. You can use it on your menu or replace it anytime by uploading your own photo from gallery or camera.'**
  String get item_image_ai_chat_message;

  /// No description provided for @generate_image.
  ///
  /// In en, this message translates to:
  /// **'Generate Image'**
  String get generate_image;

  /// No description provided for @describe_image_for_ai.
  ///
  /// In en, this message translates to:
  /// **'Describe the image'**
  String get describe_image_for_ai;

  /// No description provided for @describe_image_for_ai_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Butter chicken in a copper bowl with naan on the side'**
  String get describe_image_for_ai_hint;

  /// No description provided for @please_describe_image_for_ai.
  ///
  /// In en, this message translates to:
  /// **'Please describe the image you want to generate'**
  String get please_describe_image_for_ai;

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
  String
  get you_havent_added_any_orders_yet_Add_an_order_to_see_most_selling_items;

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
  String
  get you_havent_added_any_orders_Please_add_an_order_to_see_their_reports;

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
  String
  get you_havent_added_any_orders_Please_add_an_order_to_see_item_reports;

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
  /// **'Unknown device'**
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
  /// **'Secondary Admin has full access to all outlet features and permissions.'**
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
  /// **'Sales'**
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

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Business Dashboard'**
  String get dashboardOverview;

  /// No description provided for @dashboardOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track sales, payments and insights at a glance'**
  String get dashboardOverviewSubtitle;

  /// No description provided for @quickInsights.
  ///
  /// In en, this message translates to:
  /// **'Quick Insights'**
  String get quickInsights;

  /// No description provided for @please_select_outlet_first.
  ///
  /// In en, this message translates to:
  /// **'Please select an outlet first'**
  String get please_select_outlet_first;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @no_new_items_to_send_to_kitchen.
  ///
  /// In en, this message translates to:
  /// **'No new items to send to kitchen'**
  String get no_new_items_to_send_to_kitchen;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @no_printer_connected.
  ///
  /// In en, this message translates to:
  /// **'No printer connected'**
  String get no_printer_connected;

  /// No description provided for @use_current_filter.
  ///
  /// In en, this message translates to:
  /// **'Use current filter'**
  String get use_current_filter;

  /// No description provided for @choose_date_range.
  ///
  /// In en, this message translates to:
  /// **'Choose date range'**
  String get choose_date_range;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @saved_printer_removed.
  ///
  /// In en, this message translates to:
  /// **'Saved printer removed'**
  String get saved_printer_removed;

  /// No description provided for @remove_saved_printer_title.
  ///
  /// In en, this message translates to:
  /// **'Remove Saved Printer?'**
  String get remove_saved_printer_title;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @please_enter_order_details.
  ///
  /// In en, this message translates to:
  /// **'Please enter the order details'**
  String get please_enter_order_details;

  /// No description provided for @please_select_table_for_dine_in.
  ///
  /// In en, this message translates to:
  /// **'Please select a table for Dine In order'**
  String get please_select_table_for_dine_in;

  /// No description provided for @failed_to_share_pdf_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to share PDF: {error}'**
  String failed_to_share_pdf_error(String error);

  /// No description provided for @pdf_generation_failed_empty.
  ///
  /// In en, this message translates to:
  /// **'PDF generation failed - empty document'**
  String get pdf_generation_failed_empty;

  /// No description provided for @failed_to_pick_image.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failed_to_pick_image(String error);

  /// No description provided for @failed_to_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect: {error}'**
  String failed_to_disconnect(String error);

  /// No description provided for @form_not_initialized.
  ///
  /// In en, this message translates to:
  /// **'Form not initialized. Please try again.'**
  String get form_not_initialized;

  /// No description provided for @please_enter_user_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter user name'**
  String get please_enter_user_name;

  /// No description provided for @please_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get please_enter_email;

  /// No description provided for @please_enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get please_enter_valid_email;

  /// No description provided for @please_enter_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get please_enter_phone_number;

  /// No description provided for @please_enter_valid_10_digit_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get please_enter_valid_10_digit_phone;

  /// No description provided for @failed_to_send_messages.
  ///
  /// In en, this message translates to:
  /// **'Failed to send messages: {error}'**
  String failed_to_send_messages(String error);

  /// No description provided for @please_enter_valid_10_digit_phone_alt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10 digit phone number'**
  String get please_enter_valid_10_digit_phone_alt;

  /// No description provided for @add_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get add_payment_method;

  /// No description provided for @could_not_open_kitchen_display.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser for Kitchen Display'**
  String get could_not_open_kitchen_display;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @failed_to_capture_image.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture image: {error}'**
  String failed_to_capture_image(String error);

  /// No description provided for @please_enter_table_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter table number'**
  String get please_enter_table_number;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @please_log_in_again.
  ///
  /// In en, this message translates to:
  /// **'Please log in again'**
  String get please_log_in_again;

  /// No description provided for @could_not_open_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get could_not_open_whatsapp;

  /// No description provided for @discard_order_title.
  ///
  /// In en, this message translates to:
  /// **'Discard order?'**
  String get discard_order_title;

  /// No description provided for @close_app.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get close_app;

  /// No description provided for @continue_action.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_action;

  /// No description provided for @auto_bluetooth_printer.
  ///
  /// In en, this message translates to:
  /// **'Auto Bluetooth Printer'**
  String get auto_bluetooth_printer;

  /// No description provided for @print_test_receipt.
  ///
  /// In en, this message translates to:
  /// **'PRINT TEST RECEIPT'**
  String get print_test_receipt;

  /// No description provided for @disconnect_printer_title.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Printer?'**
  String get disconnect_printer_title;

  /// No description provided for @use_same_as_bill_printer.
  ///
  /// In en, this message translates to:
  /// **'Use same as Bill printer'**
  String get use_same_as_bill_printer;

  /// No description provided for @table_already_has_active_order.
  ///
  /// In en, this message translates to:
  /// **'This table already has an active order'**
  String get table_already_has_active_order;

  /// No description provided for @kot_sent_continue_adding_items.
  ///
  /// In en, this message translates to:
  /// **'KOT sent — continue adding items'**
  String get kot_sent_continue_adding_items;

  /// No description provided for @kot_sent_offline_continue_adding_items.
  ///
  /// In en, this message translates to:
  /// **'KOT sent (offline) — continue adding items'**
  String get kot_sent_offline_continue_adding_items;

  /// No description provided for @settle_bill.
  ///
  /// In en, this message translates to:
  /// **'Settle Bill'**
  String get settle_bill;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @enter_remark_for_order.
  ///
  /// In en, this message translates to:
  /// **'Enter remark for this order'**
  String get enter_remark_for_order;

  /// No description provided for @item_remark_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. less spicy, no onion'**
  String get item_remark_hint;

  /// No description provided for @address_saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Address saved successfully'**
  String get address_saved_successfully;

  /// No description provided for @failed_to_load_business_details.
  ///
  /// In en, this message translates to:
  /// **'Failed to load business details'**
  String get failed_to_load_business_details;

  /// No description provided for @update_failed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get update_failed;

  /// No description provided for @failed_to_delete_outlet.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete outlet'**
  String get failed_to_delete_outlet;

  /// No description provided for @business_details_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Business details updated successfully'**
  String get business_details_updated_successfully;

  /// No description provided for @error_fetching_orders.
  ///
  /// In en, this message translates to:
  /// **'Error fetching orders'**
  String get error_fetching_orders;

  /// No description provided for @failed_to_refresh_outlets.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh outlets'**
  String get failed_to_refresh_outlets;

  /// No description provided for @add_raw_material.
  ///
  /// In en, this message translates to:
  /// **'Add Raw Material'**
  String get add_raw_material;

  /// No description provided for @edit_raw_material.
  ///
  /// In en, this message translates to:
  /// **'Edit Raw Material'**
  String get edit_raw_material;

  /// No description provided for @add_supplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get add_supplier;

  /// No description provided for @edit_supplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get edit_supplier;

  /// No description provided for @adjust_stock_title.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock — {name}'**
  String adjust_stock_title(String name);

  /// No description provided for @update_stock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get update_stock;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete;

  /// No description provided for @low_stock_only.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Only'**
  String get low_stock_only;

  /// No description provided for @mark_received.
  ///
  /// In en, this message translates to:
  /// **'Mark Received'**
  String get mark_received;

  /// No description provided for @failed_to_download_pdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to download PDF: {error}'**
  String failed_to_download_pdf(String error);

  /// No description provided for @failed_to_print_invoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to print invoice: {error}'**
  String failed_to_print_invoice(String error);

  /// No description provided for @failed_to_print_pdf_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to print PDF: {error}'**
  String failed_to_print_pdf_error(String error);

  /// No description provided for @failed_to_save_pdf_file.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PDF file'**
  String get failed_to_save_pdf_file;

  /// No description provided for @failed_to_save_pdf_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PDF: {error}'**
  String failed_to_save_pdf_error(String error);

  /// No description provided for @invoice_printed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice printed successfully'**
  String get invoice_printed_successfully;

  /// No description provided for @invoice_saved_to_downloads.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved to Downloads folder'**
  String get invoice_saved_to_downloads;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @generate_bill.
  ///
  /// In en, this message translates to:
  /// **'Generate Bill'**
  String get generate_bill;

  /// No description provided for @please_enter_item_name_for_image.
  ///
  /// In en, this message translates to:
  /// **'Please enter item name first to generate image'**
  String get please_enter_item_name_for_image;

  /// No description provided for @image_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed. Please try again.'**
  String get image_upload_failed;

  /// No description provided for @please_select_image_first.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get please_select_image_first;

  /// No description provided for @ai_image_ready.
  ///
  /// In en, this message translates to:
  /// **'AI image ready'**
  String get ai_image_ready;

  /// No description provided for @image_removed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Image removed successfully'**
  String get image_removed_successfully;

  /// No description provided for @failed_to_bump_ticket.
  ///
  /// In en, this message translates to:
  /// **'Failed to bump ticket'**
  String get failed_to_bump_ticket;

  /// No description provided for @failed_to_update_item.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item'**
  String get failed_to_update_item;

  /// No description provided for @failed_to_update_kitchen_status.
  ///
  /// In en, this message translates to:
  /// **'Failed to update kitchen status'**
  String get failed_to_update_kitchen_status;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @view_queue.
  ///
  /// In en, this message translates to:
  /// **'View Queue'**
  String get view_queue;

  /// No description provided for @start_preparing.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get start_preparing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @bump.
  ///
  /// In en, this message translates to:
  /// **'Bump'**
  String get bump;

  /// No description provided for @please_enable_location_permission.
  ///
  /// In en, this message translates to:
  /// **'Please enable location permission in settings'**
  String get please_enable_location_permission;

  /// No description provided for @failed_to_get_address_details.
  ///
  /// In en, this message translates to:
  /// **'Failed to get address details'**
  String get failed_to_get_address_details;

  /// No description provided for @please_select_location_on_map.
  ///
  /// In en, this message translates to:
  /// **'Please select a location on the map'**
  String get please_select_location_on_map;

  /// No description provided for @notifications_cleared.
  ///
  /// In en, this message translates to:
  /// **'Notifications cleared'**
  String get notifications_cleared;

  /// No description provided for @clear_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Clear notifications?'**
  String get clear_notifications_title;

  /// No description provided for @clear_notifications_message.
  ///
  /// In en, this message translates to:
  /// **'This removes all items from your notification history.'**
  String get clear_notifications_message;

  /// No description provided for @no_notifications_yet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get no_notifications_yet;

  /// No description provided for @notifications_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Kitchen ready alerts and other updates will appear here.'**
  String get notifications_empty_hint;

  /// No description provided for @mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get mark_all_read;

  /// No description provided for @primary_contact_saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Primary contact saved successfully'**
  String get primary_contact_saved_successfully;

  /// No description provided for @failed_to_assign_printer.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign printer: {error}'**
  String failed_to_assign_printer(String error);

  /// No description provided for @bluetooth_not_supported.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth not supported on this device'**
  String get bluetooth_not_supported;

  /// No description provided for @failed_to_scan_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan Bluetooth: {error}'**
  String failed_to_scan_bluetooth(String error);

  /// No description provided for @failed_to_connect_printer.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to printer'**
  String get failed_to_connect_printer;

  /// No description provided for @error_scanning_usb.
  ///
  /// In en, this message translates to:
  /// **'Error scanning USB: {error}'**
  String error_scanning_usb(String error);

  /// No description provided for @usb_printer_not_connected.
  ///
  /// In en, this message translates to:
  /// **'USB printer is not connected'**
  String get usb_printer_not_connected;

  /// No description provided for @failed_to_connect_usb_printer.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to USB printer: {error}'**
  String failed_to_connect_usb_printer(String error);

  /// No description provided for @bluetooth_printer_not_connected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth printer not connected'**
  String get bluetooth_printer_not_connected;

  /// No description provided for @failed_to_print_via_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Failed to print via Bluetooth: {error}'**
  String failed_to_print_via_bluetooth(String error);

  /// No description provided for @failed_to_print_via_usb.
  ///
  /// In en, this message translates to:
  /// **'Failed to print via USB: {error}'**
  String failed_to_print_via_usb(String error);

  /// No description provided for @disconnected_from_printer.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from printer'**
  String get disconnected_from_printer;

  /// No description provided for @bluetooth_test_receipt_printed.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth test receipt printed successfully'**
  String get bluetooth_test_receipt_printed;

  /// No description provided for @usb_test_receipt_printed.
  ///
  /// In en, this message translates to:
  /// **'USB test receipt printed successfully'**
  String get usb_test_receipt_printed;

  /// No description provided for @please_add_business_address.
  ///
  /// In en, this message translates to:
  /// **'Please add business address'**
  String get please_add_business_address;

  /// No description provided for @please_add_primary_contact.
  ///
  /// In en, this message translates to:
  /// **'Please add primary contact'**
  String get please_add_primary_contact;

  /// No description provided for @please_complete_address_fields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all address fields'**
  String get please_complete_address_fields;

  /// No description provided for @please_complete_contact_fields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all contact fields'**
  String get please_complete_contact_fields;

  /// No description provided for @registration_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registration_failed;

  /// No description provided for @unable_to_update_staff.
  ///
  /// In en, this message translates to:
  /// **'Unable to update staff member'**
  String get unable_to_update_staff;

  /// No description provided for @unable_to_delete_staff.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete staff'**
  String get unable_to_delete_staff;

  /// No description provided for @staff_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Staff deleted successfully'**
  String get staff_deleted_successfully;

  /// No description provided for @remove_staff.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff'**
  String get remove_staff;

  /// No description provided for @search_staff_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, role, phone or email'**
  String get search_staff_hint;

  /// No description provided for @plans_and_pricing.
  ///
  /// In en, this message translates to:
  /// **'Plans & Pricing'**
  String get plans_and_pricing;

  /// No description provided for @table_already_exists.
  ///
  /// In en, this message translates to:
  /// **'This table already exists'**
  String get table_already_exists;

  /// No description provided for @cannot_delete_table_with_active_order.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete table with active order'**
  String get cannot_delete_table_with_active_order;

  /// No description provided for @table_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Table added successfully'**
  String get table_added_successfully;

  /// No description provided for @table_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Table deleted successfully'**
  String get table_deleted_successfully;

  /// No description provided for @delete_table.
  ///
  /// In en, this message translates to:
  /// **'Delete Table'**
  String get delete_table;

  /// No description provided for @please_enter_a_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get please_enter_a_phone_number;

  /// No description provided for @please_add_at_least_one_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one phone number'**
  String get please_add_at_least_one_phone_number;

  /// No description provided for @please_enter_a_message.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get please_enter_a_message;

  /// No description provided for @please_enter_restaurant_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter restaurant name'**
  String get please_enter_restaurant_name;

  /// No description provided for @please_enter_discount_value.
  ///
  /// In en, this message translates to:
  /// **'Please enter discount value'**
  String get please_enter_discount_value;

  /// No description provided for @please_enter_festival_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter festival name'**
  String get please_enter_festival_name;

  /// No description provided for @outlet_or_user_info_missing.
  ///
  /// In en, this message translates to:
  /// **'Outlet or user information is missing'**
  String get outlet_or_user_info_missing;

  /// No description provided for @confirm_bulk_message.
  ///
  /// In en, this message translates to:
  /// **'Confirm Bulk Message'**
  String get confirm_bulk_message;

  /// No description provided for @sending_messages.
  ///
  /// In en, this message translates to:
  /// **'Sending Messages'**
  String get sending_messages;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @failed_to_fetch_contacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch contacts: {error}'**
  String failed_to_fetch_contacts(String error);

  /// No description provided for @please_enter_customer_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get please_enter_customer_name;

  /// No description provided for @permission_required.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permission_required;

  /// No description provided for @customer_details.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customer_details;

  /// No description provided for @search_customer_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by customer name or phone'**
  String get search_customer_hint;

  /// No description provided for @search_contacts_hint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get search_contacts_hint;

  /// No description provided for @failed_to_print_kot.
  ///
  /// In en, this message translates to:
  /// **'Failed to print KOT: {error}'**
  String failed_to_print_kot(String error);

  /// No description provided for @failed_to_generate_kot.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate KOT: {error}'**
  String failed_to_generate_kot(String error);

  /// No description provided for @failed_to_save_kot.
  ///
  /// In en, this message translates to:
  /// **'Failed to save KOT: {error}'**
  String failed_to_save_kot(String error);

  /// No description provided for @failed_to_share_kot.
  ///
  /// In en, this message translates to:
  /// **'Failed to share KOT: {error}'**
  String failed_to_share_kot(String error);

  /// No description provided for @kot_printed_successfully.
  ///
  /// In en, this message translates to:
  /// **'KOT printed successfully'**
  String get kot_printed_successfully;

  /// No description provided for @kot_saved_to.
  ///
  /// In en, this message translates to:
  /// **'KOT saved to: {path}'**
  String kot_saved_to(String path);

  /// No description provided for @connect_printer.
  ///
  /// In en, this message translates to:
  /// **'Connect Printer'**
  String get connect_printer;

  /// No description provided for @kot_options.
  ///
  /// In en, this message translates to:
  /// **'KOT Options'**
  String get kot_options;

  /// No description provided for @scan_for_printers.
  ///
  /// In en, this message translates to:
  /// **'Scan for Printers'**
  String get scan_for_printers;

  /// No description provided for @print_thermal.
  ///
  /// In en, this message translates to:
  /// **'Print (Thermal)'**
  String get print_thermal;

  /// No description provided for @save_pdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get save_pdf;

  /// No description provided for @share_pdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get share_pdf;

  /// No description provided for @kot_receipt.
  ///
  /// In en, this message translates to:
  /// **'KOT Receipt'**
  String get kot_receipt;

  /// No description provided for @generate_pdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generate_pdf;

  /// No description provided for @generate_order.
  ///
  /// In en, this message translates to:
  /// **'Generate Order'**
  String get generate_order;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @please_add_at_least_one_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one payment method'**
  String get please_add_at_least_one_payment_method;

  /// No description provided for @camera_permission_denied_barcode.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Cannot scan barcode.'**
  String get camera_permission_denied_barcode;

  /// No description provided for @camera_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed'**
  String get camera_permission_needed;

  /// No description provided for @open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get open_settings;

  /// No description provided for @generate_image_first.
  ///
  /// In en, this message translates to:
  /// **'Generate an image first.'**
  String get generate_image_first;

  /// No description provided for @set_as_bill_printer.
  ///
  /// In en, this message translates to:
  /// **'Set as Bill Printer'**
  String get set_as_bill_printer;

  /// No description provided for @seating_capacity_min_one.
  ///
  /// In en, this message translates to:
  /// **'Seating capacity must be at least 1'**
  String get seating_capacity_min_one;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @failed_to_scan_menu.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan menu: {error}'**
  String failed_to_scan_menu(String error);

  /// No description provided for @photo_captured_successfully.
  ///
  /// In en, this message translates to:
  /// **'Photo captured successfully.'**
  String get photo_captured_successfully;

  /// No description provided for @order_section_title.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order_section_title;

  /// No description provided for @customer_section_title.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer_section_title;

  /// No description provided for @charges_section_title.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get charges_section_title;

  /// No description provided for @payment_section_title.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment_section_title;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @qr_menu.
  ///
  /// In en, this message translates to:
  /// **'QR Menu'**
  String get qr_menu;

  /// No description provided for @add_table.
  ///
  /// In en, this message translates to:
  /// **'Add Table'**
  String get add_table;

  /// No description provided for @reset_all_tables.
  ///
  /// In en, this message translates to:
  /// **'Reset All Tables'**
  String get reset_all_tables;

  /// No description provided for @change_url.
  ///
  /// In en, this message translates to:
  /// **'Change URL'**
  String get change_url;

  /// No description provided for @print_all_table_qr.
  ///
  /// In en, this message translates to:
  /// **'Print All Table QR'**
  String get print_all_table_qr;

  /// No description provided for @reset_all.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get reset_all;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @view_all.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get view_all;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @refresh_usb_devices.
  ///
  /// In en, this message translates to:
  /// **'Refresh USB Devices'**
  String get refresh_usb_devices;

  /// No description provided for @check_again.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get check_again;

  /// No description provided for @set_bill_printer_first.
  ///
  /// In en, this message translates to:
  /// **'Set a bill printer first'**
  String get set_bill_printer_first;

  /// No description provided for @bill_printer_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Bill printer not configured'**
  String get bill_printer_not_configured;

  /// No description provided for @bill_printer_not_found.
  ///
  /// In en, this message translates to:
  /// **'Bill printer not found. Turn it on and retry.'**
  String get bill_printer_not_found;

  /// No description provided for @kot_printer_same_as_bill.
  ///
  /// In en, this message translates to:
  /// **'KOT printer set same as bill printer'**
  String get kot_printer_same_as_bill;

  /// No description provided for @only_available_tables_can_be_deleted.
  ///
  /// In en, this message translates to:
  /// **'Only available tables can be deleted'**
  String get only_available_tables_can_be_deleted;

  /// No description provided for @all_tables_reset_successfully.
  ///
  /// In en, this message translates to:
  /// **'All tables reset successfully'**
  String get all_tables_reset_successfully;

  /// No description provided for @user_or_outlet_info_missing.
  ///
  /// In en, this message translates to:
  /// **'User or outlet information is missing.'**
  String get user_or_outlet_info_missing;

  /// No description provided for @payment_subscription_activated.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Subscription activated.'**
  String get payment_subscription_activated;

  /// No description provided for @stock_in.
  ///
  /// In en, this message translates to:
  /// **'Stock In (+)'**
  String get stock_in;

  /// No description provided for @stock_out.
  ///
  /// In en, this message translates to:
  /// **'Stock Out (-)'**
  String get stock_out;

  /// No description provided for @wastage.
  ///
  /// In en, this message translates to:
  /// **'Wastage'**
  String get wastage;

  /// No description provided for @return_to_supplier.
  ///
  /// In en, this message translates to:
  /// **'Return to Supplier'**
  String get return_to_supplier;

  /// No description provided for @kilogram_kg.
  ///
  /// In en, this message translates to:
  /// **'Kilogram (KG)'**
  String get kilogram_kg;

  /// No description provided for @gram_g.
  ///
  /// In en, this message translates to:
  /// **'Gram (g)'**
  String get gram_g;

  /// No description provided for @liter_l.
  ///
  /// In en, this message translates to:
  /// **'Liter (L)'**
  String get liter_l;

  /// No description provided for @milliliter_ml.
  ///
  /// In en, this message translates to:
  /// **'Milliliter (ml)'**
  String get milliliter_ml;

  /// No description provided for @piece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get piece;

  /// No description provided for @packet.
  ///
  /// In en, this message translates to:
  /// **'Packet'**
  String get packet;

  /// No description provided for @box.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get box;

  /// No description provided for @piece_pcs.
  ///
  /// In en, this message translates to:
  /// **'Piece (Pcs)'**
  String get piece_pcs;

  /// No description provided for @packet_pkt.
  ///
  /// In en, this message translates to:
  /// **'Packet (Pkt)'**
  String get packet_pkt;

  /// No description provided for @box_box.
  ///
  /// In en, this message translates to:
  /// **'Box (BOX)'**
  String get box_box;

  /// No description provided for @dozen_doz.
  ///
  /// In en, this message translates to:
  /// **'Dozen (Doz)'**
  String get dozen_doz;

  /// No description provided for @bottle_btl.
  ///
  /// In en, this message translates to:
  /// **'Bottle (Btl)'**
  String get bottle_btl;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @delete_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String delete_confirm_message(String name);

  /// No description provided for @sending_to_customers.
  ///
  /// In en, this message translates to:
  /// **'Sending to {count} customers...'**
  String sending_to_customers(String count);

  /// No description provided for @please_wait_sending.
  ///
  /// In en, this message translates to:
  /// **'Please wait, this may take a minute.'**
  String get please_wait_sending;

  /// No description provided for @no_results_available.
  ///
  /// In en, this message translates to:
  /// **'No results available'**
  String get no_results_available;

  /// No description provided for @send_bulk_message.
  ///
  /// In en, this message translates to:
  /// **'Send Bulk Message'**
  String get send_bulk_message;

  /// No description provided for @choose_an_action.
  ///
  /// In en, this message translates to:
  /// **'Choose an action:'**
  String get choose_an_action;

  /// No description provided for @customer_support.
  ///
  /// In en, this message translates to:
  /// **'Customer Support :'**
  String get customer_support;

  /// No description provided for @failed_to_add_table.
  ///
  /// In en, this message translates to:
  /// **'Failed to add table'**
  String get failed_to_add_table;

  /// No description provided for @failed_to_delete_table.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete table'**
  String get failed_to_delete_table;

  /// No description provided for @qr_menu_url_updated.
  ///
  /// In en, this message translates to:
  /// **'QR menu URL updated. Re-print table QR codes.'**
  String get qr_menu_url_updated;

  /// No description provided for @failed_to_load_orders_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failed_to_load_orders_error;

  /// No description provided for @create_order.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get create_order;

  /// No description provided for @item_list.
  ///
  /// In en, this message translates to:
  /// **'Item List'**
  String get item_list;

  /// No description provided for @add_item.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get add_item;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @kot_history.
  ///
  /// In en, this message translates to:
  /// **'KOT History'**
  String get kot_history;

  /// No description provided for @kitchen_display.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Display'**
  String get kitchen_display;

  /// No description provided for @open_kitchen_display_in_browser.
  ///
  /// In en, this message translates to:
  /// **'Open Kitchen Display in browser'**
  String get open_kitchen_display_in_browser;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @subscription_label.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription_label;

  /// No description provided for @free_trial.
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get free_trial;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @remaining_label.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {time}'**
  String remaining_label(String time);

  /// No description provided for @valid_till_label.
  ///
  /// In en, this message translates to:
  /// **'Valid till: {date}'**
  String valid_till_label(String date);

  /// No description provided for @subscription_days_left.
  ///
  /// In en, this message translates to:
  /// **'{days} days {label} left'**
  String subscription_days_left(String days, String label);

  /// No description provided for @subscription_days_left_compact.
  ///
  /// In en, this message translates to:
  /// **'{days}d\n{label}'**
  String subscription_days_left_compact(String days, String label);

  /// No description provided for @discard_order_message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved order changes. Are you sure you want to leave this screen?'**
  String get discard_order_message;

  /// No description provided for @no_permission_section.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this section.'**
  String get no_permission_section;

  /// No description provided for @settings_section_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_section_general;

  /// No description provided for @billing_list_view.
  ///
  /// In en, this message translates to:
  /// **'Billing list view'**
  String get billing_list_view;

  /// No description provided for @billing_list_view_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show orders as list instead of image grid'**
  String get billing_list_view_subtitle;

  /// No description provided for @show_qr_on_bill.
  ///
  /// In en, this message translates to:
  /// **'Show QR on bill'**
  String get show_qr_on_bill;

  /// No description provided for @show_qr_on_bill_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show UPI scan-to-pay QR on invoice and print'**
  String get show_qr_on_bill_subtitle;

  /// No description provided for @add_details_on_create_order.
  ///
  /// In en, this message translates to:
  /// **'Add details on create order'**
  String get add_details_on_create_order;

  /// No description provided for @add_details_on_create_order_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show Add Details for customer, table, discount, and payment'**
  String get add_details_on_create_order_subtitle;

  /// No description provided for @kitchen_display_in_browser.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Display in browser'**
  String get kitchen_display_in_browser;

  /// No description provided for @kitchen_display_browser_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the web kitchen screen on a second monitor or TV'**
  String get kitchen_display_browser_subtitle;

  /// No description provided for @kitchen_display_browser_subtitle_device.
  ///
  /// In en, this message translates to:
  /// **'Open the web kitchen screen on a second device'**
  String get kitchen_display_browser_subtitle_device;

  /// No description provided for @show_onboarding_again.
  ///
  /// In en, this message translates to:
  /// **'Show onboarding again'**
  String get show_onboarding_again;

  /// No description provided for @show_onboarding_again_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Replay the app intro and tips'**
  String get show_onboarding_again_subtitle;

  /// No description provided for @download_path.
  ///
  /// In en, this message translates to:
  /// **'Download path'**
  String get download_path;

  /// No description provided for @default_downloads_folder.
  ///
  /// In en, this message translates to:
  /// **'Default Downloads folder'**
  String get default_downloads_folder;

  /// No description provided for @settings_section_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_section_notifications;

  /// No description provided for @settings_notifications_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Order and reminder notifications'**
  String get settings_notifications_subtitle;

  /// No description provided for @notification_history.
  ///
  /// In en, this message translates to:
  /// **'Notification history'**
  String get notification_history;

  /// No description provided for @notification_history_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen ready and other alerts'**
  String get notification_history_subtitle;

  /// No description provided for @settings_section_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_section_appearance;

  /// No description provided for @theme_color.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get theme_color;

  /// No description provided for @settings_section_language_region.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get settings_section_language_region;

  /// No description provided for @custom_hex.
  ///
  /// In en, this message translates to:
  /// **'Custom hex'**
  String get custom_hex;

  /// No description provided for @my_colors.
  ///
  /// In en, this message translates to:
  /// **'My colors'**
  String get my_colors;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @hex_format_error.
  ///
  /// In en, this message translates to:
  /// **'Use #RRGGBB (e.g. #2196F3) or #AARRGGBB'**
  String get hex_format_error;

  /// No description provided for @download_path_updated.
  ///
  /// In en, this message translates to:
  /// **'Download path updated'**
  String get download_path_updated;

  /// No description provided for @unable_to_update_download_path.
  ///
  /// In en, this message translates to:
  /// **'Unable to update download path'**
  String get unable_to_update_download_path;

  /// No description provided for @select_folder.
  ///
  /// In en, this message translates to:
  /// **'Select folder'**
  String get select_folder;

  /// No description provided for @settings_section_home_screen.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get settings_section_home_screen;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @tutorial_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Video guide section on the home screen'**
  String get tutorial_subtitle;

  /// No description provided for @top_selling_items.
  ///
  /// In en, this message translates to:
  /// **'Top selling items'**
  String get top_selling_items;

  /// No description provided for @top_selling_items_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Best-selling menu items on the home screen'**
  String get top_selling_items_subtitle;

  /// No description provided for @recommended_items.
  ///
  /// In en, this message translates to:
  /// **'Most selling items'**
  String get recommended_items;

  /// No description provided for @features_for_you_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended setup and tools on the home screen'**
  String get features_for_you_subtitle;

  /// No description provided for @what_our_users_say.
  ///
  /// In en, this message translates to:
  /// **'What our users say'**
  String get what_our_users_say;

  /// No description provided for @what_our_users_say_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer testimonials carousel on the home screen'**
  String get what_our_users_say_subtitle;

  /// No description provided for @settings_section_haptic.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settings_section_haptic;

  /// No description provided for @haptic_feedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptic_feedback;

  /// No description provided for @haptic_feedback_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibration on tap'**
  String get haptic_feedback_subtitle;

  /// No description provided for @home_outlet_showcase_title.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get home_outlet_showcase_title;

  /// No description provided for @home_outlet_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to switch outlet. Your tables, orders, sales and reports will update for the selected outlet.'**
  String get home_outlet_showcase_desc;

  /// No description provided for @home_ai_voice_add_items.
  ///
  /// In en, this message translates to:
  /// **'AI Voice add items'**
  String get home_ai_voice_add_items;

  /// No description provided for @home_profile_business_title.
  ///
  /// In en, this message translates to:
  /// **'Profile / Business'**
  String get home_profile_business_title;

  /// No description provided for @home_profile_business_desc.
  ///
  /// In en, this message translates to:
  /// **'Open business settings, profile and outlet details from here.'**
  String get home_profile_business_desc;

  /// No description provided for @home_profile_business_desc_short.
  ///
  /// In en, this message translates to:
  /// **'Open business settings and outlet details from here.'**
  String get home_profile_business_desc_short;

  /// No description provided for @home_printer_status_title.
  ///
  /// In en, this message translates to:
  /// **'Printer Status'**
  String get home_printer_status_title;

  /// No description provided for @home_printer_status_desc.
  ///
  /// In en, this message translates to:
  /// **'When your printer is connected, you can print invoices and KOTs without interruptions.'**
  String get home_printer_status_desc;

  /// No description provided for @home_printer_connected_label.
  ///
  /// In en, this message translates to:
  /// **'Printer connected'**
  String get home_printer_connected_label;

  /// No description provided for @home_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get home_online;

  /// No description provided for @home_usb_printer.
  ///
  /// In en, this message translates to:
  /// **'USB Printer'**
  String get home_usb_printer;

  /// No description provided for @home_printer_fallback.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get home_printer_fallback;

  /// No description provided for @home_printer_connected_name.
  ///
  /// In en, this message translates to:
  /// **'Printer Connected'**
  String get home_printer_connected_name;

  /// No description provided for @home_quick_actions_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts to frequently used features like Add Items, KOT History and more.'**
  String get home_quick_actions_showcase_desc;

  /// No description provided for @home_frequently_used_shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Frequently used shortcuts'**
  String get home_frequently_used_shortcuts;

  /// No description provided for @home_kitchen_web.
  ///
  /// In en, this message translates to:
  /// **'Kitchen (Web)'**
  String get home_kitchen_web;

  /// No description provided for @home_showcase_closed_orders.
  ///
  /// In en, this message translates to:
  /// **'View completed/paid orders and open details anytime.'**
  String get home_showcase_closed_orders;

  /// No description provided for @home_showcase_hold_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders saved on hold. Resume billing anytime.'**
  String get home_showcase_hold_orders;

  /// No description provided for @home_showcase_add_items.
  ///
  /// In en, this message translates to:
  /// **'Add menu items to your inventory (manual / voice).'**
  String get home_showcase_add_items;

  /// No description provided for @home_showcase_kot_history.
  ///
  /// In en, this message translates to:
  /// **'View KOT history, open details and reprint KOTs.'**
  String get home_showcase_kot_history;

  /// No description provided for @home_tap_to_access_feature.
  ///
  /// In en, this message translates to:
  /// **'Tap to access this feature.'**
  String get home_tap_to_access_feature;

  /// No description provided for @home_occupied_tables.
  ///
  /// In en, this message translates to:
  /// **'Occupied Tables'**
  String get home_occupied_tables;

  /// No description provided for @home_live_dine_in_tables.
  ///
  /// In en, this message translates to:
  /// **'Live dine-in tables in progress'**
  String get home_live_dine_in_tables;

  /// No description provided for @home_table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get home_table;

  /// No description provided for @home_table_number.
  ///
  /// In en, this message translates to:
  /// **'Table {number}'**
  String home_table_number(String number);

  /// No description provided for @home_occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get home_occupied;

  /// No description provided for @home_bill_number.
  ///
  /// In en, this message translates to:
  /// **'Bill #{number}'**
  String home_bill_number(String number);

  /// No description provided for @home_tap_continue_order.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue order'**
  String get home_tap_continue_order;

  /// No description provided for @home_occupied_duration.
  ///
  /// In en, this message translates to:
  /// **'Occupied {duration}'**
  String home_occupied_duration(String duration);

  /// No description provided for @home_today_vs_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Today vs yesterday'**
  String get home_today_vs_yesterday;

  /// No description provided for @home_business_overview_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'View detailed business insights including sales, orders, and performance metrics for today and yesterday.'**
  String get home_business_overview_showcase_desc;

  /// No description provided for @home_performance_summary.
  ///
  /// In en, this message translates to:
  /// **'Performance summary'**
  String get home_performance_summary;

  /// No description provided for @home_yesterday_value.
  ///
  /// In en, this message translates to:
  /// **'Yesterday: {value}'**
  String home_yesterday_value(String value);

  /// No description provided for @home_category_wise_today.
  ///
  /// In en, this message translates to:
  /// **'Category-wise (Today)'**
  String get home_category_wise_today;

  /// No description provided for @home_top_count.
  ///
  /// In en, this message translates to:
  /// **'Top {count}'**
  String home_top_count(String count);

  /// No description provided for @home_weekly_sales_trend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Sales Trend'**
  String get home_weekly_sales_trend;

  /// No description provided for @home_last_7_days_sales.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days sales performance'**
  String get home_last_7_days_sales;

  /// No description provided for @home_monthly_sales_trend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales Trend'**
  String get home_monthly_sales_trend;

  /// No description provided for @home_last_12_months_sales.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months sales performance'**
  String get home_last_12_months_sales;

  /// No description provided for @home_quarterly_sales_trend.
  ///
  /// In en, this message translates to:
  /// **'Quarterly Sales Trend'**
  String get home_quarterly_sales_trend;

  /// No description provided for @home_last_4_quarters_sales.
  ///
  /// In en, this message translates to:
  /// **'Last 4 quarters sales performance'**
  String get home_last_4_quarters_sales;

  /// No description provided for @home_yearly_sales_trend.
  ///
  /// In en, this message translates to:
  /// **'Yearly Sales Trend'**
  String get home_yearly_sales_trend;

  /// No description provided for @home_last_5_years_sales.
  ///
  /// In en, this message translates to:
  /// **'Last 5 years sales performance'**
  String get home_last_5_years_sales;

  /// No description provided for @home_sales_trend.
  ///
  /// In en, this message translates to:
  /// **'Sales Trend'**
  String get home_sales_trend;

  /// No description provided for @home_sales_trend_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'Track your sales trend by week/month/quarter/year and monitor totals and averages.'**
  String get home_sales_trend_showcase_desc;

  /// No description provided for @home_no_item_sales_yet.
  ///
  /// In en, this message translates to:
  /// **'No item sales yet'**
  String get home_no_item_sales_yet;

  /// No description provided for @home_features_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'Quick setup tools and recommended features to help you run your business faster.'**
  String get home_features_showcase_desc;

  /// No description provided for @home_recommended_setup_tools.
  ///
  /// In en, this message translates to:
  /// **'Recommended setup & tools'**
  String get home_recommended_setup_tools;

  /// No description provided for @badge_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badge_new;

  /// No description provided for @home_testimonials.
  ///
  /// In en, this message translates to:
  /// **'Testimonials'**
  String get home_testimonials;

  /// No description provided for @home_testimonials_showcase_desc.
  ///
  /// In en, this message translates to:
  /// **'See feedback from restaurants using Billkaro. Swipe to read more.'**
  String get home_testimonials_showcase_desc;

  /// No description provided for @home_payment_received.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get home_payment_received;

  /// No description provided for @home_total_payments_collected.
  ///
  /// In en, this message translates to:
  /// **'Total payments collected'**
  String get home_total_payments_collected;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @home_payment_methods_today.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods (Today)'**
  String get home_payment_methods_today;

  /// No description provided for @home_no_payments_today.
  ///
  /// In en, this message translates to:
  /// **'No payments received today'**
  String get home_no_payments_today;

  /// No description provided for @home_switch_outlet.
  ///
  /// In en, this message translates to:
  /// **'Switch Outlet'**
  String get home_switch_outlet;

  /// No description provided for @home_no_outlets_available.
  ///
  /// In en, this message translates to:
  /// **'No outlets available'**
  String get home_no_outlets_available;

  /// No description provided for @home_manage_outlets.
  ///
  /// In en, this message translates to:
  /// **'Manage outlets'**
  String get home_manage_outlets;

  /// No description provided for @owner_panel_title.
  ///
  /// In en, this message translates to:
  /// **'Owner Panel'**
  String get owner_panel_title;

  /// No description provided for @owner_panel_menu.
  ///
  /// In en, this message translates to:
  /// **'Owner Panel'**
  String get owner_panel_menu;

  /// No description provided for @owner_panel_heading.
  ///
  /// In en, this message translates to:
  /// **'All Outlets'**
  String get owner_panel_heading;

  /// No description provided for @owner_panel_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} outlets in one place'**
  String owner_panel_subtitle(int count);

  /// No description provided for @owner_panel_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search outlets…'**
  String get owner_panel_search_hint;

  /// No description provided for @owner_panel_expand_all.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get owner_panel_expand_all;

  /// No description provided for @owner_panel_collapse_all.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get owner_panel_collapse_all;

  /// No description provided for @owner_panel_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an outlet to see its details here.'**
  String get owner_panel_empty_subtitle;

  /// No description provided for @owner_panel_no_results.
  ///
  /// In en, this message translates to:
  /// **'No matching outlets'**
  String get owner_panel_no_results;

  /// No description provided for @owner_panel_no_results_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, address, or GSTIN.'**
  String get owner_panel_no_results_subtitle;

  /// No description provided for @owner_panel_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get owner_panel_active;

  /// No description provided for @owner_panel_no_type.
  ///
  /// In en, this message translates to:
  /// **'Type not set'**
  String get owner_panel_no_type;

  /// No description provided for @owner_panel_outlet_age.
  ///
  /// In en, this message translates to:
  /// **'Outlet age'**
  String get owner_panel_outlet_age;

  /// No description provided for @owner_panel_google_profile.
  ///
  /// In en, this message translates to:
  /// **'Google profile'**
  String get owner_panel_google_profile;

  /// No description provided for @owner_panel_switch_to.
  ///
  /// In en, this message translates to:
  /// **'Switch to this outlet'**
  String get owner_panel_switch_to;

  /// No description provided for @home_unnamed_outlet.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Outlet'**
  String get home_unnamed_outlet;

  /// No description provided for @home_logged_out.
  ///
  /// In en, this message translates to:
  /// **'Logged Out'**
  String get home_logged_out;

  /// No description provided for @home_logged_out_message.
  ///
  /// In en, this message translates to:
  /// **'You have been successfully logged out'**
  String get home_logged_out_message;

  /// No description provided for @home_billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get home_billing;

  /// No description provided for @home_customize_home.
  ///
  /// In en, this message translates to:
  /// **'Customize home'**
  String get home_customize_home;

  /// No description provided for @home_customize_home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show or hide sections on your home screen'**
  String get home_customize_home_subtitle;

  /// No description provided for @home_section_on_home.
  ///
  /// In en, this message translates to:
  /// **'Section on home'**
  String get home_section_on_home;

  /// No description provided for @home_open_screen.
  ///
  /// In en, this message translates to:
  /// **'Open screen'**
  String get home_open_screen;

  /// No description provided for @home_open_dashboard_tab.
  ///
  /// In en, this message translates to:
  /// **'Open Dashboard tab'**
  String get home_open_dashboard_tab;

  /// No description provided for @home_customize_home_title.
  ///
  /// In en, this message translates to:
  /// **'Customize home'**
  String get home_customize_home_title;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search e.g. orders, payment, staff…'**
  String get home_search_hint;

  /// No description provided for @home_business_details.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get home_business_details;

  /// No description provided for @home_new_order.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get home_new_order;

  /// No description provided for @home_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get home_menu;

  /// No description provided for @home_app_settings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get home_app_settings;

  /// No description provided for @home_order_reports.
  ///
  /// In en, this message translates to:
  /// **'Order Reports'**
  String get home_order_reports;

  /// No description provided for @home_item_reports.
  ///
  /// In en, this message translates to:
  /// **'Item Reports'**
  String get home_item_reports;

  /// No description provided for @home_business_overview_full.
  ///
  /// In en, this message translates to:
  /// **'{overview} (full)'**
  String home_business_overview_full(String overview);

  /// No description provided for @home_video_guide_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Video guide on home'**
  String get home_video_guide_subtitle;

  /// No description provided for @home_best_selling_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Best-selling menu items'**
  String get home_best_selling_subtitle;

  /// No description provided for @home_customer_testimonials_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer testimonials'**
  String get home_customer_testimonials_subtitle;

  /// No description provided for @home_customize_sections_title.
  ///
  /// In en, this message translates to:
  /// **'Customize home sections'**
  String get home_customize_sections_title;

  /// No description provided for @home_customize_sections_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections appear on your home screen'**
  String get home_customize_sections_subtitle;

  /// No description provided for @home_show_section.
  ///
  /// In en, this message translates to:
  /// **'Show section'**
  String get home_show_section;

  /// No description provided for @testimonial_quote_1.
  ///
  /// In en, this message translates to:
  /// **'This app is fast, easy to use, and perfect for hassle-free restaurant management.'**
  String get testimonial_quote_1;

  /// No description provided for @testimonial_author_1.
  ///
  /// In en, this message translates to:
  /// **'Ankit Kumar'**
  String get testimonial_author_1;

  /// No description provided for @testimonial_quote_2.
  ///
  /// In en, this message translates to:
  /// **'Best billing solution I\'ve used. Makes running my restaurant so much easier!'**
  String get testimonial_quote_2;

  /// No description provided for @testimonial_author_2.
  ///
  /// In en, this message translates to:
  /// **'Priya Sharma'**
  String get testimonial_author_2;

  /// No description provided for @testimonial_quote_3.
  ///
  /// In en, this message translates to:
  /// **'Simple, efficient, and reliable. Exactly what every restaurant owner needs.'**
  String get testimonial_quote_3;

  /// No description provided for @testimonial_author_3.
  ///
  /// In en, this message translates to:
  /// **'Rahul Verma'**
  String get testimonial_author_3;

  /// No description provided for @search_outlets_hint.
  ///
  /// In en, this message translates to:
  /// **'Search outlets…'**
  String get search_outlets_hint;

  /// No description provided for @qr_menu_description.
  ///
  /// In en, this message translates to:
  /// **'Generate QR codes for tables so customers can scan, order, and pay from their phone.'**
  String get qr_menu_description;

  /// No description provided for @qr_menu_current_url_base.
  ///
  /// In en, this message translates to:
  /// **'Current URL base:\n{url}'**
  String qr_menu_current_url_base(String url);

  /// No description provided for @tables_count_limit.
  ///
  /// In en, this message translates to:
  /// **'Seats used: {current} / {limit}'**
  String tables_count_limit(int current, int limit);

  /// No description provided for @seating_capacity_not_set.
  ///
  /// In en, this message translates to:
  /// **'Seating capacity is not set for this outlet.'**
  String get seating_capacity_not_set;

  /// No description provided for @table_number_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 13 or Table 13'**
  String get table_number_hint;

  /// No description provided for @table_number_hint_short.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 or Table 1'**
  String get table_number_hint_short;

  /// No description provided for @delete_table_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This action cannot be undone.'**
  String delete_table_confirm_message(String name);

  /// No description provided for @delete_table_confirm_short.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String delete_table_confirm_short(String name);

  /// No description provided for @reset_all_tables_message.
  ///
  /// In en, this message translates to:
  /// **'This will remove all tables from this outlet. Do you want to continue?'**
  String get reset_all_tables_message;

  /// No description provided for @search_table.
  ///
  /// In en, this message translates to:
  /// **'Search table'**
  String get search_table;

  /// No description provided for @table_section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get table_section;

  /// No description provided for @table_section_hint.
  ///
  /// In en, this message translates to:
  /// **'Select or create a section'**
  String get table_section_hint;

  /// No description provided for @table_section_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get table_section_general;

  /// No description provided for @table_section_all.
  ///
  /// In en, this message translates to:
  /// **'All sections'**
  String get table_section_all;

  /// No description provided for @table_section_new.
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get table_section_new;

  /// No description provided for @add_section.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get add_section;

  /// No description provided for @section_name.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get section_name;

  /// No description provided for @section_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AC Room, Rooftop'**
  String get section_name_hint;

  /// No description provided for @please_enter_section_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter a section name'**
  String get please_enter_section_name;

  /// No description provided for @section_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Section added successfully'**
  String get section_added_successfully;

  /// No description provided for @failed_to_add_section.
  ///
  /// In en, this message translates to:
  /// **'Failed to add section'**
  String get failed_to_add_section;

  /// No description provided for @section_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Section already exists'**
  String get section_already_exists;

  /// No description provided for @delete_section.
  ///
  /// In en, this message translates to:
  /// **'Delete section'**
  String get delete_section;

  /// No description provided for @delete_section_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete section'**
  String get delete_section_tooltip;

  /// No description provided for @delete_section_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete section \"{name}\"? Tables are not deleted.'**
  String delete_section_confirm(String name);

  /// No description provided for @delete_section_has_tables.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete \"{name}\" while {count} tables are assigned. Move them first.'**
  String delete_section_has_tables(String name, int count);

  /// No description provided for @section_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Section deleted successfully'**
  String get section_deleted_successfully;

  /// No description provided for @failed_to_delete_section.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete section'**
  String get failed_to_delete_section;

  /// No description provided for @no_sections_yet.
  ///
  /// In en, this message translates to:
  /// **'No sections yet. Add a section first.'**
  String get no_sections_yet;

  /// No description provided for @table_section_count.
  ///
  /// In en, this message translates to:
  /// **'{count} tables'**
  String table_section_count(int count);

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @table_status_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get table_status_available;

  /// No description provided for @table_status_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get table_status_empty;

  /// No description provided for @no_tables_match_filter.
  ///
  /// In en, this message translates to:
  /// **'No tables match your search/filter'**
  String get no_tables_match_filter;

  /// No description provided for @no_tables_available.
  ///
  /// In en, this message translates to:
  /// **'No tables available'**
  String get no_tables_available;

  /// No description provided for @delete_table_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get delete_table_tooltip;

  /// No description provided for @print_qr_menu.
  ///
  /// In en, this message translates to:
  /// **'Print QR menu'**
  String get print_qr_menu;

  /// No description provided for @tap_to_create_new_order.
  ///
  /// In en, this message translates to:
  /// **'Tap to create new order'**
  String get tap_to_create_new_order;

  /// No description provided for @unable_to_load_tables_from_server.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tables from server'**
  String get unable_to_load_tables_from_server;

  /// No description provided for @no_tables_configured.
  ///
  /// In en, this message translates to:
  /// **'No tables configured for this outlet'**
  String get no_tables_configured;

  /// No description provided for @unable_to_load_local_orders.
  ///
  /// In en, this message translates to:
  /// **'Unable to load local orders'**
  String get unable_to_load_local_orders;

  /// No description provided for @set_outlet_seating_capacity_first.
  ///
  /// In en, this message translates to:
  /// **'Set outlet seating capacity first before adding tables'**
  String get set_outlet_seating_capacity_first;

  /// No description provided for @set_outlet_seating_capacity_first_short.
  ///
  /// In en, this message translates to:
  /// **'Set outlet seating capacity first'**
  String get set_outlet_seating_capacity_first_short;

  /// No description provided for @cannot_add_more_tables.
  ///
  /// In en, this message translates to:
  /// **'Outlet seating capacity is {limit} seats'**
  String cannot_add_more_tables(int limit);

  /// No description provided for @cannot_add_more_tables_short.
  ///
  /// In en, this message translates to:
  /// **'Outlet seating capacity is {limit} seats'**
  String cannot_add_more_tables_short(int limit);

  /// No description provided for @failed_to_reset_all_tables.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset all tables'**
  String get failed_to_reset_all_tables;

  /// No description provided for @could_not_generate_qr_for_table.
  ///
  /// In en, this message translates to:
  /// **'Could not generate QR for this table'**
  String get could_not_generate_qr_for_table;

  /// No description provided for @print_failed_with_error.
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String print_failed_with_error(String error);

  /// No description provided for @failed_to_generate_print_qr.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate/print QR codes: {error}'**
  String failed_to_generate_print_qr(String error);

  /// No description provided for @table_qr_printed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Table QR sent to printer'**
  String get table_qr_printed_successfully;

  /// No description provided for @all_table_qrs_printed_successfully.
  ///
  /// In en, this message translates to:
  /// **'All table QR codes sent to printer'**
  String get all_table_qrs_printed_successfully;

  /// No description provided for @table_management.
  ///
  /// In en, this message translates to:
  /// **'Table Management'**
  String get table_management;

  /// No description provided for @tables_not_available_no_seating.
  ///
  /// In en, this message translates to:
  /// **'Tables are not available for outlets with no seating.'**
  String get tables_not_available_no_seating;

  /// No description provided for @add_new_table.
  ///
  /// In en, this message translates to:
  /// **'Add New Table'**
  String get add_new_table;

  /// No description provided for @table_seats_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats'**
  String table_seats_count(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @no_tables_yet.
  ///
  /// In en, this message translates to:
  /// **'No tables yet'**
  String get no_tables_yet;

  /// No description provided for @add_first_table_hint.
  ///
  /// In en, this message translates to:
  /// **'Add your first table to get started'**
  String get add_first_table_hint;

  /// No description provided for @edit_table.
  ///
  /// In en, this message translates to:
  /// **'Edit Table'**
  String get edit_table;

  /// No description provided for @edit_table_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Update table number and seating capacity'**
  String get edit_table_subtitle;

  /// No description provided for @tables_count_of_limit.
  ///
  /// In en, this message translates to:
  /// **'{current} / {limit} seats'**
  String tables_count_of_limit(int current, int limit);

  /// No description provided for @seats_label.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats_label;

  /// No description provided for @seats_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4'**
  String get seats_hint;

  /// No description provided for @table_seats_exceed_outlet.
  ///
  /// In en, this message translates to:
  /// **'A table cannot have more than {limit} seats for this outlet'**
  String table_seats_exceed_outlet(int limit);

  /// No description provided for @table_seats_exceed_remaining.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} seats remaining (outlet limit {limit} seats)'**
  String table_seats_exceed_remaining(int remaining, int limit);

  /// No description provided for @outlet_seating_full.
  ///
  /// In en, this message translates to:
  /// **'Outlet seating is full ({limit} seats)'**
  String outlet_seating_full(int limit);

  /// No description provided for @unable_to_load_tables.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tables'**
  String get unable_to_load_tables;

  /// No description provided for @another_table_already_uses_number.
  ///
  /// In en, this message translates to:
  /// **'Another table already uses this number'**
  String get another_table_already_uses_number;

  /// No description provided for @only_empty_tables_can_be_deleted.
  ///
  /// In en, this message translates to:
  /// **'Only empty tables can be deleted'**
  String get only_empty_tables_can_be_deleted;

  /// No description provided for @table_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Table updated successfully'**
  String get table_updated_successfully;

  /// No description provided for @failed_to_update_table.
  ///
  /// In en, this message translates to:
  /// **'Failed to update table'**
  String get failed_to_update_table;

  /// No description provided for @table_status_duration.
  ///
  /// In en, this message translates to:
  /// **'{status} {duration}'**
  String table_status_duration(String status, String duration);

  /// No description provided for @loading_menu.
  ///
  /// In en, this message translates to:
  /// **'Loading menu...'**
  String get loading_menu;

  /// No description provided for @note_hold_category_to_edit.
  ///
  /// In en, this message translates to:
  /// **'Note: Hold category chip to edit.'**
  String get note_hold_category_to_edit;

  /// No description provided for @select_items.
  ///
  /// In en, this message translates to:
  /// **'Select items'**
  String get select_items;

  /// No description provided for @items_selected_count.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String items_selected_count(int count);

  /// No description provided for @select_items_to_delete.
  ///
  /// In en, this message translates to:
  /// **'Select items to delete'**
  String get select_items_to_delete;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clear_all;

  /// No description provided for @select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get select_all;

  /// No description provided for @delete_selected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get delete_selected;

  /// No description provided for @delete_count.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String delete_count(int count);

  /// No description provided for @import_from_file.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get import_from_file;

  /// No description provided for @search_dishes.
  ///
  /// In en, this message translates to:
  /// **'Search dishes'**
  String get search_dishes;

  /// No description provided for @categories_label.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories_label;

  /// No description provided for @select_category_to_edit.
  ///
  /// In en, this message translates to:
  /// **'Select a category to edit'**
  String get select_category_to_edit;

  /// No description provided for @edit_selected_category.
  ///
  /// In en, this message translates to:
  /// **'Edit selected category'**
  String get edit_selected_category;

  /// No description provided for @tip_right_click_category_edit.
  ///
  /// In en, this message translates to:
  /// **'Tip: Right-click / long-press a category to edit.'**
  String get tip_right_click_category_edit;

  /// No description provided for @no_items_found.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get no_items_found;

  /// No description provided for @try_different_search_term.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get try_different_search_term;

  /// No description provided for @add_items_to_this_category.
  ///
  /// In en, this message translates to:
  /// **'Add items to this category'**
  String get add_items_to_this_category;

  /// No description provided for @no_more_items.
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get no_more_items;

  /// No description provided for @scroll_for_more.
  ///
  /// In en, this message translates to:
  /// **'Scroll for more'**
  String get scroll_for_more;

  /// No description provided for @long_press_edit_category.
  ///
  /// In en, this message translates to:
  /// **'Long press to edit category'**
  String get long_press_edit_category;

  /// No description provided for @more_options.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get more_options;

  /// No description provided for @close_search.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get close_search;

  /// No description provided for @search_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_tooltip;

  /// No description provided for @add_new_item.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get add_new_item;

  /// No description provided for @delete_item_title.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get delete_item_title;

  /// No description provided for @delete_item_named_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String delete_item_named_confirm(String name);

  /// No description provided for @delete_items_title.
  ///
  /// In en, this message translates to:
  /// **'Delete items'**
  String get delete_items_title;

  /// No description provided for @delete_items_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected item(s)? This cannot be undone.'**
  String delete_items_confirm(int count);

  /// No description provided for @select_at_least_one_item_to_delete.
  ///
  /// In en, this message translates to:
  /// **'Select at least one item to delete'**
  String get select_at_least_one_item_to_delete;

  /// No description provided for @items_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) deleted successfully'**
  String items_deleted_successfully(int count);

  /// No description provided for @failed_to_delete_selected_items.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete selected items'**
  String get failed_to_delete_selected_items;

  /// No description provided for @failed_to_delete_items_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete items: {error}'**
  String failed_to_delete_items_error(String error);

  /// No description provided for @failed_to_read_file_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file: {error}'**
  String failed_to_read_file_error(String error);

  /// No description provided for @no_valid_import_rows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows found. Use headers like: Item Name, Price / Price (₹), Category, Tax % or GST. Avoid Item Code / Description / Unit only as names. Prices must be numbers greater than 0.'**
  String get no_valid_import_rows;

  /// No description provided for @import_item_missing_fields.
  ///
  /// In en, this message translates to:
  /// **'Missing fields in item #{row}: {fields}'**
  String import_item_missing_fields(int row, String fields);

  /// No description provided for @items_imported_successfully.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) imported successfully'**
  String items_imported_successfully(int count);

  /// No description provided for @failed_to_import_items.
  ///
  /// In en, this message translates to:
  /// **'Failed to import items'**
  String get failed_to_import_items;

  /// No description provided for @failed_to_import_file_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to import file: {error}'**
  String failed_to_import_file_error(String error);

  /// No description provided for @this_item.
  ///
  /// In en, this message translates to:
  /// **'this item'**
  String get this_item;

  /// No description provided for @confirm_delete_item_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirm_delete_item_message;

  /// No description provided for @category_chip_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category_chip_label;

  /// No description provided for @more_tooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more_tooltip;

  /// No description provided for @item_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully'**
  String get item_deleted_successfully;

  /// No description provided for @failed_to_delete_item.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item'**
  String get failed_to_delete_item;

  /// No description provided for @inventory_management.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventory_management;

  /// No description provided for @inventory_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw materials · Product stock · Recipes'**
  String get inventory_subtitle;

  /// No description provided for @tab_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tab_overview;

  /// No description provided for @tab_raw_materials.
  ///
  /// In en, this message translates to:
  /// **'Raw Materials'**
  String get tab_raw_materials;

  /// No description provided for @tab_stock_log.
  ///
  /// In en, this message translates to:
  /// **'Stock Log'**
  String get tab_stock_log;

  /// No description provided for @tab_suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get tab_suppliers;

  /// No description provided for @tab_purchase_orders.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get tab_purchase_orders;

  /// No description provided for @tab_recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get tab_recipes;

  /// No description provided for @stat_raw_materials.
  ///
  /// In en, this message translates to:
  /// **'Raw Materials'**
  String get stat_raw_materials;

  /// No description provided for @stat_low_stock_alerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get stat_low_stock_alerts;

  /// No description provided for @stat_stock_value.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stat_stock_value;

  /// No description provided for @stat_pending_pos.
  ///
  /// In en, this message translates to:
  /// **'Pending POs'**
  String get stat_pending_pos;

  /// No description provided for @section_low_stock_alerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get section_low_stock_alerts;

  /// No description provided for @all_materials_above_min.
  ///
  /// In en, this message translates to:
  /// **'All materials are above minimum stock levels.'**
  String get all_materials_above_min;

  /// No description provided for @section_quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get section_quick_actions;

  /// No description provided for @view_stock_log.
  ///
  /// In en, this message translates to:
  /// **'View Stock Log'**
  String get view_stock_log;

  /// No description provided for @todays_consumption.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Consumption'**
  String get todays_consumption;

  /// No description provided for @todays_consumption_units.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String todays_consumption_units(int count);

  /// No description provided for @active_suppliers.
  ///
  /// In en, this message translates to:
  /// **'Active Suppliers'**
  String get active_suppliers;

  /// No description provided for @tracked_menu_items.
  ///
  /// In en, this message translates to:
  /// **'Tracked Menu Items'**
  String get tracked_menu_items;

  /// No description provided for @search_raw_materials.
  ///
  /// In en, this message translates to:
  /// **'Search raw materials...'**
  String get search_raw_materials;

  /// No description provided for @add_material.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get add_material;

  /// No description provided for @material_column.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material_column;

  /// No description provided for @status_low.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get status_low;

  /// No description provided for @status_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get status_ok;

  /// No description provided for @no_raw_materials_yet.
  ///
  /// In en, this message translates to:
  /// **'No raw materials yet. Add your first ingredient.'**
  String get no_raw_materials_yet;

  /// No description provided for @no_stock_movements.
  ///
  /// In en, this message translates to:
  /// **'No stock movements recorded yet.'**
  String get no_stock_movements;

  /// No description provided for @search_suppliers.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers...'**
  String get search_suppliers;

  /// No description provided for @no_suppliers_yet.
  ///
  /// In en, this message translates to:
  /// **'No suppliers added yet.'**
  String get no_suppliers_yet;

  /// No description provided for @status_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get status_active;

  /// No description provided for @status_inactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get status_inactive;

  /// No description provided for @gst_number_display.
  ///
  /// In en, this message translates to:
  /// **'GST: {number}'**
  String gst_number_display(String number);

  /// No description provided for @no_purchase_orders_yet.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get no_purchase_orders_yet;

  /// No description provided for @purchase_order_supplier_date.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name} · {date}'**
  String purchase_order_supplier_date(String name, String date);

  /// No description provided for @purchase_order_supplier_created_date.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name} · Created: {date}'**
  String purchase_order_supplier_created_date(String name, String date);

  /// No description provided for @purchase_order_supplier_updated_date.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name} · Updated: {date}'**
  String purchase_order_supplier_updated_date(String name, String date);

  /// No description provided for @purchase_order_line_item.
  ///
  /// In en, this message translates to:
  /// **'{name}: {quantity} {unit} @ ₹{price}'**
  String purchase_order_line_item(
    String name,
    String quantity,
    String unit,
    String price,
  );

  /// No description provided for @no_recipes_yet.
  ///
  /// In en, this message translates to:
  /// **'No recipes mapped yet.\nLink menu items to raw materials for auto stock deduction on sales.'**
  String get no_recipes_yet;

  /// No description provided for @this_recipe.
  ///
  /// In en, this message translates to:
  /// **'this recipe'**
  String get this_recipe;

  /// No description provided for @search_default_hint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search_default_hint;

  /// No description provided for @material_name_required.
  ///
  /// In en, this message translates to:
  /// **'Material Name *'**
  String get material_name_required;

  /// No description provided for @please_enter_material_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter material name'**
  String get please_enter_material_name;

  /// No description provided for @select_category_required.
  ///
  /// In en, this message translates to:
  /// **'Please select category'**
  String get select_category_required;

  /// No description provided for @invalid_opening_stock.
  ///
  /// In en, this message translates to:
  /// **'Opening stock must be greater than 0'**
  String get invalid_opening_stock;

  /// No description provided for @min_stock_required.
  ///
  /// In en, this message translates to:
  /// **'Minimum stock alert is required'**
  String get min_stock_required;

  /// No description provided for @invalid_min_stock.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid minimum stock alert (0 or greater)'**
  String get invalid_min_stock;

  /// No description provided for @invalid_purchase_price.
  ///
  /// In en, this message translates to:
  /// **'Purchase price must be greater than 0'**
  String get invalid_purchase_price;

  /// No description provided for @category_example_hint.
  ///
  /// In en, this message translates to:
  /// **'Category (e.g. Vegetables, Dairy)'**
  String get category_example_hint;

  /// No description provided for @opening_stock.
  ///
  /// In en, this message translates to:
  /// **'Opening Stock'**
  String get opening_stock;

  /// No description provided for @min_stock_alert.
  ///
  /// In en, this message translates to:
  /// **'Min Stock Alert'**
  String get min_stock_alert;

  /// No description provided for @purchase_price_per_unit.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price (per unit)'**
  String get purchase_price_per_unit;

  /// No description provided for @supplier_name_required.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name *'**
  String get supplier_name_required;

  /// No description provided for @please_enter_supplier_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter supplier name'**
  String get please_enter_supplier_name;

  /// No description provided for @please_enter_vendor_no.
  ///
  /// In en, this message translates to:
  /// **'Please enter vendor number'**
  String get please_enter_vendor_no;

  /// No description provided for @please_enter_contact_person.
  ///
  /// In en, this message translates to:
  /// **'Please enter contact person'**
  String get please_enter_contact_person;

  /// No description provided for @please_enter_address.
  ///
  /// In en, this message translates to:
  /// **'Please enter address'**
  String get please_enter_address;

  /// No description provided for @please_enter_gst_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter GST number'**
  String get please_enter_gst_number;

  /// No description provided for @phone_label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone_label;

  /// No description provided for @address_label.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address_label;

  /// No description provided for @gst_number_label.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get gst_number_label;

  /// No description provided for @current_stock_label.
  ///
  /// In en, this message translates to:
  /// **'Current: {stock} {unit}'**
  String current_stock_label(String stock, String unit);

  /// No description provided for @transaction_type.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transaction_type;

  /// No description provided for @quantity_with_unit_label.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String quantity_with_unit_label(String unit);

  /// No description provided for @notes_label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes_label;

  /// No description provided for @material_stock_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{current} {unit} · Min: {min} · ₹{price}/unit'**
  String material_stock_subtitle(
    String current,
    String unit,
    String min,
    String price,
  );

  /// No description provided for @adjust_stock_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock'**
  String get adjust_stock_tooltip;

  /// No description provided for @import_products_excel.
  ///
  /// In en, this message translates to:
  /// **'Import Products - Excel (.xlsx)'**
  String get import_products_excel;

  /// No description provided for @import_products_description.
  ///
  /// In en, this message translates to:
  /// **'Select an Excel (.xlsx) file following the BillKaro template format. Required columns: Item Name and Price (₹). Optional: Item Code, Category, Description, Item Image, Unit, Tax %, Price Incl. Tax (₹). Missing categories will be created automatically.'**
  String get import_products_description;

  /// No description provided for @export_products_excel.
  ///
  /// In en, this message translates to:
  /// **'Export Products - Excel (.xlsx)'**
  String get export_products_excel;

  /// No description provided for @export_products_description.
  ///
  /// In en, this message translates to:
  /// **'Export your menu items to an Excel (.xlsx) file using the BillKaro template format. Columns include Item Code, Category, Item Name, Description, Item Image, Unit, Price (₹), Tax %, and Price Incl. Tax (₹).'**
  String get export_products_description;

  /// No description provided for @export_file.
  ///
  /// In en, this message translates to:
  /// **'Export File'**
  String get export_file;

  /// No description provided for @select_file.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get select_file;

  /// No description provided for @import_preview.
  ///
  /// In en, this message translates to:
  /// **'Import preview'**
  String get import_preview;

  /// No description provided for @import_count_items.
  ///
  /// In en, this message translates to:
  /// **'Import {count} item(s)'**
  String import_count_items(int count);

  /// No description provided for @availability_column.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability_column;

  /// No description provided for @stock_units_suffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get stock_units_suffix;

  /// No description provided for @stock_change_range.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String stock_change_range(String before, String after);

  /// No description provided for @gst_label.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get gst_label;

  /// No description provided for @recipe_uses_material.
  ///
  /// In en, this message translates to:
  /// **'Uses {quantity} {unit} of {name}'**
  String recipe_uses_material(String quantity, String unit, String name);

  /// No description provided for @add_recipe.
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get add_recipe;

  /// No description provided for @add_recipe_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add all raw materials needed to make one unit of this item (e.g. bread, cheese, lettuce for a sandwich)'**
  String get add_recipe_subtitle;

  /// No description provided for @add_another_ingredient.
  ///
  /// In en, this message translates to:
  /// **'Add Another Ingredient'**
  String get add_another_ingredient;

  /// No description provided for @recipe_ingredients_section.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipe_ingredients_section;

  /// No description provided for @recipe_need_at_least_one_ingredient.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient with a valid quantity'**
  String get recipe_need_at_least_one_ingredient;

  /// No description provided for @recipe_duplicate_material.
  ///
  /// In en, this message translates to:
  /// **'Each raw material can only be used once per recipe'**
  String get recipe_duplicate_material;

  /// No description provided for @ingredient_number.
  ///
  /// In en, this message translates to:
  /// **'Ingredient {number}'**
  String ingredient_number(int number);

  /// No description provided for @edit_recipe.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get edit_recipe;

  /// No description provided for @select_menu_item.
  ///
  /// In en, this message translates to:
  /// **'Menu Item *'**
  String get select_menu_item;

  /// No description provided for @select_raw_material.
  ///
  /// In en, this message translates to:
  /// **'Raw Material *'**
  String get select_raw_material;

  /// No description provided for @recipe_quantity_hint.
  ///
  /// In en, this message translates to:
  /// **'Quantity per serving *'**
  String get recipe_quantity_hint;

  /// No description provided for @recipe_quantity_helper.
  ///
  /// In en, this message translates to:
  /// **'Used to deduct raw material stock each time this item is sold'**
  String get recipe_quantity_helper;

  /// No description provided for @recipe_quantity_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity greater than 0'**
  String get recipe_quantity_invalid;

  /// No description provided for @select_menu_item_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a menu item'**
  String get select_menu_item_required;

  /// No description provided for @select_raw_material_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a raw material'**
  String get select_raw_material_required;

  /// No description provided for @recipe_ingredients.
  ///
  /// In en, this message translates to:
  /// **'Recipe Ingredients'**
  String get recipe_ingredients;

  /// No description provided for @recipe_ingredients_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Link raw materials to auto-deduct stock when this item is sold'**
  String get recipe_ingredients_subtitle;

  /// No description provided for @add_ingredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get add_ingredient;

  /// No description provided for @no_ingredients_yet.
  ///
  /// In en, this message translates to:
  /// **'No ingredients linked yet'**
  String get no_ingredients_yet;

  /// No description provided for @search_recipes.
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get search_recipes;

  /// No description provided for @recipe_lines_count.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredient(s)'**
  String recipe_lines_count(int count);

  /// No description provided for @create_purchase_order.
  ///
  /// In en, this message translates to:
  /// **'Create Purchase Order'**
  String get create_purchase_order;

  /// No description provided for @create_po.
  ///
  /// In en, this message translates to:
  /// **'Create PO'**
  String get create_po;

  /// No description provided for @save_as_draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get save_as_draft;

  /// No description provided for @po_draft_saved.
  ///
  /// In en, this message translates to:
  /// **'Purchase order saved as draft'**
  String get po_draft_saved;

  /// No description provided for @edit_purchase_order.
  ///
  /// In en, this message translates to:
  /// **'Edit Purchase Order'**
  String get edit_purchase_order;

  /// No description provided for @edit_po.
  ///
  /// In en, this message translates to:
  /// **'Edit PO'**
  String get edit_po;

  /// No description provided for @save_po_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_po_changes;

  /// No description provided for @po_updated.
  ///
  /// In en, this message translates to:
  /// **'Purchase order updated'**
  String get po_updated;

  /// No description provided for @po_cannot_edit.
  ///
  /// In en, this message translates to:
  /// **'Only pending purchase orders can be edited'**
  String get po_cannot_edit;

  /// No description provided for @generate_po_from_low_stock.
  ///
  /// In en, this message translates to:
  /// **'Generate PO from Low Stock'**
  String get generate_po_from_low_stock;

  /// No description provided for @po_header_section.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get po_header_section;

  /// No description provided for @po_line_items_section.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get po_line_items_section;

  /// No description provided for @select_supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier *'**
  String get select_supplier;

  /// No description provided for @select_supplier_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier'**
  String get select_supplier_required;

  /// No description provided for @po_delivery_date_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery date'**
  String get po_delivery_date_required;

  /// No description provided for @po_payment_terms_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter payment terms'**
  String get po_payment_terms_required;

  /// No description provided for @po_line_material_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a material name that exists in inventory'**
  String get po_line_material_required;

  /// No description provided for @po_line_qty_required.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity greater than 0'**
  String get po_line_qty_required;

  /// No description provided for @po_line_rate_required.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate'**
  String get po_line_rate_required;

  /// No description provided for @po_address_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get po_address_name_required;

  /// No description provided for @po_pin_code_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter pin code'**
  String get po_pin_code_required;

  /// No description provided for @po_state_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter state'**
  String get po_state_required;

  /// No description provided for @delivery_date.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get delivery_date;

  /// No description provided for @fill_from_low_stock.
  ///
  /// In en, this message translates to:
  /// **'Fill from Low Stock'**
  String get fill_from_low_stock;

  /// No description provided for @po_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Delivery instructions, reference number, etc.'**
  String get po_notes_hint;

  /// No description provided for @add_line.
  ///
  /// In en, this message translates to:
  /// **'Add Line'**
  String get add_line;

  /// No description provided for @po_order_qty.
  ///
  /// In en, this message translates to:
  /// **'Order Qty'**
  String get po_order_qty;

  /// No description provided for @po_rate.
  ///
  /// In en, this message translates to:
  /// **'Rate (₹)'**
  String get po_rate;

  /// No description provided for @po_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get po_amount;

  /// No description provided for @po_grand_total.
  ///
  /// In en, this message translates to:
  /// **'Grand Total: {total}'**
  String po_grand_total(String total);

  /// No description provided for @po_line_invalid.
  ///
  /// In en, this message translates to:
  /// **'Each line needs a material, quantity > 0, and valid rate'**
  String get po_line_invalid;

  /// No description provided for @po_items_required.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line item'**
  String get po_items_required;

  /// No description provided for @po_order_date.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get po_order_date;

  /// No description provided for @po_received_date.
  ///
  /// In en, this message translates to:
  /// **'Received On'**
  String get po_received_date;

  /// No description provided for @supplier_label.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier_label;

  /// No description provided for @cancel_po.
  ///
  /// In en, this message translates to:
  /// **'Cancel PO'**
  String get cancel_po;

  /// No description provided for @cancel_po_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Purchase Order'**
  String get cancel_po_title;

  /// No description provided for @cancel_po_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this P.O ({name})?'**
  String cancel_po_confirm_message(String name);

  /// No description provided for @keep_po.
  ///
  /// In en, this message translates to:
  /// **'No, Keep It'**
  String get keep_po;

  /// No description provided for @yes_cancel_po.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yes_cancel_po;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @print_po.
  ///
  /// In en, this message translates to:
  /// **'Print PO'**
  String get print_po;

  /// No description provided for @po_payment_terms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get po_payment_terms;

  /// No description provided for @po_reference_no.
  ///
  /// In en, this message translates to:
  /// **'Reference No'**
  String get po_reference_no;

  /// No description provided for @po_document_type.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get po_document_type;

  /// No description provided for @po_billing_address_section.
  ///
  /// In en, this message translates to:
  /// **'Billing Details'**
  String get po_billing_address_section;

  /// No description provided for @po_terms_and_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get po_terms_and_conditions;

  /// No description provided for @po_terms_heading.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions :'**
  String get po_terms_heading;

  /// No description provided for @po_terms_intro.
  ///
  /// In en, this message translates to:
  /// **'These terms and conditions shall form an integral part of the Purchase Order (PO)'**
  String get po_terms_intro;

  /// No description provided for @po_terms_and_conditions_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter terms and conditions for purchase orders. One point per line works best.'**
  String get po_terms_and_conditions_hint;

  /// No description provided for @settings_po_terms.
  ///
  /// In en, this message translates to:
  /// **'PO Terms & Conditions'**
  String get settings_po_terms;

  /// No description provided for @settings_po_terms_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Default text for new purchase orders'**
  String get settings_po_terms_subtitle;

  /// No description provided for @settings_po_print_orientation.
  ///
  /// In en, this message translates to:
  /// **'PO Print Orientation'**
  String get settings_po_print_orientation;

  /// No description provided for @settings_po_print_orientation_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Page layout when printing purchase orders'**
  String get settings_po_print_orientation_subtitle;

  /// No description provided for @po_print_portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get po_print_portrait;

  /// No description provided for @po_print_landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get po_print_landscape;

  /// No description provided for @po_terms_saved.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions saved'**
  String get po_terms_saved;

  /// No description provided for @po_shipping_address_section.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get po_shipping_address_section;

  /// No description provided for @po_same_as_billing.
  ///
  /// In en, this message translates to:
  /// **'Same as billing'**
  String get po_same_as_billing;

  /// No description provided for @po_address_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get po_address_name;

  /// No description provided for @po_address_line1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get po_address_line1;

  /// No description provided for @po_address_line2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get po_address_line2;

  /// No description provided for @po_pin_code.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get po_pin_code;

  /// No description provided for @po_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get po_state;

  /// No description provided for @po_contact_no.
  ///
  /// In en, this message translates to:
  /// **'Contact No'**
  String get po_contact_no;

  /// No description provided for @po_gst_no.
  ///
  /// In en, this message translates to:
  /// **'GST No'**
  String get po_gst_no;

  /// No description provided for @po_sl_no.
  ///
  /// In en, this message translates to:
  /// **'Sl. No'**
  String get po_sl_no;

  /// No description provided for @po_hsn_sac.
  ///
  /// In en, this message translates to:
  /// **'HSN/SAC Code'**
  String get po_hsn_sac;

  /// No description provided for @po_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get po_description;

  /// No description provided for @template_saved_opened.
  ///
  /// In en, this message translates to:
  /// **'Template saved and opened'**
  String get template_saved_opened;

  /// No description provided for @template_saved_to.
  ///
  /// In en, this message translates to:
  /// **'Template saved to: {path}'**
  String template_saved_to(String path);

  /// No description provided for @hold_orders_title.
  ///
  /// In en, this message translates to:
  /// **'Hold Orders'**
  String get hold_orders_title;

  /// No description provided for @all_time.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get all_time;

  /// No description provided for @last_60_min.
  ///
  /// In en, this message translates to:
  /// **'Last 60 Min'**
  String get last_60_min;

  /// No description provided for @no_more_orders.
  ///
  /// In en, this message translates to:
  /// **'No more orders'**
  String get no_more_orders;

  /// No description provided for @no_closed_orders.
  ///
  /// In en, this message translates to:
  /// **'No Closed Orders'**
  String get no_closed_orders;

  /// No description provided for @closed_orders_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Closed orders will appear here'**
  String get closed_orders_empty_hint;

  /// No description provided for @no_hold_orders.
  ///
  /// In en, this message translates to:
  /// **'No Hold Orders'**
  String get no_hold_orders;

  /// No description provided for @hold_orders_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Orders on hold will appear here'**
  String get hold_orders_empty_hint;

  /// No description provided for @on_hold_badge.
  ///
  /// In en, this message translates to:
  /// **'ON HOLD'**
  String get on_hold_badge;

  /// No description provided for @order_items_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String order_items_count(int count);

  /// No description provided for @edit_order.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get edit_order;

  /// No description provided for @update_order.
  ///
  /// In en, this message translates to:
  /// **'Update Order'**
  String get update_order;

  /// No description provided for @modify_order_details_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify order details'**
  String get modify_order_details_subtitle;

  /// No description provided for @delete_order_permanently_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Move this order to Deleted Orders'**
  String get delete_order_permanently_subtitle;

  /// No description provided for @delete_order_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this order? You can restore it later from Deleted Orders.'**
  String get delete_order_confirm_message;

  /// No description provided for @deletedOrders.
  ///
  /// In en, this message translates to:
  /// **'Deleted Orders'**
  String get deletedOrders;

  /// No description provided for @deleted_orders_title.
  ///
  /// In en, this message translates to:
  /// **'Deleted Orders'**
  String get deleted_orders_title;

  /// No description provided for @no_deleted_orders.
  ///
  /// In en, this message translates to:
  /// **'No Deleted Orders'**
  String get no_deleted_orders;

  /// No description provided for @deleted_orders_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Deleted orders will appear here'**
  String get deleted_orders_empty_hint;

  /// No description provided for @stockSummary.
  ///
  /// In en, this message translates to:
  /// **'Stock Summary'**
  String get stockSummary;

  /// No description provided for @stock_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Stock Summary'**
  String get stock_summary_title;

  /// No description provided for @stock_summary_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, category, code…'**
  String get stock_summary_search_hint;

  /// No description provided for @stock_summary_products.
  ///
  /// In en, this message translates to:
  /// **'Raw Materials'**
  String get stock_summary_products;

  /// No description provided for @stock_summary_value.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stock_summary_value;

  /// No description provided for @stock_summary_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get stock_summary_qty;

  /// No description provided for @stock_summary_min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get stock_summary_min;

  /// No description provided for @stock_summary_rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get stock_summary_rate;

  /// No description provided for @stock_summary_empty.
  ///
  /// In en, this message translates to:
  /// **'No raw materials found'**
  String get stock_summary_empty;

  /// No description provided for @stock_summary_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Raw material stock will appear here. Add materials from Inventory.'**
  String get stock_summary_empty_hint;

  /// No description provided for @stock_status_in_stock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get stock_status_in_stock;

  /// No description provided for @stock_status_low_stock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get stock_status_low_stock;

  /// No description provided for @stock_status_out_of_stock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get stock_status_out_of_stock;

  /// No description provided for @deleted_badge.
  ///
  /// In en, this message translates to:
  /// **'DELETED'**
  String get deleted_badge;

  /// No description provided for @restore_order.
  ///
  /// In en, this message translates to:
  /// **'Restore Order'**
  String get restore_order;

  /// No description provided for @restore_order_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Restore this order? It will return to On Hold Orders.'**
  String get restore_order_confirm_message;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @order_moved_to_deleted.
  ///
  /// In en, this message translates to:
  /// **'Order moved to Deleted Orders'**
  String get order_moved_to_deleted;

  /// No description provided for @order_restored_successfully.
  ///
  /// In en, this message translates to:
  /// **'Order restored successfully'**
  String get order_restored_successfully;

  /// No description provided for @customers_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Customers'**
  String customers_count(int count);

  /// No description provided for @no_matching_customers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers'**
  String get no_matching_customers;

  /// No description provided for @unable_to_load_customers.
  ///
  /// In en, this message translates to:
  /// **'Unable to load customers. Please try again.'**
  String get unable_to_load_customers;

  /// No description provided for @unable_to_load_customers_connection.
  ///
  /// In en, this message translates to:
  /// **'Unable to load customers. Please check your connection.'**
  String get unable_to_load_customers_connection;

  /// No description provided for @fetch_customer_from_contacts.
  ///
  /// In en, this message translates to:
  /// **'Fetch customer details directly from your contacts.'**
  String get fetch_customer_from_contacts;

  /// No description provided for @loyalty_discount_label.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Discount'**
  String get loyalty_discount_label;

  /// No description provided for @discount_applied_on_orders.
  ///
  /// In en, this message translates to:
  /// **'Discount will be applied on orders of this customer.'**
  String get discount_applied_on_orders;

  /// No description provided for @save_customer.
  ///
  /// In en, this message translates to:
  /// **'Save Customer'**
  String get save_customer;

  /// No description provided for @select_contact.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get select_contact;

  /// No description provided for @no_contacts_found.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get no_contacts_found;

  /// No description provided for @no_contacts_match_search.
  ///
  /// In en, this message translates to:
  /// **'No contacts match your search'**
  String get no_contacts_match_search;

  /// No description provided for @contact_permission_permanently_denied.
  ///
  /// In en, this message translates to:
  /// **'Contact permission is permanently denied. Please enable it from settings.'**
  String get contact_permission_permanently_denied;

  /// No description provided for @customer_added.
  ///
  /// In en, this message translates to:
  /// **'Customer Added'**
  String get customer_added;

  /// No description provided for @name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name_label;

  /// No description provided for @clear_search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clear_search;

  /// No description provided for @edit_regular_customer.
  ///
  /// In en, this message translates to:
  /// **'Edit Regular Customer'**
  String get edit_regular_customer;

  /// No description provided for @staff_list_title.
  ///
  /// In en, this message translates to:
  /// **'Staff List'**
  String get staff_list_title;

  /// No description provided for @manage_outlet_staff_access.
  ///
  /// In en, this message translates to:
  /// **'Manage your outlet staff access'**
  String get manage_outlet_staff_access;

  /// No description provided for @check_staff_activity.
  ///
  /// In en, this message translates to:
  /// **'Check Staff Activity'**
  String get check_staff_activity;

  /// No description provided for @staff_activity_filter_hint.
  ///
  /// In en, this message translates to:
  /// **'Filter activity by date range and user'**
  String get staff_activity_filter_hint;

  /// No description provided for @role_label.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role_label;

  /// No description provided for @no_matching_staff_found.
  ///
  /// In en, this message translates to:
  /// **'No matching staff found'**
  String get no_matching_staff_found;

  /// No description provided for @no_staff_found.
  ///
  /// In en, this message translates to:
  /// **'No staff found'**
  String get no_staff_found;

  /// No description provided for @try_different_staff_search.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, role, phone, or email.'**
  String get try_different_staff_search;

  /// No description provided for @invite_staff_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Invite your first team member to start managing staff permissions.'**
  String get invite_staff_empty_hint;

  /// No description provided for @unable_to_delete_staff_entry.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete this staff entry'**
  String get unable_to_delete_staff_entry;

  /// No description provided for @remove_staff_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove {name}?'**
  String remove_staff_confirm(String name);

  /// No description provided for @this_staff.
  ///
  /// In en, this message translates to:
  /// **'this staff'**
  String get this_staff;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_active_label.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get status_active_label;

  /// No description provided for @status_inactive_label.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get status_inactive_label;

  /// No description provided for @status_deactivated_label.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get status_deactivated_label;

  /// No description provided for @edit_staff.
  ///
  /// In en, this message translates to:
  /// **'Edit Staff'**
  String get edit_staff;

  /// No description provided for @update_staff.
  ///
  /// In en, this message translates to:
  /// **'Update Staff'**
  String get update_staff;

  /// No description provided for @invite_sent_successfully.
  ///
  /// In en, this message translates to:
  /// **'Invite sent successfully'**
  String get invite_sent_successfully;

  /// No description provided for @reinvite.
  ///
  /// In en, this message translates to:
  /// **'Reinvite'**
  String get reinvite;

  /// No description provided for @reinvite_sent_successfully.
  ///
  /// In en, this message translates to:
  /// **'Invite resent successfully'**
  String get reinvite_sent_successfully;

  /// No description provided for @unique_id.
  ///
  /// In en, this message translates to:
  /// **'Unique ID'**
  String get unique_id;

  /// No description provided for @state_label.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state_label;

  /// No description provided for @district_label.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district_label;

  /// No description provided for @pincode_label.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode_label;

  /// No description provided for @date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get date_of_birth;

  /// No description provided for @join_date.
  ///
  /// In en, this message translates to:
  /// **'Join Date'**
  String get join_date;

  /// No description provided for @gender_label.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender_label;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other_gender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other_gender;

  /// No description provided for @select_gender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get select_gender;

  /// No description provided for @dd_mm_yyyy.
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get dd_mm_yyyy;

  /// No description provided for @mobile_number.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobile_number;

  /// No description provided for @staff_image.
  ///
  /// In en, this message translates to:
  /// **'Staff Image'**
  String get staff_image;

  /// No description provided for @please_select_staff_image.
  ///
  /// In en, this message translates to:
  /// **'Please select a staff image'**
  String get please_select_staff_image;

  /// No description provided for @please_select_date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get please_select_date_of_birth;

  /// No description provided for @please_enter_state.
  ///
  /// In en, this message translates to:
  /// **'Please enter state'**
  String get please_enter_state;

  /// No description provided for @please_enter_district.
  ///
  /// In en, this message translates to:
  /// **'Please enter district'**
  String get please_enter_district;

  /// No description provided for @please_enter_pincode.
  ///
  /// In en, this message translates to:
  /// **'Please enter pincode'**
  String get please_enter_pincode;

  /// No description provided for @please_enter_valid_pincode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit pincode'**
  String get please_enter_valid_pincode;

  /// No description provided for @tap_to_upload_image.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload image'**
  String get tap_to_upload_image;

  /// No description provided for @staff_member_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Staff member updated successfully'**
  String get staff_member_updated_successfully;

  /// No description provided for @role_overview.
  ///
  /// In en, this message translates to:
  /// **'Role Overview'**
  String get role_overview;

  /// No description provided for @allow_biller_create_menu_items.
  ///
  /// In en, this message translates to:
  /// **'Allow biller to create menu items'**
  String get allow_biller_create_menu_items;

  /// No description provided for @allow_biller_edit_menu_items.
  ///
  /// In en, this message translates to:
  /// **'Allow biller to edit existing menu items'**
  String get allow_biller_edit_menu_items;

  /// No description provided for @biller_overview_create_orders.
  ///
  /// In en, this message translates to:
  /// **'Create and print orders and KOT.'**
  String get biller_overview_create_orders;

  /// No description provided for @biller_overview_view_items.
  ///
  /// In en, this message translates to:
  /// **'View all items and use them for billing.'**
  String get biller_overview_view_items;

  /// No description provided for @biller_overview_cannot_delete.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete any orders (self or others).'**
  String get biller_overview_cannot_delete;

  /// No description provided for @biller_overview_cannot_access_others.
  ///
  /// In en, this message translates to:
  /// **'Cannot access orders created by other members.'**
  String get biller_overview_cannot_access_others;

  /// No description provided for @select_user_role.
  ///
  /// In en, this message translates to:
  /// **'Select User Role'**
  String get select_user_role;

  /// No description provided for @invite_team_member_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a team member and assign a role.'**
  String get invite_team_member_subtitle;

  /// No description provided for @update_team_member_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Update team member details and role.'**
  String get update_team_member_subtitle;

  /// No description provided for @plans_pricing_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan — printer bundles include free home delivery'**
  String get plans_pricing_subtitle;

  /// No description provided for @secure_payment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get secure_payment;

  /// No description provided for @free_printer_delivery.
  ///
  /// In en, this message translates to:
  /// **'Free Printer Delivery'**
  String get free_printer_delivery;

  /// No description provided for @support_24_7.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get support_24_7;

  /// No description provided for @no_plans_available.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get no_plans_available;

  /// No description provided for @please_check_back_later.
  ///
  /// In en, this message translates to:
  /// **'Please check back later'**
  String get please_check_back_later;

  /// No description provided for @printer_feature_free_home_delivery.
  ///
  /// In en, this message translates to:
  /// **'Free Home Delivery'**
  String get printer_feature_free_home_delivery;

  /// No description provided for @printer_feature_bluetooth_usb.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth + USB Support'**
  String get printer_feature_bluetooth_usb;

  /// No description provided for @printer_feature_one_year_warranty.
  ///
  /// In en, this message translates to:
  /// **'1 Year Warranty'**
  String get printer_feature_one_year_warranty;

  /// No description provided for @printer_not_included_in_plan.
  ///
  /// In en, this message translates to:
  /// **'Printer not included in this plan.'**
  String get printer_not_included_in_plan;

  /// No description provided for @includes_thermal_printer.
  ///
  /// In en, this message translates to:
  /// **'Includes Thermal Printer'**
  String get includes_thermal_printer;

  /// No description provided for @whats_included.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get whats_included;

  /// No description provided for @printer_features.
  ///
  /// In en, this message translates to:
  /// **'Printer Features'**
  String get printer_features;

  /// No description provided for @current_plan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get current_plan;

  /// No description provided for @already_subscribed.
  ///
  /// In en, this message translates to:
  /// **'Already Subscribed'**
  String get already_subscribed;

  /// No description provided for @outlet_already_subscribed.
  ///
  /// In en, this message translates to:
  /// **'This outlet already has an active subscription.'**
  String get outlet_already_subscribed;

  /// No description provided for @buy_now.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buy_now;

  /// No description provided for @buy_now_with_printer.
  ///
  /// In en, this message translates to:
  /// **'Buy Now with Printer'**
  String get buy_now_with_printer;

  /// No description provided for @discount_percent_off.
  ///
  /// In en, this message translates to:
  /// **'{percent}% OFF'**
  String discount_percent_off(int percent);

  /// No description provided for @invalid_duration.
  ///
  /// In en, this message translates to:
  /// **'Invalid duration'**
  String get invalid_duration;

  /// No description provided for @duration_months.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String duration_months(int count);

  /// No description provided for @duration_years.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String duration_years(int count);

  /// No description provided for @duration_years_months.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year} other{{years} years}} {months, plural, =1{1 month} other{{months} months}}'**
  String duration_years_months(int years, int months);

  /// No description provided for @payment_activation_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment successful but subscription activation failed. Please contact support.'**
  String get payment_activation_failed;

  /// No description provided for @failed_create_payment_order.
  ///
  /// In en, this message translates to:
  /// **'Failed to create payment order. Please try again.'**
  String get failed_create_payment_order;

  /// No description provided for @user_not_logged_in_retry.
  ///
  /// In en, this message translates to:
  /// **'User not logged in. Please login and try again.'**
  String get user_not_logged_in_retry;

  /// No description provided for @no_outlet_selected_retry.
  ///
  /// In en, this message translates to:
  /// **'No outlet selected. Please select an outlet and try again.'**
  String get no_outlet_selected_retry;

  /// No description provided for @invalid_order_response.
  ///
  /// In en, this message translates to:
  /// **'Invalid order response. Please try again.'**
  String get invalid_order_response;

  /// No description provided for @subscription_purchase.
  ///
  /// In en, this message translates to:
  /// **'Subscription Purchase'**
  String get subscription_purchase;

  /// No description provided for @error_occurred_try_again.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get error_occurred_try_again;

  /// No description provided for @select_message_template.
  ///
  /// In en, this message translates to:
  /// **'Select Message Template'**
  String get select_message_template;

  /// No description provided for @choose_whatsapp_template_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose a WhatsApp message template. You can edit it before sending.'**
  String get choose_whatsapp_template_hint;

  /// No description provided for @discount_offer.
  ///
  /// In en, this message translates to:
  /// **'Discount Offer'**
  String get discount_offer;

  /// No description provided for @template_discount_preview_prefix.
  ///
  /// In en, this message translates to:
  /// **'Special offer for our loyal customers of '**
  String get template_discount_preview_prefix;

  /// No description provided for @restaurant_name_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name'**
  String get restaurant_name_placeholder;

  /// No description provided for @template_discount_get.
  ///
  /// In en, this message translates to:
  /// **'! Get '**
  String get template_discount_get;

  /// No description provided for @discount_value_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Discount value'**
  String get discount_value_placeholder;

  /// No description provided for @template_discount_suffix.
  ///
  /// In en, this message translates to:
  /// **' off on your next visit. Show this message at the restaurant for discount.'**
  String get template_discount_suffix;

  /// No description provided for @new_menu.
  ///
  /// In en, this message translates to:
  /// **'New Menu'**
  String get new_menu;

  /// No description provided for @template_new_menu_suffix.
  ///
  /// In en, this message translates to:
  /// **' has added new items to their menu. Come and try these items today!'**
  String get template_new_menu_suffix;

  /// No description provided for @festival_wishes.
  ///
  /// In en, this message translates to:
  /// **'Festival Wishes'**
  String get festival_wishes;

  /// No description provided for @template_festival_wishes_you.
  ///
  /// In en, this message translates to:
  /// **' wishes you a happy '**
  String get template_festival_wishes_you;

  /// No description provided for @festival_name_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Festival Name'**
  String get festival_name_placeholder;

  /// No description provided for @template_festival_suffix.
  ///
  /// In en, this message translates to:
  /// **'. Visit the restaurant for new festival menu and discounts!'**
  String get template_festival_suffix;

  /// No description provided for @use_template.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get use_template;

  /// No description provided for @discount_offer_from_restaurant.
  ///
  /// In en, this message translates to:
  /// **'Discount Offer from {name}'**
  String discount_offer_from_restaurant(String name);

  /// No description provided for @enjoy_new_menu_at.
  ///
  /// In en, this message translates to:
  /// **'Enjoy New Menu at {name}'**
  String enjoy_new_menu_at(String name);

  /// No description provided for @happy_festival_from.
  ///
  /// In en, this message translates to:
  /// **'Happy {festival} from {name}'**
  String happy_festival_from(String festival, String name);

  /// No description provided for @no_customers_with_phone.
  ///
  /// In en, this message translates to:
  /// **'No customers with phone numbers found. Add regular customers first.'**
  String get no_customers_with_phone;

  /// No description provided for @send_whatsapp_confirm.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp messages to {count} customers via the server?'**
  String send_whatsapp_confirm(int count);

  /// No description provided for @request_timed_out_bulk.
  ///
  /// In en, this message translates to:
  /// **'Request timed out or failed. If you have many customers, wait and check campaign history in the database before resending.'**
  String get request_timed_out_bulk;

  /// No description provided for @successfully_sent_messages.
  ///
  /// In en, this message translates to:
  /// **'Successfully sent {count} messages'**
  String successfully_sent_messages(int count);

  /// No description provided for @sent_failed_summary.
  ///
  /// In en, this message translates to:
  /// **'Sent: {success}, Failed: {failed}'**
  String sent_failed_summary(int success, int failed);

  /// No description provided for @sending_results.
  ///
  /// In en, this message translates to:
  /// **'Sending Results'**
  String get sending_results;

  /// No description provided for @success_label.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success_label;

  /// No description provided for @failed_label.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed_label;

  /// No description provided for @sent_successfully.
  ///
  /// In en, this message translates to:
  /// **'Sent successfully'**
  String get sent_successfully;

  /// No description provided for @message_failed_error.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String message_failed_error(String error);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknown_error;

  /// No description provided for @enter_custom_fields.
  ///
  /// In en, this message translates to:
  /// **'Enter Custom Fields'**
  String get enter_custom_fields;

  /// No description provided for @customers_will_receive.
  ///
  /// In en, this message translates to:
  /// **'{count} customers will receive this message'**
  String customers_will_receive(int count);

  /// No description provided for @restaurant_name_label.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name'**
  String get restaurant_name_label;

  /// No description provided for @discount_value_percent_label.
  ///
  /// In en, this message translates to:
  /// **'Discount value (%)'**
  String get discount_value_percent_label;

  /// No description provided for @festival_name_label.
  ///
  /// In en, this message translates to:
  /// **'Festival Name'**
  String get festival_name_label;

  /// No description provided for @whatsapp_msg_discount.
  ///
  /// In en, this message translates to:
  /// **'Hello! 🎉\n\nGet {discount}% OFF on your next order at {restaurant}!\n\nThis is a limited time offer. Use code: SAVE{discount}\n\nOrder now and enjoy delicious food with amazing savings!\n\nThank you for being a valued customer! ❤️'**
  String whatsapp_msg_discount(String discount, String restaurant);

  /// No description provided for @whatsapp_msg_menu.
  ///
  /// In en, this message translates to:
  /// **'Hello! 🍽️\n\nExciting news from {restaurant}!\n\nWe\'ve just launched our new menu with amazing dishes. Come try our latest specialties!\n\nVisit us today and enjoy great food! 😊\n\nBest regards,\n{restaurant} Team'**
  String whatsapp_msg_menu(String restaurant);

  /// No description provided for @whatsapp_msg_festival.
  ///
  /// In en, this message translates to:
  /// **'Hello! 🎊\n\n{restaurant} wishes you a very Happy {festival}!\n\nVisit us for our special festival menu and exclusive discounts.\n\nCelebrate with great food! 🍽️\n\nWarm wishes,\n{restaurant} Team'**
  String whatsapp_msg_festival(String restaurant, String festival);

  /// No description provided for @whatsapp_msg_default.
  ///
  /// In en, this message translates to:
  /// **'Hello from {restaurant}! 👋\n\nWe have an important update for you. Thank you for being a loyal customer!\n\nVisit us soon! ❤️'**
  String whatsapp_msg_default(String restaurant);

  /// No description provided for @printer_settings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printer_settings;

  /// No description provided for @ethernet.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get ethernet;

  /// No description provided for @available_printers.
  ///
  /// In en, this message translates to:
  /// **'Available printers'**
  String get available_printers;

  /// No description provided for @printer_help_assign_bill_kot.
  ///
  /// In en, this message translates to:
  /// **'Assign Bill for counter receipts and KOT for kitchen tickets. Use USB, Bluetooth, or Ethernet (LAN) depending on your setup.'**
  String get printer_help_assign_bill_kot;

  /// No description provided for @print_routing.
  ///
  /// In en, this message translates to:
  /// **'Print routing'**
  String get print_routing;

  /// No description provided for @print_routing_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign bill and KOT printers separately.'**
  String get print_routing_subtitle;

  /// No description provided for @bill_printer.
  ///
  /// In en, this message translates to:
  /// **'Bill Printer'**
  String get bill_printer;

  /// No description provided for @kot_printer.
  ///
  /// In en, this message translates to:
  /// **'KOT Printer'**
  String get kot_printer;

  /// No description provided for @use_bill_printer_for_kot.
  ///
  /// In en, this message translates to:
  /// **'Use bill printer for KOT'**
  String get use_bill_printer_for_kot;

  /// No description provided for @multiple_printer_settings.
  ///
  /// In en, this message translates to:
  /// **'Multiple Printer Settings'**
  String get multiple_printer_settings;

  /// No description provided for @tap_bill_or_kot_below.
  ///
  /// In en, this message translates to:
  /// **'Tap Bill or KOT on a device below.'**
  String get tap_bill_or_kot_below;

  /// No description provided for @not_assigned_pick_below.
  ///
  /// In en, this message translates to:
  /// **'Not assigned — pick Bill or KOT below'**
  String get not_assigned_pick_below;

  /// No description provided for @not_assigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get not_assigned;

  /// No description provided for @test_print.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get test_print;

  /// No description provided for @remove_assignment.
  ///
  /// In en, this message translates to:
  /// **'Remove assignment'**
  String get remove_assignment;

  /// No description provided for @bill_label.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill_label;

  /// No description provided for @kot_label.
  ///
  /// In en, this message translates to:
  /// **'KOT'**
  String get kot_label;

  /// No description provided for @status_online.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get status_online;

  /// No description provided for @status_offline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get status_offline;

  /// No description provided for @bluetooth_ble.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (BLE)'**
  String get bluetooth_ble;

  /// No description provided for @bluetooth_paired.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth (paired)'**
  String get bluetooth_paired;

  /// No description provided for @ethernet_lan.
  ///
  /// In en, this message translates to:
  /// **'Ethernet / LAN'**
  String get ethernet_lan;

  /// No description provided for @no_bluetooth_printer_connected.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth printer connected'**
  String get no_bluetooth_printer_connected;

  /// No description provided for @no_usb_printer_connected.
  ///
  /// In en, this message translates to:
  /// **'No USB printer connected'**
  String get no_usb_printer_connected;

  /// No description provided for @no_ethernet_printer_connected.
  ///
  /// In en, this message translates to:
  /// **'No Ethernet printer connected'**
  String get no_ethernet_printer_connected;

  /// No description provided for @no_paired_printer_connected.
  ///
  /// In en, this message translates to:
  /// **'No paired printer connected'**
  String get no_paired_printer_connected;

  /// No description provided for @ble_printer.
  ///
  /// In en, this message translates to:
  /// **'BLE Printer'**
  String get ble_printer;

  /// No description provided for @usb_printer.
  ///
  /// In en, this message translates to:
  /// **'USB Printer'**
  String get usb_printer;

  /// No description provided for @printer_fallback_name.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printer_fallback_name;

  /// No description provided for @search_bluetooth_devices_hint.
  ///
  /// In en, this message translates to:
  /// **'Search Bluetooth devices…'**
  String get search_bluetooth_devices_hint;

  /// No description provided for @search_usb_printers_hint.
  ///
  /// In en, this message translates to:
  /// **'Search USB printers…'**
  String get search_usb_printers_hint;

  /// No description provided for @search_printers_hint.
  ///
  /// In en, this message translates to:
  /// **'Search printers…'**
  String get search_printers_hint;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// No description provided for @scanning_nearby_printers.
  ///
  /// In en, this message translates to:
  /// **'Scanning for nearby printers…'**
  String get scanning_nearby_printers;

  /// No description provided for @no_bluetooth_printers_found.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth printers found.\nTurn on the printer and tap Scan.'**
  String get no_bluetooth_printers_found;

  /// No description provided for @no_devices_match_search.
  ///
  /// In en, this message translates to:
  /// **'No devices match your search.'**
  String get no_devices_match_search;

  /// No description provided for @paired_bluetooth_devices.
  ///
  /// In en, this message translates to:
  /// **'Paired Bluetooth Devices'**
  String get paired_bluetooth_devices;

  /// No description provided for @no_paired_devices_found.
  ///
  /// In en, this message translates to:
  /// **'No paired devices found'**
  String get no_paired_devices_found;

  /// No description provided for @scan_devices.
  ///
  /// In en, this message translates to:
  /// **'Scan Devices'**
  String get scan_devices;

  /// No description provided for @looking_for_usb_printers.
  ///
  /// In en, this message translates to:
  /// **'Looking for USB printers…'**
  String get looking_for_usb_printers;

  /// No description provided for @no_usb_printers_found.
  ///
  /// In en, this message translates to:
  /// **'No USB printers found.\nConnect the cable and tap Scan.'**
  String get no_usb_printers_found;

  /// No description provided for @no_usb_printers_match_search.
  ///
  /// In en, this message translates to:
  /// **'No USB printers match your search.'**
  String get no_usb_printers_match_search;

  /// No description provided for @usb_printers.
  ///
  /// In en, this message translates to:
  /// **'USB printers'**
  String get usb_printers;

  /// No description provided for @scan_usb_printers.
  ///
  /// In en, this message translates to:
  /// **'Scan USB printers'**
  String get scan_usb_printers;

  /// No description provided for @scanning_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning_ellipsis;

  /// No description provided for @printer_ip_network_hint.
  ///
  /// In en, this message translates to:
  /// **'Printer IP on your network (port 9100).'**
  String get printer_ip_network_hint;

  /// No description provided for @ip_address.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get ip_address;

  /// No description provided for @port_label.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port_label;

  /// No description provided for @enter_ip_above.
  ///
  /// In en, this message translates to:
  /// **'Enter IP above'**
  String get enter_ip_above;

  /// No description provided for @connected_to_label.
  ///
  /// In en, this message translates to:
  /// **'Connected: {label}'**
  String connected_to_label(String label);

  /// No description provided for @not_connected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get not_connected;

  /// No description provided for @connected_status.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected_status;

  /// No description provided for @paper_size.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get paper_size;

  /// No description provided for @paper_size_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select thermal roll width for bills and KOT receipts.'**
  String get paper_size_subtitle;

  /// No description provided for @paper_size_2inch.
  ///
  /// In en, this message translates to:
  /// **'2\" (58mm)'**
  String get paper_size_2inch;

  /// No description provided for @paper_size_3inch.
  ///
  /// In en, this message translates to:
  /// **'3\" (80mm)'**
  String get paper_size_3inch;

  /// No description provided for @paper_size_4inch.
  ///
  /// In en, this message translates to:
  /// **'4\" (104mm)'**
  String get paper_size_4inch;

  /// No description provided for @paper_size_saved.
  ///
  /// In en, this message translates to:
  /// **'Paper size set to {size}'**
  String paper_size_saved(String size);

  /// No description provided for @printer_setup.
  ///
  /// In en, this message translates to:
  /// **'Printer setup'**
  String get printer_setup;

  /// No description provided for @same_as_bill.
  ///
  /// In en, this message translates to:
  /// **'Same as Bill'**
  String get same_as_bill;

  /// No description provided for @auto_connect_on_launch.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect on launch'**
  String get auto_connect_on_launch;

  /// No description provided for @remove_saved_printer_message.
  ///
  /// In en, this message translates to:
  /// **'This clears the saved printer and turns off auto-connect.'**
  String get remove_saved_printer_message;

  /// No description provided for @bill_role_summary.
  ///
  /// In en, this message translates to:
  /// **'Bill: {name}'**
  String bill_role_summary(String name);

  /// No description provided for @bill_role_not_set.
  ///
  /// In en, this message translates to:
  /// **'Bill: not set'**
  String get bill_role_not_set;

  /// No description provided for @kot_role_summary.
  ///
  /// In en, this message translates to:
  /// **'KOT: {name}'**
  String kot_role_summary(String name);

  /// No description provided for @kot_role_not_set.
  ///
  /// In en, this message translates to:
  /// **'KOT: not set'**
  String get kot_role_not_set;

  /// No description provided for @assign_from_device_below.
  ///
  /// In en, this message translates to:
  /// **'Assign from a device below'**
  String get assign_from_device_below;

  /// No description provided for @bluetooth_on.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth on'**
  String get bluetooth_on;

  /// No description provided for @bluetooth_off.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth off'**
  String get bluetooth_off;

  /// No description provided for @turn_on_bluetooth_to_scan.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth to scan for printers.'**
  String get turn_on_bluetooth_to_scan;

  /// No description provided for @scan_devices_action.
  ///
  /// In en, this message translates to:
  /// **'Scan devices'**
  String get scan_devices_action;

  /// No description provided for @paired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get paired;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @assign_label.
  ///
  /// In en, this message translates to:
  /// **'Assign:'**
  String get assign_label;

  /// No description provided for @connect_via_usb_otg.
  ///
  /// In en, this message translates to:
  /// **'Connect via USB OTG, then scan.'**
  String get connect_via_usb_otg;

  /// No description provided for @auto_connect_enabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect enabled'**
  String get auto_connect_enabled;

  /// No description provided for @auto_connect_disabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect disabled'**
  String get auto_connect_disabled;

  /// No description provided for @enter_valid_ip_example.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address (e.g. 192.168.1.100)'**
  String get enter_valid_ip_example;

  /// No description provided for @enter_valid_port_default.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port (default 9100)'**
  String get enter_valid_port_default;

  /// No description provided for @ethernet_printer_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Ethernet printer disconnected'**
  String get ethernet_printer_disconnected;

  /// No description provided for @connected_to_endpoint.
  ///
  /// In en, this message translates to:
  /// **'Connected to {endpoint}'**
  String connected_to_endpoint(String endpoint);

  /// No description provided for @could_not_connect_network_printer.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check IP, port, and that the printer is on the same network.'**
  String get could_not_connect_network_printer;

  /// No description provided for @enter_valid_ip_first.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address first'**
  String get enter_valid_ip_first;

  /// No description provided for @enter_valid_port.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port'**
  String get enter_valid_port;

  /// No description provided for @connect_printer_first.
  ///
  /// In en, this message translates to:
  /// **'Connect to the printer first'**
  String get connect_printer_first;

  /// No description provided for @role_printer_assigned.
  ///
  /// In en, this message translates to:
  /// **'{role} printer: {name}'**
  String role_printer_assigned(String role, String name);

  /// No description provided for @role_printer_cleared.
  ///
  /// In en, this message translates to:
  /// **'{role} printer cleared'**
  String role_printer_cleared(String role);

  /// No description provided for @role_test_print_sent.
  ///
  /// In en, this message translates to:
  /// **'{role} test print sent'**
  String role_test_print_sent(String role);

  /// No description provided for @operation_failed_error.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String operation_failed_error(String error);

  /// No description provided for @ethernet_printer_name.
  ///
  /// In en, this message translates to:
  /// **'Ethernet {ip}'**
  String ethernet_printer_name(String ip);

  /// No description provided for @snackbar_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get snackbar_success;

  /// No description provided for @snackbar_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get snackbar_error;

  /// No description provided for @snackbar_removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get snackbar_removed;

  /// No description provided for @clear_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear_tooltip;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @total_visits.
  ///
  /// In en, this message translates to:
  /// **'Total Visits'**
  String get total_visits;

  /// No description provided for @customer_order_value.
  ///
  /// In en, this message translates to:
  /// **'Order Value'**
  String get customer_order_value;

  /// No description provided for @avg_order.
  ///
  /// In en, this message translates to:
  /// **'Avg Order'**
  String get avg_order;

  /// No description provided for @customer_total_discount.
  ///
  /// In en, this message translates to:
  /// **'Total Discount'**
  String get customer_total_discount;

  /// No description provided for @latest_order.
  ///
  /// In en, this message translates to:
  /// **'Latest Order'**
  String get latest_order;

  /// No description provided for @bill_number_short.
  ///
  /// In en, this message translates to:
  /// **'Bill #{number}'**
  String bill_number_short(String number);

  /// No description provided for @bill_amount_summary.
  ///
  /// In en, this message translates to:
  /// **'Bill #{billNumber} • ₹{amount}'**
  String bill_amount_summary(String billNumber, String amount);

  /// No description provided for @order_history.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get order_history;

  /// No description provided for @no_orders_yet_for_customer.
  ///
  /// In en, this message translates to:
  /// **'No orders yet for this customer'**
  String get no_orders_yet_for_customer;

  /// No description provided for @status_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get status_closed;

  /// No description provided for @no_orders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get no_orders;

  /// No description provided for @showing_orders_range.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total}'**
  String showing_orders_range(int start, int end, int total);

  /// No description provided for @unable_to_load_customer_details.
  ///
  /// In en, this message translates to:
  /// **'Unable to load customer details.'**
  String get unable_to_load_customer_details;

  /// No description provided for @unable_to_load_customer_details_retry.
  ///
  /// In en, this message translates to:
  /// **'Unable to load customer details. Please try again.'**
  String get unable_to_load_customer_details_retry;

  /// No description provided for @invalid_customer.
  ///
  /// In en, this message translates to:
  /// **'Invalid customer'**
  String get invalid_customer;

  /// No description provided for @order_discount_amount.
  ///
  /// In en, this message translates to:
  /// **' • Discount ₹{amount}'**
  String order_discount_amount(String amount);

  /// No description provided for @billing_view.
  ///
  /// In en, this message translates to:
  /// **'Billing View'**
  String get billing_view;

  /// No description provided for @billing_image_view.
  ///
  /// In en, this message translates to:
  /// **'Image View'**
  String get billing_image_view;

  /// No description provided for @billing_list_view_option.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get billing_list_view_option;

  /// No description provided for @introducing_kot_mode.
  ///
  /// In en, this message translates to:
  /// **'INTRODUCING KOT MODE'**
  String get introducing_kot_mode;

  /// No description provided for @kot_mode_choose_handling.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to handle kitchen Order & Billing'**
  String get kot_mode_choose_handling;

  /// No description provided for @kot_and_hold_description.
  ///
  /// In en, this message translates to:
  /// **'Generate KOT without billing. You can add more KOT\'s to the same order and bill later.'**
  String get kot_and_hold_description;

  /// No description provided for @kot_and_bill_description.
  ///
  /// In en, this message translates to:
  /// **'Generate KOT and final bill together in one step.'**
  String get kot_and_bill_description;

  /// No description provided for @kot_buttons_update_info.
  ///
  /// In en, this message translates to:
  /// **'Buttons Will Update On The Order Screen:'**
  String get kot_buttons_update_info;

  /// No description provided for @save_hold_to_kot_hold.
  ///
  /// In en, this message translates to:
  /// **'Save & Hold → KOT & Hold'**
  String get save_hold_to_kot_hold;

  /// No description provided for @save_bill_to_kot_bill.
  ///
  /// In en, this message translates to:
  /// **'Save & Bill → KOT & Bill'**
  String get save_bill_to_kot_bill;

  /// No description provided for @got_it.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get got_it;

  /// No description provided for @voice_add_menu_items_title.
  ///
  /// In en, this message translates to:
  /// **'Voice: Add Menu Items'**
  String get voice_add_menu_items_title;

  /// No description provided for @mic_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get mic_stop;

  /// No description provided for @mic_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mic_start;

  /// No description provided for @listening_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening_ellipsis;

  /// No description provided for @voice_add_menu_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap mic and say e.g. \"Tea 15 in Beverages, Coffee 40 category Beverages\".\nWe\'ll auto-create rows with categories, you can edit before submit.'**
  String get voice_add_menu_hint;

  /// No description provided for @item_name_label.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get item_name_label;

  /// No description provided for @price_label.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price_label;

  /// No description provided for @microphone_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to use voice input.'**
  String get microphone_permission_required;

  /// No description provided for @voice_input_requires_internet.
  ///
  /// In en, this message translates to:
  /// **'Voice input requires an internet connection. Please check your connection and try again.'**
  String get voice_input_requires_internet;

  /// No description provided for @voice_error.
  ///
  /// In en, this message translates to:
  /// **'Voice error: {error}'**
  String voice_error(String error);

  /// No description provided for @no_items_to_add.
  ///
  /// In en, this message translates to:
  /// **'No items to add.'**
  String get no_items_to_add;

  /// No description provided for @please_fill_item_name_price.
  ///
  /// In en, this message translates to:
  /// **'Please fill item name + price.'**
  String get please_fill_item_name_price;

  /// No description provided for @added_items_offline.
  ///
  /// In en, this message translates to:
  /// **'Added {count} item(s) offline.'**
  String added_items_offline(int count);

  /// No description provided for @failed_to_add_item_named.
  ///
  /// In en, this message translates to:
  /// **'Failed to add \"{name}\"'**
  String failed_to_add_item_named(String name);

  /// No description provided for @added_items_success.
  ///
  /// In en, this message translates to:
  /// **'Added {count} item(s) successfully.'**
  String added_items_success(int count);

  /// No description provided for @staff_activity_title.
  ///
  /// In en, this message translates to:
  /// **'Staff Activity'**
  String get staff_activity_title;

  /// No description provided for @activity_log.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activity_log;

  /// No description provided for @staff_activity_filters_hint.
  ///
  /// In en, this message translates to:
  /// **'Narrow the activity by time, user and activity type.'**
  String get staff_activity_filters_hint;

  /// No description provided for @no_activities_yet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get no_activities_yet;

  /// No description provided for @select_time_period.
  ///
  /// In en, this message translates to:
  /// **'Select Time Period'**
  String get select_time_period;

  /// No description provided for @select_user.
  ///
  /// In en, this message translates to:
  /// **'Select User'**
  String get select_user;

  /// No description provided for @select_activity_type.
  ///
  /// In en, this message translates to:
  /// **'Select Activity Type'**
  String get select_activity_type;

  /// No description provided for @select_date_range.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get select_date_range;

  /// No description provided for @all_users.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get all_users;

  /// No description provided for @no_users_found.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get no_users_found;

  /// No description provided for @from_date.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get from_date;

  /// No description provided for @to_date.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get to_date;

  /// No description provided for @date_range_to_separator.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get date_range_to_separator;

  /// No description provided for @this_financial_year.
  ///
  /// In en, this message translates to:
  /// **'This Financial Year'**
  String get this_financial_year;

  /// No description provided for @all_activities.
  ///
  /// In en, this message translates to:
  /// **'All Activities'**
  String get all_activities;

  /// No description provided for @activity_type.
  ///
  /// In en, this message translates to:
  /// **'Activity Type'**
  String get activity_type;

  /// No description provided for @order_added.
  ///
  /// In en, this message translates to:
  /// **'Order Added'**
  String get order_added;

  /// No description provided for @order_deleted.
  ///
  /// In en, this message translates to:
  /// **'Order Deleted'**
  String get order_deleted;

  /// No description provided for @customer_deleted.
  ///
  /// In en, this message translates to:
  /// **'Customer Deleted'**
  String get customer_deleted;

  /// No description provided for @customer_edited.
  ///
  /// In en, this message translates to:
  /// **'Customer Edited'**
  String get customer_edited;

  /// No description provided for @item_added.
  ///
  /// In en, this message translates to:
  /// **'Item Added'**
  String get item_added;

  /// No description provided for @item_deleted.
  ///
  /// In en, this message translates to:
  /// **'Item Deleted'**
  String get item_deleted;

  /// No description provided for @item_edited.
  ///
  /// In en, this message translates to:
  /// **'Item Edited'**
  String get item_edited;

  /// No description provided for @staff_added.
  ///
  /// In en, this message translates to:
  /// **'Staff Added'**
  String get staff_added;

  /// No description provided for @staff_deleted.
  ///
  /// In en, this message translates to:
  /// **'Staff Deleted'**
  String get staff_deleted;

  /// No description provided for @staff_updated.
  ///
  /// In en, this message translates to:
  /// **'Staff Updated'**
  String get staff_updated;

  /// No description provided for @activity_fallback.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity_fallback;

  /// No description provided for @users_label.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users_label;

  /// No description provided for @activity_entity_name.
  ///
  /// In en, this message translates to:
  /// **'Name : {name}'**
  String activity_entity_name(String name);

  /// No description provided for @activity_entity_category.
  ///
  /// In en, this message translates to:
  /// **'Category : {category}'**
  String activity_entity_category(String category);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @time_period.
  ///
  /// In en, this message translates to:
  /// **'Time period'**
  String get time_period;

  /// No description provided for @time_period_sheet_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose the range used for activity and filters.'**
  String get time_period_sheet_hint;

  /// No description provided for @time_period_today_subtitle.
  ///
  /// In en, this message translates to:
  /// **'From midnight through end of today'**
  String get time_period_today_subtitle;

  /// No description provided for @time_period_this_week_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Monday through Sunday of this week'**
  String get time_period_this_week_subtitle;

  /// No description provided for @time_period_this_month_subtitle.
  ///
  /// In en, this message translates to:
  /// **'First day to last day of this month'**
  String get time_period_this_month_subtitle;

  /// No description provided for @time_period_this_quarter_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Current calendar quarter'**
  String get time_period_this_quarter_subtitle;

  /// No description provided for @time_period_financial_year_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Apr–Mar financial year (India)'**
  String get time_period_financial_year_subtitle;

  /// No description provided for @time_period_custom_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the date range chip to pick dates'**
  String get time_period_custom_subtitle;

  /// No description provided for @activity_type_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Activity type'**
  String get activity_type_sheet_title;

  /// No description provided for @activity_type_sheet_hint.
  ///
  /// In en, this message translates to:
  /// **'Filter the log by what changed in your outlet.'**
  String get activity_type_sheet_hint;

  /// No description provided for @show_every_activity_type.
  ///
  /// In en, this message translates to:
  /// **'Show every activity type'**
  String get show_every_activity_type;

  /// No description provided for @staff_filter.
  ///
  /// In en, this message translates to:
  /// **'Staff filter'**
  String get staff_filter;

  /// No description provided for @staff_filter_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose whose activity appears in the log.'**
  String get staff_filter_hint;

  /// No description provided for @no_staff_found_hint.
  ///
  /// In en, this message translates to:
  /// **'Add staff to this outlet or check your connection.'**
  String get no_staff_found_hint;

  /// No description provided for @all_users_title.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get all_users_title;

  /// No description provided for @all_users_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Activity from everyone in this outlet'**
  String get all_users_subtitle;

  /// No description provided for @date_range.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get date_range;

  /// No description provided for @date_range_sheet_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick start and end dates. The time period chip switches to Custom when you apply.'**
  String get date_range_sheet_hint;

  /// No description provided for @from_date_short.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from_date_short;

  /// No description provided for @tap_to_choose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get tap_to_choose;

  /// No description provided for @table_status_reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get table_status_reserved;

  /// No description provided for @filter_reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get filter_reserved;

  /// No description provided for @reserve_table.
  ///
  /// In en, this message translates to:
  /// **'Reserve Table'**
  String get reserve_table;

  /// No description provided for @merge_tables.
  ///
  /// In en, this message translates to:
  /// **'Merge Tables'**
  String get merge_tables;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @reservation_customer_name.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get reservation_customer_name;

  /// No description provided for @reservation_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get reservation_phone;

  /// No description provided for @reservation_party_size.
  ///
  /// In en, this message translates to:
  /// **'Party size'**
  String get reservation_party_size;

  /// No description provided for @reservation_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reservation_date;

  /// No description provided for @reservation_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reservation_time;

  /// No description provided for @reservation_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get reservation_notes;

  /// No description provided for @reservation_dialog_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking for {table}'**
  String reservation_dialog_subtitle(String table);

  /// No description provided for @reservation_guest_section.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get reservation_guest_section;

  /// No description provided for @reservation_when_section.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get reservation_when_section;

  /// No description provided for @reservation_preview_label.
  ///
  /// In en, this message translates to:
  /// **'Reservation summary'**
  String get reservation_preview_label;

  /// No description provided for @reservation_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reservation_today;

  /// No description provided for @reservation_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get reservation_tomorrow;

  /// No description provided for @reservation_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get reservation_name_required;

  /// No description provided for @reservation_party_size_up_to.
  ///
  /// In en, this message translates to:
  /// **'Select up to {capacity} guests for this table'**
  String reservation_party_size_up_to(int capacity);

  /// No description provided for @reservation_combined_seating.
  ///
  /// In en, this message translates to:
  /// **'Combined seating: {capacity} guests'**
  String reservation_combined_seating(int capacity);

  /// No description provided for @reservation_party_needs_more_tables.
  ///
  /// In en, this message translates to:
  /// **'{party} guests need more seats. Combined capacity is {capacity}. Add tables below or switch to a larger table.'**
  String reservation_party_needs_more_tables(int party, int capacity);

  /// No description provided for @reservation_add_tables_to_combine.
  ///
  /// In en, this message translates to:
  /// **'Combine with more tables'**
  String get reservation_add_tables_to_combine;

  /// No description provided for @reservation_or_switch_table.
  ///
  /// In en, this message translates to:
  /// **'Or switch to a larger table'**
  String get reservation_or_switch_table;

  /// No description provided for @reservation_no_tables_for_party.
  ///
  /// In en, this message translates to:
  /// **'No available tables fit this party size. Try a smaller group or another time.'**
  String get reservation_no_tables_for_party;

  /// No description provided for @reservation_party_size_exceeds_capacity.
  ///
  /// In en, this message translates to:
  /// **'Party size cannot exceed table capacity ({capacity} seats)'**
  String reservation_party_size_exceeds_capacity(int capacity);

  /// No description provided for @reservation_tap_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to order · Seat icon to reserve'**
  String get reservation_tap_hint;

  /// No description provided for @reservation_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Table reserved successfully'**
  String get reservation_created_successfully;

  /// No description provided for @reservation_cancelled_successfully.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled'**
  String get reservation_cancelled_successfully;

  /// No description provided for @reservation_seated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Guest seated'**
  String get reservation_seated_successfully;

  /// No description provided for @failed_to_create_reservation.
  ///
  /// In en, this message translates to:
  /// **'Failed to create reservation'**
  String get failed_to_create_reservation;

  /// No description provided for @seat_guest.
  ///
  /// In en, this message translates to:
  /// **'Seat guest'**
  String get seat_guest;

  /// No description provided for @cancel_reservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancel_reservation;

  /// No description provided for @no_reservations_today.
  ///
  /// In en, this message translates to:
  /// **'No reservations for this date'**
  String get no_reservations_today;

  /// No description provided for @merge_tables_title.
  ///
  /// In en, this message translates to:
  /// **'Merge tables'**
  String get merge_tables_title;

  /// No description provided for @merge_tables_message.
  ///
  /// In en, this message translates to:
  /// **'Choose the main table, then pick other occupied tables to combine into it.'**
  String get merge_tables_message;

  /// No description provided for @merge_tables_select_primary.
  ///
  /// In en, this message translates to:
  /// **'Tap primary table first, then tables to merge into it'**
  String get merge_tables_select_primary;

  /// No description provided for @merge_select_primary_table.
  ///
  /// In en, this message translates to:
  /// **'1. Select main table (orders will merge here)'**
  String get merge_select_primary_table;

  /// No description provided for @merge_select_other_tables.
  ///
  /// In en, this message translates to:
  /// **'2. Select other tables to merge into it'**
  String get merge_select_other_tables;

  /// No description provided for @merge_step_main.
  ///
  /// In en, this message translates to:
  /// **'Main table'**
  String get merge_step_main;

  /// No description provided for @merge_step_join.
  ///
  /// In en, this message translates to:
  /// **'Join tables'**
  String get merge_step_join;

  /// No description provided for @merge_join_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more tables to combine with the main table'**
  String get merge_join_hint;

  /// No description provided for @merge_dialog_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine tables for large parties — works before or during orders'**
  String get merge_dialog_subtitle;

  /// No description provided for @merge_preview_label.
  ///
  /// In en, this message translates to:
  /// **'Combined result'**
  String get merge_preview_label;

  /// No description provided for @no_tables_to_merge.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 tables to merge'**
  String get no_tables_to_merge;

  /// No description provided for @no_other_tables_to_merge.
  ///
  /// In en, this message translates to:
  /// **'No other tables available'**
  String get no_other_tables_to_merge;

  /// No description provided for @merge_available_hint.
  ///
  /// In en, this message translates to:
  /// **'You can merge available tables before taking any order'**
  String get merge_available_hint;

  /// No description provided for @table_merged_with_others.
  ///
  /// In en, this message translates to:
  /// **'Merged with other tables'**
  String get table_merged_with_others;

  /// No description provided for @unmerge_tables.
  ///
  /// In en, this message translates to:
  /// **'Split tables'**
  String get unmerge_tables;

  /// No description provided for @unmerge_tables_success.
  ///
  /// In en, this message translates to:
  /// **'Tables split successfully'**
  String get unmerge_tables_success;

  /// No description provided for @unmerge_tables_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to split tables'**
  String get unmerge_tables_failed;

  /// No description provided for @unmerge_tables_confirm.
  ///
  /// In en, this message translates to:
  /// **'Split merged tables from {name}?'**
  String unmerge_tables_confirm(String name);

  /// No description provided for @merge_tables_success.
  ///
  /// In en, this message translates to:
  /// **'Tables merged successfully'**
  String get merge_tables_success;

  /// No description provided for @merge_tables_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to merge tables'**
  String get merge_tables_failed;

  /// No description provided for @edit_merged_tables.
  ///
  /// In en, this message translates to:
  /// **'Edit merged tables'**
  String get edit_merged_tables;

  /// No description provided for @edit_merged_tables_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add or remove tables in this combined group'**
  String get edit_merged_tables_subtitle;

  /// No description provided for @edit_merged_tables_hint.
  ///
  /// In en, this message translates to:
  /// **'Uncheck all tables to split the group apart'**
  String get edit_merged_tables_hint;

  /// No description provided for @merged_tables_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Merged tables updated successfully'**
  String get merged_tables_updated_success;

  /// No description provided for @select_at_least_two_tables_to_merge.
  ///
  /// In en, this message translates to:
  /// **'Select a primary table and at least one other occupied table'**
  String get select_at_least_two_tables_to_merge;

  /// No description provided for @whatsapp_bot_reservation_hint.
  ///
  /// In en, this message translates to:
  /// **'Customers can WhatsApp your bot code to book tables automatically'**
  String get whatsapp_bot_reservation_hint;

  /// No description provided for @whatsapp_bot_code.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp bot code'**
  String get whatsapp_bot_code;

  /// No description provided for @enable_whatsapp_reservations.
  ///
  /// In en, this message translates to:
  /// **'Enable WhatsApp reservations'**
  String get enable_whatsapp_reservations;

  /// No description provided for @reservation_for_table.
  ///
  /// In en, this message translates to:
  /// **'Reservation for {table}'**
  String reservation_for_table(String table);

  /// No description provided for @reserved_by.
  ///
  /// In en, this message translates to:
  /// **'Reserved: {name} at {time}'**
  String reserved_by(String name, String time);

  /// No description provided for @source_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get source_whatsapp;

  /// No description provided for @source_pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get source_pos;

  /// No description provided for @filter_merged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get filter_merged;

  /// No description provided for @merged_tables_badge.
  ///
  /// In en, this message translates to:
  /// **'Merged ({count})'**
  String merged_tables_badge(int count);

  /// No description provided for @merged_groups_banner.
  ///
  /// In en, this message translates to:
  /// **'{groups} merged group(s) · {tables} table(s) combined'**
  String merged_groups_banner(int groups, int tables);

  /// No description provided for @merged_tables_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to order · Split icon to unmerge'**
  String get merged_tables_hint;

  /// No description provided for @cash_drawer.
  ///
  /// In en, this message translates to:
  /// **'Cash drawer (RJ11)'**
  String get cash_drawer;

  /// No description provided for @cash_drawer_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect the drawer cable to your bill printer DK port. Opens via ESC/POS kick signal.'**
  String get cash_drawer_subtitle;

  /// No description provided for @open_cash_drawer_on_cash_payment.
  ///
  /// In en, this message translates to:
  /// **'Open drawer on cash payment'**
  String get open_cash_drawer_on_cash_payment;

  /// No description provided for @open_cash_drawer_on_cash_payment_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically open the drawer when a bill is printed with Cash payment'**
  String get open_cash_drawer_on_cash_payment_subtitle;

  /// No description provided for @cash_drawer_kick_pin.
  ///
  /// In en, this message translates to:
  /// **'Drawer kick pin'**
  String get cash_drawer_kick_pin;

  /// No description provided for @cash_drawer_kick_pin_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Most RJ11 POS drawers use Pin 2. Try Pin 5 if the drawer does not open.'**
  String get cash_drawer_kick_pin_subtitle;

  /// No description provided for @cash_drawer_pin_2.
  ///
  /// In en, this message translates to:
  /// **'Pin 2'**
  String get cash_drawer_pin_2;

  /// No description provided for @cash_drawer_pin_5.
  ///
  /// In en, this message translates to:
  /// **'Pin 5'**
  String get cash_drawer_pin_5;

  /// No description provided for @test_cash_drawer.
  ///
  /// In en, this message translates to:
  /// **'Test open drawer'**
  String get test_cash_drawer;

  /// No description provided for @cash_drawer_opened.
  ///
  /// In en, this message translates to:
  /// **'Cash drawer signal sent'**
  String get cash_drawer_opened;

  /// No description provided for @cash_drawer_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open cash drawer: {error}'**
  String cash_drawer_failed(String error);

  /// No description provided for @cash_drawer_printer_help.
  ///
  /// In en, this message translates to:
  /// **'Uses your assigned bill printer. Plug the RJ11 cable into the printer drawer port.'**
  String get cash_drawer_printer_help;

  /// No description provided for @cash_drawer_assign_bill_printer_first.
  ///
  /// In en, this message translates to:
  /// **'Assign a bill printer above before testing the drawer.'**
  String get cash_drawer_assign_bill_printer_first;

  /// No description provided for @remove_image.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get remove_image;

  /// No description provided for @store_open.
  ///
  /// In en, this message translates to:
  /// **'Store Open'**
  String get store_open;

  /// No description provided for @store_closed.
  ///
  /// In en, this message translates to:
  /// **'Store Closed'**
  String get store_closed;

  /// No description provided for @open_store.
  ///
  /// In en, this message translates to:
  /// **'Open Store'**
  String get open_store;

  /// No description provided for @close_store.
  ///
  /// In en, this message translates to:
  /// **'Close Store'**
  String get close_store;

  /// No description provided for @open_store_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your business day and enable billing'**
  String get open_store_subtitle;

  /// No description provided for @close_store_subtitle.
  ///
  /// In en, this message translates to:
  /// **'End day, reconcile cash and reset tables'**
  String get close_store_subtitle;

  /// No description provided for @opening_cash.
  ///
  /// In en, this message translates to:
  /// **'Opening cash in drawer'**
  String get opening_cash;

  /// No description provided for @closing_cash.
  ///
  /// In en, this message translates to:
  /// **'Closing cash counted'**
  String get closing_cash;

  /// No description provided for @notes_optional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes_optional;

  /// No description provided for @store_opened_success.
  ///
  /// In en, this message translates to:
  /// **'Store opened successfully'**
  String get store_opened_success;

  /// No description provided for @store_closed_success.
  ///
  /// In en, this message translates to:
  /// **'Day closed successfully'**
  String get store_closed_success;

  /// No description provided for @store_closed_banner_title.
  ///
  /// In en, this message translates to:
  /// **'Store is closed'**
  String get store_closed_banner_title;

  /// No description provided for @store_closed_banner_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the store to start taking orders'**
  String get store_closed_banner_subtitle;

  /// No description provided for @store_closed_order_blocked.
  ///
  /// In en, this message translates to:
  /// **'Store is closed. Open the store before billing.'**
  String get store_closed_order_blocked;

  /// No description provided for @close_store_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm day end?'**
  String get close_store_confirm_title;

  /// No description provided for @close_store_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'This will close the business day, save the summary and reset all tables to available.'**
  String get close_store_confirm_message;

  /// No description provided for @opened_at.
  ///
  /// In en, this message translates to:
  /// **'Opened at'**
  String get opened_at;

  /// No description provided for @opened_by.
  ///
  /// In en, this message translates to:
  /// **'Opened by'**
  String get opened_by;

  /// No description provided for @closed_by.
  ///
  /// In en, this message translates to:
  /// **'Closed by'**
  String get closed_by;

  /// No description provided for @total_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get total_orders;

  /// No description provided for @expected_cash.
  ///
  /// In en, this message translates to:
  /// **'Expected cash'**
  String get expected_cash;

  /// No description provided for @cash_variance.
  ///
  /// In en, this message translates to:
  /// **'Cash variance'**
  String get cash_variance;

  /// No description provided for @enter_valid_closing_cash.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid closing cash amount'**
  String get enter_valid_closing_cash;

  /// No description provided for @store_history_title.
  ///
  /// In en, this message translates to:
  /// **'Store Day History'**
  String get store_history_title;

  /// No description provided for @store_history_subtitle.
  ///
  /// In en, this message translates to:
  /// **'View open and close records with cash summary'**
  String get store_history_subtitle;

  /// No description provided for @store_history_empty.
  ///
  /// In en, this message translates to:
  /// **'No store day records yet. Open and close the store to build history.'**
  String get store_history_empty;

  /// No description provided for @closed_at.
  ///
  /// In en, this message translates to:
  /// **'Closed at'**
  String get closed_at;

  /// No description provided for @wallet_title.
  ///
  /// In en, this message translates to:
  /// **'BillKaro Wallet'**
  String get wallet_title;

  /// No description provided for @wallet_balance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get wallet_balance;

  /// No description provided for @wallet_balance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepaid credits for platform fees'**
  String get wallet_balance_subtitle;

  /// No description provided for @wallet_add_money.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get wallet_add_money;

  /// No description provided for @wallet_recharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get wallet_recharge;

  /// No description provided for @wallet_custom_amount.
  ///
  /// In en, this message translates to:
  /// **'Custom Amount'**
  String get wallet_custom_amount;

  /// No description provided for @wallet_enter_amount_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get wallet_enter_amount_hint;

  /// No description provided for @wallet_enter_valid_amount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than zero.'**
  String get wallet_enter_valid_amount;

  /// No description provided for @wallet_history.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get wallet_history;

  /// No description provided for @wallet_transactions.
  ///
  /// In en, this message translates to:
  /// **'transactions'**
  String get wallet_transactions;

  /// No description provided for @wallet_no_transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Recharge your wallet to get started.'**
  String get wallet_no_transactions;

  /// No description provided for @wallet_demo_note.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: balance is stored on this device only. Razorpay test checkout is used to add money — no backend verification.'**
  String get wallet_demo_note;

  /// No description provided for @wallet_low_balance_warning.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance is low. Recharge soon to avoid billing interruptions.'**
  String get wallet_low_balance_warning;

  /// No description provided for @wallet_recharge_demo.
  ///
  /// In en, this message translates to:
  /// **'Wallet Recharge (Demo)'**
  String get wallet_recharge_demo;

  /// No description provided for @wallet_recharge_via_razorpay.
  ///
  /// In en, this message translates to:
  /// **'Wallet recharge via Razorpay'**
  String get wallet_recharge_via_razorpay;

  /// No description provided for @wallet_recharge_success.
  ///
  /// In en, this message translates to:
  /// **'{amount} added to your wallet successfully.'**
  String wallet_recharge_success(String amount);

  /// No description provided for @wallet_welcome_credit.
  ///
  /// In en, this message translates to:
  /// **'Welcome credit'**
  String get wallet_welcome_credit;

  /// No description provided for @wallet_no_cards_available.
  ///
  /// In en, this message translates to:
  /// **'No recharge cards configured yet. Use custom amount or ask your admin to add cards.'**
  String get wallet_no_cards_available;

  /// No description provided for @wallet_secure_payment_note.
  ///
  /// In en, this message translates to:
  /// **'Payments are secured by Razorpay.'**
  String get wallet_secure_payment_note;

  /// No description provided for @wallet_menu_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Recharge prepaid balance for platform fees'**
  String get wallet_menu_subtitle;

  /// No description provided for @settings_section_billing.
  ///
  /// In en, this message translates to:
  /// **'Billing plan'**
  String get settings_section_billing;

  /// No description provided for @billing_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Access mode'**
  String get billing_mode_title;

  /// No description provided for @billing_mode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how this outlet pays for BillKaro'**
  String get billing_mode_subtitle;

  /// No description provided for @billing_mode_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get billing_mode_subscription;

  /// No description provided for @billing_mode_subscription_desc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access with an active plan or trial'**
  String get billing_mode_subscription_desc;

  /// No description provided for @billing_mode_wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get billing_mode_wallet;

  /// No description provided for @billing_mode_wallet_desc.
  ///
  /// In en, this message translates to:
  /// **'Pay as you go — prepaid balance deducted per bill'**
  String get billing_mode_wallet_desc;

  /// No description provided for @billing_mode_switched_subscription.
  ///
  /// In en, this message translates to:
  /// **'Switched to subscription mode'**
  String get billing_mode_switched_subscription;

  /// No description provided for @billing_mode_switched_wallet.
  ///
  /// In en, this message translates to:
  /// **'Switched to wallet mode'**
  String get billing_mode_switched_wallet;

  /// No description provided for @billing_mode_switch_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Switch billing mode?'**
  String get billing_mode_switch_confirm_title;

  /// No description provided for @billing_mode_switch_to_wallet_body.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use prepaid wallet credits instead of a subscription. Keep your wallet funded before creating bills.'**
  String get billing_mode_switch_to_wallet_body;

  /// No description provided for @billing_mode_switch_to_subscription_body.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need an active subscription or trial for gated features. Wallet balance will not unlock the app.'**
  String get billing_mode_switch_to_subscription_body;

  /// No description provided for @billing_mode_confirm_switch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get billing_mode_confirm_switch;

  /// No description provided for @billing_mode_owner_only.
  ///
  /// In en, this message translates to:
  /// **'Only the outlet owner can change billing mode'**
  String get billing_mode_owner_only;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @internet_speed_test.
  ///
  /// In en, this message translates to:
  /// **'Internet Speed Test'**
  String get internet_speed_test;

  /// No description provided for @internet_speed_test_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Measure ping, download and upload speed'**
  String get internet_speed_test_subtitle;

  /// No description provided for @internet_speed_start_test.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get internet_speed_start_test;

  /// No description provided for @internet_speed_retest.
  ///
  /// In en, this message translates to:
  /// **'Retest'**
  String get internet_speed_retest;

  /// No description provided for @internet_speed_testing.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get internet_speed_testing;

  /// No description provided for @internet_speed_ping.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get internet_speed_ping;

  /// No description provided for @internet_speed_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get internet_speed_download;

  /// No description provided for @internet_speed_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get internet_speed_upload;

  /// No description provided for @internet_speed_mbps.
  ///
  /// In en, this message translates to:
  /// **'Mbps'**
  String get internet_speed_mbps;

  /// No description provided for @internet_speed_ms.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get internet_speed_ms;

  /// No description provided for @internet_speed_quality_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get internet_speed_quality_excellent;

  /// No description provided for @internet_speed_quality_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get internet_speed_quality_good;

  /// No description provided for @internet_speed_quality_fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get internet_speed_quality_fair;

  /// No description provided for @internet_speed_quality_poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get internet_speed_quality_poor;

  /// No description provided for @internet_speed_idle_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap start to measure your connection'**
  String get internet_speed_idle_hint;

  /// No description provided for @internet_speed_phase_ping.
  ///
  /// In en, this message translates to:
  /// **'Measuring ping…'**
  String get internet_speed_phase_ping;

  /// No description provided for @internet_speed_phase_download.
  ///
  /// In en, this message translates to:
  /// **'Measuring download…'**
  String get internet_speed_phase_download;

  /// No description provided for @internet_speed_phase_upload.
  ///
  /// In en, this message translates to:
  /// **'Measuring upload…'**
  String get internet_speed_phase_upload;

  /// No description provided for @internet_speed_offline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get internet_speed_offline;

  /// No description provided for @internet_speed_failed.
  ///
  /// In en, this message translates to:
  /// **'Speed test failed. Please try again.'**
  String get internet_speed_failed;

  /// No description provided for @internet_speed_tap_to_test.
  ///
  /// In en, this message translates to:
  /// **'Tap to test internet speed'**
  String get internet_speed_tap_to_test;

  /// No description provided for @help_and_setup.
  ///
  /// In en, this message translates to:
  /// **'Help & Setup'**
  String get help_and_setup;

  /// No description provided for @help_were_here.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help'**
  String get help_were_here;

  /// No description provided for @help_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick setup steps and direct support options'**
  String get help_subtitle;

  /// No description provided for @help_your_account.
  ///
  /// In en, this message translates to:
  /// **'Your Account'**
  String get help_your_account;

  /// No description provided for @help_user_id.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get help_user_id;

  /// No description provided for @help_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get help_name;

  /// No description provided for @help_restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get help_restaurant;

  /// No description provided for @help_quick_setup.
  ///
  /// In en, this message translates to:
  /// **'Quick Setup'**
  String get help_quick_setup;

  /// No description provided for @help_setup_step_1.
  ///
  /// In en, this message translates to:
  /// **'Connect a printer: Menu → Printer → Select your printer → Pair & Test print.'**
  String get help_setup_step_1;

  /// No description provided for @help_setup_step_2.
  ///
  /// In en, this message translates to:
  /// **'Enable online orders: Ask support to activate QR menu for your restaurant. Orders will appear in Dashboard automatically.'**
  String get help_setup_step_2;

  /// No description provided for @help_setup_step_3.
  ///
  /// In en, this message translates to:
  /// **'Test print an order: Open any order → \'View Order\' → Print from the print screen.'**
  String get help_setup_step_3;

  /// No description provided for @help_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get help_contact_support;

  /// No description provided for @help_call_us.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get help_call_us;

  /// No description provided for @help_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get help_whatsapp;

  /// No description provided for @help_live_chat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get help_live_chat;

  /// No description provided for @help_support_hours.
  ///
  /// In en, this message translates to:
  /// **'Available 10am–6pm IST'**
  String get help_support_hours;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

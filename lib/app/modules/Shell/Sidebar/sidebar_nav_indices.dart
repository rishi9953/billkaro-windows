import 'package:billkaro/utils/staff_access.dart';

class SidebarNavIndices {
  const SidebarNavIndices({
    required this.items,
    required this.inventory,
    required this.purchases,
    required this.orders,
    required this.reports,
    required this.kot,
    required this.kds,
    required this.customers,
    required this.staff,
    required this.subscriptions,
    required this.whatsapp,
    required this.printer,
    required this.settings,
    required this.profile,
    required this.logout,
  });

  final int items;
  final int inventory;
  final int purchases;
  final int orders;
  final int reports;
  final int kot;
  final int kds;
  final int customers;
  final int staff;
  final int subscriptions;
  final int whatsapp;
  final int printer;
  final int settings;
  final int profile;
  final int logout;

  factory SidebarNavIndices.compute({
    required bool kotEnabled,
    required bool hasSeating,
  }) {
    final seatOffset = hasSeating ? 0 : -1;
    final inventoryOffset = StaffAccess.canViewInventory ? 1 : 0;
    final purchaseOffset = StaffAccess.canViewInventory ? 1 : 0;

    final items = 3 + seatOffset;
    final orders = items + 1;
    final inventory = StaffAccess.canViewInventory ? orders + 1 : -1;
    final purchases = StaffAccess.canViewInventory ? inventory + 1 : -1;
    final reports = 5 + seatOffset + inventoryOffset + purchaseOffset;
    final kot = 6 + seatOffset + inventoryOffset + purchaseOffset;
    final kds = kotEnabled
        ? (7 + seatOffset + inventoryOffset + purchaseOffset)
        : -1;
    final customers =
        (kotEnabled ? 8 : 6) + seatOffset + inventoryOffset + purchaseOffset;
    final staff =
        (kotEnabled ? 9 : 7) + seatOffset + inventoryOffset + purchaseOffset;
    final subscriptions =
        (kotEnabled ? 11 : 9) + seatOffset + inventoryOffset + purchaseOffset;
    final whatsapp =
        (kotEnabled ? 12 : 10) + seatOffset + inventoryOffset + purchaseOffset;
    final printer =
        (kotEnabled ? 13 : 11) + seatOffset + inventoryOffset + purchaseOffset;
    final settings =
        (kotEnabled ? 14 : 12) + seatOffset + inventoryOffset + purchaseOffset;
    final profile =
        (kotEnabled ? 15 : 13) + seatOffset + inventoryOffset + purchaseOffset;
    final logout =
        (kotEnabled ? 16 : 14) + seatOffset + inventoryOffset + purchaseOffset;

    return SidebarNavIndices(
      items: items,
      inventory: inventory,
      purchases: purchases,
      orders: orders,
      reports: reports,
      kot: kot,
      kds: kds,
      customers: customers,
      staff: staff,
      subscriptions: subscriptions,
      whatsapp: whatsapp,
      printer: printer,
      settings: settings,
      profile: profile,
      logout: logout,
    );
  }
}

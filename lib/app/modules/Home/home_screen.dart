import 'dart:async';
import 'dart:ui';
import 'package:billkaro/app/Widgets/notification_bell_button.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/Home/Widgets/outlet_switcher.dart';
import 'package:billkaro/app/modules/Home/Widgets/payment_summary_widget.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Items/voice_add_menu_items_bottomsheet.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/kitchen_display_browser.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeScreenController controller = Get.find<HomeScreenController>();
  final showcaseController = Get.put(ShowcaseController());
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _occupiedTickTimer;

  static const double _pageHMargin = 16;
  static const double _sectionGap = 18;
  static const double _cardRadius = 16;

  static const int _testimonialCount = 3;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _startOccupiedTick();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkDeveloperOptionsAndShowSheet();
    // });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextPage = _currentPage.value + 1;
      if (nextPage >= _testimonialCount) nextPage = 0;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _currentPage.value = nextPage;
    });
  }

  List<Map<String, String>> _testimonials(AppLocalizations loc) {
    return [
      {'quote': loc.testimonial_quote_1, 'author': loc.testimonial_author_1},
      {'quote': loc.testimonial_quote_2, 'author': loc.testimonial_author_2},
      {'quote': loc.testimonial_quote_3, 'author': loc.testimonial_author_3},
    ];
  }

  void _startOccupiedTick() {
    _occupiedTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _occupiedTickTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(Get.context!)!;
    // var isKOT = controller.appPref.isKOT;
    // ShowCaseWidget is hosted in HomeMainScreen so bottom nav can be included in the tour.
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: Showcase(
          key: showcaseController.outletSwitcherKey,
          title: loc.home_outlet_showcase_title,
          description:
              loc.home_outlet_showcase_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: OutletSwitcherButton(controller: controller),
        ),
        leadingWidth: 160,
        actions: [
          const NotificationBellButton(
            iconColor: Colors.white,
            iconSize: 24,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
            child: _headerAvatarAction(loc),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          final content = SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: isDesktop ? 24 : 14,
                bottom: isDesktop ? 28 : 20,
                left: isDesktop ? 32 : 0,
                right: isDesktop ? 32 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _pageHMargin,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.dashboard,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.dashboardOverviewSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _sectionGap),
                      ],
                      _printerStatusBanner(loc),
                      const SizedBox(height: _sectionGap),
                      if (HomeMainRoutes.outletShowsTables()) ...[
                        _occupiedTablesSection(loc: loc, isDesktop: isDesktop),
                        const SizedBox(height: _sectionGap),
                      ],
                      _quickActions(loc, isDesktop: isDesktop),
                      if (StaffAccess.canViewDashboardInsights) ...[
                        const SizedBox(height: _sectionGap),
                        if (isDesktop)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _pageHMargin,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _businessOverview(loc),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: PaymentSummaryWidget()),
                              ],
                            ),
                          )
                        else ...[
                          _businessOverview(loc),
                          const SizedBox(height: _sectionGap),
                          const PaymentSummaryWidget(),
                        ],
                        const SizedBox(height: _sectionGap),
                        _weeklySalesChart(loc),
                      ],
                      const SizedBox(height: _sectionGap),
                      _topSellingItemsSection(loc),
                      const SizedBox(height: _sectionGap),
                      _featuresSection(loc),
                      const SizedBox(height: 22),
                      _testimonialsCarousel(loc),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _pageHMargin,
                        ),
                        child: footerSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (!isDesktop) return content;

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 8,
            radius: const Radius.circular(12),
            child: content,
          );
        },
      ),
      floatingActionButton: Tooltip(
        message: loc.home_ai_voice_add_items,
        child: Material(
          elevation: 8,
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              final appPref = Get.find<AppPref>();
              if (!hasTrialOrSubscription(appPref)) {
                checkSubscription();
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => const VoiceAddMenuItemsBottomSheet(),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF22D3EE), // cyan
                    Color(0xFF8B5CF6), // purple
                    Color(0xFFEC4899), // pink
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 28),
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerAvatarAction(AppLocalizations loc) {
    return Obx(() {
      final selectedOutlet = controller.selectedOutlet.value;

      if (selectedOutlet == null) {
        return Showcase(
          key: showcaseController.profileKey,
          title: loc.home_profile_business_title,
          description:
              loc.home_profile_business_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: const Icon(Icons.store, color: Colors.white, size: 18),
          ),
        );
      }

      return Showcase(
        key: showcaseController.profileKey,
        title: loc.home_profile_business_title,
        description: loc.home_profile_business_desc_short,
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        overlayColor: Colors.black54,
        overlayOpacity: 0.7,
        tooltipBackgroundColor: AppColor.primary,
        textColor: Colors.white,
        child: GestureDetector(
          onTap: () => Modular.to.navigate(HomeMainRoutes.profile),
          child: (selectedOutlet.logo?.isNotEmpty ?? false)
              ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(selectedOutlet.logo!),
                  backgroundColor: Colors.white,
                )
              : Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Text(
                    (selectedOutlet.businessName?.isNotEmpty ?? false)
                        ? selectedOutlet.businessName!
                              .substring(0, 1)
                              .toUpperCase()
                        : 'O',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _sectionHeader(String title, {String? subtitle, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _printerStatusBanner(AppLocalizations loc) {
    final thermalPrinter = ThermalPrinterService.instance;
    return Obx(() {
      final usbConnected = thermalPrinter.isUsbConnected.value;
      final bleConnected =
          thermalPrinter.connectedBleDeviceId.value != null && !usbConnected;
      final classicConnected = controller.printerservice2.isConnected.value;
      final connected = usbConnected || bleConnected || classicConnected;

      if (!connected) {
        return const SizedBox.shrink();
      }

      final String name;
      final IconData statusIcon;
      if (usbConnected) {
        name = thermalPrinter.connectedUsbPrinter?.name ?? loc.home_usb_printer;
        statusIcon = Icons.usb;
      } else if (bleConnected) {
        final platformName =
            thermalPrinter.connectedDevice?.platformName ?? '';
        name = platformName.trim().isNotEmpty ? platformName : loc.home_printer_fallback;
        statusIcon = Icons.bluetooth_connected;
      } else {
        name =
            controller.printerservice2.selectedPrinter.value?.name ??
            loc.home_printer_connected_name;
        statusIcon = Icons.bluetooth_connected;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
        child: Showcase(
          key: showcaseController.printerBannerKey,
          title: loc.home_printer_status_title,
          description:
              loc.home_printer_status_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: _cardShell(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: AppColor.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.home_printer_connected_label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.18)),
                  ),
                  child: Text(
                    loc.home_online,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _quickActions(AppLocalizations loc, {bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Showcase(
          key: showcaseController.quickActionsHeaderKey,
          title: loc.quickActions,
          description:
              loc.home_quick_actions_showcase_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: _sectionHeader(
            loc.quickActions,
            subtitle: loc.home_frequently_used_shortcuts,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: Obx(() {
            final kotVisible =
                controller.isKOT.value &&
                HomeMainRoutes.outletIsCafeOrRestaurant();
            controller.selectedOutlet.value;
            final showTables = HomeMainRoutes.outletShowsTables();
            final actions = <Map<String, dynamic>>[
              {
                'icon': Icons.check_circle_outline,
                'label': loc.closedOrders,
                'onTap': () {
                  Modular.to.pushNamed(HomeMainRoutes.closedOrders);
                },
              },
              {
                'icon': Icons.schedule_outlined,
                'label': loc.onHoldOrders,
                'onTap': () => Modular.to.pushNamed(HomeMainRoutes.holdOrders),
              },
              if (showTables)
                {
                  'icon': Icons.table_restaurant_outlined,
                  'label': loc.tables,
                  'onTap': () => Modular.to.navigate(HomeMainRoutes.tables),
                },
              {
                'icon': Icons.add_shopping_cart_outlined,
                'label': loc.addItems,
                'onTap': () => Modular.to.pushNamed(HomeMainRoutes.addItem),
              },
              if (StaffAccess.canViewInventory)
                {
                  'icon': Icons.inventory_2_outlined,
                  'label': loc.inventory,
                  'onTap': () =>
                      Modular.to.pushNamed(HomeMainRoutes.inventory),
                },
              if (kotVisible)
                {
                  'icon': Icons.receipt_long_outlined,
                  'label': loc.kot_history,
                  'onTap': () =>
                      Modular.to.pushNamed(HomeMainRoutes.kotHistory),
                },
              if (kotVisible)
                {
                  'icon': Icons.open_in_browser_rounded,
                  'label': loc.home_kitchen_web,
                  'onTap': () async {
                    await KitchenDisplayBrowser.open();
                  },
                },
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 5 : (Get.width >= 480 ? 4 : 2),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop
                    ? 1.4
                    : (Get.width >= 480 ? 1.2 : 1.6),
              ),
              itemBuilder: (context, index) {
                final item = actions[index];
                final label = item['label'] as String;
                GlobalKey? showcaseKey;
                String? showcaseDescription;

                // Assign showcase keys based on label
                if (label == loc.closedOrders) {
                  showcaseKey = showcaseController.closedOrdersKey;
                  showcaseDescription =
                      loc.home_showcase_closed_orders;
                } else if (label == loc.onHoldOrders) {
                  showcaseKey = showcaseController.holdOrdersKey;
                  showcaseDescription =
                      loc.home_showcase_hold_orders;
                } else if (label == loc.addItems) {
                  showcaseKey = showcaseController.addItemsKey;
                  showcaseDescription =
                      loc.home_showcase_add_items;
                } else if (label == loc.kot_history) {
                  showcaseKey = showcaseController.kotHistoryKey;
                  showcaseDescription =
                      loc.home_showcase_kot_history;
                }

                return _buildQuickActionCard(
                  loc: loc,
                  icon: item['icon'] as IconData,
                  label: label,
                  onTap: item['onTap'] as VoidCallback,
                  iconWidget: item['iconWidget'] as Widget?,
                  showcaseKey: showcaseKey,
                  showcaseDescription: showcaseDescription,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _occupiedTablesSection({
    required AppLocalizations loc,
    required bool isDesktop,
  }) {
    return Obx(() {
      final occupied = controller.occupiedTableOrders;
      if (occupied.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            loc.home_occupied_tables,
            subtitle: loc.home_live_dine_in_tables,
            trailing: TextButton(
              onPressed: () => Modular.to.navigate(HomeMainRoutes.tables),
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.view_all, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isDesktop ? 142 : 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
              itemCount: occupied.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: isDesktop ? 250 : 220,
                  height: isDesktop ? 142 : 146,
                  child: _occupiedTableCard(occupied[index], loc),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _occupiedTableCard(OrderModel order, AppLocalizations loc) {
    final rawTable = (order.tableNumber ?? '').trim();
    final tableLabel = rawTable.isEmpty
        ? loc.home_table
        : loc.home_table_number(
            rawTable.toLowerCase().startsWith('table ')
                ? rawTable.substring(6).trim()
                : rawTable,
          );
    final billLabel = order.billNumber.trim().isEmpty
        ? '-'
        : order.billNumber.trim();
    final createdAt = DateTime.tryParse(order.createdAt);
    final occupiedDuration = createdAt == null
        ? null
        : DateTime.now().difference(createdAt);

    final statusColor = AppColor.secondaryPrimary;

    return Tooltip(
      message: tableLabel,
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: statusColor.withOpacity(0.10),
        onTap: () {
          Modular.to.pushNamed(
            HomeMainRoutes.createOrder,
            arguments: {'order': order, 'isEdit': true},
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.35),
              width: 1.4,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.table_restaurant_rounded,
                        size: 16, color: statusColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      loc.home_occupied,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tableLabel,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Text(
                loc.home_bill_number(billLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      occupiedDuration == null
                          ? loc.home_tap_continue_order
                          : loc.home_occupied_duration(
                              _formatDuration(occupiedDuration),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: occupiedDuration == null
                            ? Colors.grey[700]
                            : statusColor,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildQuickActionCard({
    required AppLocalizations loc,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? iconWidget,
    GlobalKey? showcaseKey,
    String? showcaseDescription,
  }) {
    Widget card = _GlassContainer(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primary.withOpacity(0.22),
                        AppColor.secondaryPrimary.withOpacity(0.14),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Center(
                    child:
                        iconWidget ??
                        Icon(icon, color: AppColor.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (showcaseKey != null) {
      return Showcase(
        key: showcaseKey,
        description: showcaseDescription ?? loc.home_tap_to_access_feature,
        child: card,
        title: label,
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        overlayColor: Colors.black54,
        overlayOpacity: 0.7,
        tooltipBackgroundColor: AppColor.primary,
        textColor: Colors.white,
      );
    }

    return card;
  }

  Widget noSaleWidget() {
    return Column(
      children: [
        Center(
          child: Container(
            child: Lottie.asset(
              'assets/lottie/sales.json',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _businessOverview(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          loc.businessOverview,
          subtitle: loc.home_today_vs_yesterday,
          trailing: TextButton(
            onPressed: () =>
                Modular.to.pushNamed(HomeMainRoutes.businessOverview),
            style: TextButton.styleFrom(
              foregroundColor: AppColor.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.view, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: Showcase(
            key: showcaseController.businessOverviewKey,
            description:
                loc.home_business_overview_showcase_desc,
            title: loc.businessOverview,
            titleTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
            overlayColor: Colors.black54,
            overlayOpacity: 0.7,
            tooltipBackgroundColor: AppColor.primary,
            textColor: Colors.white,
            child: _GlassContainer(
              padding: const EdgeInsets.all(18),
              child: InkWell(
                onTap: () =>
                    Modular.to.pushNamed(HomeMainRoutes.businessOverview),
                borderRadius: BorderRadius.circular(_cardRadius),
                child: Obx(() {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColor.primary.withOpacity(0.20),
                                  AppColor.secondaryPrimary.withOpacity(0.12),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.insights,
                              color: AppColor.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.today,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.home_performance_summary,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _overviewKpiTile(
                              title: loc.todaysSales,
                              value:
                                  '₹${controller.todaySales.value.toStringAsFixed(0)}',
                              sub:
                                  loc.home_yesterday_value(
                                    '₹${controller.yesterdaySales.value.toStringAsFixed(0)}',
                                  ),
                              icon: Icons.currency_rupee,
                              color: AppColor.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _overviewKpiTile(
                              title: loc.todaysOrders,
                              value: '${controller.todayOrders.value}',
                              sub:
                                  loc.home_yesterday_value(
                                    '${controller.yesterdayOrders.value}',
                                  ),
                              icon: Icons.receipt_long,
                              color: AppColor.secondaryPrimary,
                            ),
                          ),
                        ],
                      ),
                      Obx(() {
                        final list = controller.todayCategorySales;
                        if (list.isEmpty) return const SizedBox.shrink();

                        // show top few categories to keep the card compact
                        final top = list.take(4).toList();
                        return Column(
                          children: [
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.08),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  loc.home_category_wise_today,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  loc.home_top_count(top.length.toString()),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...top.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.category.capitalize ?? e.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[900],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '₹${e.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'x${e.quantity}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _overviewKpiTile({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklySalesChart(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final period = controller.selectedChartPeriod.value;
          String title = '';
          String subtitle = '';

          // Compare using enum index/name since nested enum access is problematic
          if (period.toString().contains('weekly')) {
            title = loc.home_weekly_sales_trend;
            subtitle = loc.home_last_7_days_sales;
          } else if (period.toString().contains('monthly')) {
            title = loc.home_monthly_sales_trend;
            subtitle = loc.home_last_12_months_sales;
          } else if (period.toString().contains('quarterly')) {
            title = loc.home_quarterly_sales_trend;
            subtitle = loc.home_last_4_quarters_sales;
          } else if (period.toString().contains('yearly')) {
            title = loc.home_yearly_sales_trend;
            subtitle = loc.home_last_5_years_sales;
          }

          return Showcase(
            key: showcaseController.salesChartKey,
            title: loc.home_sales_trend,
            description:
                loc.home_sales_trend_showcase_desc,
            titleTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
            overlayColor: Colors.black54,
            overlayOpacity: 0.7,
            tooltipBackgroundColor: AppColor.primary,
            textColor: Colors.white,
            child: _sectionHeader(
              title,
              subtitle: subtitle,
              trailing: Obx(() {
                final data = controller.chartSalesData;
                final total = data.fold<double>(0, (sum, item) => sum + item);
                final period = controller.selectedChartPeriod.value;
                final avg = total / (data.isEmpty ? 1 : data.length);

                String avgLabel = '';
                switch (period) {
                  case ChartPeriod.weekly:
                    avgLabel = 'Avg: ₹${avg.toStringAsFixed(0)}/day';
                    break;
                  case ChartPeriod.monthly:
                    avgLabel = 'Avg: ₹${avg.toStringAsFixed(0)}/month';
                    break;
                  case ChartPeriod.quarterly:
                    avgLabel = 'Avg: ₹${avg.toStringAsFixed(0)}/quarter';
                    break;
                  case ChartPeriod.yearly:
                    avgLabel = 'Avg: ₹${avg.toStringAsFixed(0)}/year';
                    break;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColor.primary,
                      ),
                    ),
                    Text(
                      avgLabel,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                  ],
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Filter buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: Obx(
            () => Row(
              children: [
                _buildPeriodFilterButton(
                  'Weekly',
                  ChartPeriod.weekly,
                  controller.selectedChartPeriod.value == ChartPeriod.weekly,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterButton(
                  'Monthly',
                  ChartPeriod.monthly,
                  controller.selectedChartPeriod.value == ChartPeriod.monthly,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterButton(
                  'Quarterly',
                  ChartPeriod.quarterly,
                  controller.selectedChartPeriod.value == ChartPeriod.quarterly,
                ),
                const SizedBox(width: 8),
                _buildPeriodFilterButton(
                  'Yearly',
                  ChartPeriod.yearly,
                  controller.selectedChartPeriod.value == ChartPeriod.yearly,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: _GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final data = controller.chartSalesData;
              final period = controller.selectedChartPeriod.value;
              final dataKey =
                  '${period.name}_${data.length}_${data.fold<double>(0, (a, b) => a + b).toStringAsFixed(0)}';
              final isEmpty = data.isEmpty;
              final maxValue = isEmpty
                  ? 10000.0
                  : data.reduce((a, b) => a > b ? a : b);
              final minValue = isEmpty
                  ? 0.0
                  : data.reduce((a, b) => a < b ? a : b);

              final calculatedMax = maxValue * 1.15;
              final horizontalInterval = calculatedMax > 0
                  ? calculatedMax / 4
                  : 2500.0;

              final labels = controller.chartLabels;
              final maxX = data.length > 0 ? (data.length - 1).toDouble() : 6.0;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: data.isEmpty
                    ? noSaleWidget().animate().fadeIn(duration: 300.ms)
                    : Column(
                        key: ValueKey(dataKey),
                        children: [
                          LayoutBuilder(
                            builder: (context, c) {
                              final rowMode = c.maxWidth >= 860;
                              final pieTitle = switch (period) {
                                ChartPeriod.weekly => 'Weekly distribution',
                                ChartPeriod.monthly => 'Monthly distribution',
                                ChartPeriod.quarterly =>
                                  'Quarterly distribution',
                                ChartPeriod.yearly => 'Yearly distribution',
                              };
                              final line = SizedBox(
                                height: rowMode ? 260 : 220,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: horizontalInterval,
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.15),
                                          strokeWidth: 1,
                                          dashArray: [5, 5],
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withOpacity(0.1),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 45,
                                          interval: horizontalInterval,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) {
                                              return Text(
                                                '₹0',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            }
                                            return Text(
                                              value >= 1000
                                                  ? '₹${(value / 1000).toStringAsFixed(1)}k'
                                                  : '₹${value.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize:
                                              period == ChartPeriod.yearly
                                              ? 50
                                              : 40,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < labels.length) {
                                              final label = labels[index];
                                              // Highlight current period
                                              bool isCurrent = false;
                                              final currentPeriod = controller
                                                  .selectedChartPeriod
                                                  .value;
                                              switch (currentPeriod) {
                                                case ChartPeriod.weekly:
                                                  isCurrent =
                                                      index ==
                                                      DateTime.now().weekday -
                                                          1;
                                                  break;
                                                case ChartPeriod.monthly:
                                                  isCurrent =
                                                      index ==
                                                      11; // Current month is last in array
                                                  break;
                                                case ChartPeriod.quarterly:
                                                  isCurrent =
                                                      index ==
                                                      3; // Current quarter is last
                                                  break;
                                                case ChartPeriod.yearly:
                                                  isCurrent =
                                                      index ==
                                                      4; // Current year is last
                                                  break;
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize:
                                                        currentPeriod ==
                                                            ChartPeriod.yearly
                                                        ? 9
                                                        : 10,
                                                    color: isCurrent
                                                        ? AppColor.primary
                                                        : Colors.grey[600],
                                                    fontWeight: isCurrent
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        left: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: maxX,
                                    minY: 0,
                                    maxY: calculatedMax,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          data.length,
                                          (index) => FlSpot(
                                            index.toDouble(),
                                            data[index],
                                          ),
                                        ),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColor.primary,
                                            AppColor.secondaryPrimary,
                                          ],
                                        ),
                                        barWidth: 3.5,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                                final isHighest =
                                                    spot.y == maxValue;
                                                final isLowest =
                                                    spot.y == minValue &&
                                                    minValue != maxValue;
                                                return FlDotCirclePainter(
                                                  radius:
                                                      (isHighest || isLowest)
                                                      ? 5
                                                      : 4,
                                                  color: Colors.white,
                                                  strokeWidth:
                                                      (isHighest || isLowest)
                                                      ? 2.5
                                                      : 2,
                                                  strokeColor: isHighest
                                                      ? Colors.green
                                                      : isLowest
                                                      ? Colors.orange
                                                      : AppColor.primary,
                                                );
                                              },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColor.primary.withOpacity(
                                                0.25,
                                              ),
                                              AppColor.primary.withOpacity(
                                                0.05,
                                              ),
                                              AppColor.primary.withOpacity(0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (_) =>
                                            AppColor.primary.withOpacity(0.9),
                                        tooltipPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final index = spot.x.toInt();
                                            String periodLabel;
                                            if (index >= 0 &&
                                                index < labels.length) {
                                              periodLabel = labels[index];
                                            } else {
                                              periodLabel =
                                                  'Period ${index + 1}';
                                            }
                                            return LineTooltipItem(
                                              '$periodLabel\n₹${spot.y.toStringAsFixed(0)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                      handleBuiltInTouches: true,
                                      getTouchedSpotIndicator:
                                          (barData, spotIndexes) {
                                            return spotIndexes.map((index) {
                                              return TouchedSpotIndicatorData(
                                                FlLine(
                                                  color: AppColor.primary
                                                      .withOpacity(0.5),
                                                  strokeWidth: 2,
                                                  dashArray: [5, 5],
                                                ),
                                                FlDotData(
                                                  show: true,
                                                  getDotPainter:
                                                      (
                                                        spot,
                                                        percent,
                                                        barData,
                                                        index,
                                                      ) {
                                                        return FlDotCirclePainter(
                                                          radius: 6,
                                                          color: Colors.white,
                                                          strokeWidth: 3,
                                                          strokeColor:
                                                              AppColor.primary,
                                                        );
                                                      },
                                                ),
                                              );
                                            }).toList();
                                          },
                                    ),
                                  ),
                                ),
                              );

                              final pie =
                                  _buildSalesPie(data, labels, title: pieTitle)
                                      .animate()
                                      .fadeIn(duration: 420.ms, delay: 80.ms)
                                      .slideY(
                                        begin: 0.06,
                                        end: 0,
                                        duration: 420.ms,
                                      );

                              if (!rowMode) {
                                // Narrow: stack
                                return Column(
                                  children: [
                                    line
                                        .animate()
                                        .fadeIn(duration: 420.ms)
                                        .slideY(
                                          begin: 0.08,
                                          end: 0,
                                          duration: 420.ms,
                                        ),
                                    const SizedBox(height: 14),
                                    pie,
                                  ],
                                );
                              }

                              // Wide: show both charts in a row
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: line
                                        .animate()
                                        .fadeIn(duration: 420.ms)
                                        .slideY(
                                          begin: 0.08,
                                          end: 0,
                                          duration: 420.ms,
                                        ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(width: 320, child: pie),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatIndicator(
                                      'Highest',
                                      '₹${maxValue.toStringAsFixed(0)}',
                                      Colors.green,
                                      Icons.trending_up,
                                    ),
                                    Container(
                                      height: 28,
                                      width: 1,
                                      color: Colors.grey.withOpacity(0.25),
                                    ),
                                    _buildStatIndicator(
                                      'Lowest',
                                      '₹${minValue.toStringAsFixed(0)}',
                                      Colors.orange,
                                      Icons.trending_down,
                                    ),
                                    Container(
                                      height: 28,
                                      width: 1,
                                      color: Colors.grey.withOpacity(0.25),
                                    ),
                                    _buildStatIndicator(
                                      'Average',
                                      '₹${(data.isEmpty ? 0 : data.reduce((a, b) => a + b) / data.length).toStringAsFixed(0)}',
                                      AppColor.primary,
                                      Icons.show_chart,
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 420.ms, delay: 140.ms)
                              .slideY(begin: 0.06, end: 0, duration: 420.ms),
                        ],
                      ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesPie(
    List<double> data,
    List<String> labels, {
    required String title,
  }) {
    final total = data.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 210,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Text(
                'No sales in this period',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final colors = <Color>[
      const Color(0xFF22D3EE), // cyan
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFEC4899), // pink
      const Color(0xFFF59E0B), // amber
      const Color(0xFF10B981), // green
      const Color(0xFF3B82F6), // blue
      const Color(0xFFEF4444), // red
    ];

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < data.length; i++) {
      final v = data[i];
      if (v <= 0) continue;
      final pct = (v / total) * 100;
      sections.add(
        PieChartSectionData(
          value: v,
          color: colors[i % colors.length],
          radius: 48,
          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    final pie = SizedBox(
      width: double.infinity,
      height: 210,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 38,
          startDegreeOffset: -90,
          borderData: FlBorderData(show: false),
          pieTouchData: PieTouchData(enabled: true),
        ),
      ),
    );

    final legend = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: List.generate(data.length, (i) {
        final v = data[i];
        if (v <= 0) return const SizedBox.shrink();
        final pct = (v / total) * 100;
        final label = (i >= 0 && i < labels.length) ? labels[i] : 'Day';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label • ₹${v.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).whereType<Widget>().toList(),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 10),
        pie,
        const SizedBox(height: 10),
        legend,
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: content,
    );
  }

  Widget _buildPeriodFilterButton(
    String label,
    ChartPeriod period,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setChartPeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColor.primary, AppColor.secondaryPrimary],
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatIndicator(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _topSellingItemsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          loc.top_selling_items,
          subtitle: loc.top_selling_items_subtitle,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: _GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final topItems = controller.topSellingItems.take(5).toList();
              if (topItems.isEmpty) {
                return Container(
                  height: 90,
                  alignment: Alignment.center,
                  child: Text(
                    loc.home_no_item_sales_yet,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(topItems.length, (index) {
                  final item = topItems[index];
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == topItems.length - 1 ? 0 : 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.imageUrl.isNotEmpty
                              ? m.Image.network(
                                  item.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return _itemPlaceholder();
                                  },
                                )
                              : _itemPlaceholder(),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColor.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name.capitalizeFirst ?? item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.category.capitalizeFirst ?? item.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${item.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Icon(
        Icons.fastfood_rounded,
        size: 18,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _featuresSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Showcase(
          key: showcaseController.featuresKey,
          title: loc.featuresForYou,
          description:
              loc.home_features_showcase_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: _sectionHeader(
            loc.featuresForYou,
            subtitle: loc.home_recommended_setup_tools,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return Obx(() {
                final List<Widget> tiles = [];

                tiles.add(
                  Expanded(
                    child: _buildFeatureListTile(
                      title: loc.addStaffSecurely_title,
                      description: loc.addStaffSecurely_desc,
                      icon: Icons.people_outline,
                      onTap: () => Modular.to.navigate(HomeMainRoutes.staff),
                    ),
                  ),
                );

                if (HomeMainRoutes.outletIsCafeOrRestaurant() &&
                    !controller.isKOT.value) {
                  tiles.add(const SizedBox(width: 12, height: 12));
                  tiles.add(
                    Expanded(
                      child: _buildFeatureListTile(
                        title: loc.printKOT_title,
                        description: loc.printKOT_desc,
                        icon: Icons.print_outlined,
                        onTap: () {
                          controller.setKotMode(true);
                        },
                        badgeText: loc.badge_new,
                      ),
                    ),
                  );
                }

                if (isWide) {
                  // Show tiles in a single row on wide screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tiles,
                  );
                }

                // Stack tiles vertically on small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFeatureListTile(
                      title: loc.addStaffSecurely_title,
                      description: loc.addStaffSecurely_desc,
                      icon: Icons.people_outline,
                      onTap: () => Get.toNamed(AppRoute.staffDetailsScreen),
                    ),
                    const SizedBox(height: 12),
                    if (HomeMainRoutes.outletIsCafeOrRestaurant() &&
                        !controller.isKOT.value)
                      _buildFeatureListTile(
                        title: loc.printKOT_title,
                        description: loc.printKOT_desc,
                        icon: Icons.print_outlined,
                        onTap: () {
                          controller.setKotMode(true);
                        },
                        badgeText: loc.badge_new,
                      ),
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureListTile({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return _GlassContainer(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColor.primary.withOpacity(0.18),
                    AppColor.secondaryPrimary.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Icon(icon, color: AppColor.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _testimonialsCarousel(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Showcase(
          key: showcaseController.testimonialsKey,
          title: loc.home_testimonials,
          description:
              loc.home_testimonials_showcase_desc,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          overlayColor: Colors.black54,
          overlayOpacity: 0.7,
          tooltipBackgroundColor: AppColor.primary,
          textColor: Colors.white,
          child: _sectionHeader(
            loc.what_our_users_say,
            subtitle: loc.what_our_users_say_subtitle,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
          child: _GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 18,
                            color: AppColor.secondaryPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.home_testimonials,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColor.primary.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '5.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 132,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _testimonials(loc).length,
                    onPageChanged: (index) => _currentPage.value = index,
                    itemBuilder: (context, index) {
                      final testimonial = _testimonials(loc)[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              testimonial['quote']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColor.primary,
                                      AppColor.secondaryPrimary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    testimonial['author']![0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  testimonial['author']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _testimonials(loc).length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage.value == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage.value == index
                                ? AppColor.secondaryPrimary
                                : Colors.grey[300],
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
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

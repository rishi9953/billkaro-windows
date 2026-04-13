import 'dart:async';
import 'dart:ui';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/Home/Widgets/payment_summary_widget.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Items/voice_add_menu_items_bottomsheet.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
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
  final controller = Get.put(HomeScreenController());
  final showcaseController = Get.put(ShowcaseController());
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  static const double _pageHMargin = 16;
  static const double _sectionGap = 18;
  static const double _cardRadius = 16;

  final List<Map<String, String>> testimonials = [
    {
      'quote':
          'This app is fast, easy to use, and perfect for hassle-free restaurant management.',
      'author': 'Ankit Kumar',
    },
    {
      'quote':
          'Best billing solution I\'ve used. Makes running my restaurant so much easier!',
      'author': 'Priya Sharma',
    },
    {
      'quote':
          'Simple, efficient, and reliable. Exactly what every restaurant owner needs.',
      'author': 'Rahul Verma',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkDeveloperOptionsAndShowSheet();
    // });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      int nextPage = _currentPage.value + 1;
      if (nextPage >= testimonials.length) nextPage = 0;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _currentPage.value = nextPage;
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    // var isKOT = controller.appPref.isKOT;
    // ShowCaseWidget is hosted in HomeMainScreen so bottom nav can be included in the tour.
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: Obx(() {
          return Showcase(
            key: showcaseController.outletSwitcherKey,
            title: 'Outlet',
            description:
                'Tap here to switch outlet. Your tables, orders, sales and reports will update for the selected outlet.',
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
            child: InkWell(
              onTap: () => controller.showOutletBottomSheet(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        controller.selectedOutletName.capitalizeFirst!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        leadingWidth: 160,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
            child: _headerAvatarAction(),
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
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Overview of your sales, orders and quick tools.',
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
                      _printerStatusBanner(),
                      const SizedBox(height: _sectionGap),
                      _quickActions(loc, isDesktop: isDesktop),
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
                      const SizedBox(height: _sectionGap),
                      _topSellingItemsSection(),
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
        message: 'AI Voice add items',
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

  Widget _headerAvatarAction() {
    return Obx(() {
      final selectedOutlet = controller.selectedOutlet.value;

      if (selectedOutlet == null) {
        return Showcase(
          key: showcaseController.profileKey,
          title: 'Profile / Business',
          description:
              'Open business settings, profile and outlet details from here.',
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
        title: 'Profile / Business',
        description: 'Open business settings and outlet details from here.',
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

  Widget _printerStatusBanner() {
    return Obx(() {
      if (!controller.printerservice2.isConnected.value) {
        return const SizedBox.shrink();
      }
      final name =
          controller.printerservice2.selectedPrinter.value?.name ??
          'Printer Connected';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pageHMargin),
        child: Showcase(
          key: showcaseController.printerBannerKey,
          title: 'Printer Status',
          description:
              'When your printer is connected, you can print invoices and KOTs without interruptions.',
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
                    Icons.bluetooth_connected,
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
                        'Printer connected',
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
                  child: const Text(
                    'Online',
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
          title: 'Quick Actions',
          description:
              'Shortcuts to frequently used features like Add Items, KOT History and more.',
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
            subtitle: 'Frequently used shortcuts',
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
                  'label': 'Tables',
                  'onTap': () => Modular.to.navigate(HomeMainRoutes.tables),
                },
              {
                'icon': Icons.add_shopping_cart_outlined,
                'label': loc.addItems,
                'onTap': () => Modular.to.pushNamed(HomeMainRoutes.addItem),
              },
              if (kotVisible)
                {
                  'icon': Icons.receipt_long_outlined,
                  'label': 'KOT History',
                  'onTap': () =>
                      Modular.to.pushNamed(HomeMainRoutes.kotHistory),
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
                      'View completed/paid orders and open details anytime.';
                } else if (label == loc.onHoldOrders) {
                  showcaseKey = showcaseController.holdOrdersKey;
                  showcaseDescription =
                      'Orders saved on hold. Resume billing anytime.';
                } else if (label == loc.addItems) {
                  showcaseKey = showcaseController.addItemsKey;
                  showcaseDescription =
                      'Add menu items to your inventory (manual / voice).';
                } else if (label == 'KOT History') {
                  showcaseKey = showcaseController.kotHistoryKey;
                  showcaseDescription =
                      'View KOT history, open details and reprint KOTs.';
                }

                return _buildQuickActionCard(
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

  Widget _buildQuickActionCard({
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
        description: showcaseDescription ?? 'Tap to access this feature.',
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
          subtitle: 'Today vs yesterday',
          trailing: TextButton(
            onPressed: () =>
                Modular.to.pushNamed(HomeMainRoutes.businessOverview),
            style: TextButton.styleFrom(
              foregroundColor: AppColor.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 12),
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
                'View detailed business insights including sales, orders, and performance metrics for today and yesterday.',
            title: 'Business Overview',
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
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Performance summary',
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
                                  'Yesterday: ₹${controller.yesterdaySales.value.toStringAsFixed(0)}',
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
                                  'Yesterday: ${controller.yesterdayOrders.value}',
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
                                  'Category-wise (Today)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Top ${top.length}',
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
            title = 'Weekly Sales Trend';
            subtitle = 'Last 7 days sales performance';
          } else if (period.toString().contains('monthly')) {
            title = 'Monthly Sales Trend';
            subtitle = 'Last 12 months sales performance';
          } else if (period.toString().contains('quarterly')) {
            title = 'Quarterly Sales Trend';
            subtitle = 'Last 4 quarters sales performance';
          } else if (period.toString().contains('yearly')) {
            title = 'Yearly Sales Trend';
            subtitle = 'Last 5 years sales performance';
          }

          return Showcase(
            key: showcaseController.salesChartKey,
            title: 'Sales Trend',
            description:
                'Track your sales trend by week/month/quarter/year and monitor totals and averages.',
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

  Widget _topSellingItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Top Selling Items',
          subtitle: 'Best performers (all time)',
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
                    'No item sales yet',
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
          title: 'Features for you',
          description:
              'Quick setup tools and recommended features to help you run your business faster.',
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
            subtitle: 'Recommended setup & tools',
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
                        badgeText: 'New',
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
                        badgeText: 'New',
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
          title: 'Testimonials',
          description:
              'See feedback from restaurants using Billkaro. Swipe to read more.',
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
            'What Our Users Say',
            subtitle: 'Feedback from restaurants using Billkaro',
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
                            'Testimonials',
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
                    itemCount: testimonials.length,
                    onPageChanged: (index) => _currentPage.value = index,
                    itemBuilder: (context, index) {
                      final testimonial = testimonials[index];
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
                      testimonials.length,
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

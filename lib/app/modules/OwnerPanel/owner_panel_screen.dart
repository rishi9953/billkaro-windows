import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/app/modules/OwnerPanel/widgets/owner_filter_bar.dart';
import 'package:billkaro/app/modules/OwnerPanel/widgets/owner_panel_tabs.dart';
import 'package:billkaro/config/config.dart';

class OwnerPanelScreen extends StatefulWidget {
  const OwnerPanelScreen({super.key});

  @override
  State<OwnerPanelScreen> createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen>
    with SingleTickerProviderStateMixin {
  late final OwnerPanelController controller =
      Get.put(OwnerPanelController());
  late final TabController _tabs;

  static const _tabLabels = [
    'Overview',
    'Inventory',
    'Wallet',
    'Subscriptions',
    'Transactions',
    'Outlets',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColor.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          loc.owner_panel_title,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(() {
            final refreshing = controller.isRefreshing.value;
            return IconButton(
              tooltip: loc.refresh,
              onPressed: refreshing ? null : controller.refreshDashboard,
              icon: refreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: AppColor.white),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ColoredBox(
            color: AppColor.primary,
            child: Align(
              alignment: Alignment.center,
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: AppColor.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelColor: AppColor.white,
                unselectedLabelColor: AppColor.white.withOpacity(0.62),
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  for (final label in _tabLabels) Tab(text: label),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.metrics.isEmpty) {
          return const _LoadingState();
        }

        if (controller.outlets.isEmpty) {
          return _EmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: loc.home_no_outlets_available,
            subtitle: loc.owner_panel_empty_subtitle,
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: OwnerFilterBar(controller: controller),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      OwnerOverviewTab(controller: controller),
                      OwnerInventoryTab(controller: controller),
                      OwnerWalletTab(controller: controller),
                      OwnerSubscriptionsTab(controller: controller),
                      OwnerTransactionsTab(controller: controller),
                      OwnerOutletsTab(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading outlet analytics…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

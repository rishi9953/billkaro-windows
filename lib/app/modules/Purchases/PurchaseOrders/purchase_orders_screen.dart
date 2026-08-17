import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_ui_actions.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_card.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_empty_state.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_header_bar.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_tab_bar.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_toolbar.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter_modular/flutter_modular.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  late final PurchaseOrderController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PurchaseOrderController>()
        ? Get.find<PurchaseOrderController>()
        : Get.put(PurchaseOrderController());
    searchController = TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !shouldConfirmLeavePurchaseOrders(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave =
            await confirmLeavePurchaseOrdersScreen(context, loc);
        if (shouldLeave && context.mounted) {
          Modular.to.navigate(HomeMainRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: PurchaseOrderController.screenBg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PurchaseOrderTabBar(controller: controller, loc: loc),
                PurchaseOrderHeaderBar(
                  title: loc.tab_purchase_orders,
                  onRefresh: controller.loadPurchaseOrders,
                ),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              PurchaseOrderToolbar(
                controller: controller,
                loc: loc,
                searchController: searchController,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final all = controller.purchaseOrders;
                  final list = controller.filteredPurchaseOrders;

                  if (all.isEmpty) {
                    return PurchaseOrderEmptyState(
                      message: loc.no_purchase_orders_yet,
                    );
                  }
                  if (list.isEmpty) {
                    return PurchaseOrderEmptyState(
                      message: loc.no_results_available,
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => PurchaseOrderCard(
                      controller: controller,
                      po: list[i],
                      loc: loc,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: StaffAccess.canAdjustStock
            ? FloatingActionButton.extended(
                onPressed: () {
                  if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
                  controller.openCreateDrawer();
                },
                backgroundColor: PurchaseOrderController.accent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(loc.create_po),
              )
            : null,
      ),
    );
  }
}

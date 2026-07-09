import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_ui_actions.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_card.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_empty_state.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_header_bar.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/widgets/purchase_order_tab_bar.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  late final PurchaseOrderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PurchaseOrderController>()
        ? Get.find<PurchaseOrderController>()
        : Get.put(PurchaseOrderController());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !shouldConfirmLeavePurchaseOrders(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await confirmLeavePurchaseOrdersScreen(context, loc);
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
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final list = controller.purchaseOrders;
            if (list.isEmpty) {
              return PurchaseOrderEmptyState(message: loc.no_purchase_orders_yet);
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PurchaseOrderCard(
                controller: controller,
                po: list[i],
                loc: loc,
              ),
            );
          }),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.openCreateDrawer,
          backgroundColor: PurchaseOrderController.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(loc.create_po),
        ),
      ),
    );
  }
}

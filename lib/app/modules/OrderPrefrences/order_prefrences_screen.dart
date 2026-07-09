import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class OrderPreferencesScreen extends StatelessWidget {
  OrderPreferencesScreen({super.key});

  final OrderPreferencesController controller = Get.put(
    OrderPreferencesController(),
  );

  static const double _maxContentWidth = 720;
  static const double _sidePadding = 16;
  static const double _tileVerticalPadding = 12;
  static const double _tileHorizontalPadding = 16;
  static const double _tileIconSize = 22;
  static const double _tileIconPadding = 10;
  static const Color _mutedText = Color(0xFF757575);
  static const Color _tileHover = Color(0x22000000);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          controller.syncPreferencesToAddOrderOnPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.backGroundColor,
        appBar: AppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: _canShowBackButton(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(
            loc.order_preferences,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  _sidePadding,
                  20,
                  _sidePadding,
                  32,
                ),
                children: [
                  _buildIntroCard(loc, theme),
                  const Gap(24),
                  if (_showsKotSection()) ...[
                    _buildSection(
                      loc.kot_mode,
                      [_buildKotTile(loc)],
                    ),
                    const Gap(24),
                  ],
                  _buildSection(
                    loc.billing_view,
                    [_buildBillingViewPicker(loc, theme)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canShowBackButton(BuildContext context) {
    return Modular.to.canPop() || Navigator.of(context).canPop();
  }

  bool _showsKotSection() {
    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().selectedOutlet.value;
    }
    return HomeMainRoutes.outletIsCafeOrRestaurant();
  }

  Widget _buildIntroCard(AppLocalizations loc, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withOpacity(0.95),
            AppColor.primary.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.order_preferences,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(6),
                Text(
                  loc.billing_list_view_subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Gap(8),
        _buildSectionCard(children: children),
      ],
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLeadingIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(_tileIconPadding),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColor.primary, size: _tileIconSize),
    );
  }

  Widget _buildKotTile(AppLocalizations loc) {
    return Obx(() {
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().selectedOutlet.value;
      }
      return InkWell(
        onTap: controller.showKotModeBottomSheet,
        hoverColor: _tileHover,
        splashColor: Colors.transparent,
        highlightColor: _tileHover,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _tileHorizontalPadding,
            vertical: _tileVerticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeadingIcon(Icons.receipt_long_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.kot_mode,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.kot_mode_choose_handling,
                      style: const TextStyle(fontSize: 12, color: _mutedText),
                    ),
                    const Gap(8),
                    InkWell(
                      onTap: controller.showKotModeBottomSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          loc.how_does_this_work,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.92,
                child: Switch(
                  value: controller.kotModeEnabled.value,
                  onChanged: controller.toggleKotMode,
                  activeTrackColor: AppColor.primary,
                  activeColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBillingViewPicker(AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(_tileHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.billing_list_view_subtitle,
            style: const TextStyle(fontSize: 12, color: _mutedText, height: 1.4),
          ),
          const Gap(16),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildViewOption(
                    title: loc.billing_image_view,
                    isSelected: !controller.isListView.value,
                    preview: _ImageGridPreview(
                      isSelected: !controller.isListView.value,
                    ),
                    onTap: () => controller.selectBillingView(false),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildViewOption(
                    title: loc.billing_list_view_option,
                    isSelected: controller.isListView.value,
                    preview: _ListViewPreview(
                      isSelected: controller.isListView.value,
                    ),
                    onTap: () => controller.selectBillingView(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewOption({
    required String title,
    required Widget preview,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppColor.primary.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary.withOpacity(0.06)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColor.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  preview,
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primary.withOpacity(0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColor.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGridPreview extends StatelessWidget {
  const _ImageGridPreview({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tileColor = isSelected
        ? AppColor.primary.withOpacity(0.18)
        : Colors.grey.shade300;

    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListViewPreview extends StatelessWidget {
  const _ListViewPreview({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? AppColor.primary.withOpacity(0.18)
        : Colors.grey.shade300;

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (index == 0) ...[
                      const Gap(4),
                      Container(
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

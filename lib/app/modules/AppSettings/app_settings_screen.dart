import 'package:billkaro/app/modules/AppSettings/app_settings_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/cash_drawer_helper.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/kitchen_display_browser.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppSettingsScreen extends StatelessWidget {
  AppSettingsScreen({super.key});
  late final controller = Get.put(AppSettingsController());
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Text(
          loc.settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                loc.settings_section_general,
                _withDividers([
                  _buildSwitchTile(
                    icon: Icons.view_list_rounded,
                    title: loc.billing_list_view,
                    subtitle: loc.billing_list_view_subtitle,
                    value: controller.isListView,
                    onChanged: controller.setListView,
                  ),
                  _buildSwitchTile(
                    icon: Icons.qr_code_2_outlined,
                    title: loc.show_qr_on_bill,
                    subtitle: loc.show_qr_on_bill_subtitle,
                    value: controller.showQrOnBill,
                    onChanged: controller.setShowQrOnBill,
                  ),
                  _buildSwitchTile(
                    icon: Icons.edit_note_outlined,
                    title: loc.add_details_on_create_order,
                    subtitle: loc.add_details_on_create_order_subtitle,
                    value: controller.showAddDetailsOnCreateOrder,
                    onChanged: controller.setShowAddDetailsOnCreateOrder,
                  ),
                  _buildSwitchTile(
                    icon: Icons.sync_rounded,
                    title: loc.sync_devices,
                    subtitle: loc.sync_across_multiple_devices,
                    value: controller.autoSyncEnabled,
                    onChanged: controller.setAutoSyncEnabled,
                  ),
                  Obx(() {
                    final drawerOn = controller.cashDrawerEnabled.value;
                    return Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.point_of_sale_outlined,
                          title: loc.cash_drawer,
                          subtitle: loc.cash_drawer_subtitle,
                          value: controller.cashDrawerEnabled,
                          onChanged: controller.setCashDrawerEnabled,
                        ),
                        if (drawerOn) ...[
                          _buildSwitchTile(
                            icon: Icons.payments_outlined,
                            title: loc.open_cash_drawer_on_cash_payment,
                            subtitle:
                                loc.open_cash_drawer_on_cash_payment_subtitle,
                            value: controller.openCashDrawerOnCashPayment,
                            onChanged: controller.setOpenCashDrawerOnCashPayment,
                          ),
                          _buildCashDrawerPinTile(context, loc),
                        ],
                      ],
                    );
                  }),
                  if (Get.isRegistered<HomeScreenController>())
                    Obx(() {
                      Get.find<HomeScreenController>().selectedOutlet.value;
                      if (!HomeMainRoutes.outletIsCafeOrRestaurant()) {
                        return const SizedBox.shrink();
                      }
                      final kotOn = controller.kotModeEnabled.value;
                      return Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.restaurant_menu_outlined,
                            title: loc.kot_mode,
                            subtitle: loc.printKOT_desc.replaceAll('\n', ' '),
                            value: controller.kotModeEnabled,
                            onChanged: controller.setKotMode,
                          ),
                          if (kotOn)
                            _buildActionOrNavTile(
                              icon: Icons.open_in_browser_rounded,
                              title: loc.kitchen_display_in_browser,
                              subtitle: loc.kitchen_display_browser_subtitle,
                              onTap: KitchenDisplayBrowser.open,
                            ),
                        ],
                      );
                    })
                  else if (HomeMainRoutes.outletIsCafeOrRestaurant())
                    Obx(() {
                      final kotOn = controller.kotModeEnabled.value;
                      return Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.restaurant_menu_outlined,
                            title: loc.kot_mode,
                            subtitle: loc.printKOT_desc.replaceAll('\n', ' '),
                            value: controller.kotModeEnabled,
                            onChanged: controller.setKotMode,
                          ),
                          if (kotOn)
                            _buildActionOrNavTile(
                              icon: Icons.open_in_browser_rounded,
                              title: loc.kitchen_display_in_browser,
                              subtitle: loc.kitchen_display_browser_subtitle,
                              onTap: KitchenDisplayBrowser.open,
                            ),
                        ],
                      );
                    }),
                  _buildActionOrNavTile(
                    icon: Icons.tour_outlined,
                    title: loc.show_onboarding_again,
                    subtitle: loc.show_onboarding_again_subtitle,
                    onTap: () {
                      controller.resetOnboarding();
                      Get.back();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Modular.to.navigate(HomeMainRoutes.home);
                      });
                    },
                  ),
                  Obx(
                    () => _buildActionOrNavTile(
                      icon: Icons.folder_open_outlined,
                      title: loc.download_path,
                      subtitle: controller.downloadPath.value.isEmpty
                          ? loc.default_downloads_folder
                          : controller.downloadPath.value,
                      onTap: controller.pickDownloadPath,
                      showChevron: true,
                    ),
                  ),
                ]),
              ),
              const Gap(24),
              _buildSection(loc.settings_section_notifications, [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: loc.settings_section_notifications,
                  subtitle: loc.settings_notifications_subtitle,
                  value: controller.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                ),
                _buildTile(
                  icon: Icons.inbox_outlined,
                  title: loc.notification_history,
                  subtitle: loc.notification_history_subtitle,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onTap: () =>
                      Modular.to.pushNamed(HomeMainRoutes.notifications),
                ),
              ]),
              const Gap(24),
              _buildSection(loc.settings_section_appearance, [
                Obx(
                  () => _buildTile(
                    icon: Icons.palette_outlined,
                    title: loc.theme_color,
                    subtitle: themeController.selectedThemeColorName,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: themeController.themeColor.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                    onTap: () => _showThemeColorPicker(context, loc),
                  ),
                ),
              ]),
              const Gap(24),
              _buildSection(loc.settings_section_language_region, [
                _buildActionOrNavTile(
                  icon: Icons.language,
                  title: loc.language,
                  subtitle: loc.change_app_language,
                  onTap: () =>
                      Modular.to.pushNamed(HomeMainRoutes.changeLanguage),
                  showChevron: true,
                ),
              ]),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }

  static const double _sidePadding = 16;
  static const double _tileVerticalPadding = 12;
  static const double _tileHorizontalPadding = 16;
  static const double _tileIconSize = 22;
  static const double _tileIconPadding = 10;
  static const double _tileRadius = 12;
  static const Color _mutedText = Color(0xFF757575);
  static const Color _tileHover = Color(0x22000000);

  TextStyle get _sectionHeaderStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _mutedText,
    letterSpacing: 0.5,
  );

  TextStyle get _titleStyle => const TextStyle(
    fontSize: 15,
    color: Colors.black87,
    fontWeight: FontWeight.w600,
  );

  TextStyle get _subtitleStyle =>
      const TextStyle(fontSize: 12, color: _mutedText);

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(title, style: _sectionHeaderStyle),
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
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    color: Colors.grey[200],
    indent: _sidePadding,
    endIndent: _sidePadding,
  );

  List<Widget> _withDividers(List<Widget> tiles) {
    if (tiles.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      result.add(tiles[i]);
      if (i != tiles.length - 1) result.add(_buildDivider());
    }
    return result;
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

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: _tileHover,
      splashColor: Colors.transparent,
      highlightColor: _tileHover,
      mouseCursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(_tileRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _tileHorizontalPadding,
          vertical: _tileVerticalPadding,
        ),
        child: Row(
          children: [
            _buildLeadingIcon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _titleStyle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _subtitleStyle),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Obx(
        () => Switch(
          value: value.value,
          onChanged: onChanged,
          activeColor: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildCashDrawerPinTile(BuildContext context, AppLocalizations loc) {
    return Obx(() {
      final selected = cashDrawerPinFromStorage(controller.cashDrawerPin.value);
      return _buildTile(
        icon: Icons.settings_input_component_outlined,
        title: loc.cash_drawer_kick_pin,
        subtitle: loc.cash_drawer_kick_pin_subtitle,
        trailing: SegmentedButton<CashDrawerPin>(
          segments: [
            ButtonSegment(
              value: CashDrawerPin.pin2,
              label: Text(loc.cash_drawer_pin_2),
            ),
            ButtonSegment(
              value: CashDrawerPin.pin5,
              label: Text(loc.cash_drawer_pin_5),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (set) {
            controller.setCashDrawerPin(set.first);
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    });
  }

  Widget _buildActionOrNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return _buildTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: showChevron
          ? Icon(Icons.chevron_right, color: Colors.grey[400], size: 20)
          : const SizedBox.shrink(),
    );
  }

  Future<void> _showThemeColorPicker(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Obx(() {
            final selected =
                themeController.themeColor.value.value & 0xFFFFFFFF;
            final customs = themeController.customThemeColors.toList();
            return CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            loc.theme_color,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            tooltip: loc.close,
                            icon: Icon(Icons.close, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      loc.custom_hex,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ThemeHexInputRow(
                    themeController: themeController,
                    loc: loc,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (customs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        loc.my_colors,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final color = Color(customs[index] & 0xFFFFFFFF);
                      final label = ThemeController.hexRgbString(color);
                      final isSelected = (color.value & 0xFFFFFFFF) == selected;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 16,
                              endIndent: 16,
                            ),
                          ListTile(
                            leading: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                            title: Text(label),
                            trailing: isSelected
                                ? Icon(Icons.check, color: color)
                                : const SizedBox.shrink(),
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                await themeController.setThemeColor(color);
                              });
                            },
                          ),
                        ],
                      );
                    }, childCount: customs.length),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      loc.presets,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = ThemeController.colorOptions[index];
                    final isSelected =
                        (item.value.value & 0xFFFFFFFF) == selected;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ListTile(
                          leading: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: item.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          title: Text(item.key),
                          trailing: isSelected
                              ? Icon(Icons.check, color: item.value)
                              : const SizedBox.shrink(),
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              await themeController.setThemeColor(item.value);
                            });
                          },
                        ),
                      ],
                    );
                  }, childCount: ThemeController.colorOptions.length),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class _ThemeHexInputRow extends StatefulWidget {
  const _ThemeHexInputRow({
    required this.themeController,
    required this.loc,
  });

  final ThemeController themeController;
  final AppLocalizations loc;

  @override
  State<_ThemeHexInputRow> createState() => _ThemeHexInputRowState();
}

class _ThemeHexInputRowState extends State<_ThemeHexInputRow> {
  late final TextEditingController _hexController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(
      text: ThemeController.hexRgbString(
        widget.themeController.themeColor.value,
      ),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final ok = await widget.themeController.setThemeColorFromHex(
      _hexController.text,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _errorText = null);
      _hexController.text = ThemeController.hexRgbString(
        widget.themeController.themeColor.value,
      );
    } else {
      setState(() {
        _errorText = widget.loc.hex_format_error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _hexController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '#083C6B',
                    errorText: _errorText,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(widget.loc.apply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

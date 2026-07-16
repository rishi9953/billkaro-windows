import 'package:billkaro/app/modules/AppSettings/app_settings_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Language/language_dialog.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_dialogs.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/Widgets/billing_mode_selector.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/cash_drawer_helper.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/kitchen_display_browser.dart';
import 'package:billkaro/utils/po_print_orientation.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
                  // _buildSwitchTile(
                  //   icon: Icons.view_list_rounded,
                  //   title: loc.billing_list_view,
                  //   subtitle: loc.billing_list_view_subtitle,
                  //   value: controller.isListView,
                  //   onChanged: controller.setListView,
                  // ),
                  // _buildActionOrNavTile(
                  //   icon: Icons.description_outlined,
                  //   title: loc.settings_po_terms,
                  //   subtitle: loc.settings_po_terms_subtitle,
                  //   onTap: showPoDefaultTermsSettingsDialog,
                  //   showChevron: true,
                  // ),
                  // _buildPoPrintOrientationTile(loc),
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

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.point_of_sale_outlined,
                        title: loc.cash_drawer,
                        subtitle: loc.cash_drawer_subtitle,
                        value: controller.cashDrawerEnabled,
                        onChanged: controller.setCashDrawerEnabled,
                      ),
                      Obx(() {
                        if (!controller.cashDrawerEnabled.value) {
                          return const SizedBox.shrink();
                        }
                        final openOnCash =
                            controller.openCashDrawerOnCashPayment.value;
                        final selected = cashDrawerPinFromStorage(
                          controller.cashDrawerPin.value,
                        );
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDivider(),
                            _buildTile(
                              icon: Icons.payments_outlined,
                              title: loc.open_cash_drawer_on_cash_payment,
                              subtitle: loc
                                  .open_cash_drawer_on_cash_payment_subtitle,
                              trailing: Switch(
                                value: openOnCash,
                                onChanged:
                                    controller.setOpenCashDrawerOnCashPayment,
                                activeColor: AppColor.primary,
                              ),
                            ),
                            _buildDivider(),
                            _buildTile(
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  if (Get.isRegistered<HomeScreenController>())
                    Obx(() {
                      Get.find<HomeScreenController>().selectedOutlet.value;
                      if (!HomeMainRoutes.outletIsCafeOrRestaurant()) {
                        return const SizedBox.shrink();
                      }
                      final kotOn = controller.kotModeEnabled.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTile(
                            icon: Icons.restaurant_menu_outlined,
                            title: loc.kot_mode,
                            subtitle:
                                loc.printKOT_desc.replaceAll('\n', ' '),
                            trailing: Switch(
                              value: kotOn,
                              onChanged: controller.setKotMode,
                              activeColor: AppColor.primary,
                            ),
                          ),
                          if (kotOn) ...[
                            _buildDivider(),
                            _buildActionOrNavTile(
                              icon: Icons.open_in_browser_rounded,
                              title: loc.kitchen_display_in_browser,
                              subtitle:
                                  loc.kitchen_display_browser_subtitle,
                              onTap: KitchenDisplayBrowser.open,
                            ),
                          ],
                        ],
                      );
                    })
                  else if (HomeMainRoutes.outletIsCafeOrRestaurant())
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.restaurant_menu_outlined,
                          title: loc.kot_mode,
                          subtitle: loc.printKOT_desc.replaceAll('\n', ' '),
                          value: controller.kotModeEnabled,
                          onChanged: controller.setKotMode,
                        ),
                        Obx(() {
                          if (!controller.kotModeEnabled.value) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDivider(),
                              _buildActionOrNavTile(
                                icon: Icons.open_in_browser_rounded,
                                title: loc.kitchen_display_in_browser,
                                subtitle:
                                    loc.kitchen_display_browser_subtitle,
                                onTap: KitchenDisplayBrowser.open,
                              ),
                            ],
                          );
                        }),
                      ],
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
              if (StaffAccess.isOwnerSession) ...[
                _buildSection(loc.settings_section_billing, [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.billing_mode_title, style: _titleStyle),
                        const Gap(4),
                        Text(loc.billing_mode_subtitle, style: _subtitleStyle),
                      ],
                    ),
                  ),
                  Obx(
                    () => BillingModeSelector(
                      selected: controller.billingAccessMode.value,
                      enabled: controller.canChangeBillingMode,
                      onSelected: controller.requestBillingModeChange,
                      subscriptionTitle: loc.billing_mode_subscription,
                      subscriptionSubtitle: loc.billing_mode_subscription_desc,
                      walletTitle: loc.billing_mode_wallet,
                      walletSubtitle: loc.billing_mode_wallet_desc,
                    ),
                  ),
                ]),
                const Gap(24),
              ],
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
                  onTap: () => showLanguagePickerDialog(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
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

  Widget _buildPoPrintOrientationTile(AppLocalizations loc) {
    return Obx(() {
      final selected = controller.poPrintOrientation.value;
      return _buildTile(
        icon: Icons.print_outlined,
        title: loc.settings_po_print_orientation,
        subtitle: loc.settings_po_print_orientation_subtitle,
        trailing: SegmentedButton<PoPrintOrientation>(
          segments: [
            ButtonSegment(
              value: PoPrintOrientation.portrait,
              label: Text(loc.po_print_portrait),
            ),
            ButtonSegment(
              value: PoPrintOrientation.landscape,
              label: Text(loc.po_print_landscape),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (set) {
            controller.setPoPrintOrientation(set.first);
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

  static const double _dialogRadius = 8;

  Future<void> _showThemeColorPicker(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_dialogRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
            child: Obx(() {
              final selectedColor = themeController.themeColor.value;
              final selected =
                  selectedColor.value & 0xFFFFFFFF;
              final customs = themeController.customThemeColors.toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.theme_color,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          tooltip: loc.close,
                          icon: Icon(Icons.close, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCurrentThemeColorCard(
                            color: selectedColor,
                            name: themeController.selectedThemeColorName,
                          ),
                          const SizedBox(height: 20),
                          _buildThemeSectionLabel(loc.presets),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in ThemeController.colorOptions)
                                _ThemeColorSwatch(
                                  color: item.value,
                                  label: item.key,
                                  selected:
                                      (item.value.value & 0xFFFFFFFF) ==
                                      selected,
                                  onTap: () =>
                                      themeController.setThemeColor(item.value),
                                ),
                            ],
                          ),
                          if (customs.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildThemeSectionLabel(loc.my_colors),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final argb in customs)
                                  _ThemeColorSwatch(
                                    color: Color(argb & 0xFFFFFFFF),
                                    label: ThemeController.hexRgbString(
                                      Color(argb & 0xFFFFFFFF),
                                    ),
                                    selected:
                                        (argb & 0xFFFFFFFF) == selected,
                                    onTap: () => themeController.setThemeColor(
                                      Color(argb & 0xFFFFFFFF),
                                    ),
                                    onDelete: () => themeController
                                        .removeCustomThemeColor(
                                      Color(argb & 0xFFFFFFFF),
                                    ),
                                    deleteTooltip: loc.delete,
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          _buildThemeSectionLabel(loc.custom_hex),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _pickCustomThemeColor(
                              dialogContext,
                              loc,
                            ),
                            icon: const Icon(Icons.colorize_rounded, size: 18),
                            label: Text(loc.custom_hex),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.primary,
                              side: BorderSide(
                                color: AppColor.primary.withOpacity(0.35),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _dialogRadius,
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
            }),
          ),
        );
      },
    );
  }

  Widget _buildCurrentThemeColorCard({
    required Color color,
    required String name,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_dialogRadius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(_dialogRadius),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ThemeController.hexRgbString(color),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Future<void> _pickCustomThemeColor(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    final start = themeController.themeColor.value;
    final picked = await showColorPickerDialog(
      context,
      start,
      title: Text(
        loc.custom_hex,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      width: 40,
      height: 40,
      spacing: 6,
      runSpacing: 6,
      borderRadius: _dialogRadius,
      wheelDiameter: 190,
      wheelWidth: 18,
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      showColorName: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        dialogActionButtons: true,
      ),
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 320,
        maxWidth: 420,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogRadius),
      ),
    );

    if ((picked.value & 0xFFFFFFFF) == (start.value & 0xFFFFFFFF)) return;
    await themeController.registerCustomThemeColor(picked);
    await themeController.setThemeColor(picked);
  }
}

class _ThemeColorSwatch extends StatelessWidget {
  const _ThemeColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDelete,
    this.deleteTooltip,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final swatch = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.black87 : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 20,
                color:
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              )
            : null,
      ),
    );

    return Tooltip(
      message: label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 0, bottom: 0, child: swatch),
            if (onDelete != null)
              Positioned(
                top: -2,
                right: -2,
                child: Tooltip(
                  message: deleteTooltip ?? 'Delete',
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      onTap: onDelete,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

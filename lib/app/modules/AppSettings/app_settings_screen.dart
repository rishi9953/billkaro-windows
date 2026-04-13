import 'package:billkaro/app/modules/AppSettings/app_settings_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/config/config.dart';
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
                'General',
                _withDividers([
                  _buildSwitchTile(
                    icon: Icons.view_list_rounded,
                    title: 'Billing list view',
                    subtitle: 'Show orders as list instead of image grid',
                    value: controller.isListView,
                    onChanged: controller.setListView,
                  ),
                  _buildSwitchTile(
                    icon: Icons.qr_code_2_outlined,
                    title: 'Show QR on bill',
                    subtitle: 'Show UPI scan-to-pay QR on invoice and print',
                    value: controller.showQrOnBill,
                    onChanged: controller.setShowQrOnBill,
                  ),
                  _buildSwitchTile(
                    icon: Icons.edit_note_outlined,
                    title: 'Add details on create order',
                    subtitle:
                        'Show Add Details for customer, table, discount, and payment',
                    value: controller.showAddDetailsOnCreateOrder,
                    onChanged: controller.setShowAddDetailsOnCreateOrder,
                  ),
                  if (Get.isRegistered<HomeScreenController>())
                    Obx(() {
                      Get.find<HomeScreenController>().selectedOutlet.value;
                      if (!HomeMainRoutes.outletIsCafeOrRestaurant()) {
                        return const SizedBox.shrink();
                      }
                      return _buildSwitchTile(
                        icon: Icons.restaurant_menu_outlined,
                        title: loc.kot_mode,
                        subtitle: loc.printKOT_desc.replaceAll('\n', ' '),
                        value: controller.kotModeEnabled,
                        onChanged: controller.setKotMode,
                      );
                    })
                  else if (HomeMainRoutes.outletIsCafeOrRestaurant())
                    _buildSwitchTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: loc.kot_mode,
                      subtitle: loc.printKOT_desc.replaceAll('\n', ' '),
                      value: controller.kotModeEnabled,
                      onChanged: controller.setKotMode,
                    ),
                  _buildActionOrNavTile(
                    icon: Icons.tour_outlined,
                    title: 'Show onboarding again',
                    subtitle: 'Replay the app intro and tips',
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
                      title: 'Download path',
                      subtitle: controller.downloadPath.value.isEmpty
                          ? 'Default Downloads folder'
                          : controller.downloadPath.value,
                      onTap: controller.pickDownloadPath,
                      showChevron: true,
                    ),
                  ),
                ]),
              ),
              const Gap(24),
              _buildSection('Notifications', [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order and reminder notifications',
                  value: controller.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                ),
              ]),
              const Gap(24),
              _buildSection('Appearance', [
                Obx(
                  () => _buildTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme color',
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
                    onTap: () => _showThemeColorPicker(context),
                  ),
                ),
              ]),
              const Gap(24),
              _buildSection('Language & region', [
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

  Future<void> _showThemeColorPicker(BuildContext context) async {
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
                            'Theme color',
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
                            tooltip: 'Close',
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
                      'Custom hex',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ThemeHexInputRow(themeController: themeController),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (customs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'My colors',
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
                      'Presets',
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
  const _ThemeHexInputRow({required this.themeController});

  final ThemeController themeController;

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
        _errorText = 'Use #RRGGBB (e.g. #2196F3) or #AARRGGBB';
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
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/PrinterService2/printer_screen2_controller.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/thermal_paper_size.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
import 'dart:io' show Platform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

/// USB, BLE, and Ethernet can each be connected; each gets its own status card.
enum PrinterScreen2ConnLink {
  bleThermal,
  usbThermal,
  ethernet,
  classicBluetooth,
}

class PrinterScreen2 extends StatefulWidget {
  const PrinterScreen2({super.key});

  @override
  State<PrinterScreen2> createState() => _PrinterScreen2State();
}

class _PrinterScreen2State extends State<PrinterScreen2>
    with SingleTickerProviderStateMixin {
  late final PrinterService2 printerService;
  late final PrinterScreen2Controller roleController;
  ThermalPrinterService get thermalPrinter => ThermalPrinterService.instance;
  late TabController _tabController;
  final TextEditingController _bleSearchController = TextEditingController();
  final TextEditingController _usbSearchController = TextEditingController();
  String _bleSearchQuery = '';
  String _usbSearchQuery = '';
  bool get _isWindowsDesktop => Platform.isWindows;

  static const double _winMaxContentWidth = 1180;
  static const double _winCardRadius = 16;
  static const double _winTwoColumnBreakpoint = 920;
  static const Color _winTileHover = Color(0x0A0F172A);

  final ScrollController _bleListScrollController = ScrollController();
  final ScrollController _usbListScrollController = ScrollController();
  final ScrollController _classicBtScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    printerService = Get.put(PrinterService2());
    if (Get.isRegistered<PrinterScreen2Controller>()) {
      roleController = Get.find<PrinterScreen2Controller>();
      roleController.loadRolePrinters();
      unawaited(thermalPrinter.restoreNetworkConnectionStatus());
    } else {
      roleController = Get.put(PrinterScreen2Controller());
    }

    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanBleOnceOnOpen());
    } else {
      printerService.init();
      printerService.scanForDevices();
    }

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// One BLE scan when the screen opens (manual reconnect stays disabled).
  void _scanBleOnceOnOpen() {
    if (!mounted) return;
    if (thermalPrinter.isScanning.value ||
        thermalPrinter.isBleConnecting.value ||
        thermalPrinter.connectedBleDeviceId.value != null) {
      return;
    }
    thermalPrinter.startScan();
  }

  @override
  void dispose() {
    _bleSearchController.dispose();
    _usbSearchController.dispose();
    _bleListScrollController.dispose();
    _usbListScrollController.dispose();
    _classicBtScrollController.dispose();
    _tabController.dispose();
    if (Platform.isWindows) {
      thermalPrinter.stopScan();
    }
    super.dispose();
  }

  Widget _connectDisconnectButton({
    required BuildContext context,
    required bool isConnected,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final height = _isWindowsDesktop ? 36.0 : 40.0;
    final textStyle = TextStyle(
      fontSize: _isWindowsDesktop ? 12 : 14,
      fontWeight: FontWeight.w600,
    );
    if (isLoading) {
      return FilledButton.tonal(
        style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
        onPressed: null,
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (isConnected) {
      final error = Theme.of(context).colorScheme.error;
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error.withOpacity(0.85)),
          minimumSize: Size.fromHeight(height),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onPressed,
        child: Text(loc.disconnect, style: textStyle),
      );
    }
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: AppColor.primary.withOpacity(0.08),
        foregroundColor: AppColor.primary,
      ),
      onPressed: onPressed,
      child: Text(loc.connect, style: textStyle),
    );
  }

  Future<void> _onRefreshPressed() async {
    if (Platform.isWindows) {
      if (_tabController.index == 0) {
        await thermalPrinter.startScan();
      } else if (_tabController.index == 1) {
        await thermalPrinter.scanUsbPrinters();
      } else {
        await roleController.loadRolePrinters();
      }
    } else {
      await printerService.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWindowsDesktop) {
      return _buildWindowsScaffold(context);
    }
    return _buildMobileScaffold(context);
  }

  PreferredSizeWidget _buildAppBarBottom(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildWindowsScaffold(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: AppColor.white,
        title: Text(
          loc.printer_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.white,
          ),
        ),
        bottom: _buildAppBarBottom(context),
        actions: [
          TextButton.icon(
            onPressed: _onRefreshPressed,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(loc.refresh),
            style: TextButton.styleFrom(foregroundColor: AppColor.white),
          ),
          const Gap(8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _winMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns =
                      constraints.maxWidth >= _winTwoColumnBreakpoint;
                  Widget sidebarContent() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMultiplePrinterSettingsCard(context),
                        const Gap(14),
                        _buildPaperSizeCard(context),
                        const Gap(14),
                        _buildCashDrawerCard(context),
                        const Gap(14),
                        _buildConnectionStatusCards(context),
                        const Gap(12),
                        _buildWindowsHelpCard(context),
                      ],
                    );
                  }

                  final devices = _buildWindowsDevicePanel(context);

                  if (useTwoColumns) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 400,
                          child: SingleChildScrollView(child: sidebarContent()),
                        ),
                        const Gap(20),
                        Expanded(child: devices),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Flexible(
                        flex: 0,
                        child: SingleChildScrollView(child: sidebarContent()),
                      ),
                      const Gap(14),
                      Expanded(child: devices),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.printer_settings),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(icon: const Icon(Icons.bluetooth), text: loc.bluetooth),
            Tab(icon: const Icon(Icons.usb), text: loc.usb),
            Tab(icon: const Icon(Icons.settings_ethernet), text: loc.ethernet),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefreshPressed,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildMultiplePrinterSettingsCard(context),
                  const SizedBox(height: 12),
                  _buildPaperSizeCard(context),
                  const SizedBox(height: 12),
                  _buildCashDrawerCard(context),
                  const SizedBox(height: 12),
                  _buildConnectionStatusCards(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBluetoothTab(),
                            _buildUsbTab(),
                            _buildEthernetTab(context),
                          ],
                        ),
                      ),
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

  Widget _buildWindowsDevicePanel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _winSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Text(
                  loc.available_printers,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 380,
                  child: SegmentedButton<int>(
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Change radius here
                        ),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.bluetooth_rounded, size: 18),
                        label: Text(loc.bluetooth),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.usb_rounded, size: 18),
                        label: Text(loc.usb),
                      ),
                      ButtonSegment(
                        value: 2,
                        icon: const Icon(
                          Icons.settings_ethernet_rounded,
                          size: 18,
                        ),
                        label: Text(loc.ethernet),
                      ),
                    ],
                    selected: {_tabController.index},
                    onSelectionChanged: (set) {
                      final index = set.first;
                      _tabController.animateTo(index);
                      setState(() {});
                      if (index == 1) {
                        thermalPrinter.scanUsbPrinters();
                      } else if (index == 0) {
                        thermalPrinter.startScan();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBluetoothTab(),
                  _buildUsbTab(),
                  _buildEthernetTab(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsHelpCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _winSectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColor.primary, size: 22),
          const Gap(12),
          Expanded(
            child: Text(
              loc.printer_help_assign_bill_kot,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColor.primary.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _winSectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_winCardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  Widget _sectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColor.primary,
          ),
        ),
        if (subtitle != null) ...[
          const Gap(4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColor.primary.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconBadge(IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (color ?? AppColor.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color ?? AppColor.primary, size: 22),
    );
  }

  Widget _buildConnectionStatusCards(BuildContext context) {
    final gap = _isWindowsDesktop ? const Gap(12) : const SizedBox(height: 12);
    if (_isWindowsDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConnectionStatusCard(
            context,
            link: PrinterScreen2ConnLink.bleThermal,
          ),
          gap,
          _buildConnectionStatusCard(
            context,
            link: PrinterScreen2ConnLink.usbThermal,
          ),
          gap,
          _buildConnectionStatusCard(
            context,
            link: PrinterScreen2ConnLink.ethernet,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConnectionStatusCard(
          context,
          link: PrinterScreen2ConnLink.classicBluetooth,
        ),
        gap,
        _buildConnectionStatusCard(
          context,
          link: PrinterScreen2ConnLink.usbThermal,
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(
    BuildContext context, {
    required PrinterScreen2ConnLink link,
  }) {
    return Obx(() {
      final loc = AppLocalizations.of(context)!;
      final bool connected;
      final String connectionType;
      final String connectionName;
      final IconData statusIcon;
      final VoidCallback? onDisconnect;

      switch (link) {
        case PrinterScreen2ConnLink.bleThermal:
          connected = thermalPrinter.connectedBleDeviceId.value != null;
          connectionType = loc.bluetooth_ble;
          if (!connected) {
            connectionName = loc.no_bluetooth_printer_connected;
            statusIcon = Icons.bluetooth_disabled_rounded;
          } else {
            final platformName = thermalPrinter.connectedDevice?.platformName;
            connectionName =
                (platformName != null && platformName.trim().isNotEmpty)
                ? platformName
                : loc.ble_printer;
            statusIcon = Icons.bluetooth_connected_rounded;
          }
          onDisconnect = connected
              ? () {
                  thermalPrinter.disconnect();
                }
              : null;
          break;
        case PrinterScreen2ConnLink.usbThermal:
          connected = thermalPrinter.isUsbConnected.value;
          connectionType = loc.usb;
          if (!connected) {
            connectionName = loc.no_usb_printer_connected;
            statusIcon = Icons.usb_off_rounded;
          } else {
            connectionName =
                thermalPrinter.connectedUsbPrinter?.name ?? loc.usb_printer;
            statusIcon = Icons.usb_rounded;
          }
          onDisconnect = connected
              ? () {
                  thermalPrinter.disconnectUsbPrinter();
                }
              : null;
          break;
        case PrinterScreen2ConnLink.ethernet:
          connected = thermalPrinter.isNetworkConnected.value;
          connectionType = loc.ethernet_lan;
          if (!connected) {
            connectionName = loc.no_ethernet_printer_connected;
            statusIcon = Icons.portable_wifi_off_rounded;
          } else {
            connectionName =
                thermalPrinter.connectedNetworkLabel.value ??
                loc.connected_status;
            statusIcon = Icons.settings_ethernet_rounded;
          }
          onDisconnect = connected
              ? () {
                  thermalPrinter.disconnectNetworkPrinter();
                }
              : null;
          break;
        case PrinterScreen2ConnLink.classicBluetooth:
          connected = printerService.isConnected.value;
          connectionType = loc.bluetooth_paired;
          if (!connected) {
            connectionName = loc.no_paired_printer_connected;
            statusIcon = Icons.bluetooth_disabled_rounded;
          } else {
            connectionName =
                printerService.selectedPrinter.value?.name ??
                loc.printer_fallback_name;
            statusIcon = Icons.bluetooth_connected_rounded;
          }
          onDisconnect = connected
              ? () {
                  printerService.disconnect();
                }
              : null;
          break;
      }

      final accent = connected ? AppColor.lightgreen : Colors.red.shade400;

      if (_isWindowsDesktop) {
        return _winSectionCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBadge(statusIcon, color: accent),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                connected
                                    ? loc.status_online
                                    : loc.status_offline,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: accent,
                                ),
                              ),
                            ),
                            Text(
                              connectionType,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.primary.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          connectionName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (connected && onDisconnect != null) ...[
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: Text(loc.disconnect),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final statusBg = connected
          ? (isDark ? Colors.green.withOpacity(0.18) : Colors.green.shade100)
          : (isDark ? Colors.red.withOpacity(0.18) : Colors.red.shade100);

      return Card(
        elevation: 0,
        color: statusBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: connected
                ? Colors.green.withOpacity(0.35)
                : Colors.red.withOpacity(0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    connected ? Icons.print : Icons.print_disabled,
                    color: accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connectionType,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connectionName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (connected && onDisconnect != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off, size: 18),
                    label: Text(loc.disconnect),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPaperSizeCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Obx(() {
      final selected = roleController.selectedPaperSize.value;
      final segments = [
        ButtonSegment<ThermalPaperSize>(
          value: ThermalPaperSize.mm58,
          label: Text(loc.paper_size_2inch),
        ),
        ButtonSegment<ThermalPaperSize>(
          value: ThermalPaperSize.mm80,
          label: Text(loc.paper_size_3inch),
        ),
        ButtonSegment<ThermalPaperSize>(
          value: ThermalPaperSize.mm104,
          label: Text(loc.paper_size_4inch),
        ),
      ];

      if (_isWindowsDesktop) {
        return _winSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(loc.paper_size, subtitle: loc.paper_size_subtitle),
              const Gap(12),
              SegmentedButton<ThermalPaperSize>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: AppColor.primary,
                ),
                segments: segments,
                selected: {selected},
                onSelectionChanged: (set) {
                  final size = set.first;
                  if (size != selected) {
                    roleController.setPaperSize(size);
                  }
                },
              ),
            ],
          ),
        );
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.paper_size,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                loc.paper_size_subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThermalPaperSize>(
                segments: segments,
                selected: {selected},
                onSelectionChanged: (set) {
                  final size = set.first;
                  if (size != selected) {
                    roleController.setPaperSize(size);
                  }
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCashDrawerCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appPref = Get.find<AppPref>();
    if (!appPref.cashDrawerEnabled) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final loading = roleController.isRoleActionLoading.value;
      final billConfigured =
          roleController.savedBillPrinterName.value?.isNotEmpty == true;
      final cardChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            loc.cash_drawer,
            subtitle: loc.cash_drawer_printer_help,
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading || !billConfigured
                  ? null
                  : roleController.testOpenCashDrawer,
              icon: const Icon(Icons.point_of_sale_outlined, size: 18),
              label: Text(loc.test_cash_drawer),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (!billConfigured) ...[
            const Gap(8),
            Text(
              loc.cash_drawer_assign_bill_printer_first,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ],
      );

      if (_isWindowsDesktop) {
        return _winSectionCard(
          padding: const EdgeInsets.all(16),
          child: cardChild,
        );
      }

      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(14), child: cardChild),
      );
    });
  }

  Widget _buildMultiplePrinterSettingsCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().selectedOutlet.value;
      }
      final showKot = HomeMainRoutes.outletIsCafeOrRestaurant();
      final loading = roleController.isRoleActionLoading.value;

      final billTile = _buildRolePrinterTile(
        context,
        icon: Icons.receipt_long_outlined,
        title: loc.bill_printer,
        name: roleController.savedBillPrinterName.value,
        connectionType: roleController.savedBillPrinterType.value,
        onTest: () => roleController.testPrintForRole(PrintRole.bill),
        onClear: () => roleController.clearRolePrinter(PrintRole.bill),
      );
      final kotTile = showKot
          ? _buildRolePrinterTile(
              context,
              icon: Icons.restaurant_menu_outlined,
              title: loc.kot_printer,
              name: roleController.savedKotPrinterName.value,
              connectionType: roleController.savedKotPrinterType.value,
              onTest: () => roleController.testPrintForRole(PrintRole.kot),
              onClear: () => roleController.clearRolePrinter(PrintRole.kot),
            )
          : null;

      if (_isWindowsDesktop) {
        return _winSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _sectionHeader(
                      loc.print_routing,
                      subtitle: loc.print_routing_subtitle,
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              const Gap(14),
              billTile,
              if (showKot && kotTile != null) ...[const Gap(10), kotTile],
              if (showKot &&
                  roleController.savedBillPrinterName.value != null &&
                  roleController.savedBillPrinterName.value!.isNotEmpty) ...[
                const Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : roleController.useSamePrinterForKot,
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: Text(loc.use_bill_printer_for_kot),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.primary,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.multiple_printer_settings,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                loc.tap_bill_or_kot_below,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 12),
              billTile,
              if (kotTile != null) ...[
                const SizedBox(height: 10),
                kotTile,
                if (roleController.savedBillPrinterName.value != null &&
                    roleController.savedBillPrinterName.value!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading
                          ? null
                          : roleController.useSamePrinterForKot,
                      child: Text(loc.use_same_as_bill_printer),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRolePrinterTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? name,
    required String? connectionType,
    required VoidCallback onTest,
    required VoidCallback onClear,
  }) {
    final loc = AppLocalizations.of(context)!;
    final configured = name != null && name.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final isKot = title == loc.kot_printer;
    final accent = isKot ? AppColor.secondaryPrimary : AppColor.primary;

    if (_isWindowsDesktop) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: configured
              ? accent.withOpacity(0.06)
              : AppColor.backGroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: configured ? accent.withOpacity(0.28) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBadge(icon, color: accent),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                      if (configured &&
                          connectionType != null &&
                          connectionType.isNotEmpty) ...[
                        const Gap(6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              connectionType,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Gap(6),
                      Text(
                        configured ? name : loc.not_assigned_pick_below,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: configured
                              ? AppColor.primary.withOpacity(0.85)
                              : AppColor.primary.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (configured) ...[
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTest,
                      icon: const Icon(Icons.print_outlined, size: 17),
                      label: Text(loc.test_print),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Tooltip(
                    message: loc.remove_assignment,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onClear,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: configured
            ? colorScheme.primaryContainer.withOpacity(0.35)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: configured
              ? colorScheme.primary.withOpacity(0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  configured
                      ? '$name${connectionType != null ? ' · $connectionType' : ''}'
                      : loc.not_assigned,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (configured) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 22),
              onPressed: onTest,
            ),
            IconButton(
              icon: Icon(Icons.clear, size: 22, color: colorScheme.error),
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleActionChip({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return Material(
      color: selected ? color : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? color : color.withOpacity(0.25),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: _winTileHover,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 14, color: AppColor.white),
                const Gap(4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColor.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileRoleButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? color : color.withOpacity(0.1),
        foregroundColor: selected ? AppColor.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? color : color.withOpacity(0.35)),
        ),
      ),
      child: Text(
        selected ? '$label ✓' : label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAssignRoleButtons({
    required BuildContext context,
    required VoidCallback onBill,
    required VoidCallback onKot,
    bool billSelected = false,
    bool kotSelected = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().selectedOutlet.value;
    }
    final showKot = HomeMainRoutes.outletIsCafeOrRestaurant();

    if (_isWindowsDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleActionChip(
            label: loc.bill_label,
            color: AppColor.primary,
            onPressed: onBill,
            selected: billSelected,
          ),
          if (showKot) ...[
            const Gap(6),
            _roleActionChip(
              label: loc.kot_label,
              color: AppColor.secondaryPrimary,
              onPressed: onKot,
              selected: kotSelected,
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mobileRoleButton(
          label: loc.bill_label,
          color: AppColor.primary,
          onPressed: onBill,
          selected: billSelected,
        ),
        if (showKot) ...[
          const Gap(4),
          _mobileRoleButton(
            label: loc.kot_label,
            color: AppColor.secondaryPrimary,
            onPressed: onKot,
            selected: kotSelected,
          ),
        ],
      ],
    );
  }

  Widget _buildAssignRoleButtonsForBle(
    BuildContext context,
    BluetoothDevice device,
  ) {
    return Obx(() {
      roleController.billRoleInfo.value;
      roleController.kotRoleInfo.value;
      return _buildAssignRoleButtons(
        context: context,
        onBill: () =>
            roleController.assignBluetoothToRole(PrintRole.bill, device),
        onKot: () =>
            roleController.assignBluetoothToRole(PrintRole.kot, device),
        billSelected: roleController.isBillBleDevice(device),
        kotSelected: roleController.isKotBleDevice(device),
      );
    });
  }

  Widget _buildAssignRoleButtonsForUsb(BuildContext context, Printer printer) {
    return Obx(() {
      roleController.billRoleInfo.value;
      roleController.kotRoleInfo.value;
      return _buildAssignRoleButtons(
        context: context,
        onBill: () => roleController.assignUsbToRole(PrintRole.bill, printer),
        onKot: () => roleController.assignUsbToRole(PrintRole.kot, printer),
        billSelected: roleController.isBillUsbPrinter(printer),
        kotSelected: roleController.isKotUsbPrinter(printer),
      );
    });
  }

  Widget _buildAssignRoleButtonsForClassicBt({
    required BuildContext context,
    required String address,
    required String name,
  }) {
    return Obx(() {
      roleController.billRoleInfo.value;
      roleController.kotRoleInfo.value;
      return _buildAssignRoleButtons(
        context: context,
        onBill: () => roleController.assignClassicBluetoothToRole(
          PrintRole.bill,
          address: address,
          name: name,
        ),
        onKot: () => roleController.assignClassicBluetoothToRole(
          PrintRole.kot,
          address: address,
          name: name,
        ),
        billSelected: roleController.isBillClassicBt(address),
        kotSelected: roleController.isKotClassicBt(address),
      );
    });
  }

  Widget _buildWindowsDeviceRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget actions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: _winTileHover,
          mouseCursor: SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _iconBadge(icon, color: iconColor),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColor.primary.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinSearchField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onClear,
    required bool showClear,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColor.backGroundColor,
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: showClear
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildBluetoothTab() {
    final loc = AppLocalizations.of(context)!;
    if (Platform.isWindows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildWinSearchField(
                  controller: _bleSearchController,
                  hint: loc.search_bluetooth_devices_hint,
                  showClear: _bleSearchQuery.isNotEmpty,
                  onClear: () {
                    _bleSearchController.clear();
                    setState(() => _bleSearchQuery = '');
                  },
                  onChanged: (v) => setState(() => _bleSearchQuery = v),
                ),
              ),
              const Gap(12),
              FilledButton.icon(
                onPressed: () => thermalPrinter.startScan(),
                icon: const Icon(Icons.radar_rounded, size: 20),
                label: Text(loc.scan),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          Expanded(
            child: Obx(() {
              if (thermalPrinter.isScanning.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const Gap(16),
                      Text(
                        loc.scanning_nearby_printers,
                        style: TextStyle(
                          color: AppColor.primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final results = thermalPrinter.scanResults
                  .where((r) => r.device.platformName.trim().isNotEmpty)
                  .toList();
              final query = _bleSearchQuery.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? results
                  : results.where((r) {
                      final device = r.device;
                      final name = device.platformName;
                      final remoteId = device.remoteId.toString();
                      return name.toLowerCase().contains(query) ||
                          remoteId.toLowerCase().contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.bluetooth_disabled_rounded,
                  message: query.isEmpty
                      ? loc.no_bluetooth_printers_found
                      : loc.no_devices_match_search,
                );
              }

              return Scrollbar(
                controller: _bleListScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _bleListScrollController,
                  primary: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final device = filtered[index].device;
                    final name = device.platformName;
                    return _buildWindowsDeviceRow(
                      icon: Icons.bluetooth_rounded,
                      iconColor: AppColor.primary,
                      title: name,
                      subtitle: device.remoteId.toString(),
                      actions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAssignRoleButtonsForBle(context, device),
                          const Gap(8),
                          Obx(() {
                            final deviceId = device.remoteId.toString();
                            final isThisConnected =
                                thermalPrinter.connectedBleDeviceId.value ==
                                deviceId;
                            final isConnectingThis =
                                thermalPrinter.isBleConnecting.value &&
                                thermalPrinter.connectingBleDeviceId.value ==
                                    deviceId;
                            return SizedBox(
                              width: 108,
                              child: _connectDisconnectButton(
                                context: context,
                                isConnected: isThisConnected,
                                isLoading: isConnectingThis,
                                onPressed: isConnectingThis
                                    ? null
                                    : () async {
                                        if (isThisConnected) {
                                          await thermalPrinter.disconnect();
                                        } else {
                                          await thermalPrinter.connectToDevice(
                                            device,
                                          );
                                        }
                                      },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.bluetooth),
              const SizedBox(width: 8),
              Text(
                loc.paired_bluetooth_devices,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            final devices = printerService.availableDevices;
            if (printerService.isScanning.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (devices.isEmpty) {
              return Center(child: Text(loc.no_paired_devices_found));
            }

            return Scrollbar(
              controller: _classicBtScrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _classicBtScrollController,
                primary: false,
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = devices[index];

                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      device.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Obx(() {
                      final isThisDeviceConnected =
                          printerService.isConnected.value &&
                          printerService.selectedPrinter.value?.address ==
                              device.address;

                      return SizedBox(
                        width: 240,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildAssignRoleButtonsForClassicBt(
                              context: context,
                              address: device.address,
                              name: device.name,
                            ),
                            SizedBox(
                              width: 100,
                              child: _connectDisconnectButton(
                                context: context,
                                isConnected: isThisDeviceConnected,
                                onPressed: () async {
                                  if (isThisDeviceConnected) {
                                    await printerService.disconnect();
                                  } else {
                                    await printerService.connect(device);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: Text(loc.scan_devices),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                printerService.scanForDevices();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsbTab() {
    final loc = AppLocalizations.of(context)!;
    if (_isWindowsDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildWinSearchField(
                  controller: _usbSearchController,
                  hint: loc.search_usb_printers_hint,
                  showClear: _usbSearchQuery.isNotEmpty,
                  onClear: () {
                    _usbSearchController.clear();
                    setState(() => _usbSearchQuery = '');
                  },
                  onChanged: (v) => setState(() => _usbSearchQuery = v),
                ),
              ),
              const Gap(12),
              Obx(() {
                final isScanning = thermalPrinter.isUsbScanning.value;
                return FilledButton.icon(
                  onPressed: isScanning
                      ? null
                      : () => thermalPrinter.scanUsbPrinters(),
                  icon: isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.usb_rounded, size: 20),
                  label: Text(isScanning ? loc.scanning : loc.scan),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ],
          ),
          const Gap(14),
          Expanded(
            child: Obx(() {
              final list = thermalPrinter.usbPrinters;
              final query = _usbSearchQuery.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? list
                  : list.where((p) {
                      final name = (p.name ?? '').toLowerCase();
                      final vendor = p.vendorId?.toString().toLowerCase() ?? '';
                      final product =
                          p.productId?.toString().toLowerCase() ?? '';
                      return name.contains(query) ||
                          vendor.contains(query) ||
                          product.contains(query);
                    }).toList();

              if (thermalPrinter.isUsbScanning.value && filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const Gap(16),
                      Text(
                        loc.looking_for_usb_printers,
                        style: TextStyle(
                          color: AppColor.primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filtered.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.usb_off_rounded,
                  message: query.isEmpty
                      ? loc.no_usb_printers_found
                      : loc.no_usb_printers_match_search,
                );
              }

              return Scrollbar(
                controller: _usbListScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _usbListScrollController,
                  primary: false,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final printer = filtered[index];
                    final printerKey = ThermalPrinterService.usbPrinterKey(
                      printer,
                    );
                    final ids = [
                      if (printer.vendorId != null) 'V:${printer.vendorId}',
                      if (printer.productId != null) 'P:${printer.productId}',
                    ].join(' · ');

                    return _buildWindowsDeviceRow(
                      icon: Icons.usb_rounded,
                      iconColor: AppColor.secondaryPrimary,
                      title: printer.name ?? loc.usb_printer,
                      subtitle: ids.isNotEmpty ? ids : (printer.address ?? ''),
                      actions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAssignRoleButtonsForUsb(context, printer),
                          const Gap(8),
                          Obx(() {
                            final isConnected =
                                thermalPrinter.connectedUsbPrinterKey.value ==
                                printerKey;
                            return SizedBox(
                              width: 108,
                              child: _connectDisconnectButton(
                                context: context,
                                isConnected: isConnected,
                                onPressed: () async {
                                  if (isConnected) {
                                    await thermalPrinter.disconnectUsbPrinter();
                                  } else {
                                    await thermalPrinter.connectUsbPrinter(
                                      printer,
                                    );
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      );
    }

    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            loc.usb_printers,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _usbSearchController,
            decoration: InputDecoration(
              hintText: loc.search_printers_hint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _usbSearchQuery = v),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final isScanning = thermalPrinter.isUsbScanning.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.usb),
              label: Text(
                isScanning ? loc.scanning_ellipsis : loc.scan_usb_printers,
              ),
              onPressed: isScanning ? null : thermalPrinter.scanUsbPrinters,
            ),
          );
        }),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            final list = thermalPrinter.usbPrinters;
            final query = _usbSearchQuery.trim().toLowerCase();
            final filtered = query.isEmpty
                ? list
                : list.where((p) {
                    final name = (p.name ?? '').toLowerCase();
                    return name.contains(query);
                  }).toList();
            if (filtered.isEmpty) {
              return Center(child: Text(loc.no_usb_printers_found));
            }
            return ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final printer = filtered[index];
                final printerKey = ThermalPrinterService.usbPrinterKey(printer);
                return ListTile(
                  leading: const Icon(Icons.usb),
                  title: Text(printer.name ?? loc.usb_printer),
                  trailing: SizedBox(
                    width: 220,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildAssignRoleButtonsForUsb(context, printer),
                        Obx(() {
                          final isConnected =
                              thermalPrinter.connectedUsbPrinterKey.value ==
                              printerKey;
                          return SizedBox(
                            width: 100,
                            child: _connectDisconnectButton(
                              context: context,
                              isConnected: isConnected,
                              onPressed: () async {
                                if (isConnected) {
                                  await thermalPrinter.disconnectUsbPrinter();
                                } else {
                                  await thermalPrinter.connectUsbPrinter(
                                    printer,
                                  );
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEthernetTab(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final padding = _isWindowsDesktop ? 20.0 : 16.0;

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        Text(
          loc.printer_ip_network_hint,
          style: TextStyle(
            fontSize: _isWindowsDesktop ? 13 : 12,
            color: AppColor.primary.withOpacity(0.65),
            height: 1.4,
          ),
        ),
        const Gap(14),
        TextField(
          controller: roleController.ipController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.ip_address,
            hintText: '192.168.1.100',
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.router_outlined, size: 20),
          ),
        ),
        const Gap(10),
        TextField(
          controller: roleController.portController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: loc.port_label,
            hintText: '9100',
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.numbers, size: 20),
          ),
        ),
        const Gap(14),
        Obx(() {
          final connecting = thermalPrinter.isNetworkConnecting.value;
          final connected = thermalPrinter.isNetworkConnected.value;
          final btnWidth = _isWindowsDesktop ? 132.0 : 120.0;
          final btnHeight = _isWindowsDesktop ? 40.0 : 38.0;
          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: btnWidth,
              height: btnHeight,
              child: FilledButton(
                onPressed:
                    connecting || roleController.isRoleActionLoading.value
                    ? null
                    : roleController.connectEthernet,
                style: FilledButton.styleFrom(
                  backgroundColor: connected
                      ? Colors.red.shade400
                      : AppColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size(btnWidth, btnHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        connected ? loc.disconnect : loc.connect,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          );
        }),
        const Gap(18),
        Obx(() {
          roleController.networkFormTick.value;
          roleController.billRoleInfo.value;
          roleController.kotRoleInfo.value;
          final ip = roleController.ipController.text.trim();
          final port =
              int.tryParse(roleController.portController.text.trim()) ?? 9100;
          return _winSectionCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ip.isEmpty ? loc.enter_ip_above : '$ip:$port',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: _isWindowsDesktop ? 15 : 14,
                    color: AppColor.primary,
                  ),
                ),
                const Gap(10),
                _buildAssignRoleButtons(
                  context: context,
                  onBill: () =>
                      roleController.assignNetworkToRole(PrintRole.bill),
                  onKot: () =>
                      roleController.assignNetworkToRole(PrintRole.kot),
                  billSelected: roleController.isBillNetworkPrinter(ip, port),
                  kotSelected: roleController.isKotNetworkPrinter(ip, port),
                ),
              ],
            ),
          );
        }),
        if (!_isWindowsDesktop) ...[
          const Gap(12),
          Obx(() {
            final connected = thermalPrinter.isNetworkConnected.value;
            return Text(
              connected
                  ? loc.connected_to_label(
                      thermalPrinter.connectedNetworkLabel.value ?? '',
                    )
                  : loc.not_connected,
              style: TextStyle(
                fontSize: 12,
                color: connected ? AppColor.lightgreen : scheme.error,
              ),
            );
          }),
        ],
      ],
    );
  }
}

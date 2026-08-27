import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/download/download_notification_service.dart';
import 'package:billkaro/app/services/download/file_download_service.dart';
import 'package:billkaro/app/utils/pos_cart_line.dart';
import 'package:billkaro/config/config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:billkaro/utils/date_util.dart';
import 'package:intl/intl.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';

class ItemReportsController extends BaseController {
  // Connectivity listener
  StreamSubscription<bool>? _connectivitySubscription;
  bool _lastConnectivityState = false;
  bool _hasLoadedFromApi = false;
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final RxList<String> selectedCustomers = <String>[].obs;
  final RxBool isLoading = true.obs;

  // All orders from API
  final RxList<OrderModel> allOrders = <OrderModel>[].obs;

  // Filtered orders (displayed in UI)
  final RxList<OrderModel> ordersL = <OrderModel>[].obs;
  final RxList<OrderItem> itemsList = <OrderItem>[].obs;

  // Items filtered by category
  final RxList<OrderItem> filteredItemsList = <OrderItem>[].obs;

  // Categories from API
  final RxList<CategoryData> categories = <CategoryData>[].obs;

  List<String> ordersList = [
    'All',
    'Delivery',
    'Dine In',
    'Swiggy',
    'Takeaway',
    'Zomato',
  ];

  List<String> paymentList = ['All', 'Cash', 'UPI', 'PhonePe', 'GooglePay'];

  List<String> timePeriods = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom',
  ];

  RxString selectedTimePeriod = 'Today'.obs;
  RxString selectedPaymentType = 'All'.obs;
  RxString selectedOrderType = 'All'.obs;
  RxString selectedCategory = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    // Set default date range to Today so first API call and filters match the period dropdown
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// 🕒 Filter by Time Period
  Future<void> filterByTimePeriod() async {
    DateTime now = DateTime.now();
    DateTimeRange? range;

    switch (selectedTimePeriod.value) {
      case 'Today':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;

      case 'This Week':
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;

      case 'This Month':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;

      case 'This Quarter':
        int currentQuarter = ((now.month - 1) ~/ 3) + 1;
        int startMonth = (currentQuarter - 1) * 3 + 1;
        DateTime startOfQuarter = DateTime(now.year, startMonth, 1);
        range = DateTimeRange(
          start: startOfQuarter,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;

      case 'This Year':
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        break;
    }

    if (range != null) {
      selectedDateRange.value = range;
      await getItemsList(
        forceApiRefresh: true,
      ); // Refetch with startDate/endDate
    }
  }

  Future<void> selectCustomDateRange() async {
    final picked = await showAppDateRangePickerFromGet(
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange.value,
    );

    if (picked != null) {
      selectedDateRange.value = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      );
      selectedTimePeriod.value = 'Custom';
      await getItemsList(
        forceApiRefresh: true,
      ); // Refetch with startDate/endDate
    }
  }

  String get formattedDateRange {
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedDateRange.value == null) return loc.select_date;
    final start = selectedDateRange.value!.start;
    final end = selectedDateRange.value!.end;
    return '${_formatDate(start)} TO ${_formatDate(end)}';
  }

  /// Get localized time periods list
  List<String> getLocalizedTimePeriods(AppLocalizations loc) {
    return [
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
      'Custom',
    ];
  }

  /// Get localized label for time period
  String getLocalizedTimePeriodLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'Today':
        return loc.today;
      case 'This Week':
        return loc.this_week;
      case 'This Month':
        return loc.this_month;
      case 'This Quarter':
        return loc.this_quarter;
      case 'This Year':
        return loc.this_year;
      case 'Custom':
        return loc.custom;
      default:
        return value;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day/$month/$year';
  }

  void filterByCustomers() {
    // TODO: Implement customer selection dialog
    final loc = AppLocalizations.of(Get.context!)!;
    showError(description: loc.customer_filter_coming_soon);
  }

  /// Apply all active filters
  void applyAllFilters() {
    List<OrderModel> filtered = List.from(allOrders);

    // Filter by date range (IST calendar days vs UTC order timestamps)
    if (selectedDateRange.value != null) {
      final start = selectedDateRange.value!.start;
      final end = selectedDateRange.value!.end;

      filtered = filtered.where((order) {
        return isOrderCreatedAtInIstRange(
          order.createdAt.toString(),
          start,
          end,
        );
      }).toList();
    }

    // Filter by customers
    if (selectedCustomers.isNotEmpty) {
      filtered = filtered.where((order) {
        return selectedCustomers.contains(order.customerName) ||
            selectedCustomers.contains(order.userId);
      }).toList();
    }

    // Filter by order type
    if (selectedOrderType.value != 'All') {
      filtered = filtered.where((order) {
        return order.orderFrom.toLowerCase() ==
            selectedOrderType.value.toLowerCase();
      }).toList();
    }

    // Filter by payment type
    if (selectedPaymentType.value != 'All') {
      filtered = filtered.where((order) {
        return order.paymentReceivedIn?.toLowerCase() ==
            selectedPaymentType.value.toLowerCase();
      }).toList();
    }

    // Update filtered orders and extract items
    ordersL.value = filtered;
    itemsList.value = ordersL.expand((order) => order.items).toList();

    // Apply category filter
    applyCategoryFilter();
  }

  /// Available categories from API
  List<String> get availableCategories {
    final categoryNames =
        categories
            .map((c) => c.categoryName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categoryNames];
  }

  /// Fetch categories (online API + SQLite fallback)
  Future<void> getCategories() async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return;

      final loaded = await OfflineCategoryLoader.load(
        outletId: outletId,
        fetchFromApi: () =>
            callApi(apiClient.getCategories(outletId), showLoader: false),
      );
      categories.value = loaded;
      dismissAllAppLoader();
    } catch (e, st) {
      debugPrint('getCategories error: $e\n$st');
    }
  }

  /// Apply category filter on items
  void applyCategoryFilter() {
    final cat = selectedCategory.value.trim();
    if (cat.isEmpty || cat == 'All' || cat.toLowerCase() == 'none') {
      filteredItemsList.value = List<OrderItem>.from(itemsList);
      return;
    }

    // Match by categoryName from API categories
    filteredItemsList.value = itemsList.where((item) {
      final itemCategory = (item.category ?? '').trim();
      return itemCategory.toLowerCase() == cat.toLowerCase();
    }).toList();
  }

  /// Computed properties for summary
  int get totalItems => filteredItemsList.length;

  double get totalAmount => filteredItemsList.fold(
    0.0,
    (sum, item) => sum + ((item.quantity ?? 0) * (item.salePrice ?? 0)),
  );

  /// Parse order date from various formats
  DateTime? _parseOrderDate(dynamic dateValue) {
    try {
      if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        // If it's a timestamp
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error parsing date: $e');
      return null;
    }
  }

  // Refresh Data
  Future<void> refreshData() async {
    await getItemsList(forceApiRefresh: true);
  }

  /// Get items list from API or SQLite
  Future<void> getItemsList({bool forceApiRefresh = false}) async {
    isLoading.value = true;

    try {
      await getCategories();

      final db = AppDatabase();
      final outletId = appPref.selectedOutlet!.id!;
      final userId = appPref.ordersApiUserId;
      if (userId == null || userId.isEmpty) {
        showError(description: 'User or outlet information is missing.');
        return;
      }
      final isOnline = await NetworkUtils.hasInternetConnection();
      debugPrint('🔄 isOnline: $isOnline');

      /// Always load local orders first
      final localOrders = await db.getAllOrders(outletId: outletId);
      allOrders.value = localOrders.where((e) => e.status == 'closed').toList();

      if (isOnline && (!_hasLoadedFromApi || forceApiRefresh)) {
        final range = selectedDateRange.value;
        final startDateStr = range != null
            ? DateFormat('yyyy-MM-dd').format(range.start)
            : null;
        final endDateStr = range != null
            ? DateFormat('yyyy-MM-dd').format(range.end)
            : null;

        final response = await callApi(
          apiClient.getOrders(
            userId,
            outletId,
            null,
            null,
            null,
            null,
            startDateStr,
            endDateStr,
          ),
          showLoader: false,
        );

        if (response != null) {
          allOrders.value = response.data
              .where((e) => e.status == 'closed')
              .toList();
          await db.insertOrders(allOrders, outletId, isSyncedFromApi: true);
          _hasLoadedFromApi = true;
        }
      } else if (!isOnline) {
        _hasLoadedFromApi = false;
      }

      debugPrint(' ✅ Loaded ${allOrders.length} closed orders');
      applyAllFilters();
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.failed_to_load_orders);
      allOrders.value = [];
      ordersL.value = [];
      itemsList.value = [];
      filteredItemsList.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all filters
  void resetFilters() {
    selectedTimePeriod.value = 'Today';
    selectedCustomers.clear();
    selectedOrderType.value = 'All';
    selectedPaymentType.value = 'All';
    filterByTimePeriod();
  }

  /// Format date range for export header (null = All / Select date)
  String formatExportDateRange(DateTimeRange? range, AppLocalizations loc) {
    if (range == null) return loc.all;
    return '${_formatDate(range.start)} TO ${_formatDate(range.end)}';
  }

  String _exportFileSlug(DateTimeRange? range) {
    if (range == null) return 'all';
    final fmt = DateFormat('yyyy-MM-dd');
    return '${fmt.format(range.start)}_to_${fmt.format(range.end)}';
  }

  /// Fetch orders for export — uses API when online, local SQLite when offline.
  Future<List<OrderItem>> fetchItemsForExport(DateTimeRange range) async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.ordersApiUserId;
    if (outletId == null || userId == null || userId.isEmpty) return [];

    final isOnline = await NetworkUtils.hasInternetConnection();
    List<OrderModel> orders;

    if (isOnline) {
      final startDateStr = DateFormat('yyyy-MM-dd').format(range.start);
      final endDateStr = DateFormat('yyyy-MM-dd').format(range.end);
      final paymentParam = selectedPaymentType.value == 'All'
          ? null
          : selectedPaymentType.value.toLowerCase();
      const exportLimit = 500;

      final response = await callApi(
        apiClient.getOrders(
          userId,
          outletId,
          1,
          exportLimit,
          null,
          paymentParam,
          startDateStr,
          endDateStr,
        ),
        showLoader: false,
      );

      if (response?.status != 'success' || response!.data.isEmpty) {
        return [];
      }
      orders = response.data.where((e) => e.status == 'closed').toList();
    } else {
      final localOrders = await AppDatabase().getAllOrders(outletId: outletId);
      orders = localOrders.where((e) => e.status == 'closed').toList();
      orders = orders.where((order) {
        return isOrderCreatedAtInIstRange(
          order.createdAt.toString(),
          range.start,
          range.end,
        );
      }).toList();
    }

    if (selectedOrderType.value != 'All') {
      orders = orders
          .where(
            (o) =>
                o.orderFrom.toLowerCase() ==
                selectedOrderType.value.toLowerCase(),
          )
          .toList();
    }
    if (selectedPaymentType.value != 'All') {
      orders = orders
          .where(
            (o) =>
                o.paymentReceivedIn?.toLowerCase() ==
                selectedPaymentType.value.toLowerCase(),
          )
          .toList();
    }
    return orders.expand((o) => o.items).toList();
  }

  /// Show date range dialog then export to Excel or PDF. [isExcel] true = Excel, false = PDF.
  Future<void> showExportDateRangeDialogAndExport(bool isExcel) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final isWindows = Theme.of(Get.context!).platform == TargetPlatform.windows;
    final actionLabel = isExcel ? 'Excel' : 'PDF';

    final useCurrent = await Get.dialog<bool>(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(
              isExcel ? Icons.table_view_rounded : Icons.picture_as_pdf_rounded,
              color: AppColor.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${loc.item_reports} ($actionLabel)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isWindows ? 460 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${loc.period}: ${formatExportDateRange(selectedDateRange.value, loc)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use current filter or choose a custom date range for export.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          if (isWindows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(loc.cancel),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Get.back(result: true),
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Use current filter'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      Get.back(result: false);
                      final picked = await showAppDateRangePickerFromGet(
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: selectedDateRange.value,
                      );
                      if (picked == null) return;
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      final items = await fetchItemsForExport(picked);
                      if (Get.isDialogOpen ?? false) Get.back();
                      if (items.isEmpty) {
                        showError(description: loc.no_items_to_export);
                        return;
                      }
                      if (isExcel) {
                        await _exportToExcelWithItems(items, picked);
                      } else {
                        await _exportToPdfWithItems(items, picked);
                      }
                    },
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: const Text('Choose date range'),
                  ),
                ],
              ),
            )
          else ...[
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Use current filter'),
            ),
            FilledButton(
              onPressed: () async {
                Get.back(result: false);
                final picked = await showAppDateRangePickerFromGet(
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: selectedDateRange.value,
                );
                if (picked == null) return;
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                final items = await fetchItemsForExport(picked);
                if (Get.isDialogOpen ?? false) Get.back();
                if (items.isEmpty) {
                  showError(description: loc.no_items_to_export);
                  return;
                }
                if (isExcel) {
                  await _exportToExcelWithItems(items, picked);
                } else {
                  await _exportToPdfWithItems(items, picked);
                }
              },
              child: const Text('Choose date range'),
            ),
          ],
        ],
      ),
    );

    if (useCurrent == true) {
      if (itemsList.isEmpty) {
        showError(description: loc.no_items_to_export);
        return;
      }
      if (isExcel) {
        await _exportToExcelWithItems(itemsList, selectedDateRange.value);
      } else {
        await _exportToPdfWithItems(itemsList, selectedDateRange.value);
      }
    }
  }

  /// Export to PDF (entry point – shows date range dialog first)
  void exportToPDF() {
    exportToPdf();
  }

  /// 📤 Export to Excel. Entry point shows date range dialog first.
  Future<void> exportToExcel() async {
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    await showExportDateRangeDialogAndExport(true);
  }

  /// Internal: export given items to Excel with optional date range for header.
  Future<void> _exportToExcelWithItems(
    List<OrderItem> itemsToExport,
    DateTimeRange? exportDateRange,
  ) async {
    const notificationId =
        DownloadNotificationService.itemExcelDownloadNotificationId;
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      if (itemsToExport.isEmpty) {
        showError(description: loc.no_items_to_export);
        return;
      }
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt < 33) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            await Permission.storage.request();
          }
        }
      }

      await DownloadNotificationService.instance.notifyProgress(
        notificationId: notificationId,
        title: 'Excel downloading',
        body: 'Preparing item report…',
      );

      final exportRangeLabel = formatExportDateRange(exportDateRange, loc);

      Map<String, Map<String, dynamic>> groupedItems = {};
      for (var item in itemsToExport) {
        final groupKey = PosCartLine.reportGroupKey(
          itemName: item.itemName ?? 'Unknown Item',
          variantName: item.variantName,
          variantId: item.variantId,
        );
        if (groupedItems.containsKey(groupKey)) {
          groupedItems[groupKey]!['quantity'] += item.quantity ?? 0;
          groupedItems[groupKey]!['totalAmount'] +=
              (item.quantity ?? 0) * (item.salePrice ?? 0);
        } else {
          groupedItems[groupKey] = {
            'quantity': item.quantity ?? 0,
            'totalAmount': (item.quantity ?? 0) * (item.salePrice ?? 0),
          };
        }
      }

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = loc.item_reports;

      final Style headerStyle = workbook.styles.add('header');
      headerStyle.bold = true;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;

      sheet.getRangeByName('A1:C1').merge();
      sheet.getRangeByName('A1').setText(loc.item_reports);
      sheet.getRangeByName('A1').cellStyle
        ..bold = true
        ..fontSize = 16
        ..hAlign = HAlignType.center;

      sheet.getRangeByName('A2:C2').merge();
      sheet
          .getRangeByName('A2')
          .setText(
            '${loc.period}: $exportRangeLabel | ${loc.order_type}: ${getLocalizedOrderLabel(selectedOrderType.value, loc)} | ${loc.payment_type}: ${getLocalizedPaymentLabel(selectedPaymentType.value, loc)}',
          );
      sheet.getRangeByName('A2').cellStyle.italic = true;

      final headers = [
        loc.item_name,
        loc.order_quantity,
        '${loc.order_amount} (₹)',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(4, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle = headerStyle;
      }

      int rowIndex = 5;
      double totalQuantity = 0;
      double totalAmount = 0;
      groupedItems.forEach((itemName, itemData) {
        sheet.getRangeByIndex(rowIndex, 1).setText(itemName);
        sheet
            .getRangeByIndex(rowIndex, 2)
            .setNumber(itemData['quantity'].toDouble());
        sheet.getRangeByIndex(rowIndex, 3).setNumber(itemData['totalAmount']);
        sheet.getRangeByIndex(rowIndex, 3).numberFormat = "₹#,##0.00";
        totalQuantity += itemData['quantity'];
        totalAmount += itemData['totalAmount'];
        if ((rowIndex - 5) % 2 == 1) {
          sheet.getRangeByIndex(rowIndex, 1, rowIndex, 3).cellStyle.backColor =
              "#F2F2F2";
        }
        rowIndex++;
      });

      final summaryRow = rowIndex + 1;
      sheet.getRangeByIndex(summaryRow, 1).setText("${loc.total_items}:");
      sheet.getRangeByIndex(summaryRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(summaryRow, 2).setNumber(totalQuantity);
      sheet.getRangeByIndex(summaryRow, 2).cellStyle.bold = true;
      sheet.getRangeByIndex(summaryRow, 3).setNumber(totalAmount);
      sheet.getRangeByIndex(summaryRow, 3).numberFormat = "₹#,##0.00";
      sheet.getRangeByIndex(summaryRow, 3).cellStyle
        ..bold = true
        ..backColor = "#FFEB9C";

      for (int i = 1; i <= 3; i++) sheet.autoFitColumn(i);
      sheet.getRangeByIndex(4, 1, summaryRow, 3).cellStyle.borders.all
        ..lineStyle = LineStyle.thin
        ..color = '#D3D3D3';

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final rangeSlug = _exportFileSlug(exportDateRange);
      final fileName = 'item-report-$rangeSlug.xlsx';
      final file = await FileDownloadService.instance.saveBytes(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        preferredDirectory: appPref.downloadPath,
        notificationId: notificationId,
        notificationTitle: 'Item report downloaded',
        notificationBody: '$fileName saved to Downloads',
      );

      if (file == null) {
        await DownloadNotificationService.instance.notifyFailed(
          notificationId: notificationId,
          title: 'Download failed',
          body: loc.failed_to_export,
        );
        showError(description: loc.failed_to_export);
      }
    } catch (e) {
      await DownloadNotificationService.instance.notifyFailed(
        notificationId: notificationId,
        title: 'Download failed',
        body: 'Failed to export Excel',
      );
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_export}: $e');
      debugPrint("❌ EXPORT ERROR: $e");
    }
  }

  String getLocalizedOrderLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Delivery':
        return loc.delivery;
      case 'Dine In':
        return loc.dine_in;
      case 'Swiggy':
        return loc.swiggy;
      case 'Takeaway':
        return loc.takeaway;
      case 'Zomato':
        return loc.zomato;
      default:
        return value;
    }
  }

  String getLocalizedPaymentLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'All':
        return loc.all;
      case 'Cash':
        return loc.cash;
      case 'UPI':
        return loc.upi;
      case 'PhonePe':
        return loc.phonepe;
      case 'GooglePay':
        return loc.googlepay;
      default:
        return value;
    }
  }

  /// Export to PDF. Entry point shows date range dialog first.
  Future<void> exportToPdf() async {
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    await showExportDateRangeDialogAndExport(false);
  }

  /// Internal: export given items to PDF with optional date range for header.
  Future<void> _exportToPdfWithItems(
    List<OrderItem> itemsToExport,
    DateTimeRange? exportDateRange,
  ) async {
    const notificationId =
        DownloadNotificationService.itemPdfDownloadNotificationId;
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      if (itemsToExport.isEmpty) {
        showError(description: loc.no_items_to_export);
        return;
      }

      final exportRangeLabel = formatExportDateRange(exportDateRange, loc);

      await DownloadNotificationService.instance.notifyProgress(
        notificationId: notificationId,
        title: 'PDF downloading',
        body: 'Preparing item report…',
      );

      Map<String, Map<String, dynamic>> groupedItems = {};
      double totalQuantity = 0;
      double totalAmount = 0;
      for (var item in itemsToExport) {
        final groupKey = PosCartLine.reportGroupKey(
          itemName: item.itemName ?? 'Unknown Item',
          variantName: item.variantName,
          variantId: item.variantId,
        );
        if (groupedItems.containsKey(groupKey)) {
          groupedItems[groupKey]!['quantity'] += item.quantity ?? 0;
          groupedItems[groupKey]!['totalAmount'] +=
              (item.quantity ?? 0) * (item.salePrice ?? 0);
        } else {
          groupedItems[groupKey] = {
            'quantity': item.quantity ?? 0,
            'totalAmount': (item.quantity ?? 0) * (item.salePrice ?? 0),
          };
        }
      }
      groupedItems.forEach((_, value) {
        totalQuantity += value['quantity'];
        totalAmount += value['totalAmount'];
      });

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          loc.item_reports,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildDottedLine(),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${loc.date}: ${formatDate(DateTime.now().toString())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '${loc.period}: $exportRangeLabel',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (selectedOrderType.value != 'All') ...[
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '${loc.order_type}: ${getLocalizedOrderLabel(selectedOrderType.value, loc)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                      if (selectedPaymentType.value != 'All') ...[
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '${loc.payment_type}: ${getLocalizedPaymentLabel(selectedPaymentType.value, loc)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  _buildDottedLine(),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            loc.item_name,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            loc.quantity,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            loc.amount_rupee,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...groupedItems.entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              entry.key,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '${entry.value['quantity']}',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '₹${entry.value['totalAmount'].toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 15),
                  _buildDottedLine(),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            loc.total,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${totalQuantity.toInt()}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        _buildDottedLine(),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          loc.item_reports_generated(
                            formatDate(DateTime.now().toString()),
                          ),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Download only — no options dialog, open, or share
      final bytes = await pdf.save();
      final rangeSlug = _exportFileSlug(exportDateRange);
      final fileName = 'item-report-$rangeSlug.pdf';

      final file = await FileDownloadService.instance.saveBytes(
        bytes: bytes,
        fileName: fileName,
        preferredDirectory: appPref.downloadPath,
        notificationId: notificationId,
        notificationTitle: 'Item report downloaded',
        notificationBody: '$fileName saved to Downloads',
      );

      if (file == null) {
        await DownloadNotificationService.instance.notifyFailed(
          notificationId: notificationId,
          title: 'Download failed',
          body: loc.failed_to_save_pdf,
        );
        showError(description: loc.failed_to_save_pdf);
      }
    } catch (e) {
      await DownloadNotificationService.instance.notifyFailed(
        notificationId: notificationId,
        title: 'Download failed',
        body: 'Failed to export PDF',
      );
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: '${loc.failed_to_generate_pdf}: $e');
      debugPrint('❌ PDF Generation Error: $e');
    }
  }

  pw.Widget _buildDottedLine() {
    return pw.Container(
      height: 1,
      child: pw.LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 4.0;
          final dashSpace = 3.0;
          final dashCount = (constraints!.maxWidth / (dashWidth + dashSpace))
              .floor();

          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return pw.Container(
                width: dashWidth,
                height: 1,
                color: PdfColors.grey400,
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void onReady() {
    getItemsList();

    // Listen to connectivity changes
    _connectivitySubscription = ConnectivityHelper.instance.onConnectivityChange
        .listen((isConnected) {
          if (isConnected && !_lastConnectivityState && !_hasLoadedFromApi) {
            debugPrint(
              '🌐 Internet came back - refreshing item reports from API',
            );
            getItemsList(forceApiRefresh: true);
          }
          _lastConnectivityState = isConnected;
        });

    _lastConnectivityState = ConnectivityHelper.instance.isConnected;
    super.onReady();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}

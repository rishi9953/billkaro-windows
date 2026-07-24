import 'dart:io';

import 'package:billkaro/utils/app_info.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:path_provider/path_provider.dart';

/// Product details resolved from Open Food Facts for a scanned barcode.
class OpenFoodProductDetails {
  const OpenFoodProductDetails({
    required this.barcode,
    this.name,
    this.brand,
    this.category,
    this.imageUrl,
    this.quantity,
    this.price,
    this.currency,
  });

  final String barcode;
  final String? name;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? quantity;

  /// Crowd-sourced retail price from Open Prices (taxes included when present).
  /// Often missing — especially for India. Never includes GST tax %.
  final double? price;
  final String? currency;

  String? get displayName {
    final n = name?.trim();
    final b = brand?.trim();
    if (n != null && n.isNotEmpty && b != null && b.isNotEmpty) {
      return '$n ($b)';
    }
    if (n != null && n.isNotEmpty) return n;
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}

/// Looks up packaged-food product data by barcode via Open Food Facts.
class OpenFoodFactsService {
  OpenFoodFactsService._();

  static var _configured = false;

  static void ensureConfigured() {
    if (_configured) return;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'BillKaro',
      version: AppInfoUtil.version == 'Unknown' ? '1.0.0' : AppInfoUtil.version,
      system: defaultTargetPlatform.name,
      url: 'https://billkrochillkro.com/',
    );
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.INDIA;
    _configured = true;
  }

  static Future<Product?> getProduct(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    ensureConfigured();

    final configuration = ProductQueryConfiguration(
      code,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [ProductField.ALL],
      version: ProductQueryVersion.v3,
    );

    debugPrint('🛒 [OFF] Fetching product for barcode: $code');
    final result = await OpenFoodAPIClient.getProductV3(configuration);
    debugPrint('🛒 [OFF] status: ${result.status}');
    debugPrint('🛒 [OFF] barcode: ${result.barcode}');
    debugPrint('🛒 [OFF] raw product null? ${result.product == null}');

    if (result.product != null) {
      final p = result.product!;
      debugPrint('🛒 [OFF] productName: ${p.productName}');
      debugPrint('🛒 [OFF] brands: ${p.brands}');
      debugPrint('🛒 [OFF] categories: ${p.categories}');
      debugPrint('🛒 [OFF] quantity: ${p.quantity}');
      debugPrint('🛒 [OFF] imageFrontUrl: ${p.imageFrontUrl}');
      debugPrint('🛒 [OFF] imageFrontSmallUrl: ${p.imageFrontSmallUrl}');
      debugPrint('🛒 [OFF] full product: $p');
    } else {
      debugPrint('🛒 [OFF] No product in response for $code');
    }

    if (result.status == ProductResultV3.statusSuccess) {
      return result.product;
    }
    return null;
  }

  /// Crowd-sourced prices from Open Prices API (separate from product API).
  /// Prefer INR when available; otherwise latest reported price.
  static Future<({double price, String currency})?> fetchPrice(
    String barcode,
  ) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    ensureConfigured();

    try {
      debugPrint('💰 [OFF Prices] Fetching prices for barcode: $code');

      // Prefer India (INR) prices first.
      for (final currency in [Currency.INR, null]) {
        final parameters = GetPricesParameters()
          ..productCode = code
          ..pageSize = 20
          ..pageNumber = 1
          ..orderBy = <OrderBy<GetPricesOrderField>>[
            OrderBy(field: GetPricesOrderField.created, ascending: false),
          ];
        if (currency != null) {
          parameters.currency = currency;
        }

        final maybe = await OpenPricesAPIClient.getPrices(parameters);
        debugPrint(
          '💰 [OFF Prices] currency=${currency?.name ?? 'any'} '
          'isError=${maybe.isError} '
          'items=${maybe.isError ? 0 : maybe.value.items?.length ?? 0}',
        );

        if (maybe.isError) {
          debugPrint('💰 [OFF Prices] error: ${maybe.detailError}');
          continue;
        }

        final items = maybe.value.items;
        if (items == null || items.isEmpty) continue;

        for (final item in items) {
          debugPrint(
            '💰 [OFF Prices] item → '
            'price=${item.price} currency=${item.currency.name} '
            'date=${item.date} location=${item.location?.displayName}',
          );
        }

        final best = items.firstWhere(
          (p) => p.price > 0,
          orElse: () => items.first,
        );
        if (best.price <= 0) continue;

        final value = (
          price: best.price.toDouble(),
          currency: best.currency.name,
        );
        debugPrint(
          '💰 [OFF Prices] selected → ${value.price} ${value.currency}',
        );
        return value;
      }

      debugPrint('💰 [OFF Prices] No price found for $code');
    } catch (e, st) {
      debugPrint('💰 [OFF Prices] fetchPrice error: $e\n$st');
    }
    return null;
  }

  static Future<OpenFoodProductDetails?> fetchByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    try {
      final product = await getProduct(code);
      final priceInfo = await fetchPrice(code);

      if (product == null && priceInfo == null) {
        debugPrint('🛒 [OFF] fetchByBarcode → null (not found) for $code');
        return null;
      }

      final category = product?.categories
          ?.split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty && !c.contains(':'))
          .firstOrNull;

      final details = OpenFoodProductDetails(
        barcode: product?.barcode ?? code,
        name: product?.productName?.trim(),
        brand: product?.brands?.split(',').firstOrNull?.trim(),
        category: category,
        imageUrl: product?.imageFrontUrl ?? product?.imageFrontSmallUrl,
        quantity: product?.quantity?.trim(),
        price: priceInfo?.price,
        currency: priceInfo?.currency,
      );

      debugPrint(
        '🛒 [OFF] mapped → '
        'name=${details.displayName}, '
        'brand=${details.brand}, '
        'category=${details.category}, '
        'qty=${details.quantity}, '
        'price=${details.price} ${details.currency}, '
        'image=${details.imageUrl}',
      );
      debugPrint('🛒 [OFF] note: GST/tax % is NOT provided by Open Food Facts');

      return details;
    } catch (e, st) {
      debugPrint('OpenFoodFactsService.fetchByBarcode error: $e\n$st');
      return null;
    }
  }

  static Future<File?> downloadImage(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(trimmed));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final dir = await getTemporaryDirectory();
      final ext = trimmed.contains('.png')
          ? 'png'
          : trimmed.contains('.webp')
          ? 'webp'
          : 'jpg';
      final file = File(
        '${dir.path}${Platform.pathSeparator}off_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } catch (e, st) {
      debugPrint('OpenFoodFactsService.downloadImage error: $e\n$st');
      return null;
    }
  }
}

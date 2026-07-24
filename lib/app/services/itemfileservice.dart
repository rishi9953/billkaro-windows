import 'dart:io';
import 'dart:math';

import 'package:billkaro/utils/xlsx_table_reader.dart';

/// One row read from a menu CSV / Excel import file.
class ItemImportRow {
  const ItemImportRow({
    required this.name,
    required this.price,
    required this.category,
    required this.gst,
    required this.withTax,
    this.imageUrl = '',
  });

  final String name;
  final double price;
  final String category;
  final double gst;
  final bool withTax;
  final String imageUrl;
}

/// Parses spreadsheet paths (`.xlsx`, `.csv`) into [ItemImportRow]s.
class ItemFileService {
  ItemFileService._();

  static List<ItemImportRow> parseSpreadsheet(String path) {
    final ext = path.split('.').last.toLowerCase();
    final List<List<String>> table;
    switch (ext) {
      case 'xlsx':
        table = XlsxTableReader.readRows(path);
        break;
      case 'csv':
        table = _parseCsvTable(File(path).readAsStringSync());
        break;
      default:
        throw Exception(
          'Unsupported file type. Use .xlsx or .csv (legacy .xls: save as .xlsx in Excel).',
        );
    }
    return _rowsFromTable(table);
  }

  static List<List<String>> _parseCsvTable(String content) {
    return content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(_parseCsvLine)
        .toList();
  }

  static List<String> _parseCsvLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote =
            inQuotes && i + 1 < line.length && line[i + 1] == '"';
        if (nextIsQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString().trim());
    return cells;
  }

  static List<ItemImportRow> _rowsFromTable(List<List<String>> table) {
    if (table.isEmpty) return [];

    final data = _trimLeadingEmptyRows(table);
    if (data.isEmpty) return [];

    final headerIdx = _findBestImportHeaderRowIndex(data);
    var columns = headerIdx >= 0
        ? _columnsFromHeaderRow(data[headerIdx])
        : _defaultsImportColumns();

    if (headerIdx >= 0) {
      final startSample = headerIdx + 1;
      if (startSample < data.length) {
        final sampleEnd = min(data.length, startSample + 15);
        final samples = data.sublist(startSample, sampleEnd);
        columns = _refineImportNameColumn(columns, data[headerIdx], samples);
      }
    }

    final start = headerIdx >= 0 ? headerIdx + 1 : 0;

    final rows = <ItemImportRow>[];
    for (var i = start; i < data.length; i++) {
      final cells = data[i];
      if (cells.every((cell) => cell.trim().isEmpty)) continue;

      final categoryRaw = _cellAt(cells, columns.categoryCol)?.trim();

      var name = _cellAt(cells, columns.nameCol)?.trim();
      if (name == null || name.isEmpty || _isNumericOnly(name)) {
        name = _guessItemNameFromRow(cells, columns);
      }
      if (categoryRaw != null &&
          categoryRaw.isNotEmpty &&
          name != null &&
          name.trim().toLowerCase() == categoryRaw.trim().toLowerCase()) {
        name = _guessItemNameFromRow(
          cells,
          columns,
          extraSkip: {columns.nameCol},
        );
      }
      if (name == null || name.isEmpty) continue;

      var price =
          _parsePriceValue(_cellAt(cells, columns.priceCol)) ??
          (columns.inclusivePriceCol != null
              ? _parsePriceValue(_cellAt(cells, columns.inclusivePriceCol!))
              : null) ??
          _firstPriceInRowSkippingCoreColumns(cells, columns);
      if (price == null || price <= 0) continue;

      // Lowercase to match app category chips / API filters (case-sensitive match otherwise)
      final category = categoryRaw != null && categoryRaw.isNotEmpty
          ? (categoryRaw.toLowerCase() == 'none' ? 'none' : categoryRaw.toLowerCase())
          : 'none';

      final gstRaw = _cellAt(cells, columns.gstCol);
      final gst = _parsePriceValue(gstRaw) ?? 0.0;

      var withTax = false;
      if (columns.withTaxToggleCol != null) {
        final toggleRaw =
            _cellAt(cells, columns.withTaxToggleCol!)?.trim() ?? '';
        if (toggleRaw.isNotEmpty) {
          withTax =
              _parseBool(toggleRaw) || (_parsePriceValue(toggleRaw) ?? 0) > 0;
        }
      }
      if (!withTax && columns.inclusivePriceCol != null) {
        final incRaw = _cellAt(cells, columns.inclusivePriceCol!)?.trim() ?? '';
        if ((_parsePriceValue(incRaw) ?? 0) > 0) {
          withTax = true;
        }
      }

      final imageUrl = columns.imageCol != null
          ? (_cellAt(cells, columns.imageCol!)?.trim() ?? '')
          : '';

      rows.add(
        ItemImportRow(
          name: name,
          price: price,
          category: category,
          gst: gst,
          withTax: withTax,
          imageUrl: imageUrl,
        ),
      );
    }
    return rows;
  }

  static _ItemImportColumns _defaultsImportColumns() =>
      const _ItemImportColumns(
        nameCol: 0,
        priceCol: 1,
        categoryCol: 2,
        gstCol: 3,
        imageCol: 4,
        inclusivePriceCol: null,
        withTaxToggleCol: null,
      );

  static List<List<String>> _trimLeadingEmptyRows(List<List<String>> table) {
    var i = 0;
    while (i < table.length && table[i].every((c) => c.trim().isEmpty)) {
      i++;
    }
    if (i == 0) return table;
    return table.sublist(i);
  }

  static int _findBestImportHeaderRowIndex(List<List<String>> table) {
    final limit = min(40, table.length);
    var bestIdx = -1;
    var bestScore = -1;
    for (var r = 0; r < limit; r++) {
      final s = _importHeaderLikenessScore(table[r]);
      if (s > bestScore) {
        bestScore = s;
        bestIdx = r;
      }
    }
    return bestScore >= 6 ? bestIdx : -1;
  }

  static int _importHeaderLikenessScore(List<String> row) {
    var score = 0;
    for (final cell in row) {
      final n = _normalizeSpreadsheetHeader(cell);
      if (n.isEmpty) continue;
      if (n.contains('categor')) score += 3;
      if ((n.contains('price') || n.contains('rate') || n.contains('mrp')) &&
          !n.contains('incl')) {
        score += 2;
      }
      if (_headerIsGstPercent(n)) score += 2;
      if (_headerIsInclusiveTaxPrice(n)) score += 1;
      if (_headerIsImageLink(n)) score += 2;
      if (n.contains('item name') || n.contains('product name')) score += 3;
      if (n.contains('item code') || n == 'sku' || n == 'code') score += 1;
      if (n.contains('descr')) score += 1;
      if (n == 'unit' || n == 'units' || n.contains('uom')) score += 1;
    }
    return score;
  }

  static _ItemImportColumns _refineImportNameColumn(
    _ItemImportColumns cols,
    List<String> headerRow,
    List<List<String>> samples,
  ) {
    if (samples.isEmpty) return cols;

    final skip = _indicesToSkipWhenSniffingNames(headerRow, cols);

    int widest() {
      var w = 0;
      for (final row in samples) {
        if (row.length > w) w = row.length;
      }
      return w;
    }

    int nameFitness(List<List<String>> rows, int col) {
      var sum = 0;
      for (final row in rows) {
        final t = _cellAt(row, col)?.trim() ?? '';
        if (t.isEmpty || _isNumericOnly(t)) continue;
        final cat = _cellAt(row, cols.categoryCol)?.trim() ?? '';
        if (cat.isNotEmpty && t.toLowerCase() == cat.toLowerCase()) {
          continue;
        }
        if (_looksLikeSkuOrCompactItemCode(t)) continue;
        if (_looksLikeUnitMeasureToken(t)) continue;
        if (t.length > 90) continue;
        sum++;
      }
      return sum;
    }

    final w = widest();
    var bestCol = cols.nameCol;
    var bestScore = nameFitness(samples, cols.nameCol);

    for (var j = 0; j < w; j++) {
      if (skip.contains(j)) continue;
      final sc = nameFitness(samples, j);
      if (sc > bestScore) {
        bestScore = sc;
        bestCol = j;
      }
    }

    if (bestCol != cols.nameCol && bestScore > 0) {
      return _ItemImportColumns(
        nameCol: bestCol,
        priceCol: cols.priceCol,
        categoryCol: cols.categoryCol,
        gstCol: cols.gstCol,
        imageCol: cols.imageCol,
        inclusivePriceCol: cols.inclusivePriceCol,
        withTaxToggleCol: cols.withTaxToggleCol,
      );
    }
    return cols;
  }

  static Set<int> _indicesToSkipWhenSniffingNames(
    List<String> header,
    _ItemImportColumns cols,
  ) {
    final skip = <int>{
      cols.priceCol,
      cols.gstCol,
      cols.categoryCol,
      if (cols.imageCol != null) cols.imageCol!,
      if (cols.inclusivePriceCol != null) cols.inclusivePriceCol!,
      if (cols.withTaxToggleCol != null) cols.withTaxToggleCol!,
    };

    for (var i = 0; i < header.length; i++) {
      final n = _normalizeSpreadsheetHeader(header[i]);
      if (n.isEmpty) continue;

      if (n.contains('descr') || n.contains('note') || n.contains('remark')) {
        skip.add(i);
      }
      if (n == 'unit' || n == 'units' || n.contains('uom')) {
        skip.add(i);
      }

      final skuOnly = (n.contains('code') || n == 'sku') && !n.contains('name');
      if (skuOnly) skip.add(i);

      if (_headerIsBasePrice(n) ||
          _headerIsGstPercent(n) ||
          _headerIsInclusiveTaxPrice(n) ||
          _headerIsImageLink(n)) {
        skip.add(i);
      }
    }
    return skip;
  }

  static int? _nameColumnRightAfterCategory(
    List<String> header,
    int categoryCol,
  ) {
    if (categoryCol < 0 || categoryCol + 1 >= header.length) return null;
    final n = _normalizeSpreadsheetHeader(header[categoryCol + 1]);
    if (n.isEmpty) return null;
    if (n.contains('descr') ||
        n == 'unit' ||
        n == 'units' ||
        _headerIsBasePrice(n) ||
        _headerIsGstPercent(n) ||
        _headerIsInclusiveTaxPrice(n)) {
      return null;
    }
    if ((n.contains('code') || n == 'sku') && !n.contains('name')) {
      return null;
    }
    return categoryCol + 1;
  }

  static _ItemImportColumns _columnsFromHeaderRow(List<String> header) {
    final defaults = _defaultsImportColumns();
    var nameCol = defaults.nameCol;
    var priceCol = defaults.priceCol;
    var categoryCol = defaults.categoryCol;
    var gstCol = defaults.gstCol;
    var inclusivePriceCol = defaults.inclusivePriceCol;
    var withTaxToggleCol = defaults.withTaxToggleCol;
    int? imageCol = defaults.imageCol;
    var found = false;

    for (var i = 0; i < header.length; i++) {
      final label = _normalizeSpreadsheetHeader(header[i]);
      if (label.isEmpty) continue;

      if (_headerIsInclusiveTaxPrice(label)) {
        inclusivePriceCol = i;
        found = true;
      } else if (_headerIsGstPercent(label)) {
        gstCol = i;
        found = true;
      } else if (_headerIsBasePrice(label)) {
        priceCol = i;
        found = true;
      } else if (label.contains('categor')) {
        categoryCol = i;
        found = true;
      } else if (_headerIsImageLink(label)) {
        imageCol = i;
        found = true;
      } else if (_headerExplicitWithTaxToggle(label)) {
        withTaxToggleCol = i;
        found = true;
      }
    }

    var namePriority = -1;
    final explicitItemNameIdx = _findExplicitItemNameColumnIndex(header);
    if (explicitItemNameIdx != null) {
      nameCol = explicitItemNameIdx;
      found = true;
    } else {
      for (var i = 0; i < header.length; i++) {
        final label = _normalizeSpreadsheetHeader(header[i]);
        final p = _headerNameColumnPriority(label);
        if (p > namePriority) {
          namePriority = p;
          nameCol = i;
        }
      }
      if (namePriority >= 0) found = true;
    }

    if (explicitItemNameIdx == null && namePriority < 0) {
      final besideCategory = _nameColumnRightAfterCategory(header, categoryCol);
      if (besideCategory != null) {
        nameCol = besideCategory;
        found = true;
      }
    }

    return found
        ? _ItemImportColumns(
            nameCol: nameCol,
            priceCol: priceCol,
            categoryCol: categoryCol,
            gstCol: gstCol,
            imageCol: imageCol,
            inclusivePriceCol: inclusivePriceCol,
            withTaxToggleCol: withTaxToggleCol,
          )
        : defaults;
  }

  static String _normalizeSpreadsheetHeader(String raw) {
    var s = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\r\n]+'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static int? _findExplicitItemNameColumnIndex(List<String> header) {
    for (var i = 0; i < header.length; i++) {
      final n = _normalizeSpreadsheetHeader(header[i]);
      if (n.isEmpty) continue;

      if (n.contains('item code') ||
          n.contains('product code') ||
          n.contains('barcode')) {
        continue;
      }

      final hasItemNameToken = n.contains('item name');
      final hasProductNameToken =
          n.contains('product name') || n.endsWith(' product name');

      if (hasProductNameToken) return i;
      if (hasItemNameToken) return i;

      if (RegExp(r'\bitem\b').hasMatch(n) &&
          RegExp(r'\bname\b').hasMatch(n) &&
          !RegExp(r'\bcode\b').hasMatch(n) &&
          !n.contains('category')) {
        return i;
      }

      final dishName =
          RegExp(r'\bdish\b').hasMatch(n) && RegExp(r'\bname\b').hasMatch(n);
      if (dishName) return i;

      if (n == 'dish') return i;
      if (n == 'food item') return i;
    }

    final norms = [for (final h in header) _normalizeSpreadsheetHeader(h)];
    final codeIx = norms.indexWhere(
      (n) =>
          n.contains('item') &&
          (n.contains('code') || n.contains('sku')) &&
          !n.contains('name'),
    );
    final catIx = norms.indexWhere((n) => n.contains('categor'));
    if (codeIx >= 0 && catIx == codeIx + 1 && norms.length > codeIx + 2) {
      return codeIx + 2;
    }

    return null;
  }

  static String? _cellAt(List<String> cells, int index) {
    if (index < 0 || index >= cells.length) return null;
    return cells[index];
  }

  static double? _parsePriceValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  static double? _firstPriceInRowSkippingCoreColumns(
    List<String> cells,
    _ItemImportColumns columns,
  ) {
    final skip = <int>{columns.nameCol, columns.categoryCol, columns.gstCol};
    final inc = columns.inclusivePriceCol;
    if (inc != null) skip.add(inc);
    final img = columns.imageCol;
    if (img != null) skip.add(img);
    final wtt = columns.withTaxToggleCol;
    if (wtt != null) skip.add(wtt);
    for (var i = 0; i < cells.length; i++) {
      if (skip.contains(i)) continue;
      final value = _parsePriceValue(cells[i]);
      if (value != null && value > 0) return value;
    }
    return null;
  }

  static String? _guessItemNameFromRow(
    List<String> cells,
    _ItemImportColumns columns, {
    Set<int> extraSkip = const {},
  }) {
    final skip = <int>{
      columns.categoryCol,
      columns.gstCol,
      columns.priceCol,
      if (columns.imageCol != null) columns.imageCol!,
      if (columns.inclusivePriceCol != null) columns.inclusivePriceCol!,
      if (columns.withTaxToggleCol != null) columns.withTaxToggleCol!,
      ...extraSkip,
    };

    for (var i = 0; i < cells.length; i++) {
      if (skip.contains(i)) continue;
      final text = cells[i].trim();
      if (text.isEmpty || _isNumericOnly(text)) continue;
      if (_parseBool(text)) continue;
      if (_looksLikeSkuOrCompactItemCode(text)) continue;
      if (_looksLikeUnitMeasureToken(text)) continue;
      if (text.length > 140) continue;
      return text;
    }
    return null;
  }

  static bool _looksLikeSkuOrCompactItemCode(String text) {
    final t = text.trim();
    if (t.length < 4 || t.length > 28) return false;
    final compact = RegExp(r'^[A-Za-z]{2,6}[\s_-]?\d{2,8}$').hasMatch(t);
    if (compact) return true;
    return RegExp(
      r'^(sku|pid|skucode)[\s#:-]?\w+$',
      caseSensitive: false,
    ).hasMatch(t.replaceAll(RegExp(r'\s+'), ''));
  }

  static bool _looksLikeUnitMeasureToken(String raw) {
    final t = raw.trim().toLowerCase();
    const units = <String>{
      'cup',
      'cups',
      'glass',
      'pcs',
      'pc',
      'nos',
      'no',
      'nr',
      'kg',
      'gm',
      'g',
      'ltr',
      'l',
      'ml',
      'box',
      'pkt',
      'packet',
      'plate',
      'plates',
      'bowl',
      'piece',
      'pieces',
      'portion',
      'serving',
      'each',
      'combo',
      'qty',
      'qty.',
    };
    return units.contains(t);
  }

  static int _headerNameColumnPriority(String lower) {
    if (lower.contains('description')) return -1;
    if (lower.contains('sku')) return -1;
    if (lower == 'unit' || lower == 'units' || lower == 'uom') {
      return -1;
    }
    if (lower.contains('item code') ||
        lower.contains('product code') ||
        lower.contains('barcode')) {
      return -1;
    }
    if (lower.contains('categor')) return -1;

    if (lower.contains('item name') ||
        lower.contains('product name') ||
        lower.contains('food item')) {
      return 40;
    }
    if (lower.contains('menu item')) return 38;
    if (lower.contains('dish')) return 35;

    final hasBareName = lower.trim() == 'name' || lower.endsWith(' name');

    if (hasBareName ||
        (lower.contains('name') &&
            !lower.contains('category') &&
            !lower.contains('company') &&
            !lower.contains('code') &&
            !lower.contains('user'))) {
      return 10;
    }
    return -1;
  }

  static bool _headerIsBasePrice(String lower) {
    if (lower.contains('incl') || lower.contains('inclusive')) {
      return false;
    }
    return lower.contains('price') ||
        lower.contains('rate') ||
        lower.contains('amount') ||
        lower.contains('mrp') ||
        lower.contains('cost');
  }

  static bool _headerExplicitWithTaxToggle(String lower) {
    if (lower.contains('incl') ||
        lower.contains('inclusive') ||
        lower.contains('price')) {
      return false;
    }
    return lower.contains('with tax');
  }

  static bool _headerIsInclusiveTaxPrice(String lower) {
    return (lower.contains('incl') || lower.contains('inclusive')) &&
        (lower.contains('tax') || lower.contains('gst'));
  }

  static bool _headerIsGstPercent(String lower) {
    if (lower.contains('price') || lower.contains('incl')) return false;
    return lower.contains('gst') ||
        lower.contains('tax %') ||
        lower.contains('tax%') ||
        (lower.contains('tax') && lower.contains('%'));
  }

  static bool _headerIsImageLink(String lower) {
    if (lower.contains('categor')) return false;
    return lower == 'image link' ||
        lower == 'image url' ||
        lower == 'image' ||
        lower == 'item image' ||
        lower == 'product image' ||
        lower.contains('image link') ||
        lower.contains('image url') ||
        (lower.contains('image') && lower.contains('link')) ||
        (lower.contains('image') && lower.contains('url'));
  }

  static bool _isNumericOnly(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return false;
    return double.tryParse(cleaned) != null &&
        value.trim().replaceAll(RegExp(r'[\d.,\s]'), '').isEmpty;
  }

  static bool _parseBool(String value) {
    final lower = value.trim().toLowerCase();
    return lower == 'yes' || lower == 'true' || lower == '1' || lower == 'y';
  }
}

class _ItemImportColumns {
  const _ItemImportColumns({
    required this.nameCol,
    required this.priceCol,
    required this.categoryCol,
    required this.gstCol,
    this.imageCol,
    required this.inclusivePriceCol,
    required this.withTaxToggleCol,
  });

  final int nameCol;
  final int priceCol;
  final int categoryCol;
  final int gstCol;
  final int? imageCol;
  final int? inclusivePriceCol;
  final int? withTaxToggleCol;
}

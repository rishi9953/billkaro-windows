import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Reads the first worksheet from an `.xlsx` file into rows of string cells.
class XlsxTableReader {
  XlsxTableReader._();

  static List<List<String>> readRows(String path) {
    return readRowsFromBytes(File(path).readAsBytesSync());
  }

  static List<List<String>> readRowsFromBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final sharedStrings = _readSharedStrings(archive);
    final sheetBytes = _readFirstSheetBytes(archive);
    if (sheetBytes == null) {
      throw Exception('No worksheet found in Excel file');
    }

    return _parseSheet(sheetBytes, sharedStrings);
  }

  static List<String> _readSharedStrings(Archive archive) {
    final file = _findArchiveFile(archive, 'xl/sharedStrings.xml');
    if (file == null) return [];

    final document = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final strings = <String>[];
    for (final si in document.findAllElements('si')) {
      // Concatenate all text runs (<r><t>…</t></r>), not only direct <t> children.
      strings.add(
        si.descendants
            .whereType<XmlText>()
            .map((XmlText t) => t.value)
            .join()
            .trim(),
      );
    }
    return strings;
  }

  static List<int>? _readFirstSheetBytes(Archive archive) {
    const candidates = [
      'xl/worksheets/sheet1.xml',
      'xl/worksheets/sheet.xml',
    ];
    for (final name in candidates) {
      final file = _findArchiveFile(archive, name);
      if (file != null) return file.content as List<int>;
    }

    ArchiveFile? firstSheet;
    for (final file in archive) {
      final normalized = file.name.replaceAll('\\', '/');
      if (normalized.startsWith('xl/worksheets/') &&
          normalized.endsWith('.xml')) {
        firstSheet = file;
        break;
      }
    }
    return firstSheet?.content as List<int>?;
  }

  static ArchiveFile? _findArchiveFile(Archive archive, String targetName) {
    final normalizedTarget = targetName.replaceAll('\\', '/');
    for (final file in archive) {
      final normalized = file.name.replaceAll('\\', '/');
      if (normalized == normalizedTarget) return file;
    }
    return null;
  }

  static List<List<String>> _parseSheet(
    List<int> bytes,
    List<String> sharedStrings,
  ) {
    final document = XmlDocument.parse(utf8.decode(bytes));
    final sheetData = document.findAllElements('sheetData').firstOrNull;
    if (sheetData == null) return [];

    final rowMap = <int, Map<int, String>>{};
    var maxCol = 0;

    var nextRowNum = 1;
    for (final row in sheetData.findElements('row')) {
      var rowNum = int.tryParse(row.getAttribute('r') ?? '') ?? 0;
      if (rowNum <= 0) {
        rowNum = nextRowNum;
      }
      nextRowNum = rowNum + 1;

      final colMap = rowMap.putIfAbsent(rowNum, () => {});
      var nextColIndex = 0;
      for (final cell in row.findElements('c')) {
        final ref = cell.getAttribute('r');
        final int colIdx;
        if (ref != null && ref.isNotEmpty) {
          colIdx = _columnIndexFromRef(ref);
          nextColIndex = colIdx + 1;
        } else {
          colIdx = nextColIndex;
          nextColIndex++;
        }
        colMap[colIdx] = _cellValue(cell, sharedStrings);
        if (colIdx > maxCol) maxCol = colIdx;
      }
    }

    if (rowMap.isEmpty) return [];

    final minRow = rowMap.keys.reduce((a, b) => a < b ? a : b);
    final maxRow = rowMap.keys.reduce((a, b) => a > b ? a : b);
    final colCount = (maxCol + 1).clamp(1, 64);

    final result = <List<String>>[];
    for (var r = minRow; r <= maxRow; r++) {
      final cols = rowMap[r];
      final row = List.generate(
        colCount,
        (index) => cols?[index]?.trim() ?? '',
      );
      if (row.any((cell) => cell.isNotEmpty)) {
        result.add(row);
      }
    }
    return result;
  }

  static String _cellValue(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');
    if (type == 's') {
      final raw = _firstChildText(cell, 'v');
      final index = int.tryParse(raw) ?? -1;
      if (index >= 0 && index < sharedStrings.length) {
        return sharedStrings[index];
      }
      return '';
    }
    if (type == 'inlineStr' || type == 'str') {
      final inline = cell.findAllElements('t').map((node) => node.innerText).join();
      if (inline.isNotEmpty) return inline;
      return _firstChildText(cell, 'v');
    }
    if (type == 'b') {
      final raw = _firstChildText(cell, 'v');
      return raw == '1' ? 'yes' : 'no';
    }
    return _firstChildText(cell, 'v');
  }

  static String _firstChildText(XmlElement cell, String localName) {
    return cell.findElements(localName).firstOrNull?.innerText ?? '';
  }

  static int _columnIndexFromRef(String ref) {
    final match = RegExp(r'^([A-Za-z]+)').firstMatch(ref);
    if (match == null) return 0;

    final letters = match.group(1)!.toUpperCase();
    var index = 0;
    for (var i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 64);
    }
    return index - 1;
  }
}

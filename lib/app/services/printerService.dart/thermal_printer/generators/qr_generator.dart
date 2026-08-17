import 'dart:typed_data';

import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/thermal_paper_size.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

/// Builds crisp, paper-size-aware QR payloads for thermal printers.
///
/// Uses solid modules + GS v 0 raster (one image block). The old ESC *
/// banded bitmaps left gaps / soft edges on 3" and 4" rolls.
class QRGenerator {
  /// QR spec quiet zone (modules of white around the symbol).
  static const int _quietZoneModules = 4;

  static Future<List<int>> generate(
    String upiId,
    double amount,
    String payeeName,
    String transactionNote, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    final upiUrl = _buildUpiUrl(
      upiId: upiId,
      amount: amount,
      payeeName: payeeName,
      transactionNote: transactionNote,
    );
    return generateNative(upiUrl, paperSize: paperSize);
  }

  /// Printer-firmware QR (GS ( k). Sharpest when the device supports it.
  static Future<List<int>> generateNative(
    String data, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    try {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return [];

      final qrBytes = <int>[
        // Center
        0x1B, 0x61, 0x01,
        // Model 2
        0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00,
        // Module size (scales with 2"/3"/4")
        0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, paperSize.escPosQrModuleSize,
        // Error correction M
        0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31,
      ];

      final dataBytes = trimmed.codeUnits;
      final pL = (dataBytes.length + 3) % 256;
      final pH = (dataBytes.length + 3) ~/ 256;
      qrBytes
        ..addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30])
        ..addAll(dataBytes)
        ..addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30])
        ..add(0x0A);

      return qrBytes;
    } catch (e) {
      debugPrint('QR generation error: $e');
      return [];
    }
  }

  static Future<List<int>> generateBitmap(
    String upiId,
    double amount,
    String payeeName,
    String transactionNote, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    try {
      final upiUrl = _buildUpiUrl(
        upiId: upiId,
        amount: amount,
        payeeName: payeeName,
        transactionNote: transactionNote,
      );
      debugPrint('QR Code Bitmap Data: $upiUrl (${paperSize.storageKey}mm)');
      return generateUrlBitmap(upiUrl, paperSize: paperSize);
    } catch (e) {
      debugPrint('QR bitmap generation error: $e');
      return [];
    }
  }

  /// Prefer crisp GS v 0 raster (works on most ESC/POS printers without soft edges).
  static Future<List<int>> generateUrlBitmap(
    String data, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    return generateUrlRasterBitmap(data, paperSize: paperSize);
  }

  /// GS v 0 raster with solid modules sized for the selected paper.
  static Future<List<int>> generateUrlRasterBitmap(
    String data, {
    ThermalPaperSize paperSize = ThermalPaperSize.mm58,
  }) async {
    try {
      final mono = buildCrispQrImage(
        data,
        moduleDots: paperSize.qrModuleDots,
        maxDots: paperSize.qrMaxDots,
      );
      if (mono == null) return [];
      return _toEscPosRaster(mono);
    } catch (e) {
      debugPrint('QR raster generation error: $e');
      return [];
    }
  }

  /// PNG bytes for PDF / on-screen print previews.
  static Future<Uint8List?> generatePngBytes(
    String data, {
    required int size,
    int moduleDots = 8,
  }) async {
    try {
      final mono = buildCrispQrImage(
        data,
        moduleDots: moduleDots,
        maxDots: size,
      );
      if (mono == null) return null;
      return Uint8List.fromList(img.encodePng(mono));
    } catch (e) {
      debugPrint('QR PNG generation error: $e');
      return null;
    }
  }

  /// Renders a binary QR with whole-pixel modules (no anti-aliasing).
  static img.Image? buildCrispQrImage(
    String data, {
    required int moduleDots,
    required int maxDots,
  }) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return null;

    final qrCode = QrCode.fromData(
      data: trimmed,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final modules = qrImage.moduleCount;
    final totalModules = modules + (_quietZoneModules * 2);

    var modulePx = moduleDots.clamp(4, 16);
    while (totalModules * modulePx > maxDots && modulePx > 4) {
      modulePx--;
    }

    // Keep width divisible by 8 for GS v 0 packing (sharp, no soft resize).
    var size = totalModules * modulePx;
    final pad = (8 - (size % 8)) % 8;
    size += pad;
    final quietPx = _quietZoneModules * modulePx + (pad ~/ 2);

    final image = img.Image(width: size, height: size);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final black = img.ColorRgb8(0, 0, 0);

    for (var row = 0; row < modules; row++) {
      for (var col = 0; col < modules; col++) {
        if (!qrImage.isDark(row, col)) continue;
        final x1 = quietPx + col * modulePx;
        final y1 = quietPx + row * modulePx;
        img.fillRect(
          image,
          x1: x1,
          y1: y1,
          x2: x1 + modulePx - 1,
          y2: y1 + modulePx - 1,
          color: black,
          alphaBlend: false,
        );
      }
    }
    return image;
  }

  static String _buildUpiUrl({
    required String upiId,
    required double amount,
    required String payeeName,
    required String transactionNote,
  }) {
    // Keep payload short so QR version stays low → larger modules → clearer print.
    final shortName = payeeName.trim().isEmpty
        ? 'Pay'
        : (payeeName.trim().length > 20
            ? payeeName.trim().substring(0, 20)
            : payeeName.trim());
    final shortNote = transactionNote.trim().length > 24
        ? transactionNote.trim().substring(0, 24)
        : transactionNote.trim();
    final encodedPayeeName = Uri.encodeComponent(shortName);
    final encodedTransactionNote = Uri.encodeComponent(shortNote);
    return 'upi://pay?pa=$upiId&pn=$encodedPayeeName'
        '&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$encodedTransactionNote';
  }

  /// GS v 0 raster bit image — one block, no band gaps (unlike ESC *).
  static List<int> _toEscPosRaster(img.Image monoImage) {
    final width = monoImage.width;
    final height = monoImage.height;
    final widthBytes = (width + 7) ~/ 8;

    final bytes = <int>[
      // Center alignment
      0x1B, 0x61, 0x01,
      // GS v 0 m=0 (normal density, 1:1 dots)
      0x1D, 0x76, 0x30, 0x00,
      widthBytes & 0xFF,
      (widthBytes >> 8) & 0xFF,
      height & 0xFF,
      (height >> 8) & 0xFF,
    ];

    for (var y = 0; y < height; y++) {
      for (var byteX = 0; byteX < widthBytes; byteX++) {
        var packed = 0;
        for (var bit = 0; bit < 8; bit++) {
          final x = byteX * 8 + bit;
          if (x >= width) continue;
          final pixel = monoImage.getPixel(x, y);
          if (img.getLuminance(pixel) < 128) {
            packed |= 0x80 >> bit;
          }
        }
        bytes.add(packed);
      }
    }

    // Feed a little so the QR is not flush against the next text.
    bytes.addAll([0x0A]);
    return bytes;
  }
}

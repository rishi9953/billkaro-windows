import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class QRGenerator {
  static Future<List<int>> generate(
    String upiId,
    double amount,
    String payeeName,
    String transactionNote,
  ) async {
    try {
      String encodedPayeeName = Uri.encodeComponent(payeeName);
      String encodedTransactionNote = Uri.encodeComponent(transactionNote);
      String upiUrl = 'upi://pay?pa=$upiId&pn=$encodedPayeeName&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$encodedTransactionNote';

      print('QR Code Data: $upiUrl');

      List<int> qrBytes = [];

      // Select QR code model (Model 2)
      qrBytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);

      // Set module size (size 6)
      qrBytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]);

      // Set error correction level (M)
      qrBytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);

      // Store data in symbol storage
      List<int> dataBytes = upiUrl.codeUnits;
      int pL = (dataBytes.length + 3) % 256;
      int pH = (dataBytes.length + 3) ~/ 256;
      qrBytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
      qrBytes.addAll(dataBytes);

      // Print the QR code
      qrBytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

      return qrBytes;
    } catch (e) {
      print('QR generation error: $e');
      return [];
    }
  }

  static Future<List<int>> generateBitmap(
    String upiId,
    double amount,
    String payeeName,
    String transactionNote,
  ) async {
    try {
      String encodedPayeeName = Uri.encodeComponent(payeeName);
      String encodedTransactionNote = Uri.encodeComponent(transactionNote);
      String upiUrl = 'upi://pay?pa=$upiId&pn=$encodedPayeeName&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$encodedTransactionNote';

      print('QR Code Bitmap Data: $upiUrl');

      // Create QR code
      final qrCode = QrCode.fromData(data: upiUrl, errorCorrectLevel: QrErrorCorrectLevel.M);
      final qrPainter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      // Generate image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      qrPainter.paint(canvas, const Size(200, 200));

      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return [];

      final pngBytes = byteData.buffer.asUint8List();
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) return [];

      final monoImage = img.grayscale(decodedImage);
      List<int> bytes = [];

      // Center alignment
      bytes.addAll([0x1B, 0x61, 0x01]);

      int width = monoImage.width;
      int height = monoImage.height;

      // Convert to ESC/POS bitmap format
      for (int y = 0; y < height; y += 24) {
        bytes.addAll([0x1B, 0x2A, 0x21]); // 24-dot double-density
        bytes.addAll([width % 256, width ~/ 256]);

        for (int x = 0; x < width; x++) {
          for (int k = 0; k < 3; k++) {
            int slice = 0;
            for (int b = 0; b < 8; b++) {
              int yy = y + k * 8 + b;
              if (yy < height) {
                var pixel = monoImage.getPixel(x, yy);
                num luminance = img.getLuminance(pixel);
                if (luminance < 128) {
                  slice |= 1 << (7 - b);
                }
              }
            }
            bytes.add(slice);
          }
        }
        bytes.add(0x0A); // Line feed
      }

      // Reset alignment
      bytes.addAll([0x1B, 0x61, 0x01]);

      return bytes;
    } catch (e) {
      print('QR bitmap generation error: $e');
      return [];
    }
  }
}
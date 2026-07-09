import 'package:pdf/pdf.dart';

enum PoPrintOrientation {
  portrait,
  landscape;

  PdfPageFormat get pageFormat =>
      this == PoPrintOrientation.landscape
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4;

  String get storageValue =>
      this == PoPrintOrientation.portrait ? 'portrait' : 'landscape';

  static PoPrintOrientation fromStorage(String? value) =>
      value == 'portrait'
          ? PoPrintOrientation.portrait
          : PoPrintOrientation.landscape;
}

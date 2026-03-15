import 'package:billkaro/app/services/printerService.dart/thermal_printer/builders/print_builder.dart';
import 'package:pdf/widgets.dart' as pw;

abstract class PrintJob {
  final PrintJobType type;
  final DateTime timestamp;
  
  PrintJob({
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Build thermal printer commands
  List<int> buildThermal(PrintBuilder builder);
  
  /// Build PDF document
  pw.Document buildPdf();
  
  /// Validate the print job data
  bool validate();
}

enum PrintJobType {
  invoice,
  kot,
  receipt,
  report,
}
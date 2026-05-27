import 'dart:io';

import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

/// Shows instructions and template download before picking an import file.
/// Returns `true` when the user chooses [Select File], otherwise `null`.
Future<bool?> showMenuImportFileDialog() async {
  return Get.dialog<bool>(
    const _MenuImportFileDialog(),
    barrierDismissible: false,
  );
}

class _MenuImportFileDialog extends StatelessWidget {
  const _MenuImportFileDialog();

  static const _templateFileName = 'products_template.xlsx';

  Future<void> _downloadTemplate() async {
    try {
      showAppLoader();
      final workbook = Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Products';

      final headers = ['Name', 'Price', 'Category', 'Tax %'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = '#E8EEF7';
      }

      sheet.getRangeByIndex(2, 1).setText('Sample Item');
      sheet.getRangeByIndex(2, 2).setNumber(100);
      sheet.getRangeByIndex(2, 3).setText('Beverages');
      sheet.getRangeByIndex(2, 4).setNumber(5);

      for (var i = 1; i <= headers.length; i++) {
        sheet.autoFitColumn(i);
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final saveDir = Directory(await DownloadPathUtil.resolveSaveDirectory());
      if (!saveDir.existsSync()) {
        saveDir.createSync(recursive: true);
      }

      final fullPath = '${saveDir.path}/$_templateFileName';
      await File(fullPath).writeAsBytes(bytes);

      final openResult = await OpenFile.open(fullPath);
      if (openResult.type == ResultType.done) {
        showSuccess(description: 'Template saved and opened');
      } else {
        showSuccess(description: 'Template saved to: $fullPath');
      }
    } catch (e) {
      showError(description: 'Failed to save template: $e');
    } finally {
      dismissAllAppLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.upload_file_outlined,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Import Products - Excel (.xlsx)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Select an Excel (.xlsx) file following the BillKaro template format. '
                'Required columns: Name and Price. Missing categories will be created automatically.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  // onTap: _downloadTemplate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColor.primary.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Assets.svg.excel.svg(
                          height: 18,
                          width: 18,
                          colorFilter: ColorFilter.mode(
                            AppColor.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _templateFileName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: Text(
                      'Select File',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

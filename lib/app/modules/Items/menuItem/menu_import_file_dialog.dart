import 'package:billkaro/app/modules/Items/menuItem/menu_products_template_service.dart';
import 'package:billkaro/config/config.dart';

enum MenuProductsExcelDialogMode { import, export }

/// Shows instructions and template download before picking an import file.
/// Returns `true` when the user chooses [Select File], otherwise `null`.
Future<bool?> showMenuImportFileDialog() =>
    showMenuProductsExcelDialog(MenuProductsExcelDialogMode.import);

/// Shows instructions and template download before exporting products.
/// Returns `true` when the user chooses [Export File], otherwise `null`.
Future<bool?> showMenuExportFileDialog() =>
    showMenuProductsExcelDialog(MenuProductsExcelDialogMode.export);

Future<bool?> showMenuProductsExcelDialog(MenuProductsExcelDialogMode mode) {
  return Get.dialog<bool>(
    _MenuProductsExcelDialog(mode: mode),
    barrierDismissible: false,
  );
}

class _MenuProductsExcelDialog extends StatelessWidget {
  const _MenuProductsExcelDialog({required this.mode});

  final MenuProductsExcelDialogMode mode;

  bool get _isImport => mode == MenuProductsExcelDialogMode.import;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                      _isImport
                          ? Icons.upload_file_outlined
                          : Icons.download_outlined,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isImport
                          ? loc.import_products_excel
                          : loc.export_products_excel,
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
                _isImport
                    ? loc.import_products_description
                    : loc.export_products_description,
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
                  onTap: MenuProductsTemplateService.downloadTemplate,
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
                          MenuProductsTemplateService.templateFileName,
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
                      loc.cancel.toUpperCase(),
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
                      _isImport ? loc.select_file : loc.export_file,
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

import 'package:billkaro/config/config.dart';

class MenuImportPreviewRow {
  const MenuImportPreviewRow({
    required this.name,
    required this.price,
    required this.category,
    required this.gst,
    required this.withTax,
    this.isAvailable = true,
  });

  final String name;
  final double price;
  final String category;
  final double gst;
  final bool withTax;
  final bool isAvailable;
}

Future<List<MenuImportPreviewRow>?> showMenuImportPreviewDialog({
  required List<MenuImportPreviewRow> items,
  required String fileName,
}) async {
  return Get.dialog<List<MenuImportPreviewRow>>(
    _MenuImportPreviewDialog(items: items, fileName: fileName),
    barrierDismissible: false,
  );
}

class _MenuImportPreviewDialog extends StatefulWidget {
  const _MenuImportPreviewDialog({required this.items, required this.fileName});

  final List<MenuImportPreviewRow> items;
  final String fileName;

  @override
  State<_MenuImportPreviewDialog> createState() =>
      _MenuImportPreviewDialogState();
}

class _MenuImportPreviewDialogState extends State<_MenuImportPreviewDialog> {
  late final List<MenuImportPreviewRow> _items;
  late final List<bool> _availability;

  @override
  void initState() {
    super.initState();
    _items = List<MenuImportPreviewRow>.from(widget.items);
    _availability = _items.map((row) => row.isAvailable).toList();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _availability.removeAt(index);
    });
  }

  List<MenuImportPreviewRow> _buildResultRows() {
    return List.generate(_items.length, (index) {
      final item = _items[index];
      return MenuImportPreviewRow(
        name: item.name,
        price: item.price,
        category: item.category,
        gst: item.gst,
        withTax: item.withTax,
        isAvailable: _availability[index],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.import_from_file,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.items_selected_count(_items.length),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: loc.close_search,
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildTableHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  return _buildItemRow(_items[index], index);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _items.isEmpty
                        ? null
                        : () => Get.back(result: _buildResultRows()),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: Text(loc.import_from_file),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.item_name,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.sale_price,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.category,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.gst_label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.availability_column,
              textAlign: TextAlign.center,

              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              loc.delete,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(MenuImportPreviewRow item, int index) {
    final loc = AppLocalizations.of(context)!;
    final categoryLabel =
        item.category.isEmpty || item.category.toLowerCase() == 'none'
        ? '—'
        : item.category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              _formatPrice(item.price),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              categoryLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              item.gst > 0 ? '${item.gst.toStringAsFixed(0)}%' : '—',
              // textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: _availability[index],
                onChanged: (value) {
                  setState(() => _availability[index] = value);
                },
                activeColor: AppColor.primary.withOpacity(0.9),
                activeTrackColor: AppColor.primary.withOpacity(0.2),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: IconButton(
                tooltip: loc.delete,
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return '₹${price.toInt()}';
    }
    return '₹${price.toStringAsFixed(2)}';
  }
}

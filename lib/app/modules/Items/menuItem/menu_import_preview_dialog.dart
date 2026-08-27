import 'package:billkaro/config/config.dart';

String? _resolveImportImageUrl(String raw) {
  final url = resolvedMediaUrl(raw);
  return url.isEmpty ? null : url;
}

class MenuImportPreviewRow {
  const MenuImportPreviewRow({
    required this.name,
    required this.price,
    required this.category,
    required this.gst,
    required this.withTax,
    this.imageUrl = '',
    this.isAvailable = true,
  });

  final String name;
  final double price;
  final String category;
  final double gst;
  final bool withTax;
  final String imageUrl;
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
  static const _gap = 12.0;
  static const _indexW = 40.0;
  static const _imageW = 56.0;
  static const _nameW = 180.0;
  static const _priceW = 130.0;
  static const _categoryW = 150.0;
  static const _gstW = 110.0;
  static const _availabilityW = 110.0;
  static const _deleteW = 72.0;

  late final List<MenuImportPreviewRow> _items;
  late final List<bool> _availability;
  late final List<TextEditingController> _nameCtrls;
  late final List<TextEditingController> _priceCtrls;
  late final List<TextEditingController> _gstCtrls;
  late final ScrollController _horizontalCtrl;
  late final ScrollController _verticalCtrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _horizontalCtrl = ScrollController();
    _verticalCtrl = ScrollController();
    _items = List<MenuImportPreviewRow>.from(widget.items);
    _availability = _items.map((row) => row.isAvailable).toList();
    _nameCtrls = _items
        .map((row) => TextEditingController(text: row.name))
        .toList();
    _priceCtrls = _items
        .map(
          (row) => TextEditingController(
            text: row.price > 0 ? _priceToInput(row.price) : '',
          ),
        )
        .toList();
    _gstCtrls = _items
        .map(
          (row) => TextEditingController(
            text: row.gst > 0 ? row.gst.toStringAsFixed(0) : '',
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    _verticalCtrl.dispose();
    for (final c in _nameCtrls) {
      c.dispose();
    }
    for (final c in _priceCtrls) {
      c.dispose();
    }
    for (final c in _gstCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _priceToInput(double price) {
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }

  double _parseNumber(String raw) {
    return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  bool _isNameMissing(int index) => _nameCtrls[index].text.trim().isEmpty;

  bool _isPriceMissing(int index) => _parseNumber(_priceCtrls[index].text) <= 0;

  bool _isGstMissing(int index) => _gstCtrls[index].text.trim().isEmpty;

  void _removeItem(int index) {
    setState(() {
      _nameCtrls.removeAt(index).dispose();
      _priceCtrls.removeAt(index).dispose();
      _gstCtrls.removeAt(index).dispose();
      _items.removeAt(index);
      _availability.removeAt(index);
      _errorText = null;
    });
  }

  bool get _hasAnyImages =>
      _items.any((item) => item.imageUrl.trim().isNotEmpty);

  double get _tableWidth {
    var width = 32 + // left padding
        _indexW +
        _gap +
        _nameW +
        _gap +
        _priceW +
        _gap +
        _categoryW +
        _gap +
        _gstW +
        _gap +
        _availabilityW +
        _gap +
        _deleteW +
        32; // right padding
    if (_hasAnyImages) {
      width += _imageW + _gap;
    }
    return width;
  }

  /// Item name and sale price are required. GST and other fields are optional.
  String? _validateItems(AppLocalizations loc) {
    for (var i = 0; i < _items.length; i++) {
      final missing = <String>[];
      if (_isNameMissing(i)) missing.add(loc.item_name);
      if (_isPriceMissing(i)) missing.add(loc.sale_price);
      if (missing.isNotEmpty) {
        return loc.import_item_missing_fields(i + 1, missing.join(', '));
      }
    }
    return null;
  }

  void _onImportPressed() {
    final loc = AppLocalizations.of(context)!;
    final error = _validateItems(loc);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    setState(() => _errorText = null);
    Get.back(result: _buildResultRows());
  }

  List<MenuImportPreviewRow> _buildResultRows() {
    return List.generate(_items.length, (index) {
      final item = _items[index];
      return MenuImportPreviewRow(
        name: _nameCtrls[index].text.trim(),
        price: _parseNumber(_priceCtrls[index].text),
        category: item.category,
        gst: _parseNumber(_gstCtrls[index].text),
        withTax: item.withTax,
        imageUrl: item.imageUrl,
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
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 560),
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
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(child: _buildScrollableTable()),
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
                    onPressed: _items.isEmpty ? null : _onImportPressed,
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

  Widget _buildScrollableTable() {
    return Scrollbar(
      controller: _horizontalCtrl,
      thumbVisibility: true,
      trackVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalCtrl,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(),
              const Divider(height: 1),
              Expanded(
                child: Scrollbar(
                  controller: _verticalCtrl,
                  thumbVisibility: true,
                  trackVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.right,
                  child: ListView.separated(
                    controller: _verticalCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      return _buildItemRow(_items[index], index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerLabel(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    );
  }

  Widget _buildTableHeader() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: _indexW, child: _headerLabel('#')),
          const SizedBox(width: _gap),
          if (_hasAnyImages) ...[
            SizedBox(width: _imageW, child: _headerLabel(loc.item_image)),
            const SizedBox(width: _gap),
          ],
          SizedBox(width: _nameW, child: _headerLabel(loc.item_name)),
          const SizedBox(width: _gap),
          SizedBox(width: _priceW, child: _headerLabel(loc.sale_price)),
          const SizedBox(width: _gap),
          SizedBox(width: _categoryW, child: _headerLabel(loc.category)),
          const SizedBox(width: _gap),
          SizedBox(width: _gstW, child: _headerLabel(loc.gst_label)),
          const SizedBox(width: _gap),
          SizedBox(
            width: _availabilityW,
            child: _headerLabel(loc.availability_column, align: TextAlign.center),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _deleteW,
            child: _headerLabel(loc.delete, align: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String hint,
    required bool hasError,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? suffixText,
  }) {
    final borderColor = hasError ? Colors.redAccent : Colors.grey.shade400;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
        hintStyle: TextStyle(
          fontSize: 12,
          color: hasError ? Colors.redAccent.shade200 : Colors.grey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppColor.primary,
            width: 1.5,
          ),
        ),
      ),
      onChanged: (_) {
        setState(() {
          if (_errorText != null) _errorText = null;
        });
      },
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
            width: _indexW,
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: _gap),
          if (_hasAnyImages) ...[
            SizedBox(
              width: _imageW,
              child: _buildImageThumbnail(item.imageUrl),
            ),
            const SizedBox(width: _gap),
          ],
          SizedBox(
            width: _nameW,
            child: _buildEditField(
              controller: _nameCtrls[index],
              hint: loc.item_name,
              hasError: _isNameMissing(index),
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _priceW,
            child: _buildEditField(
              controller: _priceCtrls[index],
              hint: loc.sale_price,
              hasError: _isPriceMissing(index),
              prefixText: '₹',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _categoryW,
            child: Text(
              categoryLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _gstW,
            child: _buildEditField(
              controller: _gstCtrls[index],
              hint: loc.gst_label,
              hasError: _isGstMissing(index),
              suffixText: '%',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _availabilityW,
            child: Center(
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
          const SizedBox(width: _gap),
          SizedBox(
            width: _deleteW,
            child: Center(
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

  Widget _buildImageThumbnail(String raw) {
    final imageUrl = _resolveImportImageUrl(raw);
    if (imageUrl == null) {
      return const SizedBox(width: 36, height: 36);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AppCachedNetworkImage(
        imageUrl: imageUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        memCacheWidth: 72,
        memCacheHeight: 72,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) =>
            Container(width: 36, height: 36, color: Colors.grey.shade200),
        errorWidget: (_, __, ___) => Container(
          width: 36,
          height: 36,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            size: 18,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

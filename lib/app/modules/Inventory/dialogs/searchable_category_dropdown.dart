import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// Searchable category dropdown used by Stock / Item Stock filters and add forms.
class SearchableCategoryDropdown extends StatefulWidget {
  const SearchableCategoryDropdown({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
    this.label = 'Category',
    this.includeAllOption = false,
    this.allOptionLabel = 'All categories',
    this.validator,
    this.decoration,
    this.width,
    this.height,
  });

  final List<String> categories;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool includeAllOption;
  final String allOptionLabel;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;
  final double? width;
  final double? height;

  @override
  State<SearchableCategoryDropdown> createState() =>
      _SearchableCategoryDropdownState();
}

class _SearchableCategoryDropdownState
    extends State<SearchableCategoryDropdown> {
  late final TextEditingController _searchCtrl;
  late final ValueNotifier<String?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _valueListenable = ValueNotifier<String?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchableCategoryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueListenable.value = widget.value;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = <DropdownItem<String>>[
      if (widget.includeAllOption)
        DropdownItem(
          value: '',
          child: Text(
            widget.allOptionLabel,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ...widget.categories.map(
        (c) => DropdownItem(
          value: c,
          child: Text(
            c.capitalize ?? '',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    final field = DropdownButtonFormField2<String>(
      isExpanded: true,
      valueListenable: _valueListenable,
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
      items: items,
      validator: widget.validator,
      onChanged: (value) {
        _valueListenable.value = value;
        widget.onChanged(value);
      },
      onMenuStateChange: (isOpen) {
        if (!isOpen) _searchCtrl.clear();
      },
      iconStyleData: IconStyleData(
        icon: Icon(Icons.keyboard_arrow_down, color: AppColor.primary),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
      ),
      dropdownSearchData: DropdownSearchData(
        searchController: _searchCtrl,
        searchBarWidgetHeight: 50,
        searchBarWidget: Container(
          height: 50,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextFormField(
            expands: true,
            maxLines: null,
            controller: _searchCtrl,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: 'Search category',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) {
          final value = item.value?.toString() ?? '';
          if (value.isEmpty) return true;
          return value.toLowerCase().contains(searchValue.toLowerCase());
        },
        noResultsWidget: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No category found', style: TextStyle(fontSize: 13)),
        ),
      ),
    );

    Widget child = field;
    if (widget.height != null) {
      child = SizedBox(height: widget.height, child: child);
    }
    if (widget.width != null) {
      child = SizedBox(width: widget.width, child: child);
    }
    return child;
  }
}

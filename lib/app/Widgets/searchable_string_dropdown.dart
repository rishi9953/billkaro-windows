import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// Searchable single-select dropdown for string values (state/city lists).
class SearchableStringDropdown extends StatefulWidget {
  const SearchableStringDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.searchHint = 'Search',
    this.validator,
    this.enabled = true,
    this.isLoading = false,
    this.decoration,
  });

  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Widget? label;
  final String? hintText;
  final String searchHint;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool isLoading;
  final InputDecoration? decoration;

  @override
  State<SearchableStringDropdown> createState() =>
      _SearchableStringDropdownState();
}

class _SearchableStringDropdownState extends State<SearchableStringDropdown> {
  late final TextEditingController _searchCtrl;
  late final ValueNotifier<String?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _valueListenable = ValueNotifier<String?>(_resolvedValue(widget.value));
  }

  @override
  void didUpdateWidget(covariant SearchableStringDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _resolvedValue(widget.value);
    if (next != _valueListenable.value) {
      _valueListenable.value = next;
    }
  }

  String? _resolvedValue(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (widget.items.contains(value)) return value;
    return null;
  }

  InputDecoration _effectiveDecoration() {
    final base = widget.decoration ??
        InputDecoration(
          label: widget.label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        );

    if (!widget.isLoading) return base;

    return base.copyWith(
      suffixIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.items.toList();
    final enabled = widget.enabled && !widget.isLoading;

    return DropdownButtonFormField2<String>(
      isExpanded: true,
      valueListenable: _valueListenable,
      decoration: _effectiveDecoration(),
      hint: Text(widget.hintText ?? 'Select'),
      items: entries
          .map(
            (name) => DropdownItem(
              value: name,
              child: Text(
                name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => entries
          .map(
            (name) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                name,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      validator: widget.validator,
      onChanged: enabled
          ? (value) {
              _valueListenable.value = value;
              widget.onChanged(value);
            }
          : null,
      onMenuStateChange: (isOpen) {
        if (!isOpen) _searchCtrl.clear();
      },
      iconStyleData: appDropdownIconStyle(color: AppColor.primary),
      dropdownStyleData: appDropdownMenuStyle(context: context, maxHeight: 320),
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
              hintText: widget.searchHint,
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) {
          final name = item.value?.toString() ?? '';
          return name.toLowerCase().contains(searchValue.toLowerCase());
        },
        noResultsWidget: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No results', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

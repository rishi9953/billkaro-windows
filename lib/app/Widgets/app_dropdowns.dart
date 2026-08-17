import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

BoxDecoration appFilterDropdownDecoration({
  Color? fillColor,
  double borderRadius = 12,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: fillColor ?? Colors.grey[50],
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor ?? Colors.grey[300]!),
  );
}

IconStyleData appDropdownIconStyle({Color? color, double size = 20}) {
  return IconStyleData(
    icon: Icon(Icons.keyboard_arrow_down, size: size, color: color),
  );
}

DropdownStyleData appDropdownMenuStyle({
  BuildContext? context,
  double maxHeight = 280,
  double? width,
  Offset offset = Offset.zero,
}) {
  return DropdownStyleData(
    maxHeight: maxHeight,
    width: width,
    offset: offset,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: context != null
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
  );
}

/// Form-field dropdown backed by [DropdownButtonFormField2].
class AppDropdownFormField2<T> extends StatefulWidget {
  const AppDropdownFormField2({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.decoration,
    this.validator,
    this.isExpanded = true,
    this.hint,
    this.disabledHint,
    this.iconStyleData,
    this.dropdownStyleData,
    this.menuItemStyleData,
    this.buttonStyleData,
    this.autovalidateMode,
    this.style,
    this.selectedItemBuilder,
  });

  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;
  final Widget? hint;
  final Widget? disabledHint;
  final IconStyleData? iconStyleData;
  final DropdownStyleData? dropdownStyleData;
  final MenuItemStyleData? menuItemStyleData;
  final FormFieldButtonStyleData? buttonStyleData;
  final AutovalidateMode? autovalidateMode;
  final TextStyle? style;
  final DropdownButtonBuilder? selectedItemBuilder;

  @override
  State<AppDropdownFormField2<T>> createState() =>
      _AppDropdownFormField2State<T>();
}

class _AppDropdownFormField2State<T> extends State<AppDropdownFormField2<T>> {
  late final ValueNotifier<T?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _valueListenable = ValueNotifier<T?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppDropdownFormField2<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueListenable.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField2<T>(
      isExpanded: widget.isExpanded,
      decoration: widget.decoration,
      hint: widget.hint,
      disabledHint: widget.disabledHint,
      style: widget.style,
      valueListenable: _valueListenable,
      items: widget.items,
      selectedItemBuilder: widget.selectedItemBuilder,
      onChanged: widget.onChanged == null
          ? null
          : (T? value) {
              _valueListenable.value = value;
              widget.onChanged!(value);
            },
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      iconStyleData: widget.iconStyleData ?? appDropdownIconStyle(),
      buttonStyleData:
          widget.buttonStyleData ??
          const FormFieldButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 4),
          ),
      dropdownStyleData:
          widget.dropdownStyleData ??
          appDropdownMenuStyle(context: context),
      menuItemStyleData:
          widget.menuItemStyleData ??
          const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 14),
          ),
    );
  }
}

/// Filter/toolbar dropdown with bordered container styling.
class AppFilterDropdown2<T> extends StatefulWidget {
  const AppFilterDropdown2({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.decoration,
    this.iconStyleData,
    this.dropdownStyleData,
    this.menuItemStyleData,
    this.style,
    this.hint,
    this.isExpanded = true,
  });

  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double height;
  final EdgeInsetsGeometry padding;
  final BoxDecoration? decoration;
  final IconStyleData? iconStyleData;
  final DropdownStyleData? dropdownStyleData;
  final MenuItemStyleData? menuItemStyleData;
  final TextStyle? style;
  final Widget? hint;
  final bool isExpanded;

  @override
  State<AppFilterDropdown2<T>> createState() => _AppFilterDropdown2State<T>();
}

class _AppFilterDropdown2State<T> extends State<AppFilterDropdown2<T>> {
  late final ValueNotifier<T?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _valueListenable = ValueNotifier<T?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppFilterDropdown2<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueListenable.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep height/padding on [ButtonStyleData] only — nesting a fixed-height
    // Container with padding caused a ~2px bottom RenderFlex overflow.
    return Container(
      width: double.infinity,
      decoration: widget.decoration ?? appFilterDropdownDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          isExpanded: widget.isExpanded,
          hint: widget.hint,
          style: widget.style,
          valueListenable: _valueListenable,
          items: widget.items,
          onChanged: widget.onChanged == null
              ? null
              : (T? value) {
                  _valueListenable.value = value;
                  widget.onChanged!(value);
                },
          buttonStyleData: ButtonStyleData(
            height: widget.height,
            width: double.infinity,
            padding: widget.padding,
          ),
          iconStyleData: widget.iconStyleData ?? appDropdownIconStyle(),
          dropdownStyleData:
              widget.dropdownStyleData ??
              appDropdownMenuStyle(context: context),
          menuItemStyleData:
              widget.menuItemStyleData ??
              const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
        ),
      ),
    );
  }
}

/// Popup-style action menu using [DropdownButton2.customButton].
class AppActionDropdown2<T> extends StatelessWidget {
  const AppActionDropdown2({
    super.key,
    required this.items,
    required this.onChanged,
    required this.customButton,
    this.dropdownStyleData,
    this.menuItemStyleData,
    this.buttonStyleData,
    this.offset = const Offset(0, -4),
    this.width = 160,
  });

  final List<DropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Widget customButton;
  final DropdownStyleData? dropdownStyleData;
  final MenuItemStyleData? menuItemStyleData;
  final ButtonStyleData? buttonStyleData;
  final Offset offset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        customButton: customButton,
        items: items,
        onChanged: onChanged,
        buttonStyleData:
            buttonStyleData ??
            const ButtonStyleData(padding: EdgeInsets.zero),
        dropdownStyleData:
            dropdownStyleData ??
            DropdownStyleData(
              width: width,
              offset: offset,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
        menuItemStyleData:
            menuItemStyleData ??
            const MenuItemStyleData(
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
      ),
    );
  }
}

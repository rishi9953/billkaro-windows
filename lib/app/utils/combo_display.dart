import 'package:billkaro/app/services/Modals/addItem/combo_component.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:flutter/material.dart';

class ComboDisplay {
  ComboDisplay._();

  static String? labelForItem(
    ItemData item,
    Map<String, ItemData> itemsById,
  ) {
    if (!item.isCombo || item.comboComponents.isEmpty) return null;
    return labelForComponents(item.comboComponents, itemsById);
  }

  static String? labelForComponents(
    List<ComboComponent> components,
    Map<String, ItemData> itemsById,
  ) {
    if (components.isEmpty) return null;
    final names = <String>[];
    for (final component in components) {
      final name = itemsById[component.itemId]?.itemName.trim();
      if (name != null && name.isNotEmpty) names.add(name);
    }
    if (names.isEmpty) return null;
    return '(include : ${names.join(' ')})';
  }
}

class ComboIncludesLabel extends StatelessWidget {
  const ComboIncludesLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

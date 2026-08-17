import 'package:billkaro/app/services/Modals/addItem/menu_item_variant.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductVariantsSection extends StatelessWidget {
  const ProductVariantsSection({
    super.key,
    required this.enabled,
    required this.variants,
    required this.onEnabledChanged,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.onSetDefault,
  });

  final bool enabled;
  final List<VariantDraft> variants;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onAddVariant;
  final ValueChanged<int> onRemoveVariant;
  final ValueChanged<int> onSetDefault;

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Variants',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppColor.primary,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            ...List.generate(variants.length, (index) {
              final draft = variants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: draft.nameController,
                        decoration: _fieldDecoration(context, 'e.g., Half, Full'),
                        validator: (value) {
                          if (!enabled) return null;
                          if ((value ?? '').trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: draft.priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: _fieldDecoration(context, 'Enter Price'),
                        validator: (value) {
                          if (!enabled) return null;
                          final parsed = double.tryParse((value ?? '').trim());
                          if (parsed == null || parsed < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Mark as default',
                      onPressed: () => onSetDefault(index),
                      icon: Icon(
                        draft.isDefault
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: draft.isDefault
                            ? AppColor.primary
                            : Colors.grey[400],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove variant',
                      onPressed: variants.length <= 1
                          ? null
                          : () => onRemoveVariant(index),
                      icon: Icon(
                        Icons.delete_outline,
                        color: variants.length <= 1
                            ? Colors.grey[300]
                            : Colors.red[400],
                      ),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddVariant,
                icon: Icon(Icons.add, color: AppColor.primary, size: 18),
                label: Text(
                  'Add Variant',
                  style: TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Text(
              'Mark one variant as default. Base price should match it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

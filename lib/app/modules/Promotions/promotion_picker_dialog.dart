import 'dart:math' as math;

import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/promotions/promotion_response.dart';
import 'package:billkaro/config/config.dart';

Future<PromotionFreeItem?> showPromotionPickerDialog({
  required PromotionData promotion,
  required Map<String, ItemData> itemsById,
}) {
  final choices = promotion.rewards.freeItems
      .where((entry) => itemsById.containsKey(entry.itemId))
      .toList();
  if (choices.isEmpty) return Future.value(null);

  final context = Get.context;
  final screenWidth = context != null
      ? MediaQuery.sizeOf(context).width
      : 400.0;
  final screenHeight = context != null
      ? MediaQuery.sizeOf(context).height
      : 700.0;

  return Get.dialog<PromotionFreeItem>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColor.cardSurface,
      child: SizedBox(
        width: math.min(420, screenWidth - 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
          child: _PromotionPickerDialog(
            promotion: promotion,
            choices: choices,
            itemsById: itemsById,
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

class _PromotionPickerDialog extends StatelessWidget {
  const _PromotionPickerDialog({
    required this.promotion,
    required this.choices,
    required this.itemsById,
  });

  final PromotionData promotion;
  final List<PromotionFreeItem> choices;
  final Map<String, ItemData> itemsById;

  @override
  Widget build(BuildContext context) {
    final minAmount = promotion.conditions.minOrderAmount.toStringAsFixed(0);
    final category = promotion.conditions.categoryName?.trim();
    final hasCategory = category != null && category.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.celebration_outlined,
                  color: AppColor.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offer unlocked!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promotion.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.secondaryPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCategory
                          ? '$category items above ₹$minAmount — pick one free'
                          : 'Order above ₹$minAmount — pick one free item',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: AppColor.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: choices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final choice = choices[index];
              final item = itemsById[choice.itemId]!;
              final label = choice.displayLabel(item.itemName);
              final category = item.category.trim();
              final showCategory =
                  category.isNotEmpty && category.toLowerCase() != 'none';

              return Material(
                color: AppColor.backGroundColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Get.back(result: choice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColor.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColor.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.local_cafe_outlined,
                            color: AppColor.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              if (showCategory)
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${item.salePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColor.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Skip for now'),
          ),
        ),
      ],
    );
  }
}

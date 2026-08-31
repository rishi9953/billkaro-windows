import 'package:billkaro/app/services/Modals/promotions/promotion_response.dart';
import 'package:billkaro/app/utils/promo_cart_line.dart';
import 'package:billkaro/app/utils/promotion_apply_result.dart';
import 'package:billkaro/app/utils/promotion_types.dart';

class PromotionEngine {
  const PromotionEngine._();

  static bool categoryMatches(String itemCategory, String ruleCategory) {
    final a = itemCategory.trim().toLowerCase();
    final b = ruleCategory.trim().toLowerCase();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  static bool itemMatches({
    required String? cartItemId,
    required String? cartVariantId,
    required String? ruleItemId,
    required String? ruleVariantId,
  }) {
    if (ruleItemId == null || ruleItemId.trim().isEmpty) return true;
    if (cartItemId != ruleItemId) return false;
    final variant = ruleVariantId?.trim();
    if (variant == null || variant.isEmpty) return true;
    return cartVariantId == variant;
  }

  static bool isScheduleActive(PromotionConditions conditions, DateTime now) {
    if (conditions.daysOfWeek.isNotEmpty &&
        !conditions.daysOfWeek.contains(now.weekday % 7)) {
      return false;
    }
    final start = _parseTime(conditions.startTime);
    final end = _parseTime(conditions.endTime);
    if (start == null || end == null) return true;

    final current = Duration(hours: now.hour, minutes: now.minute);
    if (start <= end) {
      return current >= start && current <= end;
    }
    return current >= start || current <= end;
  }

  static Duration? _parseTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return Duration(hours: h, minutes: m);
  }

  static double scopedSubtotal({
    required PromotionConditions conditions,
    required PromotionCartContext ctx,
    String? itemId,
    String? variantId,
  }) {
    var total = 0.0;
    for (final entry in ctx.itemQuantities.entries) {
      if (PromoCartLine.isPromo(entry.key)) continue;
      final lineItemId = ctx.lineItemId(entry.key);
      final lineVariantId = ctx.lineVariantId(entry.key);
      final category = ctx.lineCategory(entry.key) ?? '';
      if (conditions.hasCategoryScope &&
          !categoryMatches(category, conditions.categoryName!)) {
        continue;
      }
      if (!itemMatches(
        cartItemId: lineItemId,
        cartVariantId: lineVariantId,
        ruleItemId: itemId,
        ruleVariantId: variantId,
      )) {
        continue;
      }
      total += ctx.linePrice(entry.key) * entry.value;
    }
    return total;
  }

  static int scopedQuantity({
    required PromotionConditions conditions,
    required PromotionCartContext ctx,
    String? itemId,
    String? variantId,
  }) {
    var total = 0;
    for (final entry in ctx.itemQuantities.entries) {
      if (PromoCartLine.isPromo(entry.key)) continue;
      final lineItemId = ctx.lineItemId(entry.key);
      final lineVariantId = ctx.lineVariantId(entry.key);
      final category = ctx.lineCategory(entry.key) ?? '';
      if (conditions.hasCategoryScope &&
          !categoryMatches(category, conditions.categoryName!)) {
        continue;
      }
      if (!itemMatches(
        cartItemId: lineItemId,
        cartVariantId: lineVariantId,
        ruleItemId: itemId,
        ruleVariantId: variantId,
      )) {
        continue;
      }
      total += entry.value;
    }
    return total;
  }

  static double capDiscount(double amount, double base, double maxDiscount) {
    var result = amount;
    if (maxDiscount > 0) result = result.clamp(0, maxDiscount);
    return result.clamp(0, base);
  }

  static PromotionApplyResult? evaluate({
    required PromotionData rule,
    required PromotionCartContext ctx,
  }) {
    if (!rule.active) return null;
    if (!isScheduleActive(rule.conditions, ctx.now) &&
        rule.type == PromotionTypes.timeBased) {
      return null;
    }

    final type = rule.type;
    final conditions = rule.conditions;
    final rewards = rule.rewards;

    switch (type) {
      case PromotionTypes.spendThresholdFreeItem:
      case PromotionTypes.categorySpendThresholdFreeItem:
        final subtotal = scopedSubtotal(conditions: conditions, ctx: ctx);
        if (subtotal < conditions.minOrderAmount) {
          return null;
        }
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.pickFreeItem,
          freeQuantity: rewards.getQuantity,
        );

      case PromotionTypes.buyXGetY:
        final buyQty = conditions.buyQuantity > 0 ? conditions.buyQuantity : 1;
        final paidQty = scopedQuantity(
          conditions: conditions,
          ctx: ctx,
          itemId: conditions.itemId,
          variantId: conditions.variantId,
        );
        if (paidQty < buyQty) return null;
        final freeSets = paidQty ~/ buyQty;
        final freeQty = freeSets * (rewards.getQuantity > 0 ? rewards.getQuantity : 1);
        if (rewards.sameAsTrigger &&
            conditions.itemId != null &&
            conditions.itemId!.isNotEmpty) {
          return PromotionApplyResult(
            promotionId: rule.id,
            promotionName: rule.name,
            kind: PromotionApplyKind.autoFreeLine,
            freeQuantity: freeQty,
            sameAsTrigger: true,
          );
        }
        if (rewards.freeItems.isNotEmpty) {
          return PromotionApplyResult(
            promotionId: rule.id,
            promotionName: rule.name,
            kind: rewards.freeItems.length == 1
                ? PromotionApplyKind.autoFreeLine
                : PromotionApplyKind.pickFreeItem,
            freeQuantity: freeQty,
          );
        }
        return null;

      case PromotionTypes.amountThresholdDiscount:
        final subtotal = scopedSubtotal(conditions: conditions, ctx: ctx);
        if (subtotal < conditions.minOrderAmount) return null;
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: rewards.flatAmount,
        );

      case PromotionTypes.percentageThreshold:
        final subtotal = scopedSubtotal(conditions: conditions, ctx: ctx);
        if (subtotal < conditions.minOrderAmount) return null;
        final discount = subtotal * rewards.percent / 100;
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            discount,
            ctx.subtotal + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      case PromotionTypes.flatDiscount:
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            rewards.flatAmount,
            ctx.subtotal + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      case PromotionTypes.buyXPercentOff:
        final buyQty = conditions.buyQuantity > 0 ? conditions.buyQuantity : 2;
        final paidQty = scopedQuantity(
          conditions: conditions,
          ctx: ctx,
          itemId: conditions.itemId,
          variantId: conditions.variantId,
        );
        if (paidQty < buyQty) return null;
        final base = scopedSubtotal(
          conditions: conditions,
          ctx: ctx,
          itemId: conditions.itemId,
          variantId: conditions.variantId,
        );
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            base * rewards.percent / 100,
            ctx.subtotal + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      case PromotionTypes.productSpecific:
        final buyQty = conditions.buyQuantity > 0 ? conditions.buyQuantity : 2;
        final paidQty = scopedQuantity(
          conditions: conditions,
          ctx: ctx,
          itemId: conditions.itemId,
          variantId: conditions.variantId,
        );
        if (paidQty < buyQty) return null;
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            rewards.flatAmount,
            ctx.subtotal + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      case PromotionTypes.categoryPercent:
        if (!conditions.hasCategoryScope) return null;
        final base = scopedSubtotal(conditions: conditions, ctx: ctx);
        if (base <= 0) return null;
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            base * rewards.percent / 100,
            ctx.subtotal + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      case PromotionTypes.timeBased:
        if (!isScheduleActive(conditions, ctx.now)) return null;
        final base = ctx.subtotal;
        if (rewards.flatAmount > 0) {
          return PromotionApplyResult(
            promotionId: rule.id,
            promotionName: rule.name,
            kind: PromotionApplyKind.discount,
            discountAmount: capDiscount(
              rewards.flatAmount,
              base + ctx.totalTax,
              rewards.maxDiscount,
            ),
          );
        }
        return PromotionApplyResult(
          promotionId: rule.id,
          promotionName: rule.name,
          kind: PromotionApplyKind.discount,
          discountAmount: capDiscount(
            base * rewards.percent / 100,
            base + ctx.totalTax,
            rewards.maxDiscount,
          ),
        );

      default:
        return null;
    }
  }

  static String summary(PromotionData promotion) {
    final c = promotion.conditions;
    final r = promotion.rewards;
    switch (promotion.type) {
      case PromotionTypes.buyXGetY:
        return 'Buy ${c.buyQuantity} → get ${r.getQuantity} free';
      case PromotionTypes.amountThresholdDiscount:
        return '₹${c.minOrderAmount.toStringAsFixed(0)}+ → ₹${r.flatAmount.toStringAsFixed(0)} off';
      case PromotionTypes.percentageThreshold:
        return '₹${c.minOrderAmount.toStringAsFixed(0)}+ → ${r.percent.toStringAsFixed(0)}% off';
      case PromotionTypes.flatDiscount:
        return '₹${r.flatAmount.toStringAsFixed(0)} off order';
      case PromotionTypes.buyXPercentOff:
        return 'Buy ${c.buyQuantity} → ${r.percent.toStringAsFixed(0)}% off';
      case PromotionTypes.productSpecific:
        return 'Buy ${c.buyQuantity} → ₹${r.flatAmount.toStringAsFixed(0)} off';
      case PromotionTypes.categoryPercent:
        return '${c.categoryName} → ${r.percent.toStringAsFixed(0)}% off';
      case PromotionTypes.timeBased:
        return '${c.startTime}-${c.endTime} → ${r.percent.toStringAsFixed(0)}% off';
      default:
        if (c.hasCategoryScope) {
          return '${c.categoryName} ₹${c.minOrderAmount.toStringAsFixed(0)}+ → free item';
        }
        return '₹${c.minOrderAmount.toStringAsFixed(0)}+ → free item';
    }
  }
}

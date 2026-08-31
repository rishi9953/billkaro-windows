import 'package:flutter/material.dart';

class PromotionTypes {
  const PromotionTypes._();

  static const buyXGetY = 'BUY_X_GET_Y';
  static const amountThresholdDiscount = 'AMOUNT_THRESHOLD_DISCOUNT';
  static const percentageThreshold = 'PERCENTAGE_THRESHOLD';
  static const flatDiscount = 'FLAT_DISCOUNT';
  static const buyXPercentOff = 'BUY_X_PERCENT_OFF';
  static const productSpecific = 'PRODUCT_SPECIFIC';
  static const categoryPercent = 'CATEGORY_PERCENT';
  static const timeBased = 'TIME_BASED';
  static const spendThresholdFreeItem = 'SPEND_THRESHOLD_FREE_ITEM';
  static const categorySpendThresholdFreeItem =
      'CATEGORY_SPEND_THRESHOLD_FREE_ITEM';

  static const all = [
    buyXGetY,
    amountThresholdDiscount,
    percentageThreshold,
    flatDiscount,
    buyXPercentOff,
    productSpecific,
    categoryPercent,
    timeBased,
    spendThresholdFreeItem,
  ];

  static String label(String type) {
    switch (type) {
      case buyXGetY:
        return 'Buy X Get Y';
      case amountThresholdDiscount:
        return 'Amount discount';
      case percentageThreshold:
        return 'Percentage discount';
      case flatDiscount:
        return 'Flat discount';
      case buyXPercentOff:
        return 'Buy X Get % Off';
      case productSpecific:
        return 'Product offer';
      case categoryPercent:
        return 'Category discount';
      case timeBased:
        return 'Time-based offer';
      case spendThresholdFreeItem:
      case categorySpendThresholdFreeItem:
        return 'Free item on spend';
      default:
        return type;
    }
  }

  static String example(String type) {
    switch (type) {
      case buyXGetY:
        return 'Buy 1 Pizza → Get 1 Free';
      case amountThresholdDiscount:
        return '₹250+ → ₹30 off';
      case percentageThreshold:
        return '₹500+ → 10% off';
      case flatDiscount:
        return '₹100 off order';
      case buyXPercentOff:
        return 'Buy 2 → 20% off';
      case productSpecific:
        return 'Buy 2 Coke → ₹10 off';
      case categoryPercent:
        return 'Snacks → 10% off';
      case timeBased:
        return '2 PM – 5 PM → 10% off';
      case spendThresholdFreeItem:
      case categorySpendThresholdFreeItem:
        return '₹250+ → free coffee';
      default:
        return '';
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case buyXGetY:
        return Icons.redeem_outlined;
      case amountThresholdDiscount:
      case flatDiscount:
      case productSpecific:
        return Icons.currency_rupee;
      case percentageThreshold:
      case buyXPercentOff:
      case categoryPercent:
      case timeBased:
        return Icons.percent;
      case spendThresholdFreeItem:
      case categorySpendThresholdFreeItem:
        return Icons.card_giftcard_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  static bool isFreeItemType(String type) {
    return type == buyXGetY ||
        type == spendThresholdFreeItem ||
        type == categorySpendThresholdFreeItem;
  }

  static bool isDiscountType(String type) {
    return !isFreeItemType(type);
  }
}

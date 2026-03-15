// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SplitPayment _$SplitPaymentFromJson(Map<String, dynamic> json) => SplitPayment(
  paymentMethod: json['paymentMethod'] as String,
  amount: (json['amount'] as num).toDouble(),
);

Map<String, dynamic> _$SplitPaymentToJson(SplitPayment instance) =>
    <String, dynamic>{
      'paymentMethod': instance.paymentMethod,
      'amount': instance.amount,
    };

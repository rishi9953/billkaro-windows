import 'package:json_annotation/json_annotation.dart';

part 'split_payment.g.dart';

@JsonSerializable()
class SplitPayment {
  final String paymentMethod; // 'cash', 'card', 'upi', etc.
  final double amount;

  SplitPayment({
    required this.paymentMethod,
    required this.amount,
  });

  factory SplitPayment.fromJson(Map<String, dynamic> json) =>
      _$SplitPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$SplitPaymentToJson(this);
}


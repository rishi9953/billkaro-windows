class ComboComponent {
  final String itemId;
  final double quantity;

  const ComboComponent({required this.itemId, required this.quantity});

  factory ComboComponent.fromJson(Map<String, dynamic> json) {
    return ComboComponent(
      itemId: json['itemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantity};
}

import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class CartLineOfferDetails extends StatelessWidget {
  const CartLineOfferDetails({
    super.key,
    this.offerName,
    this.offerDetail,
    this.compact = false,
  });

  final String? offerName;
  final String? offerDetail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = offerName?.trim();
    final detail = offerDetail?.trim();
    if ((name == null || name.isEmpty) && (detail == null || detail.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Text(
        [if (name != null && name.isNotEmpty) name, if (detail != null && detail.isNotEmpty) detail]
            .join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          color: AppColor.success,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null && name.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 12, color: AppColor.success),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.success,
                  ),
                ),
              ),
            ],
          ),
        if (detail != null && detail.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: name != null && name.isNotEmpty ? 2 : 0),
            child: Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:billkaro/utils/gstin_verify_helper.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GstinVerifyRow extends StatelessWidget {
  const GstinVerifyRow({
    super.key,
    required this.helper,
    required this.onVerify,
    this.ownerOnly = true,
    this.alignEnd = false,
  });

  final GstinVerifyHelper helper;
  final VoidCallback onVerify;
  final bool ownerOnly;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    if (ownerOnly && !StaffAccess.isOwnerSession) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final message = helper.gstinVerificationMessage.value;
      final messageStyle = TextStyle(
        color: helper.isGstinVerified.value ? Colors.green : Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

      final verifyButton = SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: helper.isVerifyingGstin.value ? null : onVerify,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: helper.isVerifyingGstin.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify'),
        ),
      );

      if (alignEnd) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (message.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    message,
                    style: messageStyle,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            verifyButton,
          ],
        );
      }

      return Row(
        children: [
          verifyButton,
          if (message.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  message,
                  style: messageStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      );
    });
  }
}

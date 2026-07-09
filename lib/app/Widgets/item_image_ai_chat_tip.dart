import 'package:billkaro/config/config.dart';

/// Chat-style tip explaining item image upload and Generate with AI.
class ItemImageAiChatTip extends StatelessWidget {
  const ItemImageAiChatTip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final avatarSize = compact ? 34.0 : 40.0;
    final iconSize = compact ? 18.0 : 20.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColor.primary.withOpacity(0.85),
                AppColor.primary,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppColor.primary.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.item_image_ai_chat_assistant,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  loc.add_images_ai_title,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  loc.item_image_ai_chat_message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 12 : 13,
                    color: Colors.grey[700],
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

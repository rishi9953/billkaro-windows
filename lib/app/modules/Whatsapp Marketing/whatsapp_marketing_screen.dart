import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class WhatsappMarketingScreen extends StatelessWidget {
  WhatsappMarketingScreen({super.key});
  final controller = Get.put(WhatsappMarketingController());

  void _goBack() {
    // This screen is only opened from `MenuScreen`, so return explicitly.
    Modular.to.navigate(HomeMainRoutes.menu);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      // Ensure any back/pop attempt (hardware/gesture) goes through our Modular logic.
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // This screen is opened with `Modular.to.pushNamed(...)`,
            // so we must pop using Modular/Navigator (not GetX).
            onPressed: _goBack,
          ),
          title: Text(
            loc.select_message_template,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColor.white,
            ),
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                Text(
                  loc.choose_whatsapp_template_hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTemplateCard(
                  context: context,
                  loc: loc,
                  icon: Icons.discount_rounded,
                  title: loc.discount_offer,
                  description: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: loc.template_discount_preview_prefix),
                        TextSpan(
                          text: loc.restaurant_name_placeholder,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: loc.template_discount_get),
                        TextSpan(
                          text: loc.discount_value_placeholder,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: loc.template_discount_suffix),
                      ],
                    ),
                  ),
                  onTap: () => controller.showCustomFieldsDialog(
                    'discount',
                    '',
                    '',
                  ),
                ),
                const SizedBox(height: 12),
                _buildTemplateCard(
                  context: context,
                  loc: loc,
                  icon: Icons.menu_book_rounded,
                  title: loc.new_menu,
                  description: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: loc.restaurant_name_placeholder,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: loc.template_new_menu_suffix),
                      ],
                    ),
                  ),
                  onTap: () => controller.showCustomFieldsDialog('menu', '', ''),
                ),
                const SizedBox(height: 12),
                _buildTemplateCard(
                  context: context,
                  loc: loc,
                  icon: Icons.celebration_rounded,
                  title: loc.festival_wishes,
                  description: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: loc.restaurant_name_placeholder,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: loc.template_festival_wishes_you),
                        TextSpan(
                          text: loc.festival_name_placeholder,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: loc.template_festival_suffix),
                      ],
                    ),
                  ),
                  onTap: () => controller.showCustomFieldsDialog(
                    'festival',
                    '',
                    '',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required AppLocalizations loc,
    required IconData icon,
    required String title,
    required Widget description,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: colorScheme.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              description,
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 160,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(loc.use_template),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

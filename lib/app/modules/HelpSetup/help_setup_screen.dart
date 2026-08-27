import 'package:billkaro/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSetupScreen extends StatelessWidget {
  HelpSetupScreen({super.key});

  static const _supportPhone = '+919582222724';
  static const _whatsappPhone = '916364444752';
  // static const _liveChatWhatsapp = '9350413656';
  static const _supportEmail = 'support@bill-kro.com';

  final AppPref _appPref = Get.find<AppPref>();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final primary = AppColor.primary;
    final user = _appPref.user;
    final outlet = _appPref.selectedOutlet;

    final userIdRaw = (user?.userId ?? user?.id ?? '').trim();
    final displayUserId = userIdRaw.isEmpty
        ? '—'
        : userIdRaw.toLowerCase().startsWith('customer')
            ? userIdRaw
            : 'Customer-$userIdRaw';
    final displayName = (user?.firstName?.trim().isNotEmpty == true
            ? user!.firstName!
            : (user?.brandName ?? user?.userName ?? '—'))
        .trim();
    final displayEmail =
        (user?.email?.trim().isNotEmpty == true) ? user!.email! : '—';
    final displayRestaurant =
        (outlet?.businessName?.trim().isNotEmpty == true)
            ? outlet!.businessName!
            : (user?.brandName ?? '—');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: AppColor.white,
        title: Text(
          loc.help_and_setup,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                children: [
                  _buildHero(primary, loc),
                  const Gap(20),
                  _buildCard(
                    title: loc.help_your_account,
                    child: Column(
                      children: [
                        _accountRow(
                          icon: Icons.smartphone_outlined,
                          label: loc.help_user_id,
                          value: displayUserId,
                          primary: primary,
                        ),
                        const Gap(14),
                        _accountRow(
                          icon: Icons.person_outline_rounded,
                          label: loc.help_name,
                          value: displayName,
                          primary: primary,
                        ),
                        const Gap(14),
                        _accountRow(
                          icon: Icons.mail_outline_rounded,
                          label: loc.email,
                          value: displayEmail,
                          primary: primary,
                        ),
                        const Gap(14),
                        _accountRow(
                          icon: Icons.storefront_outlined,
                          label: loc.help_restaurant,
                          value: displayRestaurant,
                          primary: primary,
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  _buildCard(
                    title: loc.help_quick_setup,
                    child: Column(
                      children: [
                        _setupStep(
                          1,
                          loc.help_setup_step_1,
                          primary,
                        ),
                        const Gap(14),
                        _setupStep(
                          2,
                          loc.help_setup_step_2,
                          primary,
                        ),
                        const Gap(14),
                        _setupStep(
                          3,
                          loc.help_setup_step_3,
                          primary,
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  _buildCard(
                    title: loc.help_contact_support,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _contactButton(
                                label: loc.help_call_us,
                                icon: Icons.phone_rounded,
                                background: primary,
                                foreground: AppColor.white,
                                onTap: () => _launchUri(
                                  Uri(scheme: 'tel', path: _supportPhone),
                                ),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: _contactButton(
                                label: loc.help_whatsapp,
                                icon: Icons.chat_rounded,
                                background: const Color(0xFF25D366),
                                foreground: AppColor.white,
                                onTap: () => _launchUri(
                                  Uri.parse(
                                    'https://api.whatsapp.com/send?phone=$_whatsappPhone',
                                  ),
                                  external: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            // Expanded(
                            //   child: _contactButton(
                            //     label: loc.help_live_chat,
                            //     icon: Icons.forum_outlined,
                            //     background: const Color(0xFF5BA3D9),
                            //     foreground: AppColor.white,
                            //     onTap: () => _launchUri(
                            //       Uri.parse(
                            //         'https://api.whatsapp.com/send?phone=$_liveChatWhatsapp',
                            //       ),
                            //       external: true,
                            //     ),
                            //   ),
                            // ),
                            // const Gap(12),
                            Expanded(
                              child: _contactButton(
                                label: loc.email,
                                icon: Icons.email_outlined,
                                background: const Color(0xFF1A2B4A),
                                foreground: AppColor.white,
                                onTap: () => _launchUri(
                                  Uri.parse(
                                    'mailto:$_supportEmail?subject=${Uri.encodeComponent(loc.support_request)}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),
                        Text(
                          loc.help_support_hours,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Color primary, AppLocalizations loc) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.support_outlined,
            size: 42,
            color: primary,
          ),
        ),
        const Gap(14),
        Text(
          loc.help_were_here,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        const Gap(6),
        Text(
          loc.help_subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }

  Widget _accountRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primary.withOpacity(0.85)),
        const Gap(10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _setupStep(int number, String text, Color primary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const Gap(8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri, {bool external = false}) async {
    try {
      final ok = await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
      if (!ok) {
        showError(description: 'Could not open link');
      }
    } catch (_) {
      showError(description: 'Could not open link');
    }
  }
}

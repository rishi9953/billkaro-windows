import 'package:billkaro/utils/exit_confirm_helper.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Custom title bar for Windows when using [bitsdojo_window] with a frameless
/// window — native min/max/close are hidden, so these controls must be drawn.
class WindowsDesktopTitleBar extends StatelessWidget {
  const WindowsDesktopTitleBar({super.key, this.actions});

  /// Shown on the right, immediately before the minimize / maximize / close
  /// buttons (e.g. language or settings on onboarding screens).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      fontSize: 11.5,
      color: Color(0xFF69B6FF),
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF69B6FF),
      fontWeight: FontWeight.w500,
    );
    const textStyle = TextStyle(
      fontSize: 11.5,
      color: Color(0xFFE5E7EB),
      fontWeight: FontWeight.w500,
    );

    final buttonColors = WindowButtonColors(
      iconNormal: Colors.white70,
      mouseOver: const Color(0xFF2A2F34),
      mouseDown: const Color(0xFF1D2228),
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return WindowTitleBarBox(
      child: Container(
        height: 34,
        color: const Color(0xFF15191D),
        child: Row(
          children: [
            const SizedBox(
              width: 180,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Billkaro ChillKaro',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MoveWindow(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopBarLink(
                          label: 'Request a Callback',
                          onTap: () => _launchExternal(
                            'https://api.whatsapp.com/send?phone=916364444752',
                          ),
                          style: linkStyle,
                        ),
                        const SizedBox(width: 10),
                        const Text('|', style: textStyle),
                        const SizedBox(width: 10),
                        const Text('Customer Support :', style: textStyle),
                        const SizedBox(width: 6),
                        _TopBarLink(
                          label: '+91-9350413656',
                          onTap: () => _launchPhone('+919350413656'),
                          style: linkStyle,
                        ),
                        const SizedBox(width: 4),
                        const Text(',', style: textStyle),
                        const SizedBox(width: 4),
                        _TopBarLink(
                          label: '+91-9333911191',
                          onTap: () => _launchPhone('+919333911191'),
                          style: linkStyle,
                        ),
                        const SizedBox(width: 10),
                        const Text('|', style: textStyle),
                        const SizedBox(width: 10),
                        _TopBarLink(
                          label: 'support@billkaro.com',
                          onTap: () => _launchEmail('support@billkaro.com'),
                          style: linkStyle,
                        ),
                        const SizedBox(width: 10),
                        const Text('|', style: textStyle),
                        const SizedBox(width: 10),
                        _TopBarLink(
                          label: 'Get Instant Online Support',
                          onTap: () => _launchExternal(
                            'https://api.whatsapp.com/send?phone=9350413656',
                          ),
                          style: linkStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...actions!,
            Row(
              children: [
                MinimizeWindowButton(colors: buttonColors),
                MaximizeWindowButton(colors: buttonColors),
                CloseWindowButton(
                  colors: WindowButtonColors(
                    mouseOver: const Color(0xFFD32F2F),
                    mouseDown: const Color(0xFFB71C1C),
                    iconNormal: Colors.white70,
                    iconMouseOver: Colors.white,
                  ),
                  onPressed: () async {
                    if (!context.mounted) return;
                    if (await ExitConfirmHelper.shouldExitAfterPrompt(context)) {
                      if (!context.mounted) return;
                      appWindow.close();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _TopBarLink extends StatelessWidget {
  const _TopBarLink({
    required this.label,
    required this.onTap,
    required this.style,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label, style: style),
      ),
    );
  }
}

import 'dart:io';

import 'package:billkaro/app/Widgets/app_shell_sidebar.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart' as modular;
import 'package:showcaseview/showcaseview.dart';

class HomeMainShell extends StatefulWidget {
  const HomeMainShell({super.key});

  @override
  State<HomeMainShell> createState() => _HomeMainShellState();
}

class _HomeMainShellState extends State<HomeMainShell> {
  final showcaseController = Get.put(ShowcaseController());
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    Get.put(HomeMainController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (modular.Modular.to.path.isEmpty ||
          modular.Modular.to.path == HomeMainRoutes.shell) {
        modular.Modular.to.navigate(HomeMainRoutes.home);
      }
    });
  }

  void _maybeStartShowcase() {
    if (showcaseController.shellShowcaseArmConsumed || !mounted) {
      return;
    }

    showcaseController.markShellShowcaseStarted();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showcaseController.startHomeShowcase(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () => showcaseController.markShowcaseCompleted(),
      builder: (_) {
        return modular.NavigationListener(
          builder: (context, _) {
            final selectedIndex = HomeMainRoutes.selectedIndexForPath(
              modular.Modular.to.path,
            );

            if (showcaseController.shouldShowShowcase() &&
                !showcaseController.shellShowcaseArmConsumed &&
                modular.Modular.to.path == HomeMainRoutes.home) {
              _maybeStartShowcase();
            }

            return Scaffold(
              body: Column(
                children: [
                  if (_isWindowsDesktop) const WindowsDesktopTitleBar(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppShellSidebar(
                          selectedIndex: selectedIndex,
                          collapsed: _sidebarCollapsed,
                          onToggleCollapsed: () {
                            setState(
                              () => _sidebarCollapsed = !_sidebarCollapsed,
                            );
                          },
                        ),
                        const SizedBox(
                          height: double.infinity,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Color(0xFF3D4558),
                          ),
                        ),
                        const Expanded(child: modular.RouterOutlet()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;
}

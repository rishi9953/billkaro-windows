import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:showcaseview/showcaseview.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final showcaseController = Get.find<ShowcaseController>();

    return Container(
      decoration: BoxDecoration(
        color:  AppColor.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _navItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: loc.homeTitle,
                    index: 0,
                    showcaseKey: showcaseController.bottomNavHomeKey,
                    showcaseTitle: 'Home',
                    showcaseDescription:
                        'Go back to the dashboard and quick actions.',
                    svgIcon: Assets.svg.home.svg(
                      width: 24,
                      height: 24,
                      color: selectedIndex == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  _navItem(
                    icon: Icons.local_bar_outlined,
                    activeIcon: Icons.bar_chart,
                    label: loc.items,
                    index: 1,
                    showcaseKey: showcaseController.bottomNavItemsKey,
                    showcaseTitle: 'Items',
                    showcaseDescription: 'Manage menu items and categories.',
                    svgIcon: Assets.svg.items.svg(
                      width: 24,
                      height: 24,
                      color: selectedIndex == 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Showcase(
                    key: showcaseController.bottomNavCreateKey,
                    title: 'Create Order',
                    description: 'Start a new order/bill quickly from here.',
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    descTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    overlayColor: Colors.black54,
                    overlayOpacity: 0.7,
                    tooltipBackgroundColor: AppColor.primary,
                    textColor: Colors.white,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xffef8819), Color(0xffff9933)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xffef8819).withOpacity(0.5),
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.white, size: 30),
                        onPressed: () => onItemTapped(2),
                      ),
                    ),
                  ),
                  _navItem(
                    icon: Icons.signal_cellular_alt_outlined,
                    activeIcon: Icons.inventory_2,
                    label: loc.reports,
                    index: 3,
                    showcaseKey: showcaseController.bottomNavReportsKey,
                    showcaseTitle: 'Reports',
                    showcaseDescription:
                        'View reports, analytics and export data.',
                    svgIcon: Assets.svg.reports.svg(
                      width: 24,
                      height: 24,
                      color: selectedIndex == 3
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  _navItem(
                    icon: Icons.menu,
                    activeIcon: Icons.person,
                    label: loc.menu,
                    index: 4,
                    showcaseKey: showcaseController.bottomNavMenuKey,
                    showcaseTitle: 'Menu',
                    showcaseDescription: 'Open settings and more options.',
                    svgIcon: Assets.svg.menu.svg(
                      width: 24,
                      height: 24,
                      color: selectedIndex == 4
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Widget svgIcon,
    GlobalKey? showcaseKey,
    String? showcaseTitle,
    String? showcaseDescription,
  }) {
    final isSelected = selectedIndex == index;

    final child = InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgIcon,
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );

    if (showcaseKey == null) return child;

    return Showcase(
      key: showcaseKey,
      title: showcaseTitle ?? label,
      description: showcaseDescription ?? 'Tap to open this section.',
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      descTextStyle: const TextStyle(fontSize: 14, color: Colors.white70),
      overlayColor: Colors.black54,
      overlayOpacity: 0.7,
      tooltipBackgroundColor: AppColor.primary,
      textColor: Colors.white,
      child: child,
    );
  }
}

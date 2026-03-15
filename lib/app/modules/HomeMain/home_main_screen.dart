import 'package:billkaro/app/Widgets/custom_bottombar.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_screen.dart';
import 'package:billkaro/app/modules/Reports/reports_screen.dart';
import 'package:billkaro/config/config.dart';
import 'package:showcaseview/showcaseview.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  final controller = Get.put(HomeMainController());
  final showcaseController = Get.put(ShowcaseController());
  int _selectedIndex = 0;
  bool _showcaseStarted = false;

  @override
  void initState() {
    super.initState();
    // Check and start showcase only once when screen is first created
    if (showcaseController.shouldShowShowcase()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showcaseStarted) {
          _showcaseStarted = true;
          showcaseController.startHomeShowcase(context);
        }
      });
    }
  }

  // Define your screens here
  final List<Widget> _screens = [
    HomeScreen(),
    MenuItemScreen(),
    const Center(child: Text('Create Screen')), // Placeholder
    ReportsScreen(),
    const SizedBox(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Handle create button tap differently (show modal or navigate)
      Get.toNamed(AppRoute.addOrder);
      return;
    }
    if (index == 4) {
      Get.toNamed(AppRoute.menu);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () => showcaseController.markShowcaseCompleted(),
      builder: (ctx) {
        // Showcase is started in initState, no need to check here again
        return Scaffold(
          body: Column(
            children: [
              Expanded(child: _screens[_selectedIndex]),
              CustomBottomBar(
                selectedIndex: _selectedIndex,
                onItemTapped: (int index) {
                  _onItemTapped(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

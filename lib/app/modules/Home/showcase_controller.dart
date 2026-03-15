import 'package:billkaro/config/config.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseController extends BaseController {
  final GlobalKey _outletSwitcherKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _printerBannerKey = GlobalKey();
  final GlobalKey _quickActionsHeaderKey = GlobalKey();
  final GlobalKey _closedOrdersKey = GlobalKey();
  final GlobalKey _holdOrdersKey = GlobalKey();
  final GlobalKey _addOrderKey = GlobalKey();
  final GlobalKey _addItemsKey = GlobalKey();
  final GlobalKey _kotHistoryKey = GlobalKey();
  final GlobalKey _businessOverviewKey = GlobalKey();
  final GlobalKey _salesChartKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  // Bottom navigation
  final GlobalKey _bottomNavHomeKey = GlobalKey();
  final GlobalKey _bottomNavItemsKey = GlobalKey();
  final GlobalKey _bottomNavCreateKey = GlobalKey();
  final GlobalKey _bottomNavReportsKey = GlobalKey();
  final GlobalKey _bottomNavMenuKey = GlobalKey();
  final GlobalKey _bottomNavMicKey = GlobalKey();

  GlobalKey get outletSwitcherKey => _outletSwitcherKey;
  GlobalKey get profileKey => _profileKey;
  GlobalKey get printerBannerKey => _printerBannerKey;
  GlobalKey get quickActionsHeaderKey => _quickActionsHeaderKey;
  GlobalKey get closedOrdersKey => _closedOrdersKey;
  GlobalKey get holdOrdersKey => _holdOrdersKey;
  GlobalKey get addOrderKey => _addOrderKey;
  GlobalKey get addItemsKey => _addItemsKey;
  GlobalKey get kotHistoryKey => _kotHistoryKey;
  GlobalKey get businessOverviewKey => _businessOverviewKey;
  GlobalKey get salesChartKey => _salesChartKey;
  GlobalKey get featuresKey => _featuresKey;
  GlobalKey get testimonialsKey => _testimonialsKey;
  GlobalKey get bottomNavHomeKey => _bottomNavHomeKey;
  GlobalKey get bottomNavItemsKey => _bottomNavItemsKey;
  GlobalKey get bottomNavCreateKey => _bottomNavCreateKey;
  GlobalKey get bottomNavReportsKey => _bottomNavReportsKey;
  GlobalKey get bottomNavMenuKey => _bottomNavMenuKey;
  GlobalKey get bottomNavMicKey => _bottomNavMicKey;

  /// Check if showcase should be shown
  bool shouldShowShowcase() {
    return !appPref.isShowcaseCompleted;
  }

  /// Mark showcase as completed
  void markShowcaseCompleted() {
    appPref.isShowcaseCompleted = true;
  }

  /// Start showcase for home screen
  void startHomeShowcase(BuildContext context) {
    if (shouldShowShowcase()) {
      // Longer delay to ensure widgets are fully built
      Future.delayed(const Duration(milliseconds: 1000), () {
        try {
          final showcaseWidget = ShowCaseWidget.of(context);
          final keys = <GlobalKey>[
            _outletSwitcherKey,
            _profileKey,
            _printerBannerKey,
            _quickActionsHeaderKey,
            _closedOrdersKey,
            _holdOrdersKey,
            _addItemsKey,
            if (appPref.isKOT) _kotHistoryKey,
            _businessOverviewKey,
            _salesChartKey,
            _featuresKey,
            _testimonialsKey,
            // Bottom navigation (last)
            _bottomNavHomeKey,
            _bottomNavItemsKey,
            _bottomNavCreateKey,
            _bottomNavReportsKey,
            _bottomNavMenuKey,
            _bottomNavMicKey,
          ];
          showcaseWidget.startShowCase(keys);
        } catch (e) {
          debugPrint('⚠️ Showcase error: $e');
        }
      });
    }
  }

  /// Reset showcase (for testing or re-showing)
  void resetShowcase() {
    appPref.isShowcaseCompleted = false;
  }
}


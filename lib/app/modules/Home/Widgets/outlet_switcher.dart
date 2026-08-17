import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

/// App bar control that opens an outlet list as a dropdown menu.
class OutletSwitcherButton extends StatefulWidget {
  const OutletSwitcherButton({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  State<OutletSwitcherButton> createState() => _OutletSwitcherButtonState();
}

class _OutletSwitcherButtonState extends State<OutletSwitcherButton> {
  final GlobalKey _anchorKey = GlobalKey();

  static const String _manageOutletsValue = '__manage_outlets__';
  static const String _ownerPanelValue = '__owner_panel__';

  AppLocalizations get _loc => AppLocalizations.of(context)!;

  Future<void> _openMenu() async {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;

    final box = anchorContext.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;

    final outlets = widget.controller.appPref.allOutlets;
    final selectedId = widget.controller.selectedOutlet.value?.id;

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + size.height + 6,
        size.width.clamp(260, 300),
        0,
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: anchorContext,
      position: position,
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.14),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 300,
        maxHeight: 420,
      ),
      items: _buildMenuItems(outlets, selectedId),
    );

    if (!mounted || result == null) return;

    if (result == _ownerPanelValue) {
      if (StaffAccess.isStaffSession) return;
      Get.toNamed(AppRoute.ownerPanel);
      return;
    }

    if (result == _manageOutletsValue) {
      if (StaffAccess.isStaffSession) return;
      widget.controller.showOutletBottomSheet(context);
      return;
    }

    final outlet = outlets.firstWhereOrNull((o) => o.id == result);
    if (outlet != null) {
      widget.controller.selectOutlet(outlet, closeSheet: false);
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    List<OutletData> outlets,
    String? selectedId,
  ) {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        padding: EdgeInsets.zero,
        height: 48,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 16,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _loc.home_switch_outlet,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${outlets.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    if (outlets.isEmpty) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          height: 88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                _loc.home_no_outlets_available,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      for (final outlet in outlets) {
        final id = outlet.id;
        if (id == null || id.isEmpty) continue;
        final isSelected = id == selectedId;
        items.add(
          PopupMenuItem<String>(
            value: id,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            height: 62,
            child: _OutletMenuTile(
              name: (outlet.businessName ?? _loc.home_unnamed_outlet).capitalizeFirst!,
              logoUrl: outlet.logo,
              businessType: outlet.businessType,
              isSelected: isSelected,
            ),
          ),
        );
      }
    }

    items.add(const PopupMenuDivider(height: 1));
    if (!StaffAccess.isStaffSession) {
      items.add(
        PopupMenuItem<String>(
          value: _ownerPanelValue,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          height: 52,
          child: _MenuActionTile(
            icon: Icons.dashboard_customize_outlined,
            label: _loc.owner_panel_menu,
          ),
        ),
      );
      items.add(
        PopupMenuItem<String>(
          value: _manageOutletsValue,
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          height: 52,
          child: _MenuActionTile(
            icon: Icons.tune_rounded,
            label: _loc.home_manage_outlets,
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildOutletChip({
    required String name,
    required OutletData? selected,
    required bool interactive,
  }) {
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        key: interactive ? _anchorKey : null,
        onTap: interactive ? _openMenu : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _OutletLogoAvatar(
                logoUrl: selected?.logo,
                name: name,
                size: 26,
                borderRadius: 6,
                onDarkBackground: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(0.92),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = widget.controller.selectedOutlet.value;
      final name = widget.controller.selectedOutletName.capitalizeFirst!;
      final isStaff = StaffAccess.isStaffSession;
      // Owners can open the menu even with a single outlet (manage / create outlet).
      final canOpenOutletMenu = !isStaff;

      return _buildOutletChip(
        name: name,
        selected: selected,
        interactive: canOpenOutletMenu,
      );
    });
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColor.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.primary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColor.primary.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

class _OutletLogoAvatar extends StatelessWidget {
  const _OutletLogoAvatar({
    required this.logoUrl,
    required this.name,
    required this.size,
    this.borderRadius = 8,
    this.onDarkBackground = false,
    this.isSelected = false,
  });

  final String? logoUrl;
  final String name;
  final double size;
  final double borderRadius;
  final bool onDarkBackground;
  final bool isSelected;

  bool get _hasLogo {
    final url = logoUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onDarkBackground
              ? Colors.white.withOpacity(0.20)
              : (isSelected
                    ? AppColor.primary.withOpacity(0.14)
                    : Colors.grey.shade100),
          border: Border.all(
            color: onDarkBackground
                ? Colors.white.withOpacity(0.28)
                : (isSelected
                      ? AppColor.primary.withOpacity(0.22)
                      : Colors.black.withOpacity(0.06)),
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: _hasLogo
            ? AppCachedNetworkImage(
                imageUrl: resolvedMediaUrl(logoUrl!.trim()),
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return Center(
        child: Text(
          trimmed.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: onDarkBackground ? Colors.white : AppColor.primary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      );
    }

    return Center(
      child: Assets.svg.smallShop.svg(
        width: size * 0.46,
        height: size * 0.46,
        color: onDarkBackground ? Colors.white : Colors.grey.shade600,
      ),
    );
  }
}

class _OutletMenuTile extends StatelessWidget {
  const _OutletMenuTile({
    required this.name,
    required this.isSelected,
    this.logoUrl,
    this.businessType,
  });

  final String name;
  final String? logoUrl;
  final String? businessType;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final typeLabel = businessType?.trim();
    final showType = typeLabel != null && typeLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColor.primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColor.primary.withOpacity(0.22)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          _OutletLogoAvatar(
            logoUrl: logoUrl,
            name: name,
            size: 36,
            borderRadius: 9,
            isSelected: isSelected,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (showType) ...[
                  const SizedBox(height: 2),
                  Text(
                    typeLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColor.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            )
          else
            Icon(
              Icons.circle_outlined,
              size: 18,
              color: Colors.grey.shade300,
            ),
        ],
      ),
    );
  }
}

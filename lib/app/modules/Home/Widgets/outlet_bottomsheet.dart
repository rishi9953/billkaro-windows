// Manage outlets dialog (kept filename for existing imports).

import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/Widgets/delete_outlet_dialog.dart';
import 'package:billkaro/app/Widgets/logout_dialog.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

/// Centered dialog for switching / creating outlets from the home screen.
class OutletBottomSheet extends StatefulWidget {
  const OutletBottomSheet({super.key});

  @override
  State<OutletBottomSheet> createState() => _OutletBottomSheetState();
}

class _OutletBottomSheetState extends State<OutletBottomSheet> {
  final HomeScreenController controller = Get.find<HomeScreenController>();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const double _radius = 16;
  static const double _maxWidth = 480;
  static const double _maxHeightFactor = 0.78;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final authLabel =
        controller.appPref.user?.mobile ??
        controller.appPref.user?.email ??
        'User';
    final maxHeight = size.height * _maxHeightFactor;

    final dialogWidth = size.width < 420
        ? size.width - 40
        : (size.width - 56).clamp(360.0, _maxWidth);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: dialogWidth,
        height: maxHeight.clamp(420.0, size.height * 0.86),
        child: Material(
          color: const Color(0xFFF7F8FA),
          elevation: 18,
          shadowColor: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _DialogHeader(
                authLabel: authLabel,
                onRefresh: controller.refreshOutlets,
                onClose: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _SearchField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final outlets = controller.appPref.allOutlets;
                  final selectedOutlet = controller.selectedOutlet.value;
                  final q = _searchCtrl.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? outlets
                      : outlets
                            .where(
                              (o) => (o.businessName ?? '')
                                  .toLowerCase()
                                  .contains(q),
                            )
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              q.isEmpty
                                  ? '${outlets.length} outlet${outlets.length == 1 ? '' : 's'}'
                                  : '${filtered.length} of ${outlets.length} shown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            if (selectedOutlet?.businessName != null)
                              Flexible(
                                child: Text(
                                  'Active · ${selectedOutlet!.businessName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary.withOpacity(0.9),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildList(
                          context: context,
                          outletsEmpty: outlets.isEmpty,
                          filteredEmpty: filtered.isEmpty,
                          filtered: filtered,
                          selectedId: selectedOutlet?.id,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              _DialogFooter(parentContext: context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required BuildContext context,
    required bool outletsEmpty,
    required bool filteredEmpty,
    required List filtered,
    required String? selectedId,
  }) {
    if (outletsEmpty) {
      return _EmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'No outlets yet',
        subtitle: 'Create your first outlet to start billing',
      );
    }

    if (filteredEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching outlets',
        subtitle: 'Try another name or clear the search',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final outlet = filtered[index];
        final isSelected = selectedId == outlet.id;
        final logo = outlet.logo?.toString() ?? '';

        return _OutletRow(
          title: outlet.businessName != null
              ? outlet.businessName.toString().capitalize!
              : 'Unnamed Outlet',
          businessType: (outlet.businessType?.isNotEmpty ?? false)
              ? outlet.businessType!.toUpperCase()
              : null,
          phone: (outlet.phoneNumber?.isNotEmpty ?? false)
              ? outlet.phoneNumber
              : null,
          logoUrl: logo,
          isSelected: isSelected,
          showDelete: StaffAccess.isOwnerSession,
          onDelete: () async {
            final name = outlet.businessName?.toString().capitalize ?? 'Unnamed Outlet';
            final confirmed = await showDeleteOutletDialog(context, outletName: name);
            if (confirmed) controller.deleteOutlet(outlet);
          },
          onTap: () {
            Navigator.of(context).pop();
            if (!isSelected) {
              controller.selectOutlet(outlet, closeSheet: false);
            }
          },
        );
      },
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String authLabel;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.authLabel,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary.withOpacity(0.16)),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: AppColor.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage outlets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Signed in as $authLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade700),
          ),
          IconButton(
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Search by outlet name…',
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColor.primary.withOpacity(0.55),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Icon(icon, size: 30, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutletRow extends StatelessWidget {
  final String title;
  final String? businessType;
  final String? phone;
  final String logoUrl;
  final bool isSelected;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _OutletRow({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.showDelete = false,
    this.onDelete,
    this.businessType,
    this.phone,
    this.logoUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColor.primary.withOpacity(0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColor.primary.withOpacity(0.40)
                  : Colors.black.withOpacity(0.07),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _OutletAvatar(logoUrl: logoUrl, isSelected: isSelected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D23),
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (businessType != null || phone != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (businessType != null) businessType!,
                          if (phone != null) phone!,
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showDelete && onDelete != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Delete outlet',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 22,
                color: isSelected ? AppColor.primary : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutletAvatar extends StatelessWidget {
  final String logoUrl;
  final bool isSelected;

  const _OutletAvatar({required this.logoUrl, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(isSelected ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Assets.svg.smallShop.svg(
          width: 18,
          height: 18,
          color: AppColor.primary,
        ),
      ),
    );

    if (logoUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: resolvedMediaUrl(logoUrl),
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final BuildContext parentContext;

  const _DialogFooter({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showLogoutDialog(
                parentContext,
                AppLocalizations.of(parentContext)!,
              ),
              icon: Icon(
                Icons.logout_rounded,
                size: 18,
                color: Colors.grey.shade800,
              ),
              label: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.black.withOpacity(0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed(AppRoute.createOutlet);
              },
              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Create outlet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

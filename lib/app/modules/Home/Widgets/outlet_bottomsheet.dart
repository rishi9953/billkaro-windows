// outlet_bottomsheet.dart

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/Widgets/logout_dialog.dart';
import 'package:billkaro/config/config.dart';

class OutletBottomSheet extends StatefulWidget {
  OutletBottomSheet({super.key});

  @override
  State<OutletBottomSheet> createState() => _OutletBottomSheetState();
}

class _OutletBottomSheetState extends State<OutletBottomSheet> {
  final HomeScreenController controller = Get.find<HomeScreenController>();
  final TextEditingController _searchCtrl = TextEditingController();

  static const double _radius = 18;
  /// Approximate height of header + search so the list can cap its height and
  /// avoid a tall empty strip below the footer (logout) when there are few outlets.
  static const double _headerSearchHeightEstimate = 208;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWindowsUi =
        !kIsWeb && Theme.of(context).platform == TargetPlatform.windows;
    final authLabel =
        controller.appPref.user?.mobile ??
        controller.appPref.user?.email ??
        'User';

    return DraggableScrollableSheet(
      // Don't force the sheet to fill the available height when content is short.
      expand: false,
      initialChildSize: isWindowsUi ? 0.82 : 0.66,
      minChildSize: isWindowsUi ? 0.55 : 0.40,
      maxChildSize: isWindowsUi ? 0.95 : 0.90,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_radius),
            topRight: Radius.circular(_radius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isWindowsUi
                    ? const Color(0xFFF8F9FB)
                    : Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_radius),
                  topRight: Radius.circular(_radius),
                ),
                border: Border.all(
                  color: isWindowsUi
                      ? Colors.black.withOpacity(0.08)
                      : Colors.white.withOpacity(0.35),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : MediaQuery.sizeOf(context).height *
                            (isWindowsUi ? 0.82 : 0.66);
                    final maxListHeight = math.max(
                      120.0,
                      maxH - _headerSearchHeightEstimate,
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        isWindowsUi ? 18 : 16,
                        isWindowsUi ? 10 : 12,
                        10,
                        isWindowsUi ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: isWindowsUi ? Colors.white : null,
                        gradient: isWindowsUi
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColor.primary,
                                  AppColor.secondaryPrimary,
                                ],
                              ),
                        border: isWindowsUi
                            ? Border(
                                bottom: BorderSide(
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          if (!isWindowsUi) ...[
                            Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isWindowsUi
                                      ? AppColor.primary.withOpacity(0.10)
                                      : Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(
                                    isWindowsUi ? 10 : 14,
                                  ),
                                  border: Border.all(
                                    color: isWindowsUi
                                        ? AppColor.primary.withOpacity(0.18)
                                        : Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: Icon(
                                  Icons.storefront,
                                  color: isWindowsUi
                                      ? AppColor.primary
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Outlet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isWindowsUi
                                            ? Colors.black87
                                            : Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Logged in as $authLabel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isWindowsUi
                                            ? Colors.grey.shade700
                                            : Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh',
                                icon: Icon(
                                  Icons.refresh,
                                  color: isWindowsUi
                                      ? Colors.black87
                                      : Colors.white,
                                ),
                                onPressed: controller.refreshOutlets,
                              ),
                              IconButton(
                                tooltip: 'Close',
                                icon: Icon(
                                  Icons.close,
                                  color: isWindowsUi
                                      ? Colors.black87
                                      : Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            isWindowsUi ? 10 : 16,
                          ),
                          border: isWindowsUi
                              ? Border.all(
                                  color: Colors.black.withOpacity(0.10),
                                )
                              : null,
                          boxShadow: isWindowsUi
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search outlets...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isWindowsUi ? 10 : 16,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // List (shrink-wraps when content is short so no huge gap below Logout)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxListHeight),
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

                        if (outlets.isEmpty) {
                          return ListView(
                            controller: scrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.store_mall_directory_outlined,
                                      size: 52,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No outlets found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Create your first outlet to get started',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _OutletSheetActions(
                                parentContext: context,
                                isWindowsUi: isWindowsUi,
                              ),
                            ],
                          );
                        }

                        if (filtered.isEmpty) {
                          return ListView(
                            controller: scrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 46,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No matching outlets',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Try a different name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _OutletSheetActions(
                                parentContext: context,
                                isWindowsUi: isWindowsUi,
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          physics: isWindowsUi
                              ? const ClampingScrollPhysics()
                              : const BouncingScrollPhysics(),

                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _OutletSheetActions(
                                  parentContext: context,
                                  isWindowsUi: isWindowsUi,
                                ),
                              );
                            }

                            final outlet = filtered[index];
                            final isSelected = selectedOutlet?.id == outlet.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OutletCard(
                                title: outlet.businessName != null
                                    ? outlet.businessName.toString().capitalize!
                                    : 'Unnamed Outlet',
                                subtitleLeft:
                                    (outlet.businessType?.isNotEmpty ?? false)
                                    ? outlet.businessType!.toUpperCase()
                                    : null,
                                subtitleRight:
                                    (outlet.phoneNumber?.isNotEmpty ?? false)
                                    ? outlet.phoneNumber
                                    : null,
                                isSelected: isSelected,
                                isWindowsUi: isWindowsUi,
                                onTap: () {
                                  if (!isSelected) {
                                    Navigator.of(context).pop();
                                    controller.selectOutlet(
                                      outlet,
                                      closeSheet: false,
                                    );
                                  } else {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            );
                          },
                        );
                      }),
                    ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OutletCard extends StatelessWidget {
  final String title;
  final String? subtitleLeft;
  final String? subtitleRight;
  final bool isSelected;
  final bool isWindowsUi;
  final VoidCallback onTap;

  const _OutletCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.isWindowsUi,
    this.subtitleLeft,
    this.subtitleRight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isWindowsUi ? 12 : 18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWindowsUi ? 12 : 18),
            border: Border.all(
              color: isSelected
                  ? AppColor.primary.withOpacity(0.35)
                  : Colors.black.withOpacity(isWindowsUi ? 0.10 : 0.06),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isWindowsUi
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isWindowsUi
                      ? AppColor.primary.withOpacity(0.10)
                      : null,
                  gradient: isWindowsUi
                      ? null
                      : LinearGradient(
                          colors: [
                            AppColor.primary.withOpacity(0.16),
                            AppColor.secondaryPrimary.withOpacity(0.10),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(isWindowsUi ? 10 : 16),
                ),
                child: Center(
                  child: Assets.svg.smallShop.svg(
                    width: 18,
                    height: 18,
                    color: AppColor.primary,
                  ),
                ),
              ),
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
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Selected',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (subtitleLeft != null || subtitleRight != null)
                      Row(
                        children: [
                          if (subtitleLeft != null)
                            Flexible(
                              child: Text(
                                subtitleLeft!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          if (subtitleLeft != null && subtitleRight != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (subtitleRight != null)
                            Flexible(
                              child: Text(
                                subtitleRight!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                size: isSelected ? 20 : 16,
                color: isSelected ? AppColor.primary : Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutletSheetActions extends StatelessWidget {
  final BuildContext parentContext;
  final bool isWindowsUi;

  const _OutletSheetActions({
    required this.parentContext,
    this.isWindowsUi = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: bottomInset > 0 ? 8 : 0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.toNamed(AppRoute.createOutlet),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWindowsUi ? 10 : 16),
                ),
              ),
              child: const Text(
                'Create New Outlet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => showLogoutDialog(
                parentContext,
                AppLocalizations.of(parentContext)!,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWindowsUi ? 10 : 16),
                ),
                side: BorderSide(color: Colors.black.withOpacity(0.12)),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

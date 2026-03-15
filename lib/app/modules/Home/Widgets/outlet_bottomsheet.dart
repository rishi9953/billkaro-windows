// outlet_bottomsheet.dart

import 'dart:ui';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authLabel =
        controller.appPref.user?.mobile ??
        controller.appPref.user?.email ??
        'User';

    return DraggableScrollableSheet(
      // Don't force the sheet to fill the available height when content is short.
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.40,
      maxChildSize: 0.90,
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
                color: Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_radius),
                  topRight: Radius.circular(_radius),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColor.primary, AppColor.secondaryPrimary],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Outlet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
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
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh',
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                onPressed: controller.refreshOutlets,
                              ),
                              IconButton(
                                tooltip: 'Close',
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Get.back(),
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
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
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
                            hintText: 'Search outlets…',
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
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // List
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

                        if (outlets.isEmpty) {
                          return ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                              _OutletSheetActions(parentContext: context),
                            ],
                          );
                        }

                        if (filtered.isEmpty) {
                          return ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                              _OutletSheetActions(parentContext: context),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          physics: BouncingScrollPhysics(),

                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _OutletSheetActions(
                                  parentContext: context,
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
                                onTap: () {
                                  if (!isSelected) {
                                    controller.selectOutlet(outlet);
                                  } else {
                                    Get.back();
                                  }
                                },
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
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
  final VoidCallback onTap;

  const _OutletCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitleLeft,
    this.subtitleRight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColor.primary.withOpacity(0.35)
                  : Colors.black.withOpacity(0.06),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
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
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primary.withOpacity(0.16),
                      AppColor.secondaryPrimary.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
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

  const _OutletSheetActions({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
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
                  borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
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

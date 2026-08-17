import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/gstin_verify_row.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/BusinessDetails/business_details_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';

class BusinessDetailsScreen extends StatelessWidget {
  BusinessDetailsScreen({super.key});

  final controller = Get.put(BusinessDetailsController());

  static const _pageBg = Color(0xFFE8EEF7);
  static const _fieldFill = Color(0xFFF8FAFC);
  static const _labelColor = Color(0xFF64748B);
  static const _hintColor = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _maxWidthDesktop = 1080.0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canEdit = StaffAccess.isOwnerSession;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          loc.business_details,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final maxWidth = isDesktop ? _maxWidthDesktop : 720.0;

          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: isDesktop,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 28 : 16,
                      vertical: isDesktop ? 20 : 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PageHeader(
                              title: loc.business_details,
                              subtitle:
                                  'Update outlet identity, billing, and online presence.',
                            ),
                            const SizedBox(height: 16),
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildIdentitySection(
                                          loc,
                                          canEdit,
                                          isDesktop,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildBillingSection(
                                          loc,
                                          canEdit,
                                          isDesktop,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildTypeSection(
                                          loc,
                                          canEdit,
                                          isDesktop,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildLinksSection(
                                          loc,
                                          canEdit,
                                          isDesktop,
                                        ),
                                        if (canEdit) ...[
                                          const SizedBox(height: 14),
                                          _DangerCard(
                                            title: loc.delete_outlet,
                                            subtitle:
                                                'Permanently remove this outlet and its local data.',
                                            buttonLabel: loc.delete_outlet,
                                            onPressed: controller.deleteOutlet,
                                            compact: true,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildIdentitySection(loc, canEdit, isDesktop),
                              const SizedBox(height: 14),
                              _buildBillingSection(loc, canEdit, isDesktop),
                              const SizedBox(height: 14),
                              _buildTypeSection(loc, canEdit, isDesktop),
                              const SizedBox(height: 14),
                              _buildLinksSection(loc, canEdit, isDesktop),
                              if (canEdit) ...[
                                const SizedBox(height: 14),
                                _DangerCard(
                                  title: loc.delete_outlet,
                                  subtitle:
                                      'Permanently remove this outlet and its local data.',
                                  buttonLabel: loc.delete_outlet,
                                  onPressed: controller.deleteOutlet,
                                ),
                              ],
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (canEdit) _buildBottomButtons(loc, maxWidth: maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentitySection(
    AppLocalizations loc,
    bool canEdit,
    bool isDesktop,
  ) {
    return _SectionCard(
      icon: Icons.storefront_outlined,
      title: 'Outlet identity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveGrid(
            isDesktop: isDesktop,
            children: [
              _buildTextField(
                label: loc.business_name,
                textController: controller.businessNameController,
                hint: loc.tap_to_enter,
                canEdit: canEdit,
              ),
              _buildTextField(
                label: loc.mobile_number,
                textController: controller.phoneController,
                required: true,
                keyboardType: TextInputType.phone,
                canEdit: canEdit,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogoSection(loc, canEdit),
          const SizedBox(height: 16),
          _buildTextField(
            label: loc.outlet_address,
            textController: controller.outletAddressController,
            hint: loc.tap_to_enter,
            maxLines: 2,
            canEdit: canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection(
    AppLocalizations loc,
    bool canEdit,
    bool isDesktop,
  ) {
    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Billing',
      child: _ResponsiveGrid(
        isDesktop: isDesktop,
        children: [
          _buildTextField(
            label: loc.upi_id,
            textController: controller.upiIdController,
            hint: loc.tap_to_enter,
            helperText: 'This will be used to print QR on bills',
            canEdit: canEdit,
          ),
          _buildTextField(
            label: loc.custom_footer_message_on_bills,
            textController: controller.footerMessageController,
            maxLines: 3,
            canEdit: canEdit,
          ),
          _buildTextField(
            label: loc.fssai_number,
            textController: controller.fssaiController,
            hint: loc.tap_to_enter,
            canEdit: canEdit,
          ),
          _buildDropdownField(
            label: loc.tax_slab,
            value: controller.selectedTaxSlab,
            items: controller.taxSlabOptions,
            canEdit: canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection(
    AppLocalizations loc,
    bool canEdit,
    bool isDesktop,
  ) {
    return _SectionCard(
      icon: Icons.category_outlined,
      title: 'Business type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveGrid(
            isDesktop: isDesktop,
            children: [
              Obx(
                () => _buildDropdownField(
                  label: loc.business_type,
                  value: controller.selectedBusinessType,
                  items: controller.businessTypeOptions,
                  canEdit: canEdit,
                ),
              ),
              _buildDropdownField(
                label: loc.business_category_question,
                value: controller.selectedBusinessCategory,
                items: controller.businessCategoryOptions,
                canEdit: canEdit,
              ),
            ],
          ),
          Obx(() {
            if (!controller.showSeatingCapacityField) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ResponsiveGrid(
                isDesktop: isDesktop,
                children: [
                  _buildSeatingCapacityField(
                    label: loc.seating_capacity,
                    value: controller.selectedSeatingCapacity,
                    options: controller.seatingCapacityOptions,
                    canEdit: canEdit,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _ResponsiveGrid(
            isDesktop: isDesktop,
            children: [
              _buildTextField(
                label: '${loc.gstin_number} (optional)',
                textController: controller.gstinController,
                hint: loc.tap_to_enter,
                canEdit: canEdit,
              ),
              _buildTextField(
                label: loc.business_address,
                textController: controller.businessAddressController,
                hint: loc.tap_to_enter,
                maxLines: 3,
                canEdit: canEdit,
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 10),
            GstinVerifyRow(
              helper: controller.gstinVerify,
              onVerify: controller.verifyGstin,
              alignEnd: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinksSection(
    AppLocalizations loc,
    bool canEdit,
    bool isDesktop,
  ) {
    return _SectionCard(
      icon: Icons.link_outlined,
      title: 'Online links',
      child: _ResponsiveGrid(
        isDesktop: isDesktop,
        children: [
          _buildTextField(
            label: loc.google_profile_link,
            textController: controller.googleProfileController,
            hint: loc.tap_to_enter,
            canEdit: canEdit,
          ),
          _buildTextField(
            label: loc.swiggy_link,
            textController: controller.swiggyLinkController,
            hint: loc.tap_to_enter,
            canEdit: canEdit,
          ),
          _buildTextField(
            label: loc.zomato_link,
            textController: controller.zomatoLinkController,
            hint: loc.tap_to_enter,
            canEdit: canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController textController,
    String? hint,
    String? helperText,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool canEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required: required),
        const SizedBox(height: 8),
        TextField(
          enabled: canEdit,
          controller: textController,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _inputDecoration(hint: hint),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  helperText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required RxString value,
    required List<String> items,
    required bool canEdit,
  }) {
    final loc = AppLocalizations.of(Get.context!)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Obx(
          () => AppFilterDropdown2<String>(
            value: value.value,
            isExpanded: true,
            decoration: appFilterDropdownDecoration(borderRadius: 11),
            style: TextStyle(
              color: value.value.contains('Tap to') || value.value == loc.none
                  ? Colors.grey
                  : Colors.black,
              overflow: TextOverflow.ellipsis,
            ),
            items: items.map((String item) {
              return DropdownItem<String>(
                value: item,
                enabled: canEdit,
                child: Text(
                  item.capitalize!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.contains('Tap to') || item == loc.none
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: canEdit
                ? (String? newValue) {
                    if (newValue != null) value.value = newValue;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatingCapacityField({
    required String label,
    required RxString value,
    required List<Map<String, String>> options,
    required bool canEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Obx(
          () => AppFilterDropdown2<String>(
            value: value.value,
            isExpanded: true,
            decoration: appFilterDropdownDecoration(borderRadius: 11),
            items: options.map((opt) {
              return DropdownItem<String>(
                value: opt['value'],
                enabled: canEdit,
                child: Text(
                  opt['label']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: canEdit
                ? (String? newValue) {
                    if (newValue != null) value.value = newValue;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(AppLocalizations loc, bool canEdit) {
    return Obx(() {
      final file = controller.businessLogo.value;
      final raw = controller.imageUrl.value.isNotEmpty
          ? controller.imageUrl.value
          : (controller.selectedOutlet.value?.logo ?? '');
      final url = resolvedMediaUrl(raw);
      final hasLogo = file != null || url.isNotEmpty;

      Widget buildImage() {
        if (file != null) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
        }
        if (url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _LogoEmpty(loc: loc),
          );
        }
        return _LogoEmpty(loc: loc);
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canEdit ? controller.pickImage : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(loc.logo),
                const SizedBox(height: 4),
                Text(
                  loc.upload_business_logo,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 16 / 5.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEF2F7)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Center(child: buildImage()),
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_outlined,
                        size: 16,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasLogo ? 'Change logo' : 'Upload logo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomButtons(
    AppLocalizations loc, {
    required double maxWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.primary,
                      side: BorderSide(
                        color: AppColor.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: controller.updateBusinessDetails,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: Text(
                        loc.update_details,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
      filled: true,
      fillColor: _fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColor.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.business_outlined,
              color: AppColor.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        softWrap: true,
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: BusinessDetailsScreen._labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColor.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.isDesktop, required this.children});

  final bool isDesktop;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        // Only split into 2 columns when there is enough room for both tiles.
        final useTwoCol = isDesktop && maxW >= 520 && children.length > 1;
        final itemWidth =
            useTwoCol ? (maxW - 16) / 2 : maxW;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _LogoEmpty extends StatelessWidget {
  const _LogoEmpty({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text(
          loc.upload_business_logo,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG/JPG • Recommended: wide logo',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: compact ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: compact ? 180 : double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

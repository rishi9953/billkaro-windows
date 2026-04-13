import 'package:billkaro/app/modules/BusinessDetails/business_details_controller.dart';
import 'package:billkaro/app/services/Network/urls.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class BusinessDetailsScreen extends StatelessWidget {
  BusinessDetailsScreen({super.key});

  final controller = Get.put(BusinessDetailsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title: Text(
          loc.business_details,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 900;
          final contentMaxWidth = isDesktop ? 980.0 : 720.0;
          final contentPadding = EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: isDesktop ? 20 : 16,
          );

          final fields = <Widget>[
            _SectionCard(
              title: loc.business_details,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResponsiveGrid(
                    isDesktop: isDesktop,
                    children: [
                      _buildTextField(
                        label: loc.business_name,
                        controller: controller.businessNameController,
                        hint: loc.tap_to_enter,
                      ),
                      _buildTextField(
                        label: 'Phone Number',
                        controller: controller.phoneController,
                        required: true,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLogoSection(),
                  const SizedBox(height: 16),
                  _ResponsiveGrid(
                    isDesktop: isDesktop,
                    children: [
                      _buildTextField(
                        label: loc.outlet_address,
                        controller: controller.outletAddressController,
                        hint: loc.tap_to_enter,
                        maxLines: 2,
                      ),
                      _buildTextField(
                        label: loc.upi_id,
                        controller: controller.upiIdController,
                        hint: loc.tap_to_enter,
                        helperText:
                            'This will be used to print QR on bills',
                      ),
                      _buildTextField(
                        label: loc.custom_footer_message_on_bills,
                        controller: controller.footerMessageController,
                        maxLines: 3,
                      ),
                      _buildTextField(
                        label: loc.fssai_number,
                        controller: controller.fssaiController,
                        hint: loc.tap_to_enter,
                      ),
                      _buildDropdownField(
                        label: loc.tax_slab,
                        value: controller.selectedTaxSlab,
                        items: controller.taxSlabOptions,
                      ),
                      Obx(
                        () => _buildDropdownField(
                          label: loc.business_type,
                          value: controller.selectedBusinessType,
                          items: controller.businessTypeOptions,
                        ),
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
                          ),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _ResponsiveGrid(
                      isDesktop: isDesktop,
                      children: [
                        _buildDropdownField(
                          label: loc.business_category_question,
                          value: controller.selectedBusinessCategory,
                          items: controller.businessCategoryOptions,
                        ),
                        _buildTextField(
                          label: loc.gstin_number,
                          controller: controller.gstinController,
                          hint: loc.tap_to_enter,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Links',
              child: _ResponsiveGrid(
                isDesktop: isDesktop,
                children: [
                  _buildTextField(
                    label: loc.google_profile_link,
                    controller: controller.googleProfileController,
                    hint: loc.tap_to_enter,
                  ),
                  _buildTextField(
                    label: loc.swiggy_link,
                    controller: controller.swiggyLinkController,
                    hint: loc.tap_to_enter,
                  ),
                  _buildTextField(
                    label: loc.zomato_link,
                    controller: controller.zomatoLinkController,
                    hint: loc.tap_to_enter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: loc.business_address,
              child: _buildTextField(
                label: loc.business_address,
                controller: controller.businessAddressController,
                hint: loc.tap_to_enter,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            _DangerZone(
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: controller.deleteOutlet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    loc.delete_outlet,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ];

          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: isDesktop,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: contentPadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: fields,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomButtons(maxWidth: contentMaxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? prefix,
    String? helperText,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixStyle: const TextStyle(color: Colors.black, fontSize: 16),
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                helperText,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
  }) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item.capitalize!,
                      style: TextStyle(
                        color: item.contains('Tap to') || item == loc.none
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    value.value = newValue;
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatingCapacityField({
    required String label,
    required RxString value,
    required List<Map<String, String>> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'],
                    child: Text(
                      opt['label']!,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) value.value = newValue;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    var loc = AppLocalizations.of(Get.context!)!;
    return Obx(
      () {
        final file = controller.businessLogo.value;
        final raw = controller.imageUrl.value.isNotEmpty
            ? controller.imageUrl.value
            : (controller.selectedOutlet.value?.logo ?? '');
        final url = resolvedMediaUrl(raw);

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
                return Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildLogoEmptyState(loc),
            );
          }
          return _buildLogoEmptyState(loc);
        }

        final hasLogo = file != null || url.isNotEmpty;

        return InkWell(
          onTap: controller.pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.logo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.upload_business_logo,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Center(child: buildImage()),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 16, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Text(
                      hasLogo ? 'Change logo' : 'Upload logo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoEmptyState(AppLocalizations loc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 44, color: Colors.grey[500]),
        const SizedBox(height: 10),
        Text(
          loc.upload_business_logo,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          'PNG/JPG works best • Recommended: wide logo',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomButtons({required double maxWidth}) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          loc.cancel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: controller.updateBusinessDetails,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          loc.update_details,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.isDesktop, required this.children});

  final bool isDesktop;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final child in children) SizedBox(width: 460, child: child),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.red.shade100),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

import 'package:billkaro/app/modules/subscription/Form/subscription_form_controller.dart';
import 'package:billkaro/config/config.dart';

class SubscriptionFormScreen extends GetView<SubscriptionFormController> {
  const SubscriptionFormScreen({super.key});

  static const double _windowsMaxContentWidth = 1120;

  bool _isWindowsDesktop(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    Get.put(SubscriptionFormController());

    final isWindowsDesktop = _isWindowsDesktop(context);

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.white,
        elevation: isWindowsDesktop ? 0 : null,
        scrolledUnderElevation: isWindowsDesktop ? 0 : null,
        surfaceTintColor: isWindowsDesktop ? Colors.transparent : null,
        toolbarHeight: isWindowsDesktop ? 48 : kToolbarHeight,
        title: const Text(
          'Subscription Details',
          style: TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      if (isWindowsDesktop)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColor.backGroundColor,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SingleChildScrollView(
                        physics: isWindowsDesktop
                            ? const ClampingScrollPhysics()
                            : const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isWindowsDesktop ? 28 : 16,
                          vertical: isWindowsDesktop ? 20 : 16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWindowsDesktop
                                  ? _windowsMaxContentWidth
                                  : double.infinity,
                            ),
                            child: LayoutBuilder(
                              builder: (context, inner) {
                                final wide =
                                    isWindowsDesktop && inner.maxWidth >= 880;
                                if (wide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildOutletCard(context),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildDeliveryCard(context),
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOutletCard(context),
                                    const SizedBox(height: 24),
                                    _buildDeliveryCard(context),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildSubmitSection(isWindowsDesktop: isWindowsDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletCard(BuildContext context) {
    final isWindowsDesktop = _isWindowsDesktop(context);
    return _DesktopSectionCard(
      isWindowsDesktop: isWindowsDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Outlet details'),
          SizedBox(height: isWindowsDesktop ? 16 : 12),
          _buildTextField(
            label: 'Outlet name',
            controller: controller.outletNameController,
            validator: controller.validateOutletName,
            hint: 'Enter outlet or business name',
            maxLength: 100,
            textInputAction: TextInputAction.next,
            dense: isWindowsDesktop,
          ),
          SizedBox(height: isWindowsDesktop ? 18 : 16),
          _buildTextField(
            label: 'Outlet address',
            controller: controller.outletAddressController,
            validator: controller.validateOutletAddress,
            hint: 'Street, area, city',
            maxLength: 300,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            dense: isWindowsDesktop,
          ),
          SizedBox(height: isWindowsDesktop ? 18 : 16),
          _buildTextField(
            label: 'Email',
            controller: controller.emailController,
            validator: controller.validateEmail,
            hint: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            dense: isWindowsDesktop,
          ),
          SizedBox(height: isWindowsDesktop ? 18 : 16),
          _buildTextField(
            label: 'Phone number',
            controller: controller.phoneController,
            validator: controller.validatePhone,
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: controller.phoneInputFormatters,
            dense: isWindowsDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context) {
    final isWindowsDesktop = _isWindowsDesktop(context);
    return _DesktopSectionCard(
      isWindowsDesktop: isWindowsDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Delivery details'),
          SizedBox(height: isWindowsDesktop ? 16 : 12),
          _buildTextField(
            label: 'Delivery address',
            controller: controller.deliveryAddressController,
            validator: controller.validateDeliveryAddress,
            hint: 'Where to deliver (street, area, city)',
            maxLength: 300,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            dense: isWindowsDesktop,
          ),
          SizedBox(height: isWindowsDesktop ? 18 : 16),
          _buildTextField(
            label: 'Pincode',
            controller: controller.pincodeController,
            validator: controller.validatePincode,
            hint: '6-digit pincode',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: controller.pincodeInputFormatters,
            dense: isWindowsDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColor.primary,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool dense = false,
  }) {
    final vPad = dense ? 14.0 : 12.0;
    final hPad = dense ? 14.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: dense ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: dense ? 6 : 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: dense ? Colors.white : Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: vPad,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dense ? 6 : 8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dense ? 6 : 8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dense ? 6 : 8),
              borderSide: BorderSide(color: AppColor.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dense ? 6 : 8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(dense ? 6 : 8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection({required bool isWindowsDesktop}) {
    final hasPlan = controller.subscriptionPlan != null;
    final buttonLabel = hasPlan ? 'Continue & Pay' : 'Continue';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWindowsDesktop ? 28 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isWindowsDesktop
            ? Border(top: BorderSide(color: Colors.black.withOpacity(0.08)))
            : null,
        boxShadow: isWindowsDesktop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWindowsDesktop
                  ? _windowsMaxContentWidth
                  : double.infinity,
            ),
            child: Align(
              alignment: isWindowsDesktop
                  ? Alignment.centerRight
                  : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isWindowsDesktop ? 200 : double.infinity,
                  maxWidth: isWindowsDesktop ? 320 : double.infinity,
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.submitSubscription();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColor.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWindowsDesktop ? 22 : 20,
                      vertical: isWindowsDesktop ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isWindowsDesktop ? 6 : 8,
                      ),
                    ),
                    minimumSize: Size(
                      isWindowsDesktop ? 200 : double.infinity,
                      isWindowsDesktop ? 46 : 50,
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          fontSize: isWindowsDesktop ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: isWindowsDesktop ? 0.25 : 0.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: isWindowsDesktop ? 8 : 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: isWindowsDesktop ? 18 : 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-style panel for Windows; flat sections on mobile.
class _DesktopSectionCard extends StatelessWidget {
  const _DesktopSectionCard({
    required this.isWindowsDesktop,
    required this.child,
  });

  final bool isWindowsDesktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWindowsDesktop) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

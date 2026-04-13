import 'package:billkaro/app/modules/Staff/add_staff_controller.dart';
import 'package:billkaro/config/config.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  late final AddStaffController controller;
  final ScrollController _scrollController = ScrollController();

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  static const double _windowsMaxFormWidth = 920;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddStaffController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required bool isWin,
  }) {
    final theme = Theme.of(context);
    if (isWin) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
    }
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _labelRequired(AppLocalizations loc, String label) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector(BuildContext context, AppLocalizations loc, bool isWin) {
    return Obx(
      () => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.showRolePicker,
          borderRadius: BorderRadius.circular(isWin ? 10 : 8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isWin ? 14 : 16,
              vertical: isWin ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: isWin
                  ? Theme.of(context).colorScheme.surface
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(isWin ? 10 : 8),
              border: isWin ? Border.all(color: Colors.grey[300]!) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedRole.value == 'Secondary Admin'
                        ? loc.secondary_admin
                        : controller.selectedRole.value == 'Biller'
                        ? loc.biller
                        : controller.selectedRole.value,
                    style: TextStyle(
                      color: const Color(0xFF374151),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    AppLocalizations loc, {
    required bool isWin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelRequired(loc, loc.user_name),
        const SizedBox(height: 8),
        TextField(
          controller: controller.userNameController,
          decoration: _fieldDecoration(
            context,
            hint: loc.tap_to_enter,
            isWin: isWin,
          ),
        ),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.email),
        const SizedBox(height: 8),
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(
            context,
            hint: loc.tap_to_enter,
            isWin: isWin,
          ),
        ),
        SizedBox(height: isWin ? 20 : 24),
        _labelRequired(loc, loc.user_phone_number),
        const SizedBox(height: 8),
        TextField(
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _fieldDecoration(
            context,
            hint: loc.tap_to_enter,
            isWin: isWin,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _buildRoleSection(
    BuildContext context,
    AppLocalizations loc,
    bool isWin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.user_role,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _roleSelector(context, loc, isWin),
        SizedBox(height: isWin ? 20 : 32),
        Obx(
          () => controller.selectedRole.value == 'Biller'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    checkbox(
                      'Allow biller to create menu items',
                      controller.canManageBills.value,
                      (val) => controller.canManageBills.value = val ?? false,
                    ),
                    checkbox(
                      'Allow biller to edit existing menu items',
                      controller.canEditMenuItems.value,
                      (val) => controller.canEditMenuItems.value = val ?? false,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: isWin ? 12 : 16),
        Obx(
          () => controller.selectedRole.value == 'Biller'
              ? billerOverView(context, isWin)
              : secondaryAdminOverView(context, isWin),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isWin = _isWindows(context);

    return Scaffold(
      backgroundColor: isWin ? AppColor.backGroundColor : null,
      appBar: AppBar(
        elevation: isWin ? 0 : 0,
        scrolledUnderElevation: isWin ? 0 : null,
        surfaceTintColor: isWin ? Colors.transparent : null,
        toolbarHeight: isWin ? 48 : kToolbarHeight,
        title: Text(
          loc.add_staff,
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = isWin ? _windowsMaxFormWidth : double.infinity;
                final isWide = isWin && constraints.maxWidth >= 960;

                final formContent = isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildFormFields(context, loc, isWin: isWin),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _buildRoleSection(context, loc, isWin),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormFields(context, loc, isWin: isWin),
                          SizedBox(height: isWin ? 20 : 24),
                          _buildRoleSection(context, loc, isWin),
                        ],
                      );

                final cardBody = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 26 : 22),
                    child: formContent,
                  ),
                );

                final scrollChild = isWin
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWide) ...[
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColor.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.group_add_outlined,
                                    color: AppColor.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.add_staff,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Invite a team member and assign a role.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 20),
                          ],
                          cardBody,
                        ],
                      )
                    : formContent;

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: isWin,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: isWin
                        ? const ClampingScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWin ? 28 : 16,
                      vertical: isWin ? 20 : 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: scrollChild,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWin ? 28 : 16,
              vertical: isWin ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isWin
                  ? Border(
                      top: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    )
                  : null,
              boxShadow: isWin
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWin ? _windowsMaxFormWidth : double.infinity,
                ),
                child: Align(
                  alignment: isWin ? Alignment.centerRight : Alignment.center,
                  child: SizedBox(
                    width: isWin ? 220 : double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.sendInvite,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: isWin ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isWin ? 10 : 8),
                        ),
                      ),
                      child: Text(
                        loc.send_invite,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget secondaryAdminOverView(BuildContext context, bool isWin) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(isWin ? 18 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
        border: isWin ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Overview',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          Gap(10),
          Text(
            loc.staff_access_info,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget billerOverView(BuildContext context, bool isWin) {
    return Container(
      padding: EdgeInsets.all(isWin ? 18 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(isWin ? 10 : 8),
        border: isWin ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Overview',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          Gap(10),
          overView(1, 'Create and print orders and KOT.'),
          overView(2, 'View all items and use them for billing.'),
          overView(3, 'Cannot delete any orders (self or others).'),
          overView(4, 'Cannot access orders created by other members.'),
        ],
      ),
    );
  }

  Widget overView(int num, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$num.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget checkbox(String title, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StaffDetailsController>();
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFE8EEF7),
        elevation: 0,
        title: isWindows
            ? null
            : Text(
                'Staff List',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
      body: isWindows
          ? _buildWindowsLayout(context, controller)
          : _buildMobileLayout(context, controller),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    StaffDetailsController controller,
  ) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadStaffList,
            child: Obx(() {
              final list = controller.staffList;
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _buildStaffTile(list[index], isWindows: false);
                },
              );
            }),
          ),
        ),
        _buildBottomButton(context, controller),
      ],
    );
  }

  Widget _buildWindowsLayout(
    BuildContext context,
    StaffDetailsController controller,
  ) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.loadStaffList,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your outlet staff access',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Obx(() {
                            final list = controller.staffList;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildWindowsHeaderRow(),
                                const SizedBox(height: 8),
                                ...list.map(
                                  (staff) =>
                                      _buildStaffTile(staff, isWindows: true),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomButton(context, controller),
      ],
    );
  }

  Widget _buildWindowsHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Role',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Phone',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTile(
    Map<String, dynamic> staff, {
    required bool isWindows,
  }) {
    final name = (staff['userName'] ?? staff['name'] ?? '-').toString();
    final role = (staff['userRole'] ?? staff['role'] ?? '-')
        .toString()
        .replaceAll('_', ' ');
    final phone = (staff['userPhoneNumber'] ?? staff['phoneNumber'] ?? '-')
        .toString();
    final email = (staff['email'] ?? '-').toString();
    final isActive = staff['activated'] == true;

    if (isWindows) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                role,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                phone,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildDeleteButton(staff: staff, forTableRow: true),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildStatusChip(isActive),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColor.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDeleteButton(staff: staff),
                        const SizedBox(width: 6),
                        _buildStatusChip(isActive),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeleteButton({
    required Map<String, dynamic> staff,
    bool forTableRow = false,
  }) {
    final staffId = (staff['id'] ?? '').toString();
    final double box = forTableRow ? 40 : 32;
    final double iconSz = forTableRow ? 22 : 18;
    return Obx(() {
      final details = Get.find<StaffDetailsController>();
      final isDeleting =
          staffId.isNotEmpty && details.deletingStaffIds.contains(staffId);
      return SizedBox(
        width: box,
        height: box,
        child: IconButton(
          onPressed: isDeleting ? null : () => _confirmDelete(staff),
          tooltip: 'Delete staff',
          padding: EdgeInsets.zero,
          icon: isDeleting
              ? SizedBox(
                  width: forTableRow ? 18 : 14,
                  height: forTableRow ? 18 : 14,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.delete_outline, size: iconSz, color: Colors.red),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.08),
            foregroundColor: Colors.red,
            minimumSize: Size(box, box),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> staff) async {
    final controller = Get.find<StaffDetailsController>();
    final staffId = (staff['id'] ?? '').toString();
    final staffName = (staff['userName'] ?? staff['name'] ?? 'this staff')
        .toString();
    if (staffId.isEmpty) {
      showError(description: 'Invalid staff id');
      return;
    }

    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Delete Staff'),
            content: Text('Are you sure you want to delete $staffName?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;
    await controller.deleteStaffById(staffId);
  }

  Widget _buildBottomButton(
    BuildContext context,
    StaffDetailsController controller,
  ) {
    var loc = AppLocalizations.of(Get.context!)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Align(
        alignment: isWindows ? Alignment.centerRight : Alignment.center,
        child: SizedBox(
          width: isWindows ? 320 : double.infinity,
          height: isWindows ? 48 : 56,
          child: ElevatedButton(
            onPressed: () async {
              await Modular.to.pushNamed(HomeMainRoutes.addStaffScreen);
              await controller.loadStaffList();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc.invite_staff,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

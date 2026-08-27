import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter_modular/flutter_modular.dart';

class StaffMemberDetailsController extends BaseController {
  /// Set just before navigation so details still load if Modular args are late.
  static StaffMember? pendingMember;

  final member = Rxn<StaffMember>();

  StaffDetailsController? get listController =>
      Get.isRegistered<StaffDetailsController>()
          ? Get.find<StaffDetailsController>()
          : null;

  bool get isActivating {
    final id = member.value?.id.trim() ?? '';
    final list = listController;
    return id.isNotEmpty &&
        list != null &&
        list.activationStaffIds.contains(id);
  }

  bool get isReinviting {
    final id = member.value?.id.trim() ?? '';
    final list = listController;
    return id.isNotEmpty &&
        list != null &&
        list.reinvitingStaffIds.contains(id);
  }

  bool get isDeleting {
    final id = member.value?.id.trim() ?? '';
    final list = listController;
    return id.isNotEmpty &&
        list != null &&
        list.deletingStaffIds.contains(id);
  }

  @override
  void onInit() {
    super.onInit();
    resolveMember();
    if (member.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed) return;
        resolveMember();
      });
    }
  }

  void resolveMember({StaffMember? seed}) {
    final resolved = seed ??
        pendingMember ??
        _readArgs() ??
        member.value;
    pendingMember = null;
    if (resolved != null) {
      member.value = resolved;
    }
  }

  StaffMember? _readArgs() {
    final args = Get.arguments ?? Modular.args.data;
    return args is StaffMember ? args : null;
  }

  void syncFromList() {
    final current = member.value;
    final list = listController;
    if (current == null || list == null) return;
    for (final m in list.staffMembers) {
      if (m.id == current.id) {
        member.value = m;
        return;
      }
    }
  }

  Future<void> openEdit() async {
    final current = member.value;
    if (current == null) return;
    if (!StaffAccess.ensure(StaffAccess.canUpdateStaff)) return;
    final list = listController;
    if (list == null) return;
    await list.onEditStaff(current);
    syncFromList();
  }

  Future<void> activate() async {
    final current = member.value;
    if (current == null) return;
    if (!StaffAccess.ensure(StaffAccess.canUpdateStaff)) return;
    final list = listController;
    if (list == null) return;
    await list.setStaffActive(current, true);
    syncFromList();
  }

  Future<void> deactivate() async {
    final current = member.value;
    if (current == null) return;
    if (!StaffAccess.ensure(StaffAccess.canUpdateStaff)) return;
    final list = listController;
    if (list == null) return;

    final loc = AppLocalizations.of(Get.context!)!;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Deactivate Staff'),
        content: Text(
          'Deactivate ${current.name.isEmpty ? 'this staff' : current.name}? They will be logged out immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await list.setStaffActive(current, false);
    syncFromList();
  }

  Future<void> reinvite() async {
    final current = member.value;
    if (current == null) return;
    if (!StaffAccess.ensure(StaffAccess.canUpdateStaff)) return;
    final list = listController;
    if (list == null) return;
    await list.reinviteStaff(current);
  }

  Future<void> deleteStaff() async {
    final current = member.value;
    if (current == null) return;
    if (!StaffAccess.ensure(StaffAccess.canDeleteStaff)) return;
    final list = listController;
    if (list == null) return;

    final loc = AppLocalizations.of(Get.context!)!;
    final staffId = current.id.trim();
    if (staffId.isEmpty) {
      showError(description: loc.unable_to_delete_staff_entry);
      return;
    }

    final shouldDelete = await Get.dialog<bool>(
          AlertDialog(
            title: Text(loc.remove_staff),
            content: Text(
              loc.remove_staff_confirm(
                current.name.isEmpty ? loc.this_staff : current.name,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.remove),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    await list.deleteStaffById(staffId);
    final stillExists =
        list.staffMembers.any((m) => m.id.trim() == staffId);
    if (!stillExists) {
      goBack();
    }
  }

  /// Prefer the nested Modular/Navigator stack; fall back to staff list.
  void goBack([dynamic result]) {
    final context = Get.context;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
      return;
    }
    if (Modular.to.canPop()) {
      Modular.to.pop(result);
      return;
    }
    Modular.to.navigate(HomeMainRoutes.staff);
  }
}

Future<void> openStaffMemberDetails(StaffMember member) {
  StaffMemberDetailsController.pendingMember = member;
  if (Get.isRegistered<StaffMemberDetailsController>()) {
    Get.delete<StaffMemberDetailsController>(force: true);
  }
  return Modular.to.pushNamed(
    HomeMainRoutes.staffMemberDetails,
    arguments: member,
  );
}

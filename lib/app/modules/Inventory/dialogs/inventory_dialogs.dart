import 'dart:io';

import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/gstin_verify_row.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Inventory/dialogs/searchable_category_dropdown.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/gstin_verify_helper.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:billkaro/utils/supplier_contact_verifier.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_selector/file_selector.dart';

part 'dialog_helpers.dart';
part 'inventory_drawer.dart';
part 'raw_material_dialogs.dart';
part 'supplier_dialogs.dart';
part 'stock_adjust_dialogs.dart';
part 'recipe_dialogs.dart';

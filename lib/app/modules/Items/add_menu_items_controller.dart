// Controller
import 'dart:async';
import 'dart:io';
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/Widgets/item_image_ai_chat_dialog.dart';
import 'package:billkaro/app/Widgets/remote_barcode_pair_dialog.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/combo_component.dart';
import 'package:billkaro/app/services/Modals/addItem/menu_item_variant.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/open_food_facts_service.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:billkaro/app/services/ai/pollinations_ai_image_service.dart';
import 'package:billkaro/config/config.dart';
import '../../services/Modals/Categories/categories_response.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:billkaro/app/services/sync/item_catalog_sync.dart';

class AddMenuItemController extends BaseController {
  static const String comboCategoryName = 'combo';

  final formKey = GlobalKey<FormState>();
  final itemNameController = TextEditingController();
  final salePriceController = TextEditingController();
  final costPriceController = TextEditingController();
  final barcodeController = TextEditingController();
  final skuController = TextEditingController();
  final stockController = TextEditingController();
  final minStockController = TextEditingController();
  final prepTimeController = TextEditingController(text: '15');
  MenuItemController? menuItemController;

  var selectedCategory = 'none'.obs;
  var selectedTaxPercentage = 'None'.obs;
  var isWithTax = false.obs;
  var makeDefaultTax = true.obs;
  var markAsFavorite = false.obs;
  var isComboItem = false.obs;
  final RxMap<String, double> comboComponentQuantities = <String, double>{}.obs;
  final RxList<ItemData> comboOptionItems = <ItemData>[].obs;
  final Map<String, ItemData> _comboKnownItems = <String, ItemData>{};
  final comboSearchController = TextEditingController();
  final RxString comboSearchQuery = ''.obs;
  final isLoadingComboOptions = false.obs;
  Timer? _comboSearchDebounce;
  static const _comboSearchDebounceDuration = Duration(milliseconds: 400);
  int _comboOptionsRequestId = 0;
  var itemId = ''.obs;
  var imageUrl = ''.obs;
  var isAvailable = true.obs;
  var trackStock = false.obs;
  var selectedSoldBy = 'Each'.obs;
  var selectedPosColor = ''.obs;
  final linkedRecipeItemId = ''.obs;

  static const soldByOptions = ['Each', 'Weight', 'Open'];
  static const posColorOptions = <String>[
    '',
    '#2196F3',
    '#FF9800',
    '#4CAF50',
    '#E91E63',
    '#9C27B0',
    '#00BCD4',
    '#FF5722',
    '#795548',
    '#9E9E9E',
    '#3F51B5',
    '#009688',
    '#CDDC39',
    '#F44336',
    '#212121',
  ];

  // Image picker
  final ImagePicker _picker = ImagePicker();
  var selectedImage = Rx<File?>(null);
  var imagePath = ''.obs;

  // AI Scanner
  final MenuAIScanner _aiScanner = MenuAIScanner();
  final PollinationsAiImageService _pollinations = PollinationsAiImageService();
  final isGeneratingAiImage = false.obs;
  var isScanning = false.obs;
  var aiScanResult = Rx<MenuScanResult?>(null);

  final taxOptions = ['None', '5', '12', '18', '28'];
  var isEdit = false.obs;
  final hasVariantsEnabled = false.obs;
  final RxList<VariantDraft> variantDrafts = <VariantDraft>[].obs;

  // Default category list
  RxList<String> categories = <String>['none'].obs;
  final RxList<CategoryData> categoryDetails = <CategoryData>[].obs;

  void _setCategoryNames(Iterable<String> names) {
    final unique = <String>['none'];
    final seen = <String>{'none'};
    for (final name in names) {
      final trimmed = name.trim();
      final normalized = trimmed.toLowerCase();
      if (trimmed.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      unique.add(trimmed);
    }
    categories.assignAll(unique);
    _syncSelectedCategoryToList();
  }

  /// Exact list entry for the dropdown (casing must match [DropdownItem] values).
  String? get selectedCategoryDropdownValue {
    final selected = selectedCategory.value.trim();
    if (selected.isEmpty) return null;
    return categories.firstWhereOrNull(
      (c) => c.trim().toLowerCase() == selected.toLowerCase(),
    );
  }

  void _syncSelectedCategoryToList() {
    final match = selectedCategoryDropdownValue;
    if (match != null) {
      selectedCategory.value = match;
    }
  }

  String getCategoryImageUrl(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    final category = categoryDetails.firstWhereOrNull(
      (item) => item.categoryName.trim().toLowerCase() == normalized,
    );
    return category?.imageURL ?? '';
  }

  // Upload image from gallery
  Future<void> uploadImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        imagePath.value = image.path;
        aiScanResult.value = null;
      }
    } catch (e) {
      showError(description: 'Failed to pick image: $e');
    }
  }

  bool _usesDesktopCameraPlugin() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// On mobile uses [ImageSource.camera]. On desktop, opens a live preview (USB / built-in webcam).
  Future<void> uploadImageFromCamera() async {
    try {
      String? path;
      if (_usesDesktopCameraPlugin()) {
        path = await showDesktopCameraCaptureDialog();
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        path = image?.path;
      }

      if (path == null || path.isEmpty) return;

      selectedImage.value = File(path);
      imagePath.value = path;
      aiScanResult.value = null;
    } catch (e) {
      showError(description: 'Failed to capture image: $e');
    }
  }

  // Show image source selection (gallery / camera / file)
  void uploadImage() {
    showManualUploadOptions();
  }

  /// Pick a menu photo (camera or gallery) and extract item details with AI.
  Future<void> scanImageWithAI() async {
    final source = await _showScanImageSourceDialog();
    if (source == null) return;

    try {
      String? path;
      if (source == ImageSource.camera) {
        if (_usesDesktopCameraPlugin()) {
          path = await showDesktopCameraCaptureDialog();
        } else {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 85,
          );
          path = image?.path;
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        path = image?.path;
      }

      if (path == null || path.isEmpty) return;

      selectedImage.value = File(path);
      imagePath.value = path;
      await scanMenuWithAI();
    } catch (e) {
      showError(description: 'Failed to pick image for scan: $e');
    }
  }

  Future<ImageSource?> _showScanImageSourceDialog() async {
    return Get.dialog<ImageSource>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan image with AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a photo of your menu or item label',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scanSourceChip(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      subtitle: _usesDesktopCameraPlugin()
                          ? 'Webcam / USB'
                          : 'Take photo',
                      onTap: () => Get.back(result: ImageSource.camera),
                    ),
                    _scanSourceChip(
                      icon: Icons.photo_library_outlined,
                      label: _usesDesktopCameraPlugin() ? 'Browse' : 'Gallery',
                      subtitle: 'Choose photo',
                      onTap: () => Get.back(result: ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _scanSourceChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColor.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.primary.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: AppColor.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onGenerateWithAI() async {
    if (isGeneratingAiImage.value) return;

    final imageDescription = await ItemImageAiChatDialog.show(
      initialDescription: itemNameController.text.trim(),
    );
    if (imageDescription == null || imageDescription.isEmpty) return;

    isGeneratingAiImage.value = true;
    showAppLoader();
    try {
      final prompt =
          'Professional appetizing food photo of $imageDescription on a plate, restaurant menu, warm lighting, high quality';
      final path = await _pollinations.generateImage(prompt: prompt);
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Generated file missing');
      }
      selectedImage.value = file;
      imagePath.value = file.path;
      imageUrl.value = '';
      aiScanResult.value = null;
      showSuccess(description: 'AI image ready');
    } catch (e) {
      showError(description: 'Failed to generate image. Please try again.');
    } finally {
      isGeneratingAiImage.value = false;
      dismissAppLoader();
      dismissAllAppLoader();
    }
  }

  // Show manual upload options (Gallery/Camera)
  void showManualUploadOptions() {
    if (_usesDesktopCameraPlugin()) {
      _showManualUploadDialog();
      return;
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: const Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColor.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Generate with AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Generate a menu item image using AI',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Get.back();
                  onGenerateWithAI();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: AppColor.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Scan image with AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Extract item name and price from a photo',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Get.back();
                  scanImageWithAI();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: AppColor.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Choose from your photos',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Get.back();
                  uploadImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColor.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _usesDesktopCameraPlugin()
                      ? 'Webcam or USB document camera'
                      : 'Take a new photo',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Get.back();
                  uploadImageFromCamera();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showManualUploadDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: const Text(
                          'Select Image Source',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Generate with AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Generate a menu item image using AI',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Get.back();
                    onGenerateWithAI();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Scan image with AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Extract item name and price from a photo',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Get.back();
                    scanImageWithAI();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Choose from your photos',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Get.back();
                    uploadImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColor.primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Camera',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _usesDesktopCameraPlugin()
                        ? 'Webcam or USB document camera'
                        : 'Take a new photo',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Get.back();
                    uploadImageFromCamera();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void removeImage() {
    selectedImage.value = null;
    imagePath.value = '';
    imageUrl.value = '';
    aiScanResult.value = null;
    showSuccess(description: 'Image removed successfully');
  }

  String? validateItemName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(Get.context!)!.please_enter_item_name;
    }
    return null;
  }

  String? validateSalePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(Get.context!)!.please_enter_valid_sale_price;
    }
    final price = double.tryParse(value.trim());
    if (price == null || price < 0) {
      return AppLocalizations.of(Get.context!)!.please_enter_valid_sale_price;
    }
    return null;
  }

  String? validatePrepTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final minutes = int.tryParse(value.trim());
    if (minutes == null || minutes < 1) {
      return 'Enter a valid prep time (1 or more minutes)';
    }
    return null;
  }

  bool _validateForm() {
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    if (isComboItem.value && selectedComboComponents.isEmpty) {
      showError(description: 'Please add at least one item to this meal');
      return false;
    }
    if (hasVariantsEnabled.value) {
      if (variantDrafts.isEmpty) {
        showError(description: 'Add at least one variant');
        return false;
      }
      final names = <String>{};
      for (final draft in variantDrafts) {
        final name = draft.nameController.text.trim().toLowerCase();
        if (name.isEmpty) {
          showError(description: 'Every variant needs a name');
          return false;
        }
        if (names.contains(name)) {
          showError(description: 'Duplicate variant names are not allowed');
          return false;
        }
        names.add(name);
        final price = double.tryParse(draft.priceController.text.trim());
        if (price == null || price < 0) {
          showError(description: 'Enter a valid price for each variant');
          return false;
        }
      }
      if (!variantDrafts.any((draft) => draft.isDefault)) {
        variantDrafts.first.isDefault = true;
      }
    }
    return true;
  }

  void setVariantsEnabled(bool enabled) {
    hasVariantsEnabled.value = enabled;
    if (enabled && variantDrafts.isEmpty) {
      addVariantDraft(makeDefault: true);
    }
    if (!enabled) {
      clearVariantDrafts();
    }
  }

  void addVariantDraft({bool makeDefault = false}) {
    final draft = VariantDraft(
      nameController: TextEditingController(),
      priceController: TextEditingController(
        text: salePriceController.text.trim().isEmpty
            ? ''
            : salePriceController.text.trim(),
      ),
      isDefault: makeDefault || variantDrafts.isEmpty,
      sortOrder: variantDrafts.length,
    );
    if (draft.isDefault) {
      for (final existing in variantDrafts) {
        existing.isDefault = false;
      }
    }
    variantDrafts.add(draft);
    variantDrafts.refresh();
  }

  void removeVariantDraft(int index) {
    if (index < 0 || index >= variantDrafts.length) return;
    final removed = variantDrafts.removeAt(index);
    removed.dispose();
    if (variantDrafts.isNotEmpty && !variantDrafts.any((d) => d.isDefault)) {
      variantDrafts.first.isDefault = true;
      syncDefaultVariantPriceToBase();
    }
    variantDrafts.refresh();
  }

  void setDefaultVariantDraft(int index) {
    if (index < 0 || index >= variantDrafts.length) return;
    for (var i = 0; i < variantDrafts.length; i++) {
      variantDrafts[i].isDefault = i == index;
    }
    syncDefaultVariantPriceToBase();
    variantDrafts.refresh();
  }

  void syncDefaultVariantPriceToBase() {
    final defaultDraft = variantDrafts.firstWhereOrNull((d) => d.isDefault);
    if (defaultDraft == null) return;
    salePriceController.text = defaultDraft.priceController.text.trim();
  }

  void clearVariantDrafts() {
    for (final draft in variantDrafts) {
      draft.dispose();
    }
    variantDrafts.clear();
  }

  List<MenuItemVariantInput> buildVariantInputs() {
    if (!hasVariantsEnabled.value) return const [];
    return variantDrafts.asMap().entries.map((entry) {
      final draft = entry.value.toInput();
      return MenuItemVariantInput(
        id: draft.id,
        name: draft.name,
        sku: draft.sku,
        barcode: draft.barcode,
        salePrice: draft.salePrice,
        costPrice: draft.costPrice,
        trackStock: draft.trackStock,
        stockQuantity: draft.stockQuantity,
        minStock: draft.minStock,
        isDefault: draft.isDefault,
        isActive: draft.isActive,
        sortOrder: entry.key,
      );
    }).toList();
  }

  void loadVariantsFromItem(ItemData item) {
    clearVariantDrafts();
    final activeVariants = item.variants.where((v) => v.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    hasVariantsEnabled.value = item.hasVariants || activeVariants.isNotEmpty;
    if (!hasVariantsEnabled.value) return;
    for (final variant in activeVariants) {
      variantDrafts.add(VariantDraft.fromVariant(variant));
    }
    if (variantDrafts.isEmpty) {
      addVariantDraft(makeDefault: true);
    }
  }

  void selectCategory(String category) {
    final normalized = category.trim().toLowerCase();
    final match = categories.firstWhereOrNull(
      (c) => c.trim().toLowerCase() == normalized,
    );
    selectedCategory.value = match ?? category.trim();
    isComboItem.value = normalized == comboCategoryName;
    if (!isComboItem.value) {
      costPriceController.clear();
    }
  }

  /// Quick-add a category from the add-item form and select it.
  Future<void> showQuickAddCategoryDialog() async {
    final context = Get.context;
    if (context == null) return;

    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isSaving = false.obs;

    try {
      final createdName = await Get.dialog<String>(
        Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Builder(
              builder: (dialogContext) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  color: AppColor.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loc.add_category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: loc.cancel,
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.close),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text(
                            loc.enter_category_name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: TextFormField(
                            controller: nameController,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: loc.category_name,
                              hintText: loc.enter_category_name,
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty ||
                                  trimmed.toLowerCase() == 'none') {
                                return loc.category_name_cannot_be_empty;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) async {
                              if (isSaving.value) return;
                              await _submitQuickAddCategory(
                                formKey: formKey,
                                nameController: nameController,
                                isSaving: isSaving,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving.value
                                        ? null
                                        : () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      side:
                                          BorderSide(color: Colors.grey[300]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text(loc.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving.value
                                        ? null
                                        : () => _submitQuickAddCategory(
                                            formKey: formKey,
                                            nameController: nameController,
                                            isSaving: isSaving,
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          AppColor.primary.withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: isSaving.value
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(loc.add_category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barrierDismissible: false,
      );

      if (createdName != null && createdName.isNotEmpty) {
        selectCategory(createdName);
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _submitQuickAddCategory({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required RxBool isSaving,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSaving.value) return;

    isSaving.value = true;
    try {
      final created = await createCategoryQuick(nameController.text);
      if (created != null) {
        Get.back(result: created);
      }
    } finally {
      isSaving.value = false;
    }
  }

  /// Creates a category via API (or returns existing local match), then refreshes lists.
  Future<String?> createCategoryQuick(String rawName) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final name = rawName.trim();
    if (name.isEmpty || name.toLowerCase() == 'none') {
      showError(description: loc.category_name_cannot_be_empty);
      return null;
    }

    final normalized = name.toLowerCase();
    final existing = categories.firstWhereOrNull(
      (c) => c.trim().toLowerCase() == normalized,
    );
    if (existing != null) return existing;

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) return null;

    final response = await callApi(
      apiClient.addCategory(outletId, {
        'userId': userId,
        'outletId': outletId,
        'categoryName': normalized,
      }),
      showLoader: false,
    );

    if (response == null || response['status'] != 'success') {
      showError(
        description: response?['message'] ?? loc.failed_to_add_category,
      );
      return null;
    }

    await getCategories();
    await _refreshCategoryListsOnly();

    final match = categories.firstWhereOrNull(
      (c) => c.trim().toLowerCase() == normalized,
    );
    if (match == null) {
      _setCategoryNames([...categories, name]);
    }

    showSuccess(
      description: response['message'] ?? loc.category_added_successfully,
    );
    return categories.firstWhereOrNull(
          (c) => c.trim().toLowerCase() == normalized,
        ) ??
        name;
  }

  Future<void> _refreshCategoryListsOnly() async {
    try {
      if (Get.isRegistered<MenuItemController>()) {
        await Get.find<MenuItemController>().getCategories();
      }
    } catch (e) {
      debugPrint('Failed to refresh menu categories: $e');
    }

    try {
      if (Get.isRegistered<AddOrderController>()) {
        await Get.find<AddOrderController>().getCategories();
      }
    } catch (e) {
      debugPrint('Failed to refresh add-order categories: $e');
    }
  }

  void setComboItem(bool value) {
    isComboItem.value = value;
    if (value) {
      final existing = categories.firstWhereOrNull(
        (c) => c.trim().toLowerCase() == comboCategoryName,
      );
      if (existing == null) {
        _setCategoryNames([...categories, comboCategoryName]);
      }
      selectedCategory.value = existing ?? comboCategoryName;
    } else {
      costPriceController.clear();
      if (selectedCategory.value.trim().toLowerCase() == comboCategoryName) {
        selectedCategory.value = 'none';
        comboComponentQuantities.clear();
      }
    }
  }

  /// Persists the selected category (e.g. "combo") so menu/order screens can show it.
  Future<void> _ensureSelectedCategoryExists() async {
    final categoryName = selectedCategory.value.trim().toLowerCase();
    if (categoryName.isEmpty || categoryName == 'none') return;

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) return;

    if (Get.isRegistered<MenuItemController>()) {
      final menu = Get.find<MenuItemController>();
      final alreadyPersisted = menu.categories.any(
        (c) => c.categoryName.trim().toLowerCase() == categoryName,
      );
      if (alreadyPersisted) return;
    }

    if (!await NetworkUtils.hasInternetConnection()) {
      await AppDatabase().upsertCategory(
        CategoryData(
          id: 'local_cat_${categoryName.hashCode.abs()}',
          userId: userId,
          outletId: outletId,
          categoryName: selectedCategory.value,
          imageURL: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    await callApi(
      apiClient.addCategory(outletId, {
        'userId': userId,
        'outletId': outletId,
        'categoryName': categoryName,
      }),
      showLoader: false,
      // Category may already exist on the server — ignore conflict toasts.
      apiErrorHandler: (_) async => true,
    );
  }

  Future<void> _refreshRelatedLists() async {
    try {
      if (Get.isRegistered<MenuItemController>()) {
        final menu = Get.find<MenuItemController>();
        await menu.getCategories();
        await menu.getItems(showLoader: false, forceApiRefresh: true);
      }
    } catch (e) {
      debugPrint('Failed to refresh menu lists: $e');
    }

    try {
      if (Get.isRegistered<AddOrderController>()) {
        final addOrderController = Get.find<AddOrderController>();
        await addOrderController.getCategories();
        addOrderController.resetPagination();
        await addOrderController.getItems();
      }
    } catch (e) {
      debugPrint('Failed to refresh add-order lists: $e');
    }
  }

  List<ItemData> _comboOptionSource() {
    _ensureMenuItemController();
    if (comboOptionItems.isNotEmpty) {
      return List<ItemData>.from(comboOptionItems);
    }
    final menu = menuItemController;
    if (menu == null) return const [];
    if (menu.allItems.isNotEmpty) return List<ItemData>.from(menu.allItems);
    return List<ItemData>.from(menu.items);
  }

  void _ensureMenuItemController() {
    if (menuItemController != null) return;
    if (Get.isRegistered<MenuItemController>()) {
      menuItemController = Get.find<MenuItemController>();
    }
  }

  void _rememberComboOptions(Iterable<ItemData> items) {
    for (final item in items) {
      if (item.id.isNotEmpty) {
        _comboKnownItems[item.id] = item;
      }
    }
  }

  ItemData? _findKnownComboItem(String id) {
    if (id.isEmpty) return null;
    final known = _comboKnownItems[id];
    if (known != null) return known;
    _ensureMenuItemController();
    final menu = menuItemController;
    if (menu == null) return null;
    for (final item in menu.allItems) {
      if (item.id == id) return item;
    }
    for (final item in menu.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<ItemData> get comboComponentOptions {
    final currentId = itemId.value;
    return _comboOptionSource()
        .where(
          (item) =>
              item.id.isNotEmpty && item.id != currentId && !item.isCombo,
        )
        .toList();
  }

  /// Instantly fills picker options from in-memory menu items (no network).
  void seedComboComponentOptions({bool force = false}) {
    if (!force && comboOptionItems.isNotEmpty) return;
    final cached = <ItemData>[];
    _ensureMenuItemController();
    final menu = menuItemController;
    if (menu != null) {
      if (menu.allItems.isNotEmpty) {
        cached.addAll(menu.allItems);
      } else {
        cached.addAll(menu.items);
      }
    }
    if (cached.isNotEmpty) {
      _rememberComboOptions(cached);
      comboOptionItems.assignAll(cached);
    }
  }

  Future<void> loadComboComponentOptions({String? search}) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    final query = (search ?? comboSearchQuery.value).trim();
    if (query.isEmpty) {
      seedComboComponentOptions();
    }

    final requestId = ++_comboOptionsRequestId;
    final hadCachedOptions = comboOptionItems.isNotEmpty && query.isEmpty;
    if (!hadCachedOptions) {
      isLoadingComboOptions.value = true;
    }
    try {
      final isOnline = await NetworkUtils.hasInternetConnection();
      if (isOnline) {
        final response = await callApi(
          apiClient.getItems(
            outletId,
            1,
            200,
            null,
            query.isEmpty ? null : query,
            null,
            null,
          ),
          showLoader: false,
        );
        if (requestId != _comboOptionsRequestId) return;
        if (response?.status == 'success') {
          _rememberComboOptions(response!.data);
          comboOptionItems.assignAll(response.data);
          return;
        }
      }

      final local = await AppDatabase().getItemsPage(
        outletId: outletId,
        limit: 100,
        searchQuery: query.isEmpty ? null : query,
      );
      if (requestId != _comboOptionsRequestId) return;
      _rememberComboOptions(local.items);
      comboOptionItems.assignAll(local.items);
    } finally {
      if (requestId == _comboOptionsRequestId) {
        isLoadingComboOptions.value = false;
      }
    }
  }

  void filterComboComponentOptions(String query) {
    final trimmed = query.trim();
    comboSearchQuery.value = trimmed;
    _comboSearchDebounce?.cancel();
    if (trimmed.isEmpty) {
      seedComboComponentOptions(force: true);
      loadComboComponentOptions(search: '');
      return;
    }
    _comboSearchDebounce = Timer(_comboSearchDebounceDuration, () {
      loadComboComponentOptions(search: trimmed);
    });
  }

  void clearComboComponentSearch({bool reload = true}) {
    _comboSearchDebounce?.cancel();
    _comboSearchDebounce = null;
    comboSearchController.clear();
    comboSearchQuery.value = '';
    if (reload) {
      seedComboComponentOptions(force: true);
      loadComboComponentOptions(search: '');
    }
  }

  List<ComboComponent> get selectedComboComponents => comboComponentQuantities
      .entries
      .where((entry) => entry.value > 0)
      .map((entry) => ComboComponent(itemId: entry.key, quantity: entry.value))
      .toList();

  List<ItemData> get selectedComboItems {
    final items = <ItemData>[];
    for (final entry in comboComponentQuantities.entries) {
      final item = _findKnownComboItem(entry.key);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// Sets cost price from Σ(component price with tax × qty). Sale price stays editable.
  void _recalculateComboPrices() {
    if (!isComboItem.value) return;

    final totals = comboCostBreakdown;
    if (totals.total > 0) {
      costPriceController.text = _formatComboAmount(totals.total);
    } else {
      costPriceController.clear();
    }
  }

  /// Tax added on top of sale price when the item is marked with tax.
  double comboItemTaxAmount(ItemData item) {
    if (!item.withTax || item.gst <= 0 || item.salePrice <= 0) return 0;
    return item.salePrice * item.gst / 100.0;
  }

  double comboItemPriceWithTax(ItemData item) {
    return item.salePrice + comboItemTaxAmount(item);
  }

  /// Base + tax totals for selected meal items (qty applied).
  ({double base, double tax, double total}) get comboCostBreakdown {
    double base = 0;
    double tax = 0;
    for (final entry in comboComponentQuantities.entries) {
      if (entry.value <= 0) continue;
      final item = _findKnownComboItem(entry.key);
      if (item == null) continue;
      base += item.salePrice * entry.value;
      tax += comboItemTaxAmount(item) * entry.value;
    }
    return (base: base, tax: tax, total: base + tax);
  }

  String _formatComboAmount(double value) {
    return value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
  }

  void setComboComponent(ItemData item, bool selected) {
    if (item.id.isEmpty) return;
    _rememberComboOptions([item]);
    if (selected) {
      comboComponentQuantities[item.id] =
          comboComponentQuantities[item.id] ?? 1;
    } else {
      comboComponentQuantities.remove(item.id);
    }
    comboComponentQuantities.refresh();
    _recalculateComboPrices();
  }

  void incrementComboComponent(String itemId) {
    comboComponentQuantities[itemId] =
        (comboComponentQuantities[itemId] ?? 0) + 1;
    comboComponentQuantities.refresh();
    _recalculateComboPrices();
  }

  void decrementComboComponent(String itemId) {
    final current = comboComponentQuantities[itemId] ?? 0;
    if (current <= 1) {
      comboComponentQuantities.remove(itemId);
    } else {
      comboComponentQuantities[itemId] = current - 1;
    }
    comboComponentQuantities.refresh();
    _recalculateComboPrices();
  }

  void saveAndNew() {
    if (!StaffAccess.ensure(StaffAccess.canCreateProducts)) return;
    // Save and keep screen open; reset only after SUCCESS.
    if (!_validateForm()) return;
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    onAddItem(closeOnSuccess: false);
  }

  void showDeleteConfirmationDialog() {
    if (!StaffAccess.ensure(StaffAccess.canDeleteProducts)) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close the dialog
              onDeleteItem();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void onDeleteItem() async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteProducts)) return;
    await ItemCatalogSync(
      apiClient: apiClient,
    ).deleteItemOnlineOrOffline(itemId.value.trim());
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    menuItemController?.getItems(showLoader: false, forceApiRefresh: true);
    if (Modular.to.canPop()) {
      Modular.to.pop();
    }
    isEdit.value = false;
    resetForm();
    showSuccess(description: 'Item deleted');
  }

  void saveItem() {
    if (!StaffAccess.ensure(StaffAccess.canCreateProducts)) return;
    debugPrint('Save item called. isEdit: ${isEdit.value}');
    if (!_validateForm()) return;
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    onAddItem(closeOnSuccess: true);
  }

  void onUpdateItem() async {
    if (!StaffAccess.ensure(StaffAccess.canUpdateProducts)) return;
    if (!_validateForm()) return;
    if (selectedImage.value != null &&
        await NetworkUtils.hasInternetConnection()) {
      await uploadItemImage();
    }
    await _ensureSelectedCategoryExists();
    final request = ItemRequest(
      showItem: isAvailable.value,
      isRecommended: markAsFavorite.value,
      outletId: appPref.selectedOutlet!.id!,
      userId: appPref.user!.id!,
      itemName: itemNameController.text,
      itemImage: imageUrl.value,
      salePrice: double.tryParse(salePriceController.text) ?? 0.0,
      withTax: isWithTax.value,
      gst: selectedTaxPercentage.value == 'None'
          ? 0.0
          : double.parse(selectedTaxPercentage.value),
      category: selectedCategory.value == 'none'
          ? 'none'
          : selectedCategory.value,
      orderFrom: 'None',
      barcode: barcodeController.text.trim(),
      sku: skuController.text.trim(),
      soldBy: selectedSoldBy.value,
      costPrice: double.tryParse(costPriceController.text) ?? 0.0,
      posColor: selectedPosColor.value,
      trackStock: trackStock.value,
      stockQuantity: double.tryParse(stockController.text) ?? 0.0,
      minStock: double.tryParse(minStockController.text) ?? 0.0,
      prepTimeMinutes: _parsedPrepTimeMinutes(),
      isCombo: isComboItem.value,
      comboComponents: selectedComboComponents,
      linkedRecipeItemId: linkedRecipeItemId.value.trim(),
      hasVariants: hasVariantsEnabled.value,
      variants: buildVariantInputs(),
    );
    final saved = await ItemCatalogSync(
      apiClient: apiClient,
    ).saveItemOnlineOrOffline(
      request: request,
      existingId: itemId.value.trim(),
    );
    if (saved != null) {
      selectedImage.value = null;
      imagePath.value = '';
      aiScanResult.value = null;
      await _refreshRelatedLists();
      Get.back();
      dismissAllAppLoader();
      showSuccess(description: 'Item updated');
    }
  }

  // Load categories from API or offline cache
  Future<void> getCategories() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    final categoryList = await OfflineCategoryLoader.load(
      outletId: outletId,
      fetchFromApi: () => callApi(apiClient.getCategories(outletId)),
    );

    categoryDetails.assignAll(categoryList);
    _setCategoryNames(categoryList.map((e) => e.categoryName));
    dismissAllAppLoader();
  }

  // Edit Mode Logic
  void configureFromArgs(Map<String, dynamic>? args) {
    // Always start from a clean state
    isEdit.value = false;
    itemNameController.clear();
    salePriceController.clear();
    costPriceController.clear();
    barcodeController.clear();
    skuController.clear();
    stockController.clear();
    minStockController.clear();
    prepTimeController.text = '15';
    selectedCategory.value = 'none';
    selectedTaxPercentage.value = 'None';
    isWithTax.value = false;
    isAvailable.value = true;
    trackStock.value = false;
    selectedSoldBy.value = 'Each';
    selectedPosColor.value = '';
    markAsFavorite.value = false;
    isComboItem.value = false;
    comboComponentQuantities.clear();
    itemId.value = '';
    imageUrl.value = '';
    selectedImage.value = null;
    imagePath.value = '';
    aiScanResult.value = null;
    linkedRecipeItemId.value = '';
    clearVariantDrafts();
    hasVariantsEnabled.value = false;

    if (args == null) return;

    final bool edit = args['isEdit'] == true;
    isEdit.value = edit;

    if (!edit) {
      _applyCategoryFromArgs(args['category']);
      isComboItem.value =
          selectedCategory.value.trim().toLowerCase() == comboCategoryName;
      return;
    }

    if (args['item'] == null) return;

    final item = args['item'] as ItemData;

    itemNameController.text = item.itemName;
    salePriceController.text = item.salePrice.toString();
    costPriceController.text =
        item.costPrice > 0 ? item.costPrice.toString() : '';
    barcodeController.text = item.barcode;
    skuController.text = item.sku;
    stockController.text =
        item.trackStock ? item.stockQuantity.toString() : '';
    minStockController.text = item.minStock > 0 ? item.minStock.toString() : '';
    prepTimeController.text = item.prepTimeMinutes.toString();
    trackStock.value = item.trackStock;
    selectedSoldBy.value =
        soldByOptions.contains(item.soldBy) ? item.soldBy : 'Each';
    selectedPosColor.value = item.posColor;

    _applyCategoryFromArgs(item.category);
    isComboItem.value =
        item.isCombo ||
        selectedCategory.value.trim().toLowerCase() == comboCategoryName;
    comboComponentQuantities.assignAll({
      for (final component in item.comboComponents)
        if (component.itemId.isNotEmpty && component.quantity > 0)
          component.itemId: component.quantity,
    });

    isWithTax.value = item.withTax;
    itemId.value = item.id;

    imageUrl.value = item.itemImage;
    isAvailable.value = item.showItem;
    markAsFavorite.value = item.isRecommended;
    linkedRecipeItemId.value = item.linkedRecipeItemId;
    selectedTaxPercentage.value = double.parse(item.gst.toString()).round() == 0
        ? 'None'
        : '${double.parse(item.gst.toString()).toInt()}';
    loadVariantsFromItem(item);
  }

  void _applyCategoryFromArgs(dynamic categoryArg) {
    if (categoryArg == null) return;
    final categoryName = categoryArg is String
        ? categoryArg
        : (categoryArg is CategoryData ? categoryArg.categoryName : null);
    if (categoryName == null ||
        categoryName.isEmpty ||
        categoryName.toLowerCase() == 'none') {
      return;
    }

    final normalized = categoryName.toLowerCase();
    final match = categories.firstWhereOrNull(
      (c) => c.toLowerCase() == normalized,
    );
    if (match != null) {
      selectedCategory.value = match;
      return;
    }

    // Category may have just been created and not yet in this screen's list.
    if (!categories.any((c) => c.toLowerCase() == normalized)) {
      _setCategoryNames([...categories, categoryName]);
    }
    selectedCategory.value =
        categories.firstWhereOrNull((c) => c.toLowerCase() == normalized) ??
        categoryName;
  }

  void _seedCategoriesFromMenuController() {
    try {
      if (!Get.isRegistered<MenuItemController>()) return;
      final menuCategories = Get.find<MenuItemController>().categories;
      if (menuCategories.isEmpty) return;

      categoryDetails.assignAll(menuCategories);
      _setCategoryNames(menuCategories.map((e) => e.categoryName));
    } catch (e) {
      debugPrint('Failed to seed categories from menu screen: $e');
    }
  }

  /// Called each time the add-item screen opens so category args stay in sync.
  Future<void> prepareScreen(Map<String, dynamic>? args) async {
    _seedCategoriesFromMenuController();
    await getCategories();
    configureFromArgs(args);
  }

  int _parsedPrepTimeMinutes() {
    final parsed = int.tryParse(prepTimeController.text.trim());
    if (parsed == null || parsed < 1) return 15;
    return parsed;
  }

  // Save API Call
  void resetForm() {
    itemNameController.clear();
    salePriceController.clear();
    costPriceController.clear();
    barcodeController.clear();
    skuController.clear();
    stockController.clear();
    minStockController.clear();
    prepTimeController.text = '15';
    selectedCategory.value = 'none';
    selectedTaxPercentage.value = 'None';
    isWithTax.value = false;
    isAvailable.value = true;
    trackStock.value = false;
    selectedSoldBy.value = 'Each';
    selectedPosColor.value = '';
    selectedImage.value = null;
    imagePath.value = '';
    imageUrl.value = '';
    aiScanResult.value = null;
    makeDefaultTax.value = true;
    markAsFavorite.value = false;
    isComboItem.value = false;
    comboComponentQuantities.clear();
    linkedRecipeItemId.value = '';
    clearVariantDrafts();
    hasVariantsEnabled.value = false;
  }

  // Save API Call
  void onAddItem({required bool closeOnSuccess}) async {
    if (selectedImage.value != null &&
        await NetworkUtils.hasInternetConnection()) {
      final ok = await uploadItemImage();
      if (!ok) return;
    }

    await _ensureSelectedCategoryExists();

    final request = ItemRequest(
      showItem: isAvailable.value,
      isRecommended: markAsFavorite.value,
      userId: appPref.user!.id!,
      outletId: appPref.selectedOutlet!.id!,
      itemName: itemNameController.text,
      itemImage: imageUrl.value,
      salePrice: double.tryParse(salePriceController.text) ?? 0.0,
      withTax: isWithTax.value,
      gst: selectedTaxPercentage.value == 'None'
          ? 0.0
          : double.parse(selectedTaxPercentage.value),
      category: selectedCategory.value == 'none'
          ? 'none'
          : selectedCategory.value,
      orderFrom: 'None',
      barcode: barcodeController.text.trim(),
      sku: skuController.text.trim(),
      soldBy: selectedSoldBy.value,
      costPrice: double.tryParse(costPriceController.text) ?? 0.0,
      posColor: selectedPosColor.value,
      trackStock: trackStock.value,
      stockQuantity: double.tryParse(stockController.text) ?? 0.0,
      minStock: double.tryParse(minStockController.text) ?? 0.0,
      prepTimeMinutes: _parsedPrepTimeMinutes(),
      isCombo: isComboItem.value,
      comboComponents: selectedComboComponents,
      linkedRecipeItemId: linkedRecipeItemId.value.trim(),
      hasVariants: hasVariantsEnabled.value,
      variants: buildVariantInputs(),
    );

    final saved = await ItemCatalogSync(
      apiClient: apiClient,
    ).saveItemOnlineOrOffline(request: request);

    if (saved != null) {
      await _refreshRelatedLists();
      showSuccess(description: 'Item added successfully');
      resetForm();
      if (closeOnSuccess) {
        Get.back();
      }
    } else {
      showError(description: 'Failed to add item');
    }
  }

  Future<bool> uploadItemImage() async {
    final response = await callApi(
      MediaApi().uploadImage(
        file: File(selectedImage.value!.path),
        folderName: 'items',
        outletId: appPref.selectedOutlet!.id!,
        userId: appPref.user!.id!,
      ),
    );
    if (response?.data?['url'] != null) {
      imageUrl.value = response!.data['url'];
      return true;
    }
    showError(description: 'Image upload failed. Please try again.');
    return false;
  }

  void initializecontroller() {
    if (Get.isRegistered<MenuItemController>()) {
      menuItemController = Get.find<MenuItemController>();
    } else {
      debugPrint('MenuItemController not registered yet');
    }
  }

  @override
  void onInit() {
    initializecontroller();
    super.onInit();
  }

  /// Scan menu item using AI
  Future<void> scanMenuWithAI() async {
    if (selectedImage.value == null) {
      showError(description: 'Please select an image first');
      return;
    }

    try {
      isScanning.value = true;
      showAppLoader();

      debugPrint('🤖 [AI] Starting AI scan...');
      final result = await _aiScanner.scanMenuFromPhoto(selectedImage.value!);

      aiScanResult.value = result;

      if (result.isValid) {
        // Auto-fill form fields with AI results
        if (result.itemName.isNotEmpty) {
          itemNameController.text = result.itemName;
        }

        if (result.price != null) {
          salePriceController.text = result.price!.toStringAsFixed(2);
        }

        if (result.category != null && categories.contains(result.category)) {
          selectCategory(result.category!);
        }

        dismissAppLoader();
        showSuccess(
          description:
              'AI scan completed! Found: ${result.itemName}${result.price != null ? " - ₹${result.price}" : ""}',
        );
      } else {
        dismissAppLoader();
        showError(
          description:
              'Could not extract menu information. Use a clear photo with readable item name and price, and ensure internet is available for AI scan on desktop.',
        );
      }
    } catch (e) {
      dismissAppLoader();
      debugPrint('❌ [AI] Scan error: $e');
      showError(description: 'AI scan failed: ${e.toString()}');
    } finally {
      isScanning.value = false;
    }
  }

  /// Opens barcode scan options (handheld USB / phone camera) and fills
  /// [barcodeController] with the result.
  Future<void> scanBarcode() async {
    final method = await Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppColor.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Scan barcode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to scan',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                _scanMethodTile(
                  icon: Icons.scanner,
                  title: 'Handheld scanner (USB)',
                  subtitle: 'Retsol LS450 or any keyboard scanner',
                  onTap: () => Get.back(result: 'usb'),
                ),
                const SizedBox(height: 10),
                _scanMethodTile(
                  icon: Icons.phone_android,
                  title: 'Phone camera',
                  subtitle: 'Use BillKaro mobile on the same Wi‑Fi',
                  onTap: () => Get.back(result: 'phone'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (method == null) return;

    final String? result;
    if (method == 'phone') {
      result = await showPhoneBarcodePairDialog();
    } else {
      result = await _scanBarcodeWithHandheld();
    }

    if (result == null || result.isEmpty) return;
    barcodeController.text = result;
    showSuccess(description: 'Barcode scanned: $result');
    await lookupOpenFoodFactsByBarcode(result);
  }

  /// Fetches product details from Open Food Facts and fills/refreshes the form.
  Future<void> lookupOpenFoodFactsByBarcode([String? barcode]) async {
    final code = (barcode ?? barcodeController.text).trim();
    if (code.isEmpty) {
      showError(description: 'Enter or scan a barcode first');
      return;
    }

    showAppLoader();
    try {
      final details = await OpenFoodFactsService.fetchByBarcode(code);
      if (details == null) {
        showError(
          description: 'No product found on Open Food Facts for $code',
        );
        return;
      }

      barcodeController.text = details.barcode;

      final name = details.displayName;
      if (name != null && name.isNotEmpty) {
        itemNameController.text = name;
      }

      if (details.imageUrl != null && details.imageUrl!.isNotEmpty) {
        final file =
            await OpenFoodFactsService.downloadImage(details.imageUrl!);
        if (file != null) {
          selectedImage.value = file;
          imagePath.value = file.path;
          // Clear previous remote URL so the new local file is used on save.
          imageUrl.value = '';
        }
      }

      if (details.price != null && details.price! > 0) {
        salePriceController.text = details.price!
            .toStringAsFixed(details.price!.truncateToDouble() == details.price! ? 0 : 2);
      }

      final priceLabel = details.price != null
          ? ' · ₹${details.price}'
          : '';
      showSuccess(
        description: name != null && name.isNotEmpty
            ? 'Updated from Open Food Facts: $name$priceLabel'
            : 'Product updated from Open Food Facts$priceLabel',
      );
    } finally {
      dismissAppLoader();
    }
  }

  Widget _scanMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColor.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _scanBarcodeWithHandheld() async {
    final inputController = TextEditingController(
      text: barcodeController.text,
    );
    final result = await Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppColor.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Handheld scanner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Plug in your handheld scanner (e.g. Retsol LS450) via USB.\n'
                  '2. Keep this box focused (already ready).\n'
                  '3. Aim at the barcode and press the trigger.\n'
                  'The code will appear here automatically — then press Enter or Use barcode.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: inputController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isNotEmpty) Get.back(result: trimmed);
                  },
                  decoration: InputDecoration(
                    hintText: 'Point scanner here and pull the trigger…',
                    prefixIcon: Icon(
                      Icons.qr_code_scanner,
                      color: AppColor.primary,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColor.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final trimmed = inputController.text.trim();
                          if (trimmed.isEmpty) return;
                          Get.back(result: trimmed);
                        },
                        child: const Text('Use barcode'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
    inputController.dispose();
    return result;
  }

  @override
  void onClose() {
    _comboSearchDebounce?.cancel();
    comboSearchController.dispose();
    itemNameController.dispose();
    salePriceController.dispose();
    costPriceController.dispose();
    barcodeController.dispose();
    skuController.dispose();
    stockController.dispose();
    minStockController.dispose();
    prepTimeController.dispose();
    super.onClose();
  }
}

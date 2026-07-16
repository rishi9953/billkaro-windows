// Controller
import 'dart:io';
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/Widgets/item_image_ai_chat_dialog.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/combo_component.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:billkaro/app/services/ai/pollinations_ai_image_service.dart';
import 'package:billkaro/config/config.dart';
import '../../services/Modals/Categories/categories_response.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';

class AddMenuItemController extends BaseController {
  static const String comboCategoryName = 'combo';

  final formKey = GlobalKey<FormState>();
  final itemNameController = TextEditingController();
  final salePriceController = TextEditingController();
  final prepTimeController = TextEditingController(text: '15');
  late MenuItemController menuItemController;

  var selectedCategory = 'none'.obs;
  var selectedTaxPercentage = 'None'.obs;
  var isWithTax = false.obs;
  var makeDefaultTax = true.obs;
  var markAsFavorite = false.obs;
  var isComboItem = false.obs;
  final RxMap<String, double> comboComponentQuantities = <String, double>{}.obs;
  final RxList<ItemData> comboOptionItems = <ItemData>[].obs;
  final isLoadingComboOptions = false.obs;
  var itemId = ''.obs;
  var imageUrl = ''.obs;
  var isAvailable = true.obs;
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

  // Default category list
  RxList<String> categories = <String>['none'].obs;

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
    return true;
  }

  void selectCategory(String category) {
    final normalized = category.trim().toLowerCase();
    final match = categories.firstWhereOrNull(
      (c) => c.trim().toLowerCase() == normalized,
    );
    selectedCategory.value = match ?? category.trim();
    isComboItem.value = normalized == comboCategoryName;
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
    } else if (selectedCategory.value.trim().toLowerCase() ==
        comboCategoryName) {
      selectedCategory.value = 'none';
      comboComponentQuantities.clear();
    }
  }

  List<ItemData> get comboComponentOptions {
    try {
      final source = comboOptionItems.isNotEmpty
          ? comboOptionItems
          : menuItemController.allItems.isNotEmpty
          ? menuItemController.allItems
          : menuItemController.items;
      return source
          .where((item) => item.id != itemId.value && !item.isCombo)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> loadComboComponentOptions() async {
    if (isLoadingComboOptions.value) return;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    isLoadingComboOptions.value = true;
    try {
      final response = await callApi(
        apiClient.getItems(outletId, 1, 500, null, null, null, null),
        showLoader: false,
      );
      if (response?.status == 'success') {
        comboOptionItems.assignAll(response!.data);
      }
    } finally {
      isLoadingComboOptions.value = false;
    }
  }

  List<ComboComponent> get selectedComboComponents => comboComponentQuantities
      .entries
      .where((entry) => entry.value > 0)
      .map((entry) => ComboComponent(itemId: entry.key, quantity: entry.value))
      .toList();

  List<ItemData> get selectedComboItems => comboComponentOptions
      .where((item) => comboComponentQuantities.containsKey(item.id))
      .toList();

  void setComboComponent(ItemData item, bool selected) {
    if (selected) {
      comboComponentQuantities[item.id] =
          comboComponentQuantities[item.id] ?? 1;
    } else {
      comboComponentQuantities.remove(item.id);
    }
  }

  void incrementComboComponent(String itemId) {
    comboComponentQuantities[itemId] =
        (comboComponentQuantities[itemId] ?? 0) + 1;
  }

  void decrementComboComponent(String itemId) {
    final current = comboComponentQuantities[itemId] ?? 0;
    if (current <= 1) {
      comboComponentQuantities.remove(itemId);
      return;
    }
    comboComponentQuantities[itemId] = current - 1;
  }

  void saveAndNew() {
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
    final response = await callApi(apiClient.deleteItem(itemId.value.trim()));
    if (response['status'] == 'success') {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      menuItemController.getItems(showLoader: false, forceApiRefresh: true);
      if (Modular.to.canPop()) {
        Modular.to.pop();
      }
      isEdit.value = false;
      resetForm();
      showSuccess(description: response['message']);
    }
  }

  void saveItem() {
    debugPrint('Save item called. isEdit: ${isEdit.value}');
    if (!_validateForm()) return;
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    onAddItem(closeOnSuccess: false);
  }

  void onUpdateItem() async {
    if (!_validateForm()) return;
    if (selectedImage.value != null) {
      await uploadItemImage();
    }
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
      prepTimeMinutes: _parsedPrepTimeMinutes(),
      isCombo: isComboItem.value,
      comboComponents: selectedComboComponents,
    );
    final response = await callApi(
      apiClient.updateItem(request, itemId.value.trim()),
    );
    if (response['status'] == 'success') {
      selectedImage.value = null;
      imagePath.value = '';
      aiScanResult.value = null;
      Get.back();
      menuItemController.getItems(showLoader: false, forceApiRefresh: true);
      dismissAllAppLoader();
      showSuccess(description: response['message']);
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

    _setCategoryNames(categoryList.map((e) => e.categoryName));
    dismissAllAppLoader();
  }

  // Edit Mode Logic
  void configureFromArgs(Map<String, dynamic>? args) {
    // Always start from a clean state
    isEdit.value = false;
    itemNameController.clear();
    salePriceController.clear();
    prepTimeController.text = '15';
    selectedCategory.value = 'none';
    selectedTaxPercentage.value = 'None';
    isWithTax.value = false;
    isAvailable.value = true;
    markAsFavorite.value = false;
    isComboItem.value = false;
    comboComponentQuantities.clear();
    itemId.value = '';
    imageUrl.value = '';
    selectedImage.value = null;
    imagePath.value = '';
    aiScanResult.value = null;

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
    prepTimeController.text = item.prepTimeMinutes.toString();

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
    selectedTaxPercentage.value = double.parse(item.gst.toString()).round() == 0
        ? 'None'
        : '${double.parse(item.gst.toString()).toInt()}';
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
    prepTimeController.text = '15';
    selectedCategory.value = 'none';
    selectedTaxPercentage.value = 'None';
    isWithTax.value = false;
    isAvailable.value = true;
    selectedImage.value = null;
    imagePath.value = '';
    imageUrl.value = '';
    aiScanResult.value = null;
    makeDefaultTax.value = true;
    markAsFavorite.value = false;
    isComboItem.value = false;
    comboComponentQuantities.clear();
  }

  // Save API Call
  void onAddItem({required bool closeOnSuccess}) async {
    if (selectedImage.value != null) {
      final ok = await uploadItemImage();
      if (!ok) {
        // uploadItemImage already shows an error
        return;
      }
    }

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
      prepTimeMinutes: _parsedPrepTimeMinutes(),
      isCombo: isComboItem.value,
      comboComponents: selectedComboComponents,
    );

    final response = await callApi(apiClient.addItem(request));

    if (response['status'] == 'success') {
      menuItemController.getItems(showLoader: false, forceApiRefresh: true);
      showSuccess(
        description: response['message'] ?? 'Item added successfully',
      );
      // Clear the form after a successful add (requested behavior).
      resetForm();
      if (closeOnSuccess) {
        Get.back();
      }
    } else {
      showError(description: response['message'] ?? 'Failed to add item');
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
    try {
      menuItemController = Get.find<MenuItemController>();
    } catch (e) {
      debugPrint('MenuItemController not found: $e');
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

  @override
  void onClose() {
    itemNameController.dispose();
    salePriceController.dispose();
    prepTimeController.dispose();
    super.onClose();
  }
}

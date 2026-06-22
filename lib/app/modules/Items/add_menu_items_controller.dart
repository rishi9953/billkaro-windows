// Controller
import 'dart:io';
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
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
  final itemNameController = TextEditingController();
  final salePriceController = TextEditingController();
  final prepTimeController = TextEditingController(text: '15');
  late MenuItemController menuItemController;

  var selectedCategory = 'None'.obs;
  var selectedTaxPercentage = 'None'.obs;
  var isWithTax = false.obs;
  var makeDefaultTax = true.obs;
  var markAsFavorite = false.obs;
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
    final itemName = itemNameController.text.trim();
    if (itemName.isEmpty) {
      showError(description: 'Please enter item name first to generate image');
      return;
    }
    isGeneratingAiImage.value = true;
    // Let the picker sheet close before opening global loader.
    await Future.delayed(const Duration(milliseconds: 180));
    showAppLoader();
    try {
      final prompt =
          'Professional appetizing food photo of $itemName on a plate, restaurant menu, warm lighting, high quality';
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
    showSuccess(description: 'Image removed successfully');
  }

  void saveAndNew() {
    // Save and keep screen open; reset only after SUCCESS.
    if (itemNameController.text.isEmpty) {
      showError(description: 'Please enter item name');
      return;
    }
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    onAddItem(closeOnSuccess: false);
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
      showSuccess(description: response['message']);
    }
  }

  void saveItem() {
    debugPrint('Save item called. isEdit: ${isEdit.value}');
    if (itemNameController.text.isEmpty) {
      showError(description: 'Please enter item name');
      return;
    }
    final appPref = Get.find<AppPref>();
    if (!hasTrialOrSubscription(appPref)) {
      checkSubscription();
      return;
    }
    onAddItem(closeOnSuccess: false);
  }

  void onUpdateItem() async {
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
    );
    final response = await callApi(
      apiClient.updateItem(request, itemId.value.trim()),
    );
    if (response['status'] == 'success') {
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

    categories.clear();
    categories.add('none');
    categories.addAll(categoryList.map((e) => e.categoryName));
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
    itemId.value = '';
    imageUrl.value = '';

    if (args == null) return;

    final bool edit = args['isEdit'] == true;
    isEdit.value = edit;
    if (!edit || args['item'] == null) return;

    final item = args['item'] as ItemData;

    itemNameController.text = item.itemName;
    salePriceController.text = item.salePrice.toString();
    prepTimeController.text = item.prepTimeMinutes.toString();

    selectedCategory.value = categories.contains(item.category)
        ? item.category
        : 'none';

    isWithTax.value = item.withTax;
    itemId.value = item.id;

    imageUrl.value = item.itemImage;
    isAvailable.value = item.showItem;
    markAsFavorite.value = item.isRecommended;
    selectedTaxPercentage.value = double.parse(item.gst.toString()).round() == 0
        ? 'None'
        : '${double.parse(item.gst.toString()).toInt()}';
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

  @override
  void onReady() async {
    // Categories are loaded here; screen will call configureFromArgs()
    // with the latest arguments on each build.
    await getCategories();
    super.onReady();
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
          selectedCategory.value = result.category!;
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

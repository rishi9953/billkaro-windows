// Controller
import 'dart:io';
import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:billkaro/app/services/ai/ai_image_generator.dart';
import 'package:billkaro/config/config.dart';
import '../../services/Modals/Categories/categories_response.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AddMenuItemController extends BaseController {
  final itemNameController = TextEditingController();
  final salePriceController = TextEditingController();
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
  var isScanning = false.obs;
  var aiScanResult = Rx<MenuScanResult?>(null);

  // AI Image Generator
  final AIImageGenerator _aiImageGenerator = AIImageGenerator();
  var isGeneratingImage = false.obs;

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
        // Auto-scan with AI when image is selected
        await scanMenuWithAI();
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

      // ML Kit OCR (menu scan) is only supported on Android/iOS.
      if (_usesDesktopCameraPlugin()) {
        showSuccess(
          description:
              'Photo captured. Enter item name and price (desktop scan uses the image only).',
        );
        return;
      }
      await scanMenuWithAI();
    } catch (e) {
      showError(description: 'Failed to capture image: $e');
    }
  }

  // Show image source selection dialog matching the design
  void uploadImage() {
    var loc = AppLocalizations.of(Get.context!);
    if (loc == null) return;
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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.upload_item_image,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Generate with AI option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Get.back();
                    generateImageWithAI();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
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
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Generate with AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Upload manually option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Get.back();
                    showManualUploadOptions();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload_outlined,
                            color: AppColor.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Upload manually',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Cancel button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      loc.cancel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
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

  // Show manual upload options (Gallery/Camera)
  void showManualUploadOptions() {
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
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  // Generate image using AI based on item name
  Future<void> generateImageWithAI() async {
    // Check if item name is provided
    if (itemNameController.text.trim().isEmpty) {
      showError(description: 'Please enter item name first to generate image');
      return;
    }

    try {
      isGeneratingImage.value = true;
      showAppLoader();

      debugPrint('🎨 [AI] Generating image for: ${itemNameController.text}');

      // Generate image URL using AI
      final imageUrlFromAI = await _aiImageGenerator.generateImageFromItemName(
        itemNameController.text.trim(),
      );

      if (imageUrlFromAI != null && imageUrlFromAI.isNotEmpty) {
        // Download the image and save it locally
        final downloadedFile = await _aiImageGenerator.downloadImageToFile(
          imageUrlFromAI,
        );

        if (downloadedFile != null && await downloadedFile.exists()) {
          selectedImage.value = downloadedFile;
          imagePath.value = downloadedFile.path;

          dismissAppLoader();
          isGeneratingImage.value = false;

          showSuccess(description: 'AI image generated successfully!');
        } else {
          // If download fails, try to use the URL directly
          // This will require uploading it to your server
          dismissAppLoader();
          isGeneratingImage.value = false;
          showError(
            description:
                'Failed to download generated image. Please try again.',
          );
        }
      } else {
        dismissAppLoader();
        isGeneratingImage.value = false;
        showError(
          description:
              'Failed to generate image. Please try uploading manually.',
        );
      }
    } on Exception catch (e) {
      dismissAppLoader();
      isGeneratingImage.value = false;
      debugPrint('❌ [AI] Image generation error: $e');
      // Show the user-friendly error message from the AI generator
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      showError(description: errorMessage);
    } catch (e) {
      dismissAppLoader();
      isGeneratingImage.value = false;
      debugPrint('❌ [AI] Image generation error: $e');
      showError(
        description: 'Failed to generate image. Please try uploading manually.',
      );
    }
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

  // Load categories from API
  Future<void> getCategories() async {
    final response = await callApi(
      apiClient.getCategories(appPref.selectedOutlet!.id!),
    );

    if (response!.status == 'success') {
      List<CategoryData> categoryList = response.categories;

      categories.clear();
      categories.add('none');

      List<String> categoryNames = categoryList
          .map((e) => e.categoryName)
          .toList();

      categories.addAll(categoryNames);
    } else {
      debugPrint('No categories found or API error');
    }

    dismissAllAppLoader();
  }

  // Edit Mode Logic
  void configureFromArgs(Map<String, dynamic>? args) {
    // Always start from a clean state
    isEdit.value = false;
    itemNameController.clear();
    salePriceController.clear();
    selectedCategory.value = 'none';
    selectedTaxPercentage.value = 'None';
    isWithTax.value = false;
    itemId.value = '';
    imageUrl.value = '';

    if (args == null) return;

    final bool edit = args['isEdit'] == true;
    isEdit.value = edit;
    if (!edit || args['item'] == null) return;

    final item = args['item'] as ItemData;

    itemNameController.text = item.itemName;
    salePriceController.text = item.salePrice.toString();

    selectedCategory.value = categories.contains(item.category)
        ? item.category
        : 'none';

    isWithTax.value = item.withTax;
    itemId.value = item.id;

    imageUrl.value = item.itemImage;
    selectedTaxPercentage.value = double.parse(item.gst.toString()).round() == 0
        ? 'None'
        : '${double.parse(item.gst.toString()).toInt()}';
  }

  // Save API Call
  void resetForm() {
    itemNameController.clear();
    salePriceController.clear();
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
              'Could not extract menu information. Please enter manually.',
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
    super.onClose();
  }
}

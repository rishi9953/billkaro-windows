import 'package:billkaro/app/Widgets/custom_button.dart';
import 'package:billkaro/app/modules/AddOrder/AddCategory/add_category_controller.dart';
import 'package:billkaro/config/config.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final controller = Get.put(AddCategoryController());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEdit.value ? loc.edit_category : loc.add_category,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ------------ INPUT SECTION -------------
            AppText(loc.category_name),
            Gap(10),
            TextFormField(
              controller: controller.categoryNameController,
              decoration: InputDecoration(
                hintText: loc.enter_category_name,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),

            Gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                Gap(5),
                Expanded(child: AppText.regular(loc.items_shown_by_category)),
              ],
            ),

            Gap(20),

            /// ------------ CATEGORY LIST SECTION -------------
            Expanded(
              child: Obx(() {
                if (controller.categories.isEmpty) {
                  return SizedBox.shrink();
                }
                if (controller.isEdit.value) {
                  return SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.regular(loc.all_categories),
                    Gap(10),

                    /// ListView MUST be outside Obx's rebuild
                    Expanded(
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: controller.categories.length,
                        itemBuilder: (context, index) {
                          final cat = controller.categories[index];
                          return ListTile(
                            tileColor: AppColor.white,
                            title: AppText(
                              ' ${index + 1}. ${cat.categoryName.capitalize}',
                            ),
                            trailing: IconButton(
                              icon: Assets.svg.delete.svg(
                                width: 20,
                                height: 20,
                              ),
                              onPressed: () {
                                controller.deleteCategory(index);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),

            /// ------------ BUTTON -------------
            Obx(
              () => controller.isEdit.value
                  ? Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            elevation: 0,
                            backgroundColor: AppColor.white,
                            textColor: AppColor.black,

                            width: double.infinity,
                            onPressed: () {
                              controller.isEdit.value = false;
                              controller.categoryNameController.clear();
                            },
                            text: loc.delete,
                          ),
                        ),
                        Gap(10),
                        Expanded(
                          child: CustomButton(
                            elevation: 0,
                            backgroundColor: AppColor.primary,
                            textColor: AppColor.white,

                            width: double.infinity,
                            onPressed: () {
                              controller.updateCategory();
                            },
                            text: loc.update_category,
                          ),
                        ),
                      ],
                    )
                  : CustomButton(
                      width: double.infinity,
                      onPressed: () {
                        controller.addCategory();
                      },
                      text: loc.add_category,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

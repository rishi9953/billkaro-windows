import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_controller.dart';
import 'package:billkaro/config/config.dart';

class WhatsappMarketingScreen extends StatelessWidget {
  WhatsappMarketingScreen({super.key});
  final controller = Get.put(WhatsappMarketingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Select Message Template',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTemplateCard(
            title: 'Discount Offer from Restaurant Name',
            description: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'Special offer for our loyal customers of ',
                  ),
                  TextSpan(
                    text: 'Restaurant Name',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: '! Get '),
                  TextSpan(
                    text: 'Discount value',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' off on your next visit. Show this message at the restaurant for discount.',
                  ),
                ],
              ),
            ),
            onTap: () => controller.showCustomFieldsDialog(
              'discount',
              'Special offer for our loyal customers of ${controller.restaurantNameController.text}',
              '${controller.discountValueController.text}% off on your next visit.',
            ),
          ),
          const SizedBox(height: 16),
          _buildTemplateCard(
            title: 'Enjoy New Menu at Restaurant Name',
            description: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'Restaurant Name',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' have added new items to their menu. Come and try these items today!',
                  ),
                ],
              ),
            ),
            onTap: () => controller.showCustomFieldsDialog(
              'menu',
              'Enjoy New Menu at ${controller.restaurantNameController}',
              ' have added new items to their menu. Come and try these items today!',
            ),
          ),
          const SizedBox(height: 16),
          _buildTemplateCard(
            title: 'Happy Festival Name from Restaurant Name',
            description: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'Restaurant Name',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' wishes you a happy '),
                  TextSpan(
                    text: 'Festival Name',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. Visit the restaurant for new festival menu and discounts!',
                  ),
                ],
              ),
            ),
            onTap: () => controller.showCustomFieldsDialog(
              'festival',
              'Happy Festival Name from ${controller.restaurantNameController}',
              'Festival Name . Visit the restaurant for new festival menu and discounts!',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required String title,
    required RichText description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          description,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Use Template',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

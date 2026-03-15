// ignore_for_file: deprecated_member_use

import 'package:billkaro/config/config.dart';

class CustomerTrackingScreen extends StatelessWidget {
  const CustomerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8EEF7),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 50),
                    Center(
                      child: Container(
                        color: Colors.white60,
                        child: Lottie.asset('assets/lottie/usingmobilephone.json', height: 300, fit: BoxFit.contain),
                      ),
                    ),
                    // _buildIllustration(),
                    const SizedBox(height: 40),
                    _buildFeaturesList(),
                    footerSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    var loc = AppLocalizations.of(Get.context!)!;

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.black, height: 1.2),
        children: [
          TextSpan(text: '${loc.keep_track_of_your_best_customers} '),
          TextSpan(text: '✨'),
        ],
      ),
    );
  }

  Widget buildPlaceholderIllustration() {
    return Container(
      height: 350,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[100], shape: BoxShape.circle),
                  child: Icon(Icons.messenger_outline, color: Colors.blue[700], size: 24),
                ),
                const SizedBox(height: 120),
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(color: Colors.blue[300], borderRadius: BorderRadius.circular(40)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 40,
            child: Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(2)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 20, backgroundColor: Colors.blue[300]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(height: 8, color: Colors.grey[300]),
                                        const SizedBox(height: 4),
                                        Container(height: 8, width: 80, color: Colors.grey[300]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(color: Colors.blue[200], borderRadius: BorderRadius.circular(30)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 35,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildFeatureItem(icon: Icons.star, title: loc.whatsapp_marketing_and_offers, description: loc.engage_customers_whatsapp_customised_offers),
          const SizedBox(height: 24),
          _buildFeatureItem(icon: Icons.star, title: loc.loyalty_discounts, description: loc.boost_repeat_business_loyalty_discount),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.business_insights_and_growth,
            description: loc.unlock_powerful_insights_smart_decisions,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title, required String description, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          child: Center(child: const Icon(Icons.star, color: Colors.blue, size: 3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[const SizedBox(height: 6), Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4))],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF7),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            // Handle button press
            Get.toNamed(AppRoute.addRegularCustomer);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:  Text(loc.add_regular_customer, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

}

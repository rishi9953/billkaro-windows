// ignore_for_file: deprecated_member_use

import 'package:billkaro/config/config.dart';
import 'package:billkaro/app/modules/Language/language_controller.dart';

class LanguageScreen extends StatelessWidget {
  LanguageScreen({super.key});
  final controller = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.language,
          style: const TextStyle(
            color: AppColor.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/translatelanguage.json',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: const Color(0xff083c6b).withOpacity(0.1),
                //     shape: BoxShape.circle,
                //   ),
                //   child: const Icon(
                //     Icons.language,
                //     size: 48,
                //     color: Color(0xff083c6b),
                //   ),
                // ),
                const SizedBox(height: 16),
                Text(
                  loc.choose_your_language,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.select_preferred_language_for_app,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language Options
          Expanded(
            child: Obx(
              () => ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.languages.length,
                itemBuilder: (context, index) {
                  final language = controller.languages[index];
                  final isSelected =
                      language == controller.selectedLanguage.value;
                  final flag = index == 0 ? "🇬🇧" : "🇮🇳";
                  final nativeName = index == 0 ? "English" : "हिंदी";
                  final subtitle = index == 0 ? "English (US)" : "Hindi";

                  return GestureDetector(
                    onTap: () {
                      if (index == 0) {
                        controller.changeLanguage(const Locale('en'));
                      } else if (index == 1) {
                        controller.changeLanguage(const Locale('hi'));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff083c6b)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xff083c6b).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Flag Container
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xff083c6b).withOpacity(0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  flag,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Language Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nativeName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xff083c6b)
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Check Icon
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xff083c6b)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xff083c6b)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

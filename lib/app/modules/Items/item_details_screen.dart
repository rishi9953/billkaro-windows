import 'package:billkaro/config/config.dart';
import 'package:flutter/rendering.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showButtons = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // Scrolling down
      if (_showButtons) {
        setState(() {
          _showButtons = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // Scrolling up
      if (!_showButtons) {
        setState(() {
          _showButtons = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFE8EEF7),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
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
                        child: Lottie.asset(
                          'assets/lottie/items.json',
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFeaturesList(),
                    footerSection(),
                  ],
                ),
              ),
            ),
          ),
          if (_showButtons)
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: Offset.zero,
              child: _buildbuttons(),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    var loc = AppLocalizations.of(Get.context!)!;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1.2,
        ),
        children: [
          TextSpan(text: loc.maintain_your_menu_items_effortlessly),
          TextSpan(text: '✨'),
        ],
      ),
    );
  }

  Widget _buildbuttons() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8EEF7).withOpacity(0.0),
            const Color(0xFFE8EEF7).withOpacity(0.8),
            const Color(0xFFE8EEF7),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            OutlinedButton(
              onPressed: () {
                // Action for the first button
                Get.toNamed(AppRoute.addMenuItem);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                loc.addMenuItem,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            // Gap(16),
            // ElevatedButton(
            //   onPressed: () {
            //     // Action for the first button
            //   },
            //   style: ElevatedButton.styleFrom(
            //     minimumSize: const Size(double.infinity, 50),
            //     backgroundColor: AppColor.primary,
            //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //   ),
            //   child: Text(loc.scan_Menu_to_Add_Items_via_AI, style: TextStyle(fontSize: 16, color: Colors.white)),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.feature_scanMenu_title,
            description: loc.feature_scanMenu_desc,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.add_images_ai_title,
            description: loc.add_images_ai_description,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.star,
            title: loc.manage_favourites_title,
            description:
                'Automatically get best selling items & organize items thourgh categories for easy access.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: const Icon(Icons.star, color: Colors.blue, size: 3),
          ),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

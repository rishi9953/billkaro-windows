import 'dart:ui';
import 'package:billkaro/app/modules/Main/main_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final controller = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(AppRoute.changeLanguage);
            },
            icon: Icon(Icons.language),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColor.primary),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glassy container for logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/logo.jpeg',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.store_rounded, size: 100, color: Colors.white.withOpacity(0.8));
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 50),

                  // Main glassy card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              loc.welcome_to_billkaro,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                            ),
                            SizedBox(height: 12),
                            Text(loc.manage_business_ease, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), letterSpacing: 0.3)),
                            SizedBox(height: 40),

                            // Register button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: controller.onRegister,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Text(
                                      loc.register_new_business,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Already registered button
                            TextButton(
                              onPressed: controller.onAlreadyRegistered,
                              style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    loc.already_registered,
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

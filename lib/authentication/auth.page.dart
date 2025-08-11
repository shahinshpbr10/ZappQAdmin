import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zappq_admin_app/common/colors.dart';
import '../botton_nav.dart';
import '../landing_page.dart';
import '../main.dart';
import 'firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    setState(() => isLoading = true);

    final String name = nameController.text.trim();
    final String id = idController.text.trim();

    try {
      // Get FCM token safely
      String? fcmToken = '';
      if (!kIsWeb) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint("FCM token error: $e");
        }
      }

      // Call admin login API
      final String result = await adminLogin(
        name: name,
        id: id,
        fcmToken: fcmToken ?? '',
      );

      if (result == 'Login Success') {
        // Get app version
        String appVersion = 'unknown';
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          appVersion = packageInfo.version;
        } catch (e) {
          debugPrint("App version error: $e");
        }

        // Get location safely
        String location = 'unknown';
        if (!kIsWeb) {
          try {
            LocationPermission permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse) {
              final position = await Geolocator.getCurrentPosition();
              location = "${position.latitude},${position.longitude}";
            }
          } catch (e) {
            debugPrint("Location error: $e");
          }
        } else {
          debugPrint("Location skipped: Web requires HTTPS & user permission.");
        }

        debugPrint("Login success: name=$name, version=$appVersion, loc=$location");

        // Navigate to home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      } else {
        _showSnackBar(result, Colors.red);
      }
    } catch (e, st) {
      debugPrint("Login process error: $e\n$st");
      _showSnackBar("Unexpected error, please try again", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 20.0;

    InputDecoration fieldDecoration({
      required String hint,
      required IconData icon,
    }) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        hintText: hint,
        border: InputBorder.none,
      );
    }

    Widget customField({
      required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscure = false,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          obscureText: obscure,
          decoration: fieldDecoration(hint: hint, icon: icon),
          style: const TextStyle(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/ZappQ_logo.jpg',
                    height: 60,
                    width: 60,
                  ),
                ),
                const SizedBox(height: 32),
                customField(
                  controller: nameController,
                  hint: 'Admin Name',
                  icon: Icons.person_outline,
                ),
                customField(
                  controller: idController,
                  hint: 'Admin ID',
                  icon: Icons.key_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightpacha,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: isLoading ? null : _handleAdminLogin,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'LOGIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Need help? ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement help/contact
                      },
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

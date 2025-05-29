import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lightpacha,
              radius: 40,
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
            SizedBox(height: 30),
            Text(
              "Payment Successful!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Thank you for your purchase",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

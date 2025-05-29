import 'package:flutter/material.dart';
import 'package:zappq_admin_app/pharmacy/paymentSuccesfull.dart';

import '../common/colors.dart';
import '../main.dart';
import 'add_card.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? selectedPayment; // To track selected radio

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        centerTitle: true,
        title: Text('Payment Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Credit & Debit card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCardScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Add card'),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'More Payment Options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            buildPaymentOption(
              label: 'Google Pay',
              value: 'gpay',
              icon: Icons.account_balance_wallet_outlined,
            ),
            buildPaymentOption(
              label: 'Apple Pay',
              value: 'apple',
              icon: Icons.phone_iphone,
            ),
            buildPaymentOption(
              label: 'Pay Pal',
              value: 'paypal',
              icon: Icons.payment,
            ),
            Spacer(),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  if (selectedPayment != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentSuccessScreen(),
                      ),
                    );
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please choose Any Payment Methods")),
                    );
                  }
                },
                child: Container(
                  height: height * 0.07,
                  width: width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.03),
                    color: AppColors.lightpacha,
                  ),
                  child: Center(
                    child: Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedPayment,
        onChanged: (newValue) {
          setState(() {
            selectedPayment = newValue;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 10),
            Text(label),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

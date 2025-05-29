import 'package:flutter/material.dart';
import 'package:zappq_admin_app/pharmacy/paymentSuccesfull.dart';

import '../common/colors.dart';
import '../main.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.addListener(_updateCard);
    numberController.addListener(_updateCard);
    expiryController.addListener(_updateCard);
    cvvController.addListener(_updateCard);
  }

  void _updateCard() => setState(() {});

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Card'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // LIVE CARD PREVIEW
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/images/ZappQTag.png', height: 40),
                  const SizedBox(height: 20),
                  Text(
                    numberController.text.isEmpty
                        ? 'XXXX XXXX XXXX XXXX'
                        : numberController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expiryController.text.isEmpty
                            ? 'MM/YY'
                            : expiryController.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        cvvController.text.isEmpty ? 'CVV' : cvvController.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nameController.text.isEmpty
                        ? 'CARD HOLDER'
                        : nameController.text.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            // FORM FIELDS
            buildInputField('Card Holder Name', 'Eg: John Doe', nameController),
            buildInputField(
                'Card Number', 'Eg: 4716 9627 1635 8047', numberController,
                keyboardType: TextInputType.number),
            Row(
              children: [
                Expanded(
                  child: buildInputField(
                      'Expiry Date', 'MM/YY', expiryController),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildInputField('CVV', '000', cvvController,
                      obscure: true),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentSuccessScreen(),
                      ),
                    );
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

  Widget buildInputField(
      String label,
      String hint,
      TextEditingController controller, {
        bool obscure = false,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

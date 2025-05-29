import 'package:flutter/material.dart';
import 'package:zappq_admin_app/pharmacy/pharmacyCart.dart';

import '../common/colors.dart';
import '../main.dart';

class PharmacyDetailsScreen extends StatelessWidget {
  final String imagePath;
  final String name;
  final double mrp;
  final String discount;
  final double price;

  const PharmacyDetailsScreen({
    super.key,
    required this.imagePath,
    required this.name,
    required this.mrp,
    required this.discount,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('pharmacy-details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(imagePath, height: 160),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.star, color: Colors.orange, size: 18),
                  Icon(Icons.star, color: Colors.orange, size: 18),
                  Icon(Icons.star, color: Colors.orange, size: 18),
                  Icon(Icons.star, color: Colors.orange, size: 18),
                  Icon(Icons.star_border_rounded, color: Colors.grey, size: 18),
                  Text(
                    ' 4.1 (124 Ratings)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'MRP $mrp',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    price.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    discount,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PharmacyCartScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: height * 0.05,
                    width: width * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.03),
                      color: AppColors.lightpacha,
                    ),
                    child: Center(
                      child: Text(
                        'ADD TO CART',
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
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyCartScreen(),));
              //   },
              //   child: const Text('ADD TO CART'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     foregroundColor: Colors.white,
              //   ),
              // ),
              const SizedBox(height: 20),
              _buildSection('Uses', [
                'High cholesterol (Hyperlipidemia)',
                'Prevention of heart attacks and strokes',
                'Treatment of dyslipidemia',
                'Reducing risk in patients with diabetes or heart disease',
              ]),
              const SizedBox(height: 20),
              _buildSection('How to Use', [
                'Take one tablet daily with or without food.',
                'Swallow whole with water.',
                'Take it at the same time each day.',
                'Do not stop without consulting your doctor.',
              ]),
              const SizedBox(height: 20),
              _buildSection('Storage Instructions', [
                'Store in a cool, dry place below 25°C.',
                'Keep out of reach of children.',
                'Do not use after expiry date.',
              ]),
              const SizedBox(height: 20),
              const Text(
                'Similar product',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        ...items.map(
              (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $e', style: const TextStyle(color: Colors.black87)),
          ),
        ),
      ],
    );
  }
}

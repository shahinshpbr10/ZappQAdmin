import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/main.dart';
import 'package:zappq_admin_app/pharmacy/pharmacyCart.dart';
import 'package:zappq_admin_app/pharmacy/pharmacyDetails.dart';

class PharmacyScreen extends StatelessWidget {
  PharmacyScreen({super.key});
  final List<Map<String, dynamic>> products = List.generate(6, (index) {
    return {
      'name':
          index % 2 == 0
              ? 'Pharmacy Diabetic Protein Powder French...'
              : 'Ever herb (By Pharmacy) Shilajit 5...',
      'rating': 4,
      'reviews': 62,
      'imagePath': "assets/images/img.png",
      'mrp': 30.5,
      'price': 25.66,
      'discount': '24% OFF',
    };
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(CupertinoIcons.back),
        ),
        title: Text('ZappQ Pharmacy'),
        actions: [
          GestureDetector(onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyCartScreen(),));
          }, child: Icon(Icons.shopping_cart)),
          SizedBox(width: 10),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PharmacyDetailsScreen(
                        imagePath: product['imagePath'],
                        name: product['name'],
                        mrp: product['mrp'],
                        discount: product['discount'],
                        price: product['price'],
                      ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    image: AssetImage(product['imagePath']),
                    height: height * 0.12,
                    width: width * 0.4,
                  ), // Replace with Image.network if needed
                  SizedBox(height: 8),
                  Text(
                    product['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('${product['rating']}'),
                      SizedBox(width: 4),
                      Text(
                        '(${product['reviews']})',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'MRP \$${product['mrp']}',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    product['discount'],
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${product['price']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

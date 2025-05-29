import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/main.dart';
import 'package:zappq_admin_app/pharmacy/pharmacy-Payment.dart';

class PharmacyCartScreen extends StatefulWidget {
  const PharmacyCartScreen({super.key});

  @override
  _PharmacyCartScreenState createState() => _PharmacyCartScreenState();
}

class _PharmacyCartScreenState extends State<PharmacyCartScreen> {
  List<Map<String, dynamic>> cartItems = List.generate(5, (index) {
    return {
      'name':
          index % 2 == 0
              ? 'Paracetamol 650mg Tablet'
              : 'Amoxicillin 500mg Capsule',
      'mrp': 30.5,
      'price': 25.66,
      'discount': '24% OFF',
      'quantity': 1,
      'image': 'assets/images/logo.png',
    };
  });

  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  double calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  void updateQuantity(int index, int delta) {
    setState(() {
      cartItems[index]['quantity'] += delta;
      if (cartItems[index]['quantity'] < 1) {
        cartItems[index]['quantity'] = 1;
      }
    });
  }

  void removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Apply search filter
    final filteredItems =
        cartItems.where((item) {
          return item['name'].toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
        }).toList();

    double total = calculateTotal(filteredItems);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            isSearching
                ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by name',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
                : Text('Pharmacy Cart'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                filteredItems.isEmpty
                    ? Center(child: Text("No items found"))
                    : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final itemTotal = item['price'] * item['quantity'];
                        return Container(
                          decoration: BoxDecoration(
                            border:Border.all(color:Colors.grey),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Image.asset(
                                  item['image'],
                                  width: 60,
                                  height: 60,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'MRP \$${item['mrp']}',
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${itemTotal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            item['discount'],
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey,
                                      ),
                                      onPressed:
                                          () => removeItem(
                                            cartItems.indexOf(item),
                                          ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed:
                                              () => updateQuantity(
                                                cartItems.indexOf(item),
                                                -1,
                                              ),
                                        ),
                                        Text('${item['quantity']}'),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed:
                                              () => updateQuantity(
                                                cartItems.indexOf(item),
                                                1,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentMethodScreen(),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: AppColors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

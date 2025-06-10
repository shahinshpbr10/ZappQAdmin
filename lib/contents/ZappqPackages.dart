import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/main.dart';
import 'Package_edit.dart';

class ZappqPackages extends StatefulWidget {
  const ZappqPackages({super.key});

  @override
  State<ZappqPackages> createState() => _ZappqPackagesState();
}

class _ZappqPackagesState extends State<ZappqPackages> {
  final CollectionReference packagesRef =
  FirebaseFirestore.instance.collection('zappq_healthpackage');

  TextEditingController searchController = TextEditingController();
  TextEditingController actualPriceController = TextEditingController(); // Controller for Actual Price
  TextEditingController labPriceController = TextEditingController(); // Controller for Lab Price

  List<DocumentSnapshot> allPackages = [];
  List<DocumentSnapshot> filteredPackages = [];
  List<String> selectedPackages = [];  // To track selected package IDs
  bool isLoading = true;
  bool _isLongPressed = false; // To toggle long press mode

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  // Fetch all packages from Firestore
  void _fetchPackages() async {
    final snapshot = await packagesRef.get();
    setState(() {
      allPackages = snapshot.docs;
      filteredPackages = allPackages;
      isLoading = false;
    });
  }

  // Filter packages based on search query
  void _filterPackages(String query) {
    final results = allPackages.where((doc) {
      final name = (doc['PACKAGE NAME'] ?? '').toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredPackages = results;
    });
  }

  // Toggle selection of packages on checkbox tap
  void _toggleSelection(String docId) {
    setState(() {
      if (selectedPackages.contains(docId)) {
        selectedPackages.remove(docId);
      } else {
        selectedPackages.add(docId);
      }
    });
  }

  // Update Actual and Lab prices for all selected packages
  void _updatePrices() async {
    final actualPrice = double.tryParse(actualPriceController.text);
    final labPrice = double.tryParse(labPriceController.text);

    if (actualPrice == null || labPrice == null || selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select packages and enter valid prices")),
      );
      return;
    }

    for (var docId in selectedPackages) {
      await packagesRef.doc(docId).update({
        'ACTUAL PRICE': actualPrice,
        'LAB PRICE': labPrice,
      });
    }

    setState(() {
      selectedPackages.clear();
      actualPriceController.clear();
      labPriceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prices updated for selected packages")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        centerTitle: true,
        title: Text("Zappq Packages", style: TextStyle(color: AppColors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: searchController,
              onChanged: _filterPackages,
              decoration: InputDecoration(
                hintText: "Search by Package Name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 12),

            // Price Editing Section (for selected packages)
            if (selectedPackages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // Actual Price Field
                    TextField(
                      controller: actualPriceController,
                      decoration: InputDecoration(
                        labelText: "Edit Actual Price for Selected Packages",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Lab Price Field
                    TextField(
                      controller: labPriceController,
                      decoration: InputDecoration(
                        labelText: "Edit Lab Price for Selected Packages",
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Update Prices Button
                    ElevatedButton(
                      onPressed: _updatePrices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightpacha,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("      Update    ", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

            // Package List
            Expanded(
              child: ListView.separated(
                itemCount: filteredPackages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = filteredPackages[index].data() as Map<String, dynamic>;

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _isLongPressed = true;
                      });
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPackagePage(
                            docId: filteredPackages[index].id,
                            packageData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.03),
                        color: AppColors.lightpacha,
                      ),
                      child: Row(
                        children: [
                          // Show checkbox only when long pressed
                          if (_isLongPressed)
                            Checkbox(
                              value: selectedPackages.contains(filteredPackages[index].id),
                              onChanged: (_) => _toggleSelection(filteredPackages[index].id),
                            ),
                          Expanded(
                            child: Text(
                              data['PACKAGE NAME'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

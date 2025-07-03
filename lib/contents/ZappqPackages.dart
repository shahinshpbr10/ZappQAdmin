import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/main.dart';
import 'Package_edit.dart';
import 'createLabPackage.dart';

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

  // List<DocumentSnapshot> allPackages = [];
  // List<DocumentSnapshot> filteredPackages = [];
  List<String> selectedPackages = [];  // To track selected package IDs
  // bool isLoading = true;
  bool _isLongPressed = false; // To toggle long press mode


  void _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this Package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await  packagesRef.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Package deleted successfully",),backgroundColor: Colors.red,),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting Package: $e")),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Package',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const  AddLabPackagePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {}); // triggers UI refresh on text change
              },
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

            // Price Editing Section
            if (selectedPackages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: actualPriceController,
                      decoration: const InputDecoration(
                        labelText: "Edit Actual Price for Selected Packages",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labPriceController,
                      decoration: const InputDecoration(
                        labelText: "Edit Lab Price for Selected Packages",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
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

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: packagesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No packages found"));
                  }

                  final allDocs = snapshot.data!.docs;
                  final query = searchController.text.toLowerCase();
                  final filtered = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['PACKAGE NAME'] ?? '').toString().toLowerCase();
                    return name.contains(query);
                  }).toList();

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;

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
                                docId: doc.id,
                                packageData: data,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
                            color: AppColors.lightpacha,
                          ),
                          child: Row(
                            children: [
                              if (_isLongPressed)
                                Checkbox(
                                  value: selectedPackages.contains(doc.id),
                                  onChanged: (_) => _toggleSelection(doc.id),
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
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

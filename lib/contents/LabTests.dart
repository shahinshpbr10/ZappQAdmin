import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/colors.dart';
import '../main.dart';
import 'CreateLabTestPage.dart';
import 'createLabPackage.dart';
import 'labTest_edit.dart';

class LabTestsPage extends StatefulWidget {
  const LabTestsPage({super.key});

  @override
  State<LabTestsPage> createState() => _LabTestsPageState();
}

class _LabTestsPageState extends State<LabTestsPage> {
  final CollectionReference labTestsRef = FirebaseFirestore.instance.collection(
    'lab_tests',
  );

  TextEditingController searchController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<DocumentSnapshot> allTests = [];
  List<DocumentSnapshot> filteredTests = [];
  List<String> selectedTests = []; // To store the IDs of selected tests
  bool isLoading = true;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  // Fetch lab tests from Firestore
  void _fetchTests() async {
    final snapshot = await labTestsRef.get();
    setState(() {
      allTests = snapshot.docs;
      filteredTests = allTests;
      isLoading = false;
    });
  }

  void _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: const Text('Are you sure you want to delete this lab test?'),
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
        await labTestsRef.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Test deleted successfully",),backgroundColor: Colors.red,),
        );
        _fetchTests(); // refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting test: $e")),
        );
      }
    }
  }



  // Filter tests by test name
  void _filterTests(String query) {
    final results =
        allTests.where((doc) {
          final name = (doc['TEST_NAME'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();

    setState(() {
      filteredTests = results;
    });
  }

  // Toggle selection of a test
  void _toggleSelection(String docId) {
    setState(() {
      if (selectedTests.contains(docId)) {
        selectedTests.remove(docId);
      } else {
        selectedTests.add(docId);
      }
    });
  }

  // Update the price of all selected tests
  void _updatePrices() async {
    if (selectedTests.isEmpty || priceController.text.isEmpty) return;

    final newPrice = double.tryParse(priceController.text);
    if (newPrice == null) {
      // Invalid price input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid price")),
      );
      return;
    }

    for (var docId in selectedTests) {
      await labTestsRef.doc(docId).update({'PATIENT_RATE': newPrice});
    }

    setState(() {
      // Clear selections and refresh list
      selectedTests.clear();
      priceController.clear();
    });

    // Inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prices updated successfully")),
    );
  }

  void _editTest(String docId, Map<String, dynamic> testData) {
    // Navigate to edit page (You can implement EditLabTestPage separately)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditLabTestPage(docId: docId, testData: testData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        centerTitle: true,
        title: const Text("Lab Tests", style: TextStyle(color: AppColors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Lab test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const  CreateLabPackagePage(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: searchController,
                      onChanged: _filterTests,
                      decoration: InputDecoration(
                        hintText: "Search by Test Name",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price editing section for selected tests
                    if (selectedTests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: priceController,
                              decoration: InputDecoration(
                                labelText: "Edit Price for Selected Tests",
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton(
                                  onPressed: _updatePrices,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightpacha,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    "      Update        ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder:
                                    //         (_) => AddLabPackagePage(),
                                    //   ),
                                    // );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightpacha,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    "    Create package   ",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Lab test list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('lab_tests').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text('Something went wrong'));
                          }

                          final allDocs = snapshot.data!.docs;

                          // Apply filter (if search text is present)
                          final filteredDocs = searchController.text.isEmpty
                              ? allDocs
                              : allDocs.where((doc) {
                            final name = (doc['TEST_NAME'] ?? '').toString().toLowerCase();
                            return name.contains(searchController.text.toLowerCase());
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            return const Center(child: Text('No lab tests found'));
                          }

                          return ListView.separated(
                            itemCount: filteredDocs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return GestureDetector(
                                onLongPress: () {
                                  setState(() {
                                    _isLongPressed = true;
                                  });
                                },
                                onTap: () => _editTest(doc.id, data),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  width: width * 0.9,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(width * 0.03),
                                    color: AppColors.lightpacha,
                                  ),
                                  child: Row(
                                    children: [
                                      if (_isLongPressed)
                                        Checkbox(
                                          value: selectedTests.contains(doc.id),
                                          onChanged: (_) => _toggleSelection(doc.id),
                                        ),
                                      Expanded(
                                        child: Text(
                                          data['TEST_NAME'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.white,
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

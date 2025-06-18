import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zappq_admin_app/common/colors.dart';

class AddLabPackagePage extends StatefulWidget {
  const AddLabPackagePage({super.key});

  @override
  State<AddLabPackagePage> createState() => _AddLabPackagePageState();
}

class _AddLabPackagePageState extends State<AddLabPackagePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController actualPriceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController labPriceController = TextEditingController();
  final TextEditingController packageNameController = TextEditingController();
  final TextEditingController parametersController = TextEditingController();
  final TextEditingController reportTimeController = TextEditingController();
  final TextEditingController slNoController = TextEditingController();
  final TextEditingController testCountController = TextEditingController();
  final TextEditingController validityController = TextEditingController();

  Future<void> uploadPackage() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "ACTUAL_PRICE": int.tryParse(actualPriceController.text.trim()) ?? 0,
      "DESCRIPTION": descriptionController.text.trim(),
      "LAB_PRICE": int.tryParse(labPriceController.text.trim()) ?? 0,
      "PACKAGE_NAME": packageNameController.text.trim(),
      "PARAMETERS_INCLUDED": parametersController.text.trim(),
      "REPORT_TIME": reportTimeController.text.trim(),
      "SL_NO": int.tryParse(slNoController.text.trim()) ?? 0,
      "TOTAL_TEST_COUNT": int.tryParse(testCountController.text.trim()) ?? 0,
      "VALIDITY": validityController.text.trim(),
    };

    await FirebaseFirestore.instance.collection('zappq_healthpackage').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Package uploaded successfully")),
    );

    Navigator.pop(context); // Go back after upload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          backgroundColor: AppColors.lightpacha,
          title: const Text("Add Lab Package",style: TextStyle(color: AppColors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("Package Name", packageNameController),
              _buildField("Description", descriptionController),
              _buildField("Actual Price", actualPriceController, isNumber: true),
              _buildField("Lab Price", labPriceController, isNumber: true),
              _buildField("Parameters Included", parametersController),
              _buildField("Report Time", reportTimeController),
              _buildField("SL. No", slNoController, isNumber: true),
              _buildField("Total Test Count", testCountController, isNumber: true),
              _buildField("Validity", validityController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor:AppColors.lightpacha, // Set your preferred color here
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Upload Package",
                  style: TextStyle(color: Colors.white), // Ensure text is visible
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
        value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/main.dart';

class EditPackagePage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> packageData;

  const EditPackagePage({
    super.key,
    required this.docId,
    required this.packageData,
  });

  @override
  State<EditPackagePage> createState() => _EditPackagePageState();
}

class _EditPackagePageState extends State<EditPackagePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController actualPriceController;
  late TextEditingController labPriceController;
  late TextEditingController parametersController;
  late TextEditingController reportTimeController;
  late TextEditingController slNoController;
  late TextEditingController totalTestCountController;
  late TextEditingController validityController;

  @override
  void initState() {
    super.initState();
    final data = widget.packageData;

    nameController = TextEditingController(text: data['PACKAGE NAME']);
    descController = TextEditingController(text: data['DESCRIPTION']);
    actualPriceController = TextEditingController(
      text: data['ACTUAL PRICE'].toString(),
    );
    labPriceController = TextEditingController(
      text: data['LAB PRICE'].toString(),
    );
    parametersController = TextEditingController(
      text: data['PARAMETERS INCLUDED'],
    );
    reportTimeController = TextEditingController(text: data['REPORT TIME']);
    slNoController = TextEditingController(text: data['SL. NO'].toString());
    totalTestCountController = TextEditingController(
      text: data['TOTAL TEST COUNT'].toString(),
    );
    validityController = TextEditingController(text: data['VALIDITY'].toString());
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('zappq_healthpackage')
          .doc(widget.docId)
          .update({
            'PACKAGE NAME': nameController.text,
            'DESCRIPTION': descController.text,
            'ACTUAL PRICE': int.tryParse(actualPriceController.text) ?? 0,
            'LAB PRICE': int.tryParse(labPriceController.text) ?? 0,
            'PARAMETERS INCLUDED': parametersController.text,
            'REPORT TIME': reportTimeController.text,
            'SL. NO': int.tryParse(slNoController.text) ?? 0,
            'TOTAL TEST COUNT':
                int.tryParse(totalTestCountController.text) ?? 0,
            'VALIDITY': validityController.text,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            "Package Successfully Changed",
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          backgroundColor: AppColors.lightpacha,
          title: const Text("Edit Package",style: TextStyle(color: AppColors.white),),
        leading: IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back,color: AppColors.white,)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: height*0.01,),
              _buildField("Package Name", nameController),
              _buildField("Description", descController),
              _buildField(
                "Actual Price",
                actualPriceController,
                isNumber: true,
              ),
              _buildField("Lab Price", labPriceController, isNumber: true),
              _buildField("Parameters", parametersController),
              _buildField("Report Time", reportTimeController),
              _buildField("SL. No", slNoController, isNumber: true),
              _buildField(
                "Total Test Count",
                totalTestCountController,
                isNumber: true,
              ),
              _buildField("Validity", validityController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightpacha, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width*0.03),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }
}

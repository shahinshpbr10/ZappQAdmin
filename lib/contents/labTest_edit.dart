import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/colors.dart';

class EditLabTestPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> testData;

  const EditLabTestPage({super.key, required this.docId, required this.testData});

  @override
  State<EditLabTestPage> createState() => _EditLabTestPageState();
}

class _EditLabTestPageState extends State<EditLabTestPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController testNameController;
  late TextEditingController sampleController;
  late TextEditingController volController;
  late TextEditingController categoryController;
  late TextEditingController methodController;
  late TextEditingController rateController;
  late TextEditingController reportTimeController;
  late TextEditingController daysController;
  late TextEditingController cutoffController;
  late TextEditingController tslController;

  @override
  void initState() {
    super.initState();
    final data = widget.testData;

    testNameController = TextEditingController(text: data['TEST_NAME'] ?? '');
    sampleController = TextEditingController(text: data['SAMPLE'] ?? '');
    volController = TextEditingController(text: data['VOL'] ?? '');
    categoryController = TextEditingController(text: data['Category'] ?? '');
    methodController = TextEditingController(text: data['METHOD'] ?? '');
    rateController = TextEditingController(text: data['PATIENT_RATE']?.toString() ?? '');
    reportTimeController = TextEditingController(text: data['REPORTING_TIME'] ?? '');
    daysController = TextEditingController(text: data['SCHEDULED_DAYS'] ?? '');
    cutoffController = TextEditingController(text: data['CUT_OFF_TIME'] ?? '');
    tslController = TextEditingController(text: data['TSL_NO']?.toString() ?? '');
  }

  Future<void> _saveChanges() async {
    Map<String, dynamic> updateData = {};

    if (testNameController.text.isNotEmpty) updateData['TEST_NAME'] = testNameController.text;
    if (sampleController.text.isNotEmpty) updateData['SAMPLE'] = sampleController.text;
    if (volController.text.isNotEmpty) updateData['VOL'] = volController.text;
    if (categoryController.text.isNotEmpty) updateData['Category'] = categoryController.text;
    if (methodController.text.isNotEmpty) updateData['METHOD'] = methodController.text;
    if (rateController.text.isNotEmpty) {
      updateData['PATIENT_RATE'] = int.tryParse(rateController.text) ?? 0;
    }
    if (reportTimeController.text.isNotEmpty) updateData['REPORTING_TIME'] = reportTimeController.text;
    if (daysController.text.isNotEmpty) updateData['SCHEDULED_DAYS'] = daysController.text;
    if (cutoffController.text.isNotEmpty) updateData['CUT_OFF_TIME'] = cutoffController.text;
    if (tslController.text.isNotEmpty) {
      updateData['TSL_NO'] = int.tryParse(tslController.text) ?? 0;
    }

    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance.collection('lab_tests').doc(widget.docId).update(updateData);
    }

    Navigator.pop(context);
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: "$label (Optional)",
          labelStyle: const TextStyle(fontStyle: FontStyle.italic),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        centerTitle: true,
        title: Text("Edit Lab Test", style: TextStyle(color: AppColors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("Test Name", testNameController),
              _buildField("Sample", sampleController),
              _buildField("Volume", volController),
              _buildField("Category", categoryController),
              _buildField("Method", methodController),
              _buildField("Patient Rate", rateController, isNumber: true),
              _buildField("Reporting Time", reportTimeController),
              _buildField("Scheduled Days", daysController),
              _buildField("Cut-off Time", cutoffController),
              _buildField("TSL No.", tslController, isNumber: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightpacha,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

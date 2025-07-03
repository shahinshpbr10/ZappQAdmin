import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/colors.dart';

class CreateLabPackagePage extends StatefulWidget {
  const CreateLabPackagePage({super.key});

  @override
  State<CreateLabPackagePage> createState() => _CreateLabPackagePageState();
}

class _CreateLabPackagePageState extends State<CreateLabPackagePage> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _methodController = TextEditingController();
  final _patientRateController = TextEditingController();
  final _reportingTimeController = TextEditingController();
  final _categoryController = TextEditingController();

  // Optional Fields
  final _cutOffTimeController = TextEditingController();
  final _sampleController = TextEditingController();
  final _volumeController = TextEditingController();
  final _scheduledDaysController = TextEditingController();

  final CollectionReference labTestsRef = FirebaseFirestore.instance.collection('lab_tests');

  void _savePackage() async {
    if (_formKey.currentState!.validate()) {
      try {
        await labTestsRef.add({
          'TEST_NAME': _testNameController.text.trim(),
          'METHOD': _methodController.text.trim(),
          'PATIENT_RATE': double.tryParse(_patientRateController.text.trim()) ?? 0,
          'REPORTING_TIME': _reportingTimeController.text.trim(),
          'Category': _categoryController.text.trim(),

          // Optional
          'CUT_OFF_TIME': _cutOffTimeController.text.trim().isEmpty ? null : _cutOffTimeController.text.trim(),
          'SAMPLE': _sampleController.text.trim().isEmpty ? null : _sampleController.text.trim(),
          'VOL': _volumeController.text.trim().isEmpty ? null : _volumeController.text.trim(),
          'SCHEDULED_DAYS': _scheduledDaysController.text.trim().isEmpty ? null : _scheduledDaysController.text.trim(),

          'TSL_NO': DateTime.now().millisecondsSinceEpoch,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lab package created')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _methodController.dispose();
    _patientRateController.dispose();
    _reportingTimeController.dispose();
    _categoryController.dispose();
    _cutOffTimeController.dispose();
    _sampleController.dispose();
    _volumeController.dispose();
    _scheduledDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Lab Package"),
        backgroundColor: AppColors.lightpacha,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Test Name", _testNameController, true),
              _buildTextField("Method", _methodController, true),
              _buildTextField("Patient Rate", _patientRateController, true, inputType: TextInputType.number),
              _buildTextField("Reporting Time", _reportingTimeController, true),
              _buildTextField("Category", _categoryController, true),

              const Divider(),
              _buildTextField("Cut Off Time (Optional)", _cutOffTimeController, false),
              _buildTextField("Sample (Optional)", _sampleController, false),
              _buildTextField("Volume (Optional)", _volumeController, false),
              _buildTextField("Scheduled Days (Optional)", _scheduledDaysController, false),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePackage,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightpacha),
                child: const Text("Create Package"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool required,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}

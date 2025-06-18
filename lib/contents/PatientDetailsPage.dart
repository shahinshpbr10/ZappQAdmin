import 'package:flutter/material.dart';
import '../common/colors.dart';
import '../main.dart';
import '../models/patientmodel.dart';

class PatientDetailsPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailsPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        centerTitle: true,
        title: Text(patient.name, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Card(
          color: AppColors.lightpacha, // ✅ darker green card
          elevation: 4,
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', patient.name),
                _buildDetailRow('Age', patient.age.toString()),
                _buildDetailRow('Gender', patient.gender),
                _buildDetailRow('Phone', patient.phoneNumber),
                _buildDetailRow('Address', patient.address),
                _buildDetailRow('Booking For', patient.bookingFor),
                _buildDetailRow('Booking Type', patient.bookingType),
                _buildDetailRow('Is Package', patient.isPackage ? 'Yes' : 'No'),
                _buildDetailRow('Payment', patient.selectedPaymentMethod),
                _buildDetailRow('Created At', patient.createdAt.toString()),
                _buildDetailRow('Selected Date', patient.selectedDate.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

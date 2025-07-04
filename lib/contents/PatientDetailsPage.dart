import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/colors.dart';
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Card(
                color: AppColors.lightpacha,
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
                      _buildDetailRow('Status', patient.status),
                      _buildDetailRow('Test Name', patient.testName),
                      _buildDetailRow('Slot time', patient.testTime),
                      _buildDetailRow('Slot Date', formatSelectedDate(patient.selectedDate)),
                      _buildDetailRow('Created At', formatCreatedAtFull(patient.createdAt)),
                      _buildDetailRow('Is Package', patient.isPackage ? 'Yes' : 'No'),
                      _buildDetailRow('Payment', patient.selectedPaymentMethod),
                      _buildDetailRow('Service Charge', patient.serviceCharge.toString()),
                      _buildDetailRow('Delivery Charge', patient.deliveryCharge != null ? patient.deliveryCharge.toString() : '0',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(patient.phoneNumber),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightpacha,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMapLocation(patient.address),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightpacha,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatSelectedDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  String formatCreatedAtFull(DateTime date) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(date);
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
              style: const TextStyle(
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  Future<void> _openMapLocation(String address) async {
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Could not launch $mapUri';
    }
  }
}

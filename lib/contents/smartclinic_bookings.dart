import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/main.dart';
import '../models/patientmodel.dart';
import 'PatientDetailsPage.dart';

class SmartClinicPatientPage extends StatefulWidget {
  const SmartClinicPatientPage({super.key});

  @override
  State<SmartClinicPatientPage> createState() => _SmartClinicPatientPageState();
}

class _SmartClinicPatientPageState extends State<SmartClinicPatientPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String formatSelectedDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingRef = FirebaseFirestore.instance.collection(
      'smartclinic_booking',
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.lightpacha,
        title: const Text(
          'Patient Bookings',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search by patient name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bookingRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allPatients = snapshot.data!.docs.map((doc) {
                  return Patient.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                final filteredPatients = allPatients.where((patient) {
                  return patient.name.toLowerCase().contains(_searchQuery);
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.separated(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: patient.status.toLowerCase() == 'completed'
                              ? Colors.lightBlueAccent
                              : AppColors.lightpacha,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                              'Name: ${patient.name}',
                            style: const TextStyle(color: AppColors.white),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${patient.status}',
                                style: const TextStyle(color: AppColors.white),
                              ),
                              Text(
                                'Slot Date: ${formatSelectedDate(patient.selectedDate)}',
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: const Text('Are you sure you want to delete this booking?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                              if(confirm==true){
                                final bookingDoc = await FirebaseFirestore.instance
                                    .collection('smartclinic_booking')
                                    .doc(patient.id)
                                    .get();

                                final data = bookingDoc.data();
                                if (data == null) return;

                                final Timestamp timestamp = data['selectedDate'];
                                final String timeSlot = data['selectedTimeSlot'];

                                final DateTime selectedDate = timestamp.toDate();
                                final String formattedDate = "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

                                final docRef = FirebaseFirestore.instance
                                    .collection('id_counters')
                                    .doc('lab_booking_counter');

                                await docRef.update({
                                  '$formattedDate.$timeSlot': FieldValue.increment(-1),
                                });

                                await FirebaseFirestore.instance
                                    .collection('smartclinic_booking')
                                    .doc(patient.id)
                                    .delete();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Patient booking deleted')),
                                );

                              }
                              }

                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientDetailsPage(patient: patient),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: height * 0.01),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

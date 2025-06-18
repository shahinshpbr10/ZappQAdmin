import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingRef = FirebaseFirestore.instance.collection('smartclinic_booking');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.lightpacha,
        title: const Text('Patient Bookings', style: TextStyle(color: AppColors.white)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              stream: bookingRef.snapshots(),
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
                          color: AppColors.lightpacha,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            patient.name,
                            //   'Patient Name: ${patient.name}',
                            style: const TextStyle(color: AppColors.white),
                          ),
                          subtitle: Text(
                            'Age: ${patient.age}',
                            style: const TextStyle(color: AppColors.white),
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

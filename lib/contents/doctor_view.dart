import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zappq_admin_app/common/colors.dart';

import '../main.dart';
import 'Staff_add.dart';

class DoctorView extends StatefulWidget {
  final String clinicId;

  const DoctorView({super.key, required this.clinicId});

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allDoctors = [];
  List<DocumentSnapshot> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors =
          _allDoctors.where((doc) {
            final name = (doc['name'] ?? '').toString().toLowerCase();
            return name.contains(query);
          }).toList();
    });
  }

  void _editStaff(Map<String, dynamic> staff) {
    // TODO: Implement edit staff functionality
    print('Edit staff: ${staff['name']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffCreation(
          clinicId: widget.clinicId??'no',
          doctorData: staff, // Pass the doctor data here
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctor by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('clinics')
                      .doc(widget.clinicId)
                      .collection('doctors')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No doctors found.'));
                }

                _allDoctors = snapshot.data!.docs;
                _filteredDoctors =
                    _searchController.text.isEmpty
                        ? _allDoctors
                        : _filteredDoctors;

                return ListView.builder(
                  itemCount: _filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _filteredDoctors[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.03),
                        ),
                        tileColor: AppColors.lightpacha,
                        trailing: GestureDetector(
                          onTap: () {

                          },
                          child: Icon(Icons.edit),
                        ),
                        title: Text(
                          doctor['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          doctor['specialization'] ?? 'No Specialty',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
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
    );
  }
}

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
  String? selectedClinicId;


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
        builder:
            (context) => StaffCreation(
              clinicId: widget.clinicId ?? 'no',
              doctorData: staff, // Pass the doctor data here
            ),
      ),
    );
  }

  Future<void> _confirmDeleteStaff(Map<String, dynamic> staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${staff['name']}?'),
        content: Text(
            'Are you sure you want to delete ${staff['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        selectedClinicId != null &&
        staff['staffId'] != null) {
      try {
        // Determine which collection to delete from based on role
        String collectionName = staff['role'] == 'doctor' ? 'doctors' : 'nurses';

        // Delete the staff document
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(selectedClinicId)
            .collection(collectionName)
            .doc(staff['staffId'])
            .delete();


        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff['name']} has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildStaffActions(Map<String, dynamic> staff) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black),
          onPressed: () => _editStaff(staff),
          tooltip: 'Edit Staff',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteStaff(staff),
          tooltip: 'Delete Staff',
        ),
      ],
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
                    final staff =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final doctor = _filteredDoctors[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.03),
                        ),
                        tileColor: AppColors.lightpacha,
                        // trailing: Row(
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: [
                        //     GestureDetector(
                        //       onTap: () {},
                        //       child: Icon(Icons.edit),
                        //     ),
                        //     SizedBox(width: width * 0.02),
                        //     GestureDetector(
                        //       onTap: () {},
                        //       child: Icon(Icons.delete),
                        //     ),
                        //   ],
                        // ),
                        trailing: _buildStaffActions(staff),
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

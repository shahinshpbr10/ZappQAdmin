import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/contents/smartclinic_bookings.dart';

import 'LabTests.dart';
import 'SpecializationsPage.dart';
import 'ZappqPackages.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightpacha,
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        title: Text(
          'Settings',
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 10),
        children: [
          ListTile(
            leading: Icon(Icons.cast_for_education, color: Colors.white),
            title: Text('Specializations', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SpecializationsPage()),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.science, color: Colors.white),
            title: Text('Lab Tests', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LabTestsPage()),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.medical_services, color: Colors.white),
            title: Text('Zappq Packages', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ZappqPackages()),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.my_library_books_outlined, color: Colors.white),
            title: Text('Smart Clinic Bookings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SmartClinicPatientPage()),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white,
      thickness: 1.5,
      indent: 16,
      endIndent: 16,
    );
  }
}

void _logout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/auth'); // Go to login screen
  }
}

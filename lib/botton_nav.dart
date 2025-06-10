import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'contents/LabTests.dart';
import 'contents/ZappqPackages.dart';
import 'landing_page.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ZappqPackages(),
    LabTestsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.lightpacha,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Zappq Packages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab Tests',
          ),
        ],
      ),
    );
  }
}

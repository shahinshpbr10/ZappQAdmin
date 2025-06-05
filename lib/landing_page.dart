import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'clinic_list.dart'; // Make sure this file contains the updated ClinicListWidget

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.lightpacha,
      body: Padding(
        padding: EdgeInsets.all(width * 0.03),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search clinics...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClinicListWidget(searchQuery: _searchQuery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

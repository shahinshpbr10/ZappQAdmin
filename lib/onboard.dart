import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/smartcliniccontrol.dart';

import 'landing_page.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  final List<AdminOnBoardingItem> items = [
    AdminOnBoardingItem(
      title: "Hospital Management",
      description:
          "Manage hospital registrations, monitor capacity, staff allocation and patient flow analytics",
      icon: Icons.local_hospital_outlined,
      color: AppColors.lightpacha,
      gradient: [AppColors.lightpacha, AppColors.lightpacha],
      features: ["Staff Management", "Capacity Control", "Analytics Dashboard"],
    ),
    AdminOnBoardingItem(
      title: "Smart Clinic Control",
      description:
          "Oversee smart clinic operations, telemedicine services, and digital health monitoring",
      icon: Icons.business_outlined,
      color: AppColors.lightpacha,
      gradient: [AppColors.lightpacha, AppColors.lightpacha],
      features: ["Clinic Oversight", "Telemedicine", "Digital Health"],
    ),
  ];
  int clinicsCount = 0;
  bool isLoading = true;

  // Function to get clinics count
  Future<void> fetchClinicsCount() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('clinics').get();
      setState(() {
        clinicsCount = snapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching clinics: $e');
      setState(() {
        clinicsCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClinicsCount();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.lightpacha,
        // leading: Image(
        //   image: AssetImage("assets/images/logo.png"),
        //   color: Colors.black,
        // ),
        centerTitle: true,
        title: Text(
          "Zappq Admin",
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () => _logout(context),
            child: Icon(Icons.logout),
          ),
          SizedBox(width: 10),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Management Options ListView
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final delay = index * 0.3;
                        final animationValue = Curves.easeOutCubic.transform(
                          (_animationController.value - delay).clamp(0.0, 1.0),
                        );

                        return Transform.translate(
                          offset: Offset(0, 40 * (1 - animationValue)),
                          child: Opacity(
                            opacity: animationValue,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              child: AdminManagementCard(
                                item: items[index],
                                animationValue: animationValue,
                                onTap: () {
                                  final title = items[index].title;

                                  if (title == "Hospital Management") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(),
                                      ),
                                    );
                                  } else if (title == "Smart Clinic Control") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => smartClinic_Control(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Admin Actions
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Statistics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Active Hospitals",
                              '$clinicsCount',
                              AppColors.lightpacha,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              "Smart Clinic",
                              "1",
                              AppColors.lightpacha,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AdminManagementCard extends StatelessWidget {
  final AdminOnBoardingItem item;
  final double animationValue;
  final VoidCallback onTap;

  const AdminManagementCard({
    super.key,
    required this.item,
    required this.animationValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.gradient),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // Background pattern
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.05,
                child: Icon(item.icon, size: 100, color: item.color),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Animated Icon
                      Transform.scale(
                        scale: 0.8 + (0.2 * animationValue),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: item.gradient),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 28),
                        ),
                      ),

                      const Spacer(),

                      // Admin Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminOnBoardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final List<String> features;

  AdminOnBoardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.features,
  });
}

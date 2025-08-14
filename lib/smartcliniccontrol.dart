import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';

import 'contents/LabTests.dart';
import 'contents/ZappqPackages.dart';
import 'contents/smartclinic_bookings.dart';

class smartClinic_Control extends StatefulWidget {
  const smartClinic_Control({super.key});

  @override
  State<smartClinic_Control> createState() => _smartClinic_ControlState();
}

class _smartClinic_ControlState extends State<smartClinic_Control>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  final List<Map<String, dynamic>> _options = [
    {'title': 'Lab Test', 'icon': Icons.science, 'color': Colors.teal},
    {
      'title': 'Zappq Packages',
      'icon': Icons.medical_services,
      'color': Colors.teal,
    },
    {
      'title': 'SmartClinic Bookings',
      'icon': Icons.calendar_today,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for each item
    _slideAnimations = List.generate(
      _options.length,
      (index) =>
          Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.2,
                0.6 + (index * 0.2),
                curve: Curves.easeOutBack,
              ),
            ),
          ),
    );

    _fadeAnimations = List.generate(
      _options.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    // Start animation
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Smart Clinic Control',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.lightpacha,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: _slideAnimations[index],
                      child: FadeTransition(
                        opacity: _fadeAnimations[index],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildAnimatedCard(
                            context,
                            _options[index],
                            index,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
    BuildContext context,
    Map<String, dynamic> option,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 1.0, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTapDown: (_) {
                  // Scale down animation on tap
                  setState(() {});
                },
                onTapUp: (_) {
                  // Scale back up and handle tap
                  _handleOptionTap(option['title']);
                },
                onTapCancel: () {
                  // Scale back up if tap is cancelled
                  setState(() {});
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        option['color'].withOpacity(0.8),
                        option['color'].withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: option['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleOptionTap(option['title']),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option['icon'],
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    option['title'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleOptionTap(String option) {
    // Handle navigation or action based on the selected option
    switch (option) {
      case 'Lab Test':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabTestsPage()),
        );
        break;
      case 'Zappq Packages':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ZappqPackages()),
        );
        break;
      case 'SmartClinic Bookings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SmartClinicPatientPage()),
        );
        break;
    }
  }
}

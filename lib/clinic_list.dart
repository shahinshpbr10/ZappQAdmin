import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:zappq_admin_app/common/text_styles.dart';

import 'common/colors.dart';
import 'hospital_details.dart';

// --- Animated Clinic Card Widget (Similar to the one in all_clinics...) ---
class AnimatedClinicCardHome extends StatefulWidget {
  final Map<String, dynamic> clinic;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const AnimatedClinicCardHome({
    super.key,
    required this.clinic,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  _AnimatedClinicCardHomeState createState() => _AnimatedClinicCardHomeState();
}

class _AnimatedClinicCardHomeState extends State<AnimatedClinicCardHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: const Offset(-1.5, -1.5),
      end: const Offset(1.5, 1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.clinic['name'] ?? 'Unknown Clinic';
    final location = widget.clinic['locality'] ?? widget.clinic['location'] ?? 'No Location';
    final imagePath = widget.clinic['profilePhoto'] ?? 'assets/images/ZappQTag.png';
    final phone = widget.clinic['phone'] ?? 'N/A';

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 15),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: Stack(
          children: [
            // Animated background
            Positioned.fill(
              child: SlideTransition(
                position: _animation,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.lightpacha.withOpacity(0.0),
                          AppColors.lightpacha.withOpacity(0.20),
                          AppColors.lightpacha.withOpacity(0.20),
                          AppColors.lightpacha.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imagePath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/ZappQTag.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: AppTextStyles.smallBodyText.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.call, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                phone,
                                style: AppTextStyles.smallBodyText.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: widget.onFavoriteTap,
                  //   child: Container(
                  //     padding: const EdgeInsets.all(8),
                  //     decoration: BoxDecoration(
                  //       color: AppColors.lightpacha.withOpacity(0.9),
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: Icon(
                  //       widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  //       color: Colors.white,
                  //       size: 20,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Widget (Converted to StatefulWidget) ---
class ClinicListWidget extends StatefulWidget {
  const ClinicListWidget({super.key});

  @override
  _ClinicListWidgetState createState() => _ClinicListWidgetState();
}

class _ClinicListWidgetState extends State<ClinicListWidget> {
  String? userId;
  Set<String> favoriteClinics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserDataAndFetchFavorites();
  }

  Future<void> _initializeUserDataAndFetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        userId = user?.uid;
        _isLoading = false;
      });
    }

    if (user != null) {
      await _fetchFavorites();
    }
  }

  Future<void> _fetchFavorites() async {
    if (userId == null) return;
    try {
      final favSnapshot = await FirebaseFirestore.instance
          .collection('app_users')
          .doc(userId!)
          .collection('fav_hospitals')
          .get();
      if (mounted) {
        setState(() {
          favoriteClinics = favSnapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      print("Error fetching favorites: $e");
      // Handle error appropriately, maybe show a snackbar
    }
  }

  Future<void> _toggleFavorite(String clinicId, Map<String, dynamic> clinicData) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to add favorites"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('app_users')
        .doc(userId!)
        .collection('fav_hospitals')
        .doc(clinicId);

    try {
      if (favoriteClinics.contains(clinicId)) {
        await favRef.delete();
        if (mounted) {
          setState(() {
            favoriteClinics.remove(clinicId);
          });
        }
      } else {
        final dataToSave = {
          'name': clinicData['name'] ?? 'Unknown Clinic',
          'location': clinicData['location'] ?? 'Unknown Location',
          'profilePhoto': clinicData['profilePhoto'],
          'id': clinicId,
        };
        await favRef.set(dataToSave);
        if (mounted) {
          setState(() {
            favoriteClinics.add(clinicId);
          });
        }
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      // Handle error
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: AppColors.scaffoldbackgroundcolour.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenWidth * 0.03),

          // Clinic Cards StreamBuilder
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clinics')
                .limit(2)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                return Column(
                  children: List.generate(2, (_) => _buildLoadingPlaceholder(context)),
                );
              }

              if (snapshot.hasError) {
                print('Homepage Error fetching clinics: ${snapshot.error}');
                return Center(
                  child: Text(
                    'Error loading clinics.',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14, color: Colors.red),
                  ),
                );
              }

              final clinicDocs = snapshot.data?.docs ?? [];

              if (clinicDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No clinics available',
                    style: AppTextStyles.bodyText.copyWith(fontSize: 16),
                  ),
                );
              }

              return Column(
                children: clinicDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final clinicId = doc.id;
                  data['id'] = clinicId;

                  return AnimatedClinicCardHome(
                    key: ValueKey(clinicId),
                    clinic: data,
                    isFavorite: userId != null && favoriteClinics.contains(clinicId),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClinicDetailsPage(clinicData: data, email: doc.id,),
                        ),
                      );
                    },
                    onFavoriteTap: () => _toggleFavorite(clinicId, data),
                  );
                }).toList(),
              );
            },
          ),

          SizedBox(height: screenWidth * 0.04),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Container(
                    height: 13,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Container(
                    height: 13,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


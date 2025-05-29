import 'package:flutter/material.dart';
import 'package:zappq_admin_app/pharmacy/pharmacy-AI.dart';

import '../common/colors.dart';
import '../common/text_styles.dart';
import '../main.dart';

class LandingPharmacy extends StatefulWidget {
  const LandingPharmacy({super.key});

  @override
  State<LandingPharmacy> createState() => _LandingPharmacyState();
}

class _LandingPharmacyState extends State<LandingPharmacy> {
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    Widget _IntroCard() {
      return Padding(
        padding: EdgeInsets.all(width * 0.03),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyAI(),));
          },
          child: Container(
            height: height*0.2,
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Introducing Zapp AI Chat bot',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Get instant, reliable answers to your health questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Replace this with your actual logo
                Image.asset(
                  'assets/images/logo.png', // Add your logo to assets and update path
                  height: 60,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        toolbarHeight: 160,
        backgroundColor: AppColors.lightpacha,
        flexibleSpace: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "Pharmacy",
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.scaffoldbackgroundcolour,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextField(
                      style: AppTextStyles.smallBodyText.copyWith(
                        color: Colors.white,
                      ),
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search by Medicine",
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: AppColors.scaffoldbackgroundcolour
                            .withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CategorySection(),
          Center(child: _IntroCard()),
        ],
      ),
    );
  }
}


class CategorySection extends StatelessWidget {
  final List<Map<String, String>> categories = [
    {
      'name': 'Skin care',
      'image': 'assets/images/skincare.png',
    },
    {
      'name': 'De-addiction',
      'image': 'assets/images/deaddiction.png',
    },
    {
      'name': 'Cold & Fever',
      'image': 'assets/images/cold&fever.png',
    },
    {
      'name': 'Lung care',
      'image': 'assets/images/lungcare.png',
    },
    {
      'name': 'Diabetic',
      'image': 'assets/images/diabetic.png',
    },
  ];

   CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => SizedBox(width: 20),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage(category['image']!),
              ),
              SizedBox(height: 8),
              Text(
                category['name']!,
                style: TextStyle(fontSize: 14),
              ),
            ],
          );
        },
      ),
    );
  }
}

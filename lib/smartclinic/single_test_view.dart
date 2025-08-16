import 'package:flutter/material.dart';
import 'package:zappq_admin_app/smartclinic/smartclinic_cart.dart';

import '../common/colors.dart';

// ------------------- MAIN PAGE -------------------
class SingleTestView extends StatefulWidget {
  const SingleTestView({super.key});

  @override
  State<SingleTestView> createState() => _SingleTestViewState();
}

class _SingleTestViewState extends State<SingleTestView> {
  bool isFavorite = false;
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ---------- SliverAppBar with Image ----------
          SliverAppBar(
            pinned: true,
            expandedHeight: screenHeight * 0.35,
            backgroundColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/images/Image.png',
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),
            ),
          ),

          // ---------- Sliver Body ----------
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Complete Blood count - CBC',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Green Tags
                  Row(
                    children: const [
                      _tagBox('12 Tests Included'),
                      SizedBox(width: 6),
                      _tagBox('50 Parameters'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating & Reviews
                  Row(
                    children: const [
                      Icon(Icons.star, color: Color(0xFFFFA500), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '4.1',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '87 Reviews',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price & Discount
                  Row(
                    children: const [
                      Text(
                        '\$35',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '\$40.25',
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('15% OFF', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Row
                  _buildInfoRow(),
                  const SizedBox(height: 16),

                  DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          PreferredSize(
                            preferredSize: const Size.fromHeight(50),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TabBar(tabs: [
                                Tab(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    child: Text(
                                      "Tests Included",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    child: Text(
                                      "Overview",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                                labelColor: AppColors.black,
                                unselectedLabelColor: Colors.grey.shade400,
                                indicatorColor: AppColors.white,
                                indicatorWeight: 3,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                dividerColor: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                                overlayColor: WidgetStateProperty.all(Colors.transparent),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 300, // <-- adjust as needed
                            child: TabBarView(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildTestsIncluded()
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildOverview(),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),

                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5.0),
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Product Info Section
              Row(
                children: [
                  // Amount Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOTAL AMOUNT Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightpacha,
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: const Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      // Current Price and Original Price
                      Row(
                        children: [
                          Text(
                            "355",
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            '650',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // View Cart Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyCartPage() ,));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                ),
                child: Text(
                  "Add to cart",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestsIncluded() {
    final tests = [
      {
        "title": "Kidney Function Test",
        "subtitle": "Evaluates kidney function and health.",
      },
      {
        "title": "Liver Function Test",
        "subtitle": "Checks liver enzymes and health.",
      },
      {
        "title": "Blood Sugar Test",
        "subtitle": "Measures glucose levels in the blood.",
      },
    ];

    return Column(
      children:
          tests.map((test) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Icon Background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 24,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test["title"] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          test["subtitle"] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Text(
        "This is a complete blood count test that measures various parameters "
        "of your blood to help diagnose conditions such as anemia, infection, "
        "and many more.",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// ------------------- EXTRA WIDGETS -------------------
class _tagBox extends StatelessWidget {
  final String text;
  const _tagBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightpacha,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

Widget _buildInfoRow() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _infoItem(Icons.timer, '30 min', 'Test Duration'),
        _verticalDivider(),
        _infoItem(Icons.location_on_outlined, 'Home Visit', 'Collection'),
        _verticalDivider(),
        _infoItem(Icons.check_circle, 'Same Day', 'Report Ready'),
      ],
    ),
  );
}

Widget _infoItem(IconData icon, String title, String subtitle) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.lightpacha, size: 28),
      const SizedBox(height: 6),
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

Widget _verticalDivider() {
  return Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.2));
}

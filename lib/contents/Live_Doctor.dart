import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:zappq_admin_app/common/text_styles.dart';
import '../common/colors.dart';
import '../loading_animation.dart';

class LiveTokenPage extends StatefulWidget {
  const LiveTokenPage({super.key});

  @override
  _LiveTokenPageState createState() => _LiveTokenPageState();
}

class _LiveTokenPageState extends State<LiveTokenPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedSpecialization = "All";
  String selectedClinic = "All";

  // Filtering helpers
  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void applyFilters() {
    setState(() {}); // Triggers rebuild with new filters
  }

  @override
  Widget build(BuildContext context) {
    // Filter by today's date
    DateTime now = DateTime.now().toUtc();
    DateTime startOfDay = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

    // Listen to live tokens
    Stream<QuerySnapshot> liveTokensStream = firestore
        .collection('liveToken')
        .where("createdAt", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("createdAt", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.scaffoldbackgroundcolour,
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
            Text("Live Doctors", style: AppTextStyles.heading2.copyWith(color: AppColors.scaffoldbackgroundcolour)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextField(
                      style: AppTextStyles.smallBodyText.copyWith(color: Colors.white),
                      controller: searchController,
                      onChanged: updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: "Search by doctor name",
                        hintStyle: TextStyle(color: Colors.white),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: AppColors.scaffoldbackgroundcolour.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.filter_alt_sharp, color: Colors.white),
                      onPressed: () => showFilterOptions(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: liveTokensStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading live doctors'));
            }
            if (!snapshot.hasData) {
              return Center(child: LottieLoadingIndicator());
            }

            final liveDocs = snapshot.data!.docs;

            // If no live doctors
            if (liveDocs.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Lottie.asset('assets/lotties/notfound.json', width: 200),
                      Text(
                        "No doctors available at the moment.",
                        style: AppTextStyles.bodyText.copyWith(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            ///--------

            return FutureBuilder<List<Map<String, dynamic>>>(
              // For each liveToken, fetch clinic and doctor specialization
                future: _fetchDoctorsWithDetails(liveDocs),
                builder: (context, detailsSnapshot) {
                  if (!detailsSnapshot.hasData) return const Center(child: LottieLoadingIndicator());

                  List<Map<String, dynamic>> doctorsList = detailsSnapshot.data ?? [];

                  // Apply filter logic
                  final filtered = doctorsList.where((doctor) {
                    bool matchesSpecialization = selectedSpecialization == "All" || doctor['specialisation'] == selectedSpecialization;
                    bool matchesClinic = selectedClinic == "All" || doctor['clinicName'] == selectedClinic;
                    bool matchesSearch = doctor['doctorName'].toLowerCase().contains(searchQuery.toLowerCase());
                    return matchesSpecialization && matchesClinic && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Lottie.asset('assets/lotties/notfound.json', width: 200),
                            Text(
                              "No doctors matching your filters.",
                              style: AppTextStyles.bodyText.copyWith(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      var doctor = filtered[index];
                      return GestureDetector(
                        // onTap: () => Navigator.of(context).push(
                          // MaterialPageRoute(
                          //   builder: (context) => CurrentLiveToken(
                          //     doctorId: doctor['docid'],
                          //     doctorName: doctor['doctorName'],
                          //     clinicName: doctor['clinicName'],
                          //   ),
                          // ),
                        // ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10, top: 10),
                                  child: Image.asset('assets/images/doc.png', width: 60, height: 60),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doctor['doctorName'], style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(height: 5),
                                      Row(children: [Icon(Icons.local_hospital, size: 16, color: Colors.grey[700]), SizedBox(width: 6), Expanded(child: Text(doctor['clinicName'], overflow: TextOverflow.ellipsis, style: AppTextStyles.smallBodyText))]),
                                      SizedBox(height: 5),
                                      Row(children: [Icon(Icons.health_and_safety, size: 10, color: Colors.green), SizedBox(width: 6), Expanded(child: Text(doctor['specialisation'], overflow: TextOverflow.ellipsis, style: AppTextStyles.caption))]),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    SizedBox(height: 16,),
                                    Icon(Icons.arrow_right),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
            );
          },
        ),
      ),
    );
  }

  // Helper to fetch clinic & specialisation for each live doc
  Future<List<Map<String, dynamic>>> _fetchDoctorsWithDetails(List<QueryDocumentSnapshot> liveDocs) async {
    List<Map<String, dynamic>> fetchedDoctors = [];

    for (var doc in liveDocs) {
      Map<String, dynamic> doctorData = doc.data() as Map<String, dynamic>;
      String clinicId = doctorData['clinicName'] ?? '';
      String doctorId = doctorData['doctorId'] ?? '';
      String doctorName = doctorData['doctorName'] ?? 'Unknown Doctor';
      String liveToken = doctorData['token'] ?? '0';

      if (clinicId.isNotEmpty && doctorId.isNotEmpty) {
        DocumentSnapshot clinicSnapshot = await firestore.collection('clinics').doc(clinicId).get();
        Map<String, dynamic>? clinicData = clinicSnapshot.data() as Map<String, dynamic>?;

        DocumentSnapshot doctorSpecSnapshot = await firestore.collection('clinics').doc(clinicId).collection('doctors').doc(doctorId).get();
        Map<String, dynamic>? doctorSpecData = doctorSpecSnapshot.data() as Map<String, dynamic>?;

        fetchedDoctors.add({
          'doctorName': doctorName,
          'clinicName': clinicData?['name'] ?? 'Unknown Clinic',
          'specialisation': doctorSpecData?['specialization'] ?? 'N/A',
          'token': liveToken,
          'docid': doctorId
        });
      }
    }
    return fetchedDoctors;
  }

  void showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, localSetState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Filter Options",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Select Specialization", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  StreamBuilder<DocumentSnapshot>(
                    stream: firestore.collection('settings').doc('specializations').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.data() == null) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      var specializations = data['specializations'] as List<dynamic>? ?? [];
                      var specializationOptions = ["All", ...specializations.map((s) => s["name"]).toList()];

                      return DropdownButtonFormField<String>(
                        value: specializationOptions.contains(selectedSpecialization) ? selectedSpecialization : "All",
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: specializationOptions.map((specialization) {
                          return DropdownMenuItem<String>(
                            value: specialization,
                            child: Text(specialization),
                          );
                        }).toList(),
                        onChanged: (value) {
                          localSetState(() {
                            selectedSpecialization = value!;
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 15),
                  Text("Select Clinic", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('clinics').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                      var clinics = ["All", ...snapshot.data!.docs.map((doc) => doc['name'] as String).toList()];

                      return DropdownButtonFormField<String>(
                        value: clinics.contains(selectedClinic) ? selectedClinic : "All",
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: clinics.map((clinic) {
                          return DropdownMenuItem<String>(
                            value: clinic,
                            child: Text(clinic),
                          );
                        }).toList(),
                        onChanged: (value) {
                          localSetState(() {
                            selectedClinic = value!;
                          });
                        },
                      );
                    },
                  ),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        applyFilters();
                      },
                      child: Text("Apply Filters"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

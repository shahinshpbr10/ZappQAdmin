import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../common/colors.dart';
import '../common/text_styles.dart';
import '../loading_animation.dart';
import 'live_Doctor_Details.dart';

class LiveTokenPage extends StatefulWidget {
  final String clinicId;
  const LiveTokenPage({super.key, required this.clinicId});

  @override
  _LiveTokenPageState createState() => _LiveTokenPageState();
}

class _LiveTokenPageState extends State<LiveTokenPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedSpecialization = "All";
  String selectedClinic = "All";
  int totalTokens = 0;
  bool showButtons = false;
  //
  // Future<void> _selectDateAndGenerate(String clinicId) async {
  //   final DateTime? selected = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2023),
  //     lastDate: DateTime(2030),
  //   );
  //
  //   if (selected != null) {
  //     final selectedDay = DateFormat('EEEE').format(selected); // e.g. Monday
  //
  //     final clinicSnapshot = await FirebaseFirestore.instance
  //         .collection('clinics')
  //         .doc(clinicId)
  //         .get();
  //
  //     final clinicName = clinicSnapshot.data()?['name'] ?? 'Unknown Clinic';
  //
  //     final doctors = await _getOfflineDoctorsWithSessions(clinicId, selectedDay);
  //     await _generatePdf(selected, doctors,clinicName);
  //   }
  // }
  //
  // Future<void> _generatePdf(DateTime date, List<Map<String, dynamic>> doctors, String clinicName) async {
  //   final pdf = pw.Document();
  //   final formattedDate = DateFormat('dd-MM-yyyy').format(date);
  //   final selectedDay = DateFormat('EEEE').format(date);
  //
  //   pdf.addPage(
  //     pw.MultiPage(
  //       build: (pw.Context context) => [
  //         pw.Text("Clinic: $clinicName", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
  //         pw.Text("Live Report", style: pw.TextStyle(fontSize: 20)),
  //         pw.SizedBox(height: 10),
  //         pw.Text("Date: $formattedDate"),
  //         pw.SizedBox(height: 20),
  //         _buildDoctorTable(doctors),
  //       ],
  //     ),
  //   );
  //
  //   final directory = await getApplicationDocumentsDirectory();
  //   final filePath = "${directory.path}/doctors_available_$formattedDate.pdf";
  //   final file = File(filePath);
  //   await file.writeAsBytes(await pdf.save());
  //
  //   // ScaffoldMessenger.of(context).showSnackBar(
  //   //   SnackBar(content: Text("PDF saved at: $filePath")),
  //   // );
  //
  //   await Printing.layoutPdf(
  //     onLayout: (PdfPageFormat format) async => pdf.save(),
  //   );
  // }
  //
  // pw.Widget _buildDoctorTable(List<Map<String, dynamic>> doctors) {
  //   return pw.Table.fromTextArray(
  //     headers: ['S.No', 'Doctor Name', 'Specialization','Live or No Live','Total tokens'],
  //     data: List<List<String>>.generate(
  //       doctors.length,
  //           (index) => [
  //         '${index + 1}',
  //         doctors[index]['name'] ?? 'Unknown',
  //         doctors[index]['specialization'] ?? 'N/A',
  //         doctors[index]['status'] ?? 'No Live',
  //         totalTokens.toString(),
  //       ],
  //     ),
  //     headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //     cellAlignment: pw.Alignment.centerLeft,
  //     border: pw.TableBorder.all(),
  //     cellPadding: const pw.EdgeInsets.all(6),
  //   );
  // }
  //
  //
  // Future<List<Map<String, dynamic>>> _getOfflineDoctorsWithSessions(String clinicId, String selectedDay) async {
  //   final List<Map<String, dynamic>> result = [];
  //   final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  //
  //   final clinicRef = FirebaseFirestore.instance.collection('clinics').doc(clinicId);
  //   final doctorsSnapshot = await clinicRef.collection('doctors').get();
  //
  //   for (final doc in doctorsSnapshot.docs) {
  //     final data = doc.data();
  //     if (data == null) continue;
  //
  //     final availableDays = (data['availableDays'] as List<dynamic>?)
  //         ?.map((e) => e.toString())
  //         .toList();
  //
  //     bool isLive = false;
  //
  //     // 🔍 Check doctorBehaviour document for today
  //     final behaviourDoc = await clinicRef
  //         .collection('doctors')
  //         .doc(doc.id)
  //         .collection('doctorBehaviour')
  //         .doc(todayDate)
  //         .get();
  //
  //     if (behaviourDoc.exists) {
  //       isLive = true;
  //       final behaviourData = behaviourDoc.data();
  //       final tokens = behaviourData?['tokens'] as List<dynamic>?;
  //
  //       if (tokens != null) {
  //         totalTokens = tokens.length;
  //       }
  //     }
  //
  //     if (availableDays != null && availableDays.contains(selectedDay)) {
  //       result.add({
  //         'name': data['name'] ?? 'Unknown',
  //         'specialization': data['specialization'] ?? 'N/A',
  //         'clinicName': data['clinicName'] ?? '',
  //         'availableDays': availableDays,
  //         'status': isLive ? 'Live' : 'No Live',
  //         'totalTokens': totalTokens,
  //       });
  //     }
  //   }
  //
  //   return result;
  // }

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
    CollectionReference liveTokenRef = firestore.collection('liveToken');

    Query query = liveTokenRef
        .where(
          "createdAt",
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where("createdAt", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));

    if (widget.clinicId != null && widget.clinicId!.isNotEmpty) {
      query = query.where("clinicName", isEqualTo: widget.clinicId);
    }

    Stream<QuerySnapshot> liveTokensStream = query.snapshots();

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
            Text(
              "Live Doctors",
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
                      onChanged: updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: "Search by doctor name",
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
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.filter, color: Colors.white),
                      onPressed: () => showFilterOptions(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Center(child: Icon(Icons.picture_as_pdf)),
        onPressed: () {
          final generator = TokenReportGenerator(context);
          generator.selectDateAndGenerate(widget.clinicId);
        },
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
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
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
                if (!detailsSnapshot.hasData)
                  return const Center(child: LottieLoadingIndicator());

                List<Map<String, dynamic>> doctorsList =
                    detailsSnapshot.data ?? [];

                // Apply filter logic
                final filtered =
                    doctorsList.where((doctor) {
                      bool matchesSpecialization =
                          selectedSpecialization == "All" ||
                          doctor['specialisation'] == selectedSpecialization;
                      bool matchesClinic =
                          selectedClinic == "All" ||
                          doctor['clinicName'] == selectedClinic;
                      bool matchesSearch = doctor['doctorName']
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                      return matchesSpecialization &&
                          matchesClinic &&
                          matchesSearch;
                    }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Lottie.asset(
                            'assets/lotties/notfound.json',
                            width: 200,
                          ),
                          Text(
                            "No doctors matching your filters.",
                            style: AppTextStyles.bodyText.copyWith(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
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
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => LiveDetailsPage(
                                    doctorId: doctor['docid'],
                                    clinicName: doctor['clinicName'],
                                    clinicId: doctor['clinicId'],
                                  ),
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 10,
                                  top: 10,
                                ),
                                child: Image.network(
                                  doctor['profilePhoto'],
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/doc.png',
                                      width: 60,
                                      height: 60,
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor['doctorName'],
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_hospital_sharp,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            doctor['clinicName'],
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.smallBodyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.health_and_safety,
                                          size: 10,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            doctor['specialisation'],
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.caption,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Column(
                                children: [
                                  SizedBox(height: 16),
                                  Icon(Icons.arrow_right),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchDoctorsWithDetails(
    List<QueryDocumentSnapshot> liveDocs,
  ) async {
    List<Future<Map<String, dynamic>>> fetchTasks = [];

    for (var doc in liveDocs) {
      Map<String, dynamic> doctorData = doc.data() as Map<String, dynamic>;
      String clinicId = doctorData['clinicName'] ?? '';
      String doctorId = doctorData['doctorId'] ?? '';
      String doctorName = doctorData['doctorName'] ?? 'Unknown Doctor';
      String liveToken = doctorData['token'] ?? '0';

      if (clinicId.isNotEmpty && doctorId.isNotEmpty) {
        fetchTasks.add(
          Future(() async {
            // Fetch clinic and doctor in parallel
            var clinicFuture =
                firestore.collection('clinics').doc(clinicId).get();
            var doctorFuture =
                firestore
                    .collection('clinics')
                    .doc(clinicId)
                    .collection('doctors')
                    .doc(doctorId)
                    .get();

            var results = await Future.wait([clinicFuture, doctorFuture]);
            var clinicSnapshot = results[0] as DocumentSnapshot;
            var doctorSpecSnapshot = results[1] as DocumentSnapshot;

            Map<String, dynamic>? clinicData =
                clinicSnapshot.data() as Map<String, dynamic>?;
            Map<String, dynamic>? doctorSpecData =
                doctorSpecSnapshot.data() as Map<String, dynamic>?;

            return {
              'doctorName': doctorName,
              'clinicName': clinicData?['name'] ?? 'Unknown Clinic',
              'specialisation': doctorSpecData?['specialization'] ?? 'N/A',
              'token': liveToken,
              'docid': doctorId,
              'profilePhoto': doctorSpecData?['profilePhoto'] ?? 'N/A',
              'clinicId': doctorSpecData?['clinicId'] ?? 'N/A',
            };
          }),
        );
      }
    }

    // Wait for all fetch tasks in parallel
    return await Future.wait(fetchTasks);
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Select Specialization",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        firestore
                            .collection('settings')
                            .doc('specializations')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.data() == null) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      var specializations =
                          data['specializations'] as List<dynamic>? ?? [];
                      var specializationOptions = [
                        "All",
                        ...specializations.map((s) => s["name"]).toList(),
                      ];

                      return DropdownButtonFormField<String>(
                        value:
                            specializationOptions.contains(
                                  selectedSpecialization,
                                )
                                ? selectedSpecialization
                                : "All",
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items:
                            specializationOptions.map((specialization) {
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
                  // Text("Select Clinic", style: TextStyle(fontWeight: FontWeight.w600)),
                  // SizedBox(height: 5),
                  // StreamBuilder<QuerySnapshot>(
                  //   stream: firestore.collection('clinics').snapshots(),
                  //   builder: (context, snapshot) {
                  //     if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  //     var clinics = ["All", ...snapshot.data!.docs.map((doc) => doc['name'] as String).toList()];
                  //
                  //     return DropdownButtonFormField<String>(
                  //       value: clinics.contains(selectedClinic) ? selectedClinic : "All",
                  //       decoration: InputDecoration(
                  //         filled: true,
                  //         fillColor: Colors.grey[200],
                  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  //         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  //       ),
                  //       items: clinics.map((clinic) {
                  //         return DropdownMenuItem<String>(
                  //           value: clinic,
                  //           child: Text(clinic),
                  //         );
                  //       }).toList(),
                  //       onChanged: (value) {
                  //         localSetState(() {
                  //           selectedClinic = value!;
                  //         });
                  //       },
                  //     );
                  //   },
                  // ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        applyFilters();
                      },
                      child: Text("Apply Filters"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightpacha,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

class TokenReportGenerator {
  final BuildContext context;

  TokenReportGenerator(this.context);

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        );
      },
    );
  }


  Future<void> selectDateAndGenerate(String clinicId) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (selected != null) {
      _showLoadingDialog(); // show progress dialog

      try {
        final selectedDay = DateFormat('EEEE').format(selected); // e.g. Monday

        final clinicSnapshot = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .get();

        final clinicName = clinicSnapshot.data()?['name'] ?? 'Unknown Clinic';

        final doctors = await _getDoctorsWithLiveStatus(clinicId, selected, selectedDay);
        await _generatePdf(selected, doctors, clinicName);
      } catch (e) {
        print("Error generating PDF: $e");
      } finally {
        Navigator.of(context).pop(); // close loading dialog
      }
    }
  }

  Future<void> _generatePdf(
    DateTime date,
    List<Map<String, dynamic>> doctors,
    String clinicName,
  ) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);

    pdf.addPage(
      pw.MultiPage(
        build:
            (pw.Context context) => [
              pw.Text(
                "Live Token Report : $clinicName",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Date: $formattedDate"),
              pw.SizedBox(height: 20),
              _buildDoctorTable(doctors),
            ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/live_tokens_$formattedDate.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildDoctorTable(List<Map<String, dynamic>> doctors) {
    // Sort so that "Live" doctors appear first, then others
    doctors.sort((a, b) {
      final aLive = a['status']?.toLowerCase() == 'live';
      final bLive = b['status']?.toLowerCase() == 'live';
      if (aLive && !bLive) return -1; // a comes before b
      if (!aLive && bLive) return 1;  // b comes before a
      return 0; // keep same order if same status
    });

    return pw.Table.fromTextArray(
      headers: [
        'S.No',
        'Doctor Name',
        'Specialization',
        'Live Status',
        'Token Count',
      ],
      data: List<List<String>>.generate(
        doctors.length,
            (index) => [
          '${index + 1}',
          doctors[index]['name'],
          doctors[index]['specialization'],
          doctors[index]['status'],
          doctors[index]['tokenCount'].toString(),
        ],
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  Future<List<Map<String, dynamic>>> _getDoctorsWithLiveStatus(
    String clinicId,
    DateTime date,
    String selectedDay,
  ) async {
    final List<Map<String, dynamic>> doctorList = [];
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final doctorsSnapshot =
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .collection('doctors')
            .get();

    for (final doc in doctorsSnapshot.docs) {
      final data = doc.data();
      final availableDays = List<String>.from(data['availableDays'] ?? []);

      bool isLive = false;
      int tokenCount = 0;

      if (availableDays.contains(selectedDay)) {
        final behaviourDoc =
            await FirebaseFirestore.instance
                .collection('clinics')
                .doc(clinicId)
                .collection('doctors')
                .doc(doc.id)
                .collection('doctorBehaviour')
                .doc(dateStr)
                .get();

        if (behaviourDoc.exists) {
          isLive = true;
          final behaviourData = behaviourDoc.data();
          final tokens = behaviourData?['tokens'] as List<dynamic>?;

          if (tokens != null) {
            tokenCount = tokens.length;
          }
        }

        doctorList.add({
          'name': data['name'] ?? 'Unknown',
          'specialization': data['specialization'] ?? 'N/A',
          'status': isLive ? 'Live' : 'No Live',
          'tokenCount': tokenCount,
        });
      }
    }

    return doctorList;
  }
}

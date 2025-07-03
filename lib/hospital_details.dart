import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/hospital_related/Account_Creation.dart';
import 'package:zappq_admin_app/hospital_related/Bookings.dart';
import 'package:zappq_admin_app/hospital_related/Staff_add.dart';
import 'package:zappq_admin_app/hospital_related/doctor_view.dart';
import 'package:zappq_admin_app/main.dart';
import 'package:zappq_admin_app/common/text_styles.dart';
import 'LIve/livelisting.dart';
import 'hospital_related/Hospital_Edit.dart';

class ClinicDetailsPage extends StatefulWidget {
  final Map<String, dynamic> clinicData;
  final String ClinicId;
  const ClinicDetailsPage({
    super.key,
    required this.clinicData,
    required this.ClinicId,
  });

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  late List<dynamic> contents;
  List items = ["Live Doctor", "Bookings", "Staff Edit", "Staff Add","Hospital Edit","Create Account"];


  String? clinicid;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      clinicid = widget.ClinicId;
    });
    print(clinicid);

    contents = [
      LiveTokenPage(clinicId: widget.ClinicId,),
      // LiveTokenPage(),
      // LiveHospital(),
      BookingsPage(clinicid:widget.ClinicId ),
      DoctorView(clinicId: widget.ClinicId),
      StaffCreation(clinicId: widget.ClinicId),
      EditProfilePage(clinicid: widget.ClinicId),
      CreateAccountPage()
    ];
    // Example usage
    // getClinicIdByEmail(widget.email);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back),
              ),
            ),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    widget.clinicData['profilePhoto'] ??
                        'assets/images/hospital_placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Color(0xFF84CC16),
                        ),
                  ),
                ),
              ),
            ),
            // Hospital Information
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.clinicData['name'] ?? 'Hospital Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: Color(0xFF84CC16), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text(
                  widget.clinicData['locality'] ??
                      widget.clinicData['location'] ??
                      'Location',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 14, color: Colors.grey[300]),
                const SizedBox(width: 16),
                const Icon(Icons.phone, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text(
                  widget.clinicData['phone'] ?? 'Phone Number',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(
              height: height * 0.6,
              width: width,
              child: GridView.builder(
                itemCount: contents.length,
                shrinkWrap: true,
                padding: EdgeInsets.all(width * 0.02),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => contents[index],
                          ),
                        );
                      },
                      child: Container(
                        height: height * 0.1,
                        width: width * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * 0.03),
                          color: AppColors.mainlightpacha,
                        ),
                        child: Center(
                          child: Text(
                            items[index],
                            style: AppTextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.of(context).push(
            //       CupertinoPageRoute(
            //         builder: (context) {
            //           return EditProfilePage(clinicid: clinicid??"null");
            //         },
            //       ),
            //     );
            //   },
            //   child: Container(
            //     height: height * 0.1,
            //     width: width * 0.5,
            //     decoration: BoxDecoration(
            //       color: AppColors.mainlightpacha,
            //       borderRadius: BorderRadius.circular(width * 0.03),
            //     ),
            //     child: Center(
            //       child: Text(
            //         "Hospital Edit",
            //         style: AppTextStyles.bodyText.copyWith(
            //           fontWeight: FontWeight.bold,
            //           fontSize: 16,
            //           color: AppColors.white,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zappq_admin_app/main.dart';

import '../common/colors.dart';
import '../common/text_styles.dart';

class CurrentLiveToken extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String clinicName;
  final String specialisation;
  final String profilePhoto;

  const CurrentLiveToken({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.clinicName,
    required this.specialisation,
    required this.profilePhoto,
  });

  @override
  _CurrentLiveTokenState createState() => _CurrentLiveTokenState();
}

class _CurrentLiveTokenState extends State<CurrentLiveToken>
    with TickerProviderStateMixin {
  late AnimationController _containerController;
  late Animation<double> _containerAnimation;

  @override
  void initState() {
    super.initState();
    _containerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _containerAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _containerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _containerController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getLiveTokenStream(
    String doctorId,
  ) {
    return FirebaseFirestore.instance
        .collection('liveToken')
        .doc(doctorId)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightpacha,
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        centerTitle: true,
        title: Text(
          "Live Token Status",
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.white,
            fontSize: 25,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getLiveTokenStream(widget.doctorId),
        builder: (context, snapshot) {
          String advanceTokenNumber = "...";
          String walkingTokenNumber = "...";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            advanceTokenNumber = data?['LiveAToken']?.toString() ?? "...";
            walkingTokenNumber = data?['LiveWToken']?.toString() ?? "...";
          }

          final hasLiveToken =
              advanceTokenNumber != "..." || walkingTokenNumber != "...";

          return hasLiveToken
              ? Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      width: screenWidth * 0.85,
                      height: screenHeight * 0.25,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffBEF264),
                          border: Border.all(
                            color: AppColors.lightpacha,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(38),
                        ),
                      ),
                    ),
                    Positioned(
                      width: screenWidth * 0.80,
                      height: screenHeight * 0.30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffBEF264),
                          border: Border.all(
                            color: AppColors.lightpacha,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(48),
                        ),
                      ),
                    ),
                    Positioned(
                      width: screenWidth * 0.75,
                      height: screenHeight * 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffBEF264),
                          border: Border.all(
                            color: AppColors.lightpacha,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(58),
                        ),
                      ),
                    ),
                    Positioned(
                      width: screenWidth * 0.68,
                      height: screenHeight * 0.38,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(
                            color: AppColors.lightpacha,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(68),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              Column(
                                children: [
                                  Text(
                                    "Advance Booking Token",
                                    style: AppTextStyles.smallBodyText.copyWith(
                                      color: AppColors.lightpacha,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    " $advanceTokenNumber",
                                    style: AppTextStyles.heading2.copyWith(
                                      color: AppColors.lightpacha,
                                      fontSize: screenWidth * 0.12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Walk-in Token",
                                    style: AppTextStyles.smallBodyText.copyWith(
                                      color: AppColors.lightpacha,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "$walkingTokenNumber",
                                    style: AppTextStyles.heading2.copyWith(
                                      color: AppColors.lightpacha,
                                      fontSize: screenWidth * 0.12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Positioned(
                    //   bottom: screenHeight * 0.8,
                    //   child: Text(
                    //     "Live Token Status",
                    //     style: AppTextStyles.heading2.copyWith(
                    //       color: AppColors.white,
                    //       fontSize: 25,
                    //     ),
                    //   ),
                    // ),
                    Positioned(
                      bottom: screenHeight * 0.14,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "This is the live token currently being served.",
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              " Please be at the clinic on time to ",
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "Avoid missing your turn.",
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenHeight * 0.08,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Text(
                              widget.doctorName,
                              style: AppTextStyles.heading1.copyWith(
                                color: AppColors.white,
                                fontSize: 20,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(width: 8),
                                Text(
                                  widget.clinicName,
                                  style: AppTextStyles.heading1.copyWith(
                                    color: AppColors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: width*0.02,),
                                Icon(
                                  Icons.circle_sharp,
                                  color: AppColors.white,
                                  size: width * 0.04,
                                ),
                                SizedBox(width: width*0.02,),
                                Text(
                                  widget.specialisation,
                                  style: AppTextStyles.heading1.copyWith(
                                    color: AppColors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.65,
                      child: Text(
                        "Current Token Numbers",
                        style: AppTextStyles.smallBodyText.copyWith(
                          color: AppColors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.27,
                      child: Text(
                        "Get Well Soon!",
                        style: AppTextStyles.smallBodyText.copyWith(
                          color: AppColors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/lotties/notfound.json'),
                    Text(
                      "No Live Token Available",
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
        },
      ),
    );
  }
}

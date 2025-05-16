import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zappq_admin_app/LIve/tokenStepper.dart';

import '../common/colors.dart';
import '../common/text_styles.dart';
import '../loading_animation.dart';

class LiveDetailsPage extends StatefulWidget {
  final String doctorId;
  final String clinicName;
  final String clinicId;
  const LiveDetailsPage(
      {super.key, required this.doctorId, required this.clinicName, required this.clinicId});

  @override
  State<LiveDetailsPage> createState() => _LiveDetailsPageState();
}

class _LiveDetailsPageState extends State<LiveDetailsPage> {
  DateTime now = DateTime.now();
  String advanceTokenNumber = "...";
  String walkingTokenNumber = "...";
  int activeStep = 0;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getLiveTokenStream(
      String doctorId) {
    return FirebaseFirestore.instance
        .collection('liveToken')
        .doc(doctorId)
        .snapshots();
  }

  // Helpers to extract prefix and number from token like A3,A4...etc ----------
  String extractTokenPrefix(String token) {
    final match = RegExp(r'^[A-Za-z]+').firstMatch(token);
    return match != null ? match.group(0)! : '';
  }

  int extractTokenNumber(String token) {
    final match = RegExp(r'\d+').firstMatch(token);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Firestore references
    final doctorDoc = FirebaseFirestore.instance
        .collection('clinics')
        .doc(widget.clinicId)
        .collection('doctors')
        .doc(widget.doctorId);

    final behaviorDocRef = doctorDoc
        .collection('doctorBehaviour')
        .doc(DateFormat('yyyy-MM-dd').format(now));


    return Scaffold(
      backgroundColor: AppColors.lightpacha,
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        title: Text(
          'Live Token Status',
          style: TextStyle(
            fontFamily: 'nunito',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.07,
          ),
        ),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_circle_left,
              size: 30,
              color: Colors.white,
            )),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: doctorDoc.snapshots(),
          builder: (context, doctorSnapshot) {
            if (!doctorSnapshot.hasData || !doctorSnapshot.data!.exists) {
              return const SizedBox();
            }
            final doctorDetails =
            doctorSnapshot.data!.data() as Map<String, dynamic>;
            return StreamBuilder<DocumentSnapshot>(
                stream: behaviorDocRef.snapshots(),
                builder: (context, behaviorSnapshot) {
                  if (behaviorSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: LottieLoadingIndicator());
                  }
                  if (!behaviorSnapshot.hasData ||
                      !behaviorSnapshot.data!.exists) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset('assets/lotties/notfound.json',width:screenWidth * 0.99 ),
                          Text(
                            "Doctor Behaviors Not Available",
                            style: AppTextStyles.heading2.copyWith(color: AppColors.white,fontSize: screenWidth * 0.04),
                          ),
                        ],
                      ),
                    );
                  }

                  final behavioralDetails =
                  behaviorSnapshot.data!.data() as Map<String, dynamic>;
                  final tokens = List<Map<String, dynamic>>.from(
                      behavioralDetails["tokens"] ?? []);

                  // Skipped token logic
                  List<String> skippedTokens = [];
                  if (tokens.length >= 2) {
                    String prevToken = tokens[tokens.length - 2]['tokenNumber'];
                    String currToken = tokens.last['tokenNumber'];
                    String prefix = extractTokenPrefix(currToken);
                    int prevNum = extractTokenNumber(prevToken);
                    int currNum = extractTokenNumber(currToken);

                    if (currNum - prevNum > 1 &&
                        prefix == extractTokenPrefix(prevToken)) {
                      for (int i = prevNum + 1; i < currNum; i++) {
                        skippedTokens.add('$prefix$i');
                      }
                    }
                  }
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: screenWidth * 0.25,
                          width: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: CachedNetworkImage(
                              imageUrl: doctorDetails['profilePhoto'],
                              fit: BoxFit.cover,
                              width: 70,  // or whatever size you need
                              height: 70,
                              fadeInDuration: Duration(milliseconds: 300),
                              placeholder: (context, url) => ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    color: Colors.grey.shade200,
                                    width: 70,
                                    height: 70,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.asset(
                                  "assets/images/doc.png",
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                ),
                              ),
                            ),
                          ),

                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          doctorDetails['name'],
                          style: AppTextStyles.bodyText.copyWith(

                            color: Colors.white,
                            fontSize: screenWidth * 0.06,
                          ),
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '${widget.clinicName} ',
                          style: AppTextStyles.smallBodyText.copyWith(

                            color: Colors.white60,
                            fontSize: screenWidth * 0.04,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '•',
                              style: AppTextStyles.smallBodyText.copyWith(

                                color: Colors.white60,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            TextSpan(
                              text: ' ${doctorDetails['specialization']}',
                              style:AppTextStyles.smallBodyText.copyWith(

                                color: Colors.white60,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.03,
                      ),

                      ///----LIVE CARD UI AND UX------
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: getLiveTokenStream(widget.doctorId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data();
                              advanceTokenNumber =
                                  data?['LiveAToken']?.toString() ?? "...";
                              walkingTokenNumber =
                                  data?['LiveWToken']?.toString() ?? "...";
                            }
                            return SizedBox(
                              height: screenHeight * 0.3,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    width: screenWidth * 0.60,
                                    height: screenHeight * 0.27,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xffBEF264),
                                        border: Border.all(
                                            color: AppColors.lightpacha,
                                            width: 4),
                                        borderRadius: BorderRadius.circular(35),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    width: screenWidth * 0.70,
                                    height: screenHeight * 0.22,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xffBEF264),
                                        border: Border.all(
                                            color: AppColors.lightpacha,
                                            width: 4),
                                        borderRadius: BorderRadius.circular(45),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    width: screenWidth * 0.65,
                                    height: screenHeight * 0.27,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xffBEF264),
                                        border: Border.all(
                                            color: AppColors.lightpacha,
                                            width: 4),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    width: screenWidth * 0.58,
                                    height: screenHeight * 0.30,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          border: Border.all(
                                              color: AppColors.lightpacha,
                                              width: 4),
                                          borderRadius:
                                          BorderRadius.circular(50),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                  height: screenHeight * 0.02),
                                              Column(
                                                children: [
                                                  Text(
                                                    "Advanced Booking Token",
                                                    style: AppTextStyles
                                                        .smallBodyText
                                                        .copyWith(
                                                      color:
                                                      AppColors.lightpacha,
                                                      fontSize:
                                                      screenWidth * 0.04,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    advanceTokenNumber,
                                                    style: AppTextStyles
                                                        .heading2
                                                        .copyWith(
                                                      color:
                                                      AppColors.lightpacha,
                                                      fontSize:
                                                      screenWidth * 0.09,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height: screenHeight * 0.01),
                                              Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Walk-in Token",
                                                    style: AppTextStyles
                                                        .smallBodyText
                                                        .copyWith(
                                                      color:
                                                      AppColors.lightpacha,
                                                      fontSize:
                                                      screenWidth * 0.04,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    walkingTokenNumber,
                                                    style: AppTextStyles
                                                        .heading2
                                                        .copyWith(
                                                      color:
                                                      AppColors.lightpacha,
                                                      fontSize:
                                                      screenWidth * 0.09,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9.0, vertical: 10),
                        child: Text(
                          'This is the live token currently being served . Please be at the clinic on time to avoid missing your turn',
                          style: TextStyle(
                            fontFamily: 'nunito',
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            fontSize: screenWidth * 0.03,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 8,
                                    child: Text(
                                      "A",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightpacha,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      "Advance Booking Token",
                                      style: TextStyle(
                                        fontFamily: 'nunito',
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: screenHeight * 0.02,
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 8,
                                    child: Text(
                                      "W",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightpacha,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      "Walk-in Token",
                                      style: TextStyle(
                                        fontFamily: 'nunito',
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TokenStepper(
                        doctorId: widget.doctorId,
                        clinicId: doctorDetails['clinicId'],
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      ),

                    ],
                  );
                });
          }),
    );
  }
}
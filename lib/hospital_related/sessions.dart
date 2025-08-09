import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../common/colors.dart';
import '../common/text_styles.dart';

class AvailableSessions extends StatefulWidget {
  final Function(List<String>) onSessionSelected;
  final Function(List<String>) onSessionSelected1;
  final Function(int) onSessionSelected2;
  final int selectedSessionIndex;
  final String formattedDate;
  final String doctorId;
  final String clinicId;
  final DateTime selectedDate;

  const AvailableSessions({
    super.key,
    required this.onSessionSelected,
    required this.onSessionSelected1,
    required this.onSessionSelected2,
    required this.selectedSessionIndex,
    required this.formattedDate,
    required this.doctorId,
    required this.clinicId,
    required this.selectedDate,
  });

  @override
  _AvailableSessionsState createState() => _AvailableSessionsState();
}

class _AvailableSessionsState extends State<AvailableSessions> {
  late int selectedSessionIndex;
  List<String> sessionNames = [];
  List<String> sessionTimes = [];
  List<bool> availability = [];
  List<int> sessionTokenLimit = [];
  int tokenLimit = 0;

  @override
  void initState() {
    super.initState();
    selectedSessionIndex = -1;
    fetchSessionData();
  }

  @override
  void didUpdateWidget(AvailableSessions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      fetchSessionData();
    }
  }

  // ✅ Extract the correct weekday
  String getDayFromDate(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  Future<void> fetchSessionData() async {
    try {
      print("📆 Fetching session data for date: ${widget.selectedDate}");

      String dayOfWeek = getDayFromDate(widget.selectedDate);
      print("🗓 Extracted Day of the Week: $dayOfWeek");

      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('doctors')
          .doc(widget.doctorId)
          .get();

      if (!clinicDoc.exists) {
        print("❌ Clinic or doctor document not found.");
        return;
      }

      final doctorData = clinicDoc.data();
      if (doctorData == null || !doctorData.containsKey('consultationTimes')) {
        print("⚠️ `consultationTimes` field missing in Firestore.");
        return;
      }

      final consultationTimes = doctorData['consultationTimes'];
      final dayConsultation = consultationTimes[dayOfWeek];

      if (dayConsultation == null) {
        print("⚠️ No sessions found for $dayOfWeek.");
        setState(() {
          sessionNames.clear();
          sessionTimes.clear();
          availability.clear();
          sessionTokenLimit.clear();
        });
        return;
      }

      DateTime now = DateTime.now();
      sessionNames.clear();
      sessionTimes.clear();
      availability.clear();
      sessionTokenLimit.clear();

      int sessionCounter = 1;

      dayConsultation.forEach((sessionName, session) {
        double fromTime = (session['from'] as num).toDouble();
        double toTime = (session['to'] as num).toDouble();

        DateTime sessionStartTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          fromTime.toInt(),
          ((fromTime - fromTime.toInt()) * 60).toInt(),
        );

        if (widget.selectedDate.isAfter(now) || sessionStartTime.isAfter(now)) {
          sessionNames.add("Session $sessionCounter");
          sessionTimes.add("${formatTimeTo12Hour(fromTime)} - ${formatTimeTo12Hour(toTime)}");
          availability.add(session['tokenLimit'] != null && (session['tokenLimit'] as int) > 0);
          sessionTokenLimit.add(session['tokenLimit']);
          sessionCounter++;
          print("✅ Added session: Session $sessionCounter at ${sessionStartTime.toString()}");
        }
      });

      setState(() {});
    } catch (e) {
      print("❌ Error fetching session data: $e");
    }
  }

  // ✅ Format session time to 12-hour format
  String formatTimeTo12Hour(double time) {
    int hour = time.toInt();
    int minute = ((time - hour) * 60).toInt();
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Sessions',
          style: AppTextStyles.heading2.copyWith(
            fontSize: screenWidth * 0.045,
            color: AppColors.darkpacha,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),

        if (sessionNames.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton(
              onPressed: () {
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DoctorSelectionPage()));
              },
              child: Text(
                'No available sessions for this date.book for another day',
                style: AppTextStyles.bodyText.copyWith(color: Colors.red,fontSize: screenWidth*0.03),
              ),
            ),
          )
        else
          Column(
            children: List.generate(
              sessionNames.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: GestureDetector(
                  onTap: availability[index]
                      ? () {
                    setState(() {
                      selectedSessionIndex = index;
                    });
                    widget.onSessionSelected([sessionNames[index]]);
                    widget.onSessionSelected1([sessionTimes[index]]);
                    widget.onSessionSelected2(sessionTokenLimit[index]);
                  }
                      : null,
                  child: Container(
                    width: screenWidth * 0.9,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: availability[index] ? (selectedSessionIndex == index ? AppColors.lightpacha : Colors.grey[300]) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedSessionIndex == index ? AppColors.mainlightpacha.withOpacity(0.5) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(sessionNames[index], style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04)),
                        Text(sessionTimes[index], style: AppTextStyles.bodyText.copyWith(fontSize: screenWidth * 0.04)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

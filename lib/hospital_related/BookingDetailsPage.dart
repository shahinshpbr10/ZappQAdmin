import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zappq_admin_app/common/colors.dart';
import 'package:zappq_admin_app/hospital_related/sessions.dart';

import '../common/text_styles.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String clinicId;

  const BookingDetailsPage({
    super.key,
    required this.data,
    required this.clinicId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  // Store controllers for each booking
  final Map<String, TextEditingController> tokenControllers = {};

  TextEditingController _getController(String bookingId) {
    if (!tokenControllers.containsKey(bookingId)) {
      tokenControllers[bookingId] = TextEditingController();
    }
    return tokenControllers[bookingId]!;
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd-MM-yyyy • hh:mm a').format(dateTime);
  }

  DateTime getAppointmentEndTime(String date, String timeRange) {
    try {
      timeRange = timeRange.replaceAll('[', '').replaceAll(']', '');
      final endTimeString = timeRange.split(' - ').last.trim();
      final dateTimeString = "$date $endTimeString";
      return DateFormat('yyyy-MM-dd h:mm a').parse(dateTimeString);
    } catch (e) {
      print('Error parsing appointment end time: $e');
      return DateTime.now();
    }
  }

  Future<void> _updateToken(String bookingId, int token) async {
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({'token': token});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token $token assigned successfully.'),
          backgroundColor: AppColors.lightpacha,
        ),
      );

      setState(() {
        widget.data['token'] = token;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleReschedule(
      BuildContext context, String clinicId, String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Handle Reschedule'),
          content: const Text('Orappalle machu.hospital kk vilich set alle'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // If cancelled, do nothing

    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({
        'Conform_Reschedule': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> updateTokenForAppointment(
    String bookingId,
    String uid,
    int newTokenNumber,
    String formattedDate,
    String doctorId,
  ) async {
    if (doctorId.isEmpty || uid.isEmpty) {
      print("❌ Error: Missing required data - doctorId: $doctorId, uid: $uid");
      return;
    }

    try {
      DocumentReference bookingRef = FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('bookings')
          .doc(bookingId);

      await bookingRef.update({'token': newTokenNumber});

      DocumentReference tokenDocRef = FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('doctors')
          .doc(doctorId)
          .collection('liveTokenDetails')
          .doc(formattedDate);

      DocumentSnapshot docSnapshot = await tokenDocRef.get();

      if (!docSnapshot.exists) {
        await tokenDocRef.set({
          uid: {'token': newTokenNumber},
        });
      } else {
        await tokenDocRef.update({'$uid.token': newTokenNumber});
      }

      print("✅ Token update successful for UID: $uid on $formattedDate");
    } catch (e) {
      print("❌ Error updating token: $e");
    }
  }

  Widget tokenAssign(Map<String, dynamic> appointment) {
    final hasToken = appointment['token'] > 0;
    final buttonColor = hasToken ? Colors.orange : Colors.blue;
    final buttonText = hasToken ? 'Reassign' : 'Assign';

    final tokenController = _getController(appointment['bookingId']);

    final bookingId = appointment['bookingId'] ?? '';
    final date = appointment['bookingDate'] ?? '';
    final doctorId = appointment['doctorId'] ?? '';
    final uid = appointment['uid'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasToken)
          Text(
            'Current Token: ${appointment['token']}',
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(width: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  hintText: 'New Token',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.black),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final token = int.tryParse(tokenController.text);
                if (token != null &&
                    bookingId.isNotEmpty &&
                    date.isNotEmpty &&
                    doctorId.isNotEmpty) {
                  _updateToken(bookingId, token);
                  updateTokenForAppointment(
                    bookingId,
                    uid,
                    token,
                    date,
                    doctorId,
                  );
                  tokenController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid token number and make sure all data is correct',
                      ),
                    ),
                  );
                }
              },
              child: Text(buttonText),
            ),
          ],
        ),
      ],
    );
  }

  bookingDeletion(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.pop(context, true);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Patient booking deleted')));
    }
  }

  /// State variable to store doctor’s available days
  List<String> availableDays = [];

  /// Fetch available days from Firestore based on doctor and clinic
  Future<List<String>> fetchAvailableDays(
    String clinicId,
    String doctorId,
  ) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('doctors')
              .doc(doctorId)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['availableDays'] != null) {
          return List<String>.from(
            data['availableDays'].map((day) => day.toString()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching availableDays: $e");
    }
    return [];
  }

  /// Generate list of upcoming available dates based on availableDays
  List<DateTime> getAvailableDates() {
    List<DateTime> availableDates = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      DateTime checkDate = now.add(Duration(days: i));
      String dayName = DateFormat('EEEE').format(checkDate);

      if (availableDays.contains(dayName)) {
        availableDates.add(checkDate);
      }
    }
    return availableDates;
  }

  /// Main function to handle rescheduling a booking
  Future<void> resheduleBooking(
    String bookingId,
    String clinicId,
    String doctorId,
  ) async {
    DateTime? newSelectedDate;
    String? newSessionName;
    String? newSessionTime;
    int? newTokenLimit;

    // Step 1: Fetch existing booking
    final bookingDoc =
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .collection('bookings')
            .doc(bookingId)
            .get();

    if (!bookingDoc.exists) {
      showCustomSnackBar(context, "Booking not found", isError: true);
      return;
    }

    final bookingData = bookingDoc.data();

    // Step 2: Fetch available days and store in state variable
    availableDays = await fetchAvailableDays(clinicId, doctorId);
    if (availableDays.isEmpty) {
      showCustomSnackBar(
        context,
        "No available days found for this doctor.",
        isError: true,
      );
      return;
    }

    // Step 3: Show date picker
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        List<DateTime> dates = getAvailableDates();
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text("Select a New Date", style: AppTextStyles.heading2),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    DateTime date = dates[index];
                    return ListTile(
                      title: Text(DateFormat('EEEE, MMM d, yyyy').format(date)),
                      onTap: () {
                        newSelectedDate = date;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (newSelectedDate == null) return; // User canceled

    // Step 4: Show session picker
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              children: [
                AvailableSessions(
                  onSessionSelected:
                      (names) =>
                          newSessionName =
                              names.isNotEmpty ? names.first : null,
                  onSessionSelected1:
                      (times) =>
                          newSessionTime =
                              times.isNotEmpty ? times.first : null,
                  onSessionSelected2: (limit) => newTokenLimit = limit,
                  selectedSessionIndex: 0,
                  formattedDate: DateFormat(
                    'yyyy-MM-dd',
                  ).format(newSelectedDate!),
                  doctorId: doctorId,
                  clinicId: clinicId,
                  selectedDate: newSelectedDate!,
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightpacha,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Confirm Session"),
                            content: Text(
                              "${DateFormat('yyyy-MM-dd').format(newSelectedDate!)}\n"
                              "$newSessionTime",
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  "Confirm",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Confirm Slot",
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    if (newSessionName == null || newSessionTime == null) {
      showCustomSnackBar(context, "Please select a session", isError: true);
      return;
    }

    // Step 5: Save updated booking to Firestore
    try {
      final previousBookingDate = bookingData?['bookingDate'];
      final previousAppointmentTime = bookingData?['appointmentTime'];

      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({
            'bookingDate': DateFormat('yyyy-MM-dd').format(newSelectedDate!),
            'appointmentTime': newSessionTime,
            'sessionName': newSessionName,
            'Admin reshedule': true,
            'oldBookingDate': previousBookingDate,
            'oldAppointmentTime': previousAppointmentTime,
          });

      showCustomSnackBar(context, "Booking rescheduled successfully");
    } catch (e) {
      showCustomSnackBar(
        context,
        "Failed to reschedule booking: $e",
        isError: true,
      );
    }
  }

  void showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : AppColors.lightpacha,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 10,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Function to confirm reschedule
  Future<void> confirmReschedule(
    BuildContext context,
    String clinicId,
    String bookingId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({'confirmReschedule': true});

      Navigator.pop(context); // Close the alert box

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reschedule confirmed successfully')),
      );
    } catch (e) {
      Navigator.pop(context); // Close the alert box even if failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming reschedule: $e')),
      );
    }
  }

  /// Function to show confirmation alert
  void showConfirmRescheduleDialog(
    BuildContext context,
    String clinicId,
    String bookingId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Reschedule"),
          content: const Text(
            "Are you sure you want to confirm the reschedule for this booking?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                confirmReschedule(context, clinicId, bookingId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of all controllers
    tokenControllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        title: Text(
          data['patientName'] ?? 'Booking Details',
          style: const TextStyle(color: AppColors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => bookingDeletion(data['bookingId']),
            icon: Icon(Icons.delete, color: Colors.red),
          ),
          (data['reshedule'] == true && data['Conform_Reschedule'] == false)
              ? TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue), // solid color
            ),
            onPressed: () async {
              await handleReschedule(
                context,
                widget.clinicId,
                data['bookingId'],
              );

              setState(() {
                data['Conform_Reschedule'] = true;
              });
            },
            child: const Text(
              "Handled",
              style: TextStyle(color: AppColors.white),
            ),
          )
              : const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(widget.clinicId)
                    .collection('bookings')
                    .doc(data["bookingId"]) // pass the booking ID from your page
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading booking details'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  return Center(
                    child: Card(
                      color: AppColors.lightpacha,
                      elevation: 4,
                      margin: const EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            detailItem("Patient Name", data['patientName']),
                            detailItem("Age", data['age']),
                            detailItem("Phone", data['phoneNumber']),
                            detailItem(
                              "Created At",
                              formatTimestamp(data['timestamp']),
                            ),
                            detailItem("Booking Date", data['bookingDate']),
                            detailItem("Booking Slot", data['appointmentTime']),
                            if (data['reshedule'] == true||data['Admin reshedule'] == true)
                              detailItem(
                                "Old Booking Date",
                                data['oldBookingDate'],
                                valueColor: Colors.red,
                              ),
                            if (data['reshedule'] == true||data['Admin reshedule'] == true)
                              detailItem(
                                "Old Booking Slot",
                                data['oldAppointmentTime'],
                                valueColor: Colors.red,
                              ),
                            detailItem("Doctor Name", data['doctorName']),
                            detailItem("Payment Method", data['paymentMethod']),
                            detailItem("Payment Amount", data['paymentAmount']),
                            detailItem("Token Number", data['token']),
                            detailItem("Status", data['bookingStatus']),
                            (getAppointmentEndTime(
                              data['bookingDate'],
                              data['appointmentTime'],
                            ).isAfter(DateTime.now()) &&
                                data['bookingStatus'] != 'cancelled')
                                ? tokenAssign(data)
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(data['phoneNumber']),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightpacha,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => resheduleBooking(
                        data["bookingId"],
                        widget.clinicId,
                        data["doctorId"],
                      ),
                  icon: const Icon(Icons.edit, color: Colors.red),
                  label: const Text('Reshedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightpacha,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget detailItem(
    String title,
    dynamic value, {
    Color valueColor = AppColors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(fontSize: 15, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

void _makePhoneCall(String phoneNumber) async {
  final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(callUri)) {
    await launchUrl(callUri);
  } else {
    print('Could not launch $callUri');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zappq_admin_app/common/colors.dart';

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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
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
                        detailItem("Created At",   formatTimestamp(data['timestamp']),),
                        detailItem("Booking Date", data['bookingDate']),
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
                  onPressed: () => bookingDeletion(data['bookingId']),
                  icon: const Icon(Icons.delete,color: Colors.red,),
                  label: const Text('Delete'),
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

  Widget detailItem(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 15, color: AppColors.white),
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

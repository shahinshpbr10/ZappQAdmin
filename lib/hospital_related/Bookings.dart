import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zappq_admin_app/common/colors.dart';

class BookingsPage extends StatefulWidget {
  final String clinicid;
  const BookingsPage({super.key, required this.clinicid});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  TextEditingController searchController = TextEditingController();
  // Store controllers for each booking
  Map<String, TextEditingController> tokenControllers = {};

  // Get the controller for a specific booking
  TextEditingController _getController(String bookingId) {
    if (!tokenControllers.containsKey(bookingId)) {
      tokenControllers[bookingId] = TextEditingController();
    }
    return tokenControllers[bookingId]!;
  }  String? currentClinicId;
  String uid = '';
  String? bookingDate;
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentClinicId=widget.clinicid;
  }

  bookingDeletion(String bookingId)async{
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicid)
          .collection('bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient booking deleted')),
      );
    }
  }

  DateTime getAppointmentEndTime(String date, String timeRange) {
    try {
      // Remove brackets if present
      timeRange = timeRange.replaceAll('[', '').replaceAll(']', '');

      // Extract the END time part (after " - ")
      final endTimeString = timeRange.split(' - ').last.trim(); // "9:00 AM"

      // Combine with date
      final dateTimeString = "$date $endTimeString"; // "2025-07-05 9:00 AM"

      // Parse it into DateTime
      return DateFormat('yyyy-MM-dd h:mm a').parse(dateTimeString);
    } catch (e) {
      print('Error parsing appointment end time: $e');
      return DateTime.now(); // fallback to now
    }
  }


  Future<void> _updateToken(String bookingId, int token) async {
    if (currentClinicId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(currentClinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({'token': token});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token $token assigned successfully.'),backgroundColor: AppColors.lightpacha,),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to assign token: $e'),backgroundColor: Colors.red,));
    }
  }

  Future<void> updateTokenForAppointment(
    String bookingId,
    String uid,
    int newTokenNumber,
    String formattedDate,
    String doctorId,
  ) async {
    if (currentClinicId == null || doctorId.isEmpty || uid.isEmpty) {
      print(
        "❌ Error: Missing required data - clinicId: $currentClinicId, doctorId: $doctorId, uid: $uid",
      );
      return;
    }

    try {
      // Step 1: Update Token in Bookings Collection
      DocumentReference bookingRef = FirebaseFirestore.instance
          .collection('clinics')
          .doc(currentClinicId)
          .collection('bookings')
          .doc(bookingId);

      await bookingRef.update({'token': newTokenNumber});
      print("✅ Token updated in bookings for UID: $uid");

      // Step 2: Update Token in Doctor's liveTokenDetails Collection
      DocumentReference tokenDocRef = FirebaseFirestore.instance
          .collection('clinics')
          .doc(currentClinicId)
          .collection('doctors')
          .doc(doctorId)
          .collection('liveTokenDetails')
          .doc(formattedDate);

      DocumentSnapshot docSnapshot = await tokenDocRef.get();

      if (!docSnapshot.exists) {
        print("🆕 Creating new token entry for Date: $formattedDate");
        await tokenDocRef.set({
          uid: {'token': newTokenNumber},
        });
      } else {
        print("🔄 Updating existing token for UID: $uid");
        await tokenDocRef.update({'$uid.token': newTokenNumber});
      }

      print("✅ Token update successful for UID: $uid on $formattedDate");
    } catch (e) {
      print("❌ Error updating token: $e");
    }
  }

  String searchQuery = "";
  DateTime? selectedDate;

  int currentTabIndex = 0;

  // Filtering helpers
  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  Future<void> fetchClinicBookings(String clinicId) async {
    try {
      final bookingsSnapshot =
          await FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicId)
              .collection('bookings')
              .get();

      for (var doc in bookingsSnapshot.docs) {
        print('Booking ID: ${doc.id}');
        print('Data: ${doc.data()}');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
  }

  DateTime? fromDate;
  DateTime? toDate;

  // Generate PDF function with clinic name
  Future<void> generatePdf(
    List<DocumentSnapshot> filteredBookings,
    String clinicName,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Patient Bookings Report',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'From ${DateFormat('dd-MM-yyyy').format(fromDate)} to ${DateFormat('dd-MM-yyyy').format(toDate)}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                headers: [
                  'Patient Name',
                  'Booking Date',
                  'Doctor',
                  'Phone Number',
                ],
                data:
                    filteredBookings.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return [
                        data['patientName'] ?? '',
                        data['bookingDate'] ?? '',
                        data['doctorName'] ?? '',
                        data['phoneNumber'] ?? '',
                      ];
                    }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Select from and to date, then generate report
  Future<void> _selectDateRangeAndGenerateReport(BuildContext context) async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedRange != null) {
      final fromDate = pickedRange.start;
      final toDate = pickedRange.end;

      // Fetch clinic name
      DocumentSnapshot clinicDoc =
          await FirebaseFirestore.instance
              .collection('clinics')
              .doc(widget.clinicid)
              .get();

      String clinicName =
          (clinicDoc.data() as Map<String, dynamic>)['clinicName'] ?? 'Clinic';

      // Fetch bookings within date range
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('clinics')
              .doc(widget.clinicid)
              .collection('bookings')
              .where(
                'bookingDate',
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(fromDate),
              )
              .where(
                'bookingDate',
                isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(toDate),
              )
              .get();

      List<DocumentSnapshot> filteredBookings = querySnapshot.docs;

      await generatePdf(filteredBookings, clinicName, fromDate, toDate);
    }
  }

  bool isUpcoming(String dateStr) {
    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return date.isAfter(now);
    } catch (_) {
      return false;
    }
  }

  bool isExpired(String dateStr) {
    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return date.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  Widget tokenAssign(Map<String, dynamic> appointment) {
    final hasToken = appointment['token'] > 0;
    final buttonColor = hasToken ? Colors.orange : Colors.blue;
    final buttonText = hasToken ? 'Reassign' : 'Assign';

    // Get the controller dynamically for this specific booking
    final tokenController = _getController(appointment['bookingId']);

    // Null checks for the fields you're using
    final bookingId = appointment['bookingId'] ?? '';
    final date = appointment['bookingDate'] ?? '';  // Ensure date is not null or empty
    final doctorId = appointment['doctorId'] ?? '';


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasToken)
          Text(
            'Current Token: ${appointment['token']}',
            style: TextStyle(
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
                style: TextStyle(color: AppColors.black),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final token = int.tryParse(tokenController.text);
                if (token != null && bookingId.isNotEmpty && date.isNotEmpty && doctorId.isNotEmpty) {
                  _updateToken(appointment['bookingId'], token);
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
                      content: Text('Please enter a valid token number and make sure all data is correct'),
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
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _selectDateRangeAndGenerateReport(context),
          tooltip: 'Pick Date & Generate PDF',
          child: Icon(Icons.picture_as_pdf),
        ),
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.lightpacha,
          title: Text(
            'Clinic Bookings',
            style: TextStyle(color: AppColors.white),
          ),
          bottom: TabBar(
            labelColor: AppColors.white, // Color for selected tab
            unselectedLabelColor: AppColors.white, // Color for unselected tabs
            onTap: (index) {
              setState(() => currentTabIndex = index);
            },
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by patient name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged:
                    (val) => setState(() => searchQuery = val.toLowerCase()),
              ),
            ),
            // 📋 Booking List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('clinics')
                        .doc(widget.clinicid)
                        .collection('bookings')
                        .orderBy('bookingDate', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text('Error loading data'));
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  final filtered =
                      docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['patientName'] ?? '').toLowerCase();
                        final dateStr = data['bookingDate'] ?? '';

                        if (!name.contains(searchQuery)) return false;

                        if (currentTabIndex == 1) return isUpcoming(dateStr);
                        if (currentTabIndex == 2) return isExpired(dateStr);
                        return true;
                      }).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No bookings found'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data =
                          (filtered[index].data() as Map<String, dynamic>);


                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['patientName'] ?? 'No Name'),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: ()  {
                                  bookingDeletion(data['bookingId']);
                                },
                              ),                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Age: ${data['age'] ?? 'N/A'}'),
                              Text('Date: ${data['bookingDate']}'),
                              Text('Doctor: ${data['doctorName']}'),
                              Text('Phone number:${data['phoneNumber']}'),
                              Text('Payment Method:${data['paymentMethod']}'),
                              Text('Payment Amount:${data['paymentAmount']}'),
                              isExpired(data['bookingDate'])?Text('Token Number:${data['token']}'):SizedBox(),
                              getAppointmentEndTime(data['bookingDate'], data['appointmentTime'])
                                  .isAfter(DateTime.now())
                                  ? tokenAssign(data)
                                  : SizedBox(),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

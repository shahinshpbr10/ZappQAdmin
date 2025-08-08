import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zappq_admin_app/common/colors.dart';

import 'BookingDetailsPage.dart';

class BookingsPage extends StatefulWidget {
  final String clinicid;
  const BookingsPage({super.key, required this.clinicid});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  TextEditingController searchController = TextEditingController();


  String? currentClinicId;
  String uid = '';
  String? bookingDate;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentClinicId = widget.clinicid;
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd-MM-yyyy • hh:mm a').format(dateTime);
  }

  List<DocumentSnapshot> allBookings = []; // List of all bookings fetched
  List<DocumentSnapshot> displayedBookings = []; // What you show on screen

  void filterBookingsBySelectedDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(pickedDate);

    displayedBookings =
        allBookings.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingDate = data['bookingDate'] ?? '';
          return bookingDate == selectedDateStr;
        }).toList();

    if (displayedBookings.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
          title: const Text('No  Bookings'),
          content: const Text('There are no bookings available on selected date.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {});
    }  }

  void sortBookingsByTimestamp() {
    displayedBookings.sort((a, b) {
      final Timestamp timeA = a['timestamp'] ?? Timestamp(0, 0);
      final Timestamp timeB = b['timestamp'] ?? Timestamp(0, 0);
      return timeB.compareTo(timeA); // Descending: latest first
    });
  }

  void fetchAndSortBookings() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(widget.clinicid)
            .collection('bookings')
            .get();

    setState(() {
      displayedBookings = snapshot.docs;
      sortBookingsByTimestamp(); // sort after fetching
    });
  }

  void filterCancelledBookings() {
    displayedBookings =
        allBookings
            .where((doc) => doc['bookingStatus'] == 'cancelled')
            .toList();

    if (displayedBookings.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('No Cancelled Bookings'),
              content: const Text('There are no cancelled bookings available.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } else {
      setState(() {});
    }
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
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded, color: AppColors.white),
              onSelected: (value) {
                // Reset filtered data
                displayedBookings.clear();

                if (value == 'all') {
                  setState(() {});
                } else if (value == 'date') {
                  filterBookingsBySelectedDate();
                } else if (value == 'cancelled') {
                  filterCancelledBookings();
                } else if (value == 'updated') {
                  fetchAndSortBookings();
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text('Sort by Date'),
                    ),
                    const PopupMenuItem(
                      value: 'date',
                      child: Text('Filter by Date'),
                    ),
                    const PopupMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled Bookings'),
                    ),
                    const PopupMenuItem(
                      value: 'updated',
                      child: Text('Last Updated'),
                    ),
                  ],
            ),
          ],
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
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Get all docs from Firestore and store in allBookings
                  final docs = snapshot.data!.docs;
                  allBookings = docs;

                  // If user applied a date filter, use that list; else, fallback to docs
                  final bookingsToDisplay =
                      displayedBookings.isNotEmpty ? displayedBookings : docs;

                  // Apply tab and search filters
                  final filtered =
                      bookingsToDisplay.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['patientName'] ?? '').toLowerCase();
                        final dateStr = data['bookingDate'] ?? '';

                        if (!name.contains(searchQuery)) return false;
                        if (currentTabIndex == 1) return isUpcoming(dateStr);
                        if (currentTabIndex == 2) return isExpired(dateStr);
                        return true;
                      }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No bookings found'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data =
                          filtered[index].data() as Map<String, dynamic>;

                      return Card(
                        color:
                            data['bookingStatus'] == 'cancelled'
                                ? Colors.red
                                : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['patientName'] ?? 'No Name',
                                style: TextStyle(
                                  color:
                                      data['bookingStatus'] == 'cancelled'
                                          ? Colors.white
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              data['paymentMethod']=='online'? Icon(
                                Icons.wifi,
                                size: 16,
                              ):Icon(
                                Icons.wifi_off,
                                size: 16,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Date: ${data['bookingDate']}',
                                style: TextStyle(
                                  color:
                                      data['bookingStatus'] == 'cancelled'
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              Text(
                                "Created:${formatTimestamp(data['timestamp'])}",
                                style: TextStyle(
                                  color:
                                      data['bookingStatus'] == 'cancelled'
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              // if (isExpired(data['bookingDate']))
                                Text(
                                  'Token Number: ${data['token'] ?? '-'}',
                                  style: TextStyle(
                                    color:
                                        data['bookingStatus'] == 'cancelled'
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                            ],
                          ),
                          // trailing: const Icon(
                          //   Icons.arrow_forward_ios,
                          //   size: 16,
                          // ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailsPage(data: data, clinicId: widget.clinicid,),
                              ),
                            );
                          },
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

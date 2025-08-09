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

  String searchQuery = "";
  DateTime? selectedDate;
  int currentTabIndex = 0;
  String currentSortFilter = 'updated'; // Track current filter

  // Remove the manual booking lists - let StreamBuilder handle the data
  List<DocumentSnapshot>? manualFilteredBookings; // Only for special filters

  @override
  void initState() {
    super.initState();
    currentClinicId = widget.clinicid;
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

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
                data: filteredBookings.map((doc) {
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

  Future<void> _selectDateRangeAndGenerateReport(BuildContext context) async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedRange != null) {
      final fromDate = pickedRange.start;
      final toDate = pickedRange.end;

      DocumentSnapshot clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicid)
          .get();

      String clinicName =
          (clinicDoc.data() as Map<String, dynamic>)['clinicName'] ?? 'Clinic';

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicid)
          .collection('bookings')
          .where(
        'bookingDate',
        isGreaterThanOrEqualTo:
        DateFormat('yyyy-MM-dd').format(fromDate),
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
      final today = DateTime(now.year, now.month, now.day);
      return date.isAtSameMomentAs(today) || date.isAfter(today);
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

  void filterBookingsBySelectedDate(List<DocumentSnapshot> allBookings) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(pickedDate);

    final filtered = allBookings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final bookingDate = data['bookingDate'] ?? '';
      return bookingDate == selectedDateStr;
    }).toList();

    if (filtered.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Bookings'),
          content:
          const Text('There are no bookings available on selected date.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        manualFilteredBookings = filtered;
        currentSortFilter = 'date';
      });
    }
  }

  List<DocumentSnapshot> sortBookingsByTimestamp(List<DocumentSnapshot> bookings) {
    final sortedList = List<DocumentSnapshot>.from(bookings);
    sortedList.sort((a, b) {
      final Timestamp timeA = a['timestamp'] ?? Timestamp(0, 0);
      final Timestamp timeB = b['timestamp'] ?? Timestamp(0, 0);
      return timeB.compareTo(timeA); // Descending: latest first
    });
    return sortedList;
  }

  void filterCancelledBookings(List<DocumentSnapshot> allBookings) {
    final filtered = allBookings.where((doc) => doc['bookingStatus'] == 'cancelled').toList();

    if (filtered.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
      setState(() {
        manualFilteredBookings = filtered;
        currentSortFilter = 'cancelled';
      });
    }
  }

  void filterRescheduledBookings(List<DocumentSnapshot> allBookings) {
    final filtered = allBookings.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data.containsKey('reshedule') && data['reshedule'] == true;
    }).toList();

    if (filtered.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Rescheduled Bookings'),
          content: const Text('There are no bookings marked as rescheduled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        manualFilteredBookings = filtered;
        currentSortFilter = 'Resheduled';
      });
    }
  }

  // Get the appropriate stream query based on current filter
  Stream<QuerySnapshot> getBookingsStream() {
    var query = FirebaseFirestore.instance
        .collection('clinics')
        .doc(widget.clinicid)
        .collection('bookings');

    // Apply ordering based on current filter
    if (currentSortFilter == 'updated') {
      return query.orderBy('timestamp', descending: true).snapshots();
    } else {
      return query.orderBy('bookingDate', descending: true).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return  DefaultTabController(
      length: 3,
      initialIndex: 0, // 0 = Upcoming tab is default now
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _selectDateRangeAndGenerateReport(context),
          tooltip: 'Pick Date & Generate PDF',
          child: const Icon(Icons.picture_as_pdf),
        ),
        appBar: AppBar(
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded, color: AppColors.white),
              onSelected: (value) {
                setState(() {
                  currentSortFilter = value;
                  manualFilteredBookings = null;
                });
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(
                  value: 'updated',
                  child: Text('Last Updated'),
                ),
                PopupMenuItem(
                  value: 'all',
                  child: Text('Sort by Date'),
                ),
                PopupMenuItem(
                  value: 'date',
                  child: Text('Filter by Date'),
                ),
                PopupMenuItem(
                  value: 'cancelled',
                  child: Text('Cancelled Bookings'),
                ),
                PopupMenuItem(
                  value: 'Resheduled',
                  child: Text('Resheduled'),
                ),
              ],
            ),
          ],
          centerTitle: true,
          backgroundColor: AppColors.lightpacha,
          title: const Text(
            'Clinic Bookings',
            style: TextStyle(color: AppColors.white),
          ),
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white,
            onTap: (index) {
              setState(() => currentTabIndex = index);
            },
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Expired'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by patient name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged: (val) =>
                    setState(() => searchQuery = val.toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading data: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No bookings found'));
                  }

                  final allDocs = snapshot.data!.docs;

                  // Determine which bookings to display based on current filter
                  List<DocumentSnapshot> bookingsToDisplay;

                  if (manualFilteredBookings != null) {
                    bookingsToDisplay = manualFilteredBookings!;
                  } else {
                    // Apply filtering directly without setState
                    switch (currentSortFilter) {
                      case 'cancelled':
                        bookingsToDisplay = allDocs.where((doc) => doc['bookingStatus'] == 'cancelled').toList();
                        if (bookingsToDisplay.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
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
                            setState(() {
                              currentSortFilter = 'updated';
                            });
                          });
                          return const Center(child: Text('No cancelled bookings found'));
                        }
                        break;
                      case 'Resheduled':
                        bookingsToDisplay = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data == null) return false;
                          return data.containsKey('reshedule') && data['reshedule'] == true;
                        }).toList();
                        if (bookingsToDisplay.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('No Rescheduled Bookings'),
                                content: const Text('There are no bookings marked as rescheduled.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            setState(() {
                              currentSortFilter = 'updated';
                            });
                          });
                          return const Center(child: Text('No rescheduled bookings found'));
                        }
                        break;
                      case 'date':
                        if (manualFilteredBookings == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            filterBookingsBySelectedDate(allDocs);
                          });
                          return const Center(child: CircularProgressIndicator());
                        }
                        bookingsToDisplay = allDocs;
                        break;
                      default:
                        bookingsToDisplay = allDocs;
                    }
                  }

                  // Apply search and tab filters
                  final filtered = bookingsToDisplay.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['patientName'] ?? '').toLowerCase();
                    final dateStr = data['bookingDate'] ?? '';

                    // Search filter
                    if (!name.contains(searchQuery)) return false;

                    // Tab filter
                    if (currentTabIndex == 0) return isUpcoming(dateStr); // Upcoming
                    if (currentTabIndex == 1) return isExpired(dateStr); // Expired
                    return true; // All
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No bookings found'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;

                      return Card(
                        color: data['bookingStatus'] == 'cancelled'
                            ? Colors.red
                            : ((data['reshedule'] ?? false) ? Colors.orange : Colors.white),
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
                                  color: data['bookingStatus'] == 'cancelled'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              data['paymentMethod'] == 'online'
                                  ? const Icon(Icons.wifi, size: 16)
                                  : const Icon(Icons.wifi_off, size: 16),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Date: ${data['bookingDate']}',
                                style: TextStyle(
                                  color: data['bookingStatus'] == 'cancelled'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              if (data['timestamp'] != null)
                                Text(
                                  "Created: ${formatTimestamp(data['timestamp'])}",
                                  style: TextStyle(
                                    color: data['bookingStatus'] == 'cancelled'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              Text(
                                'Token Number: ${data['token'] ?? '-'}',
                                style: TextStyle(
                                  color: data['bookingStatus'] == 'cancelled'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: (data["Conform_Reschedule"] == false||data['Conform_Delete'] == false)
                              ? const Icon(
                            Icons.circle_rounded,
                            size: 15,
                            color: Colors.blue,
                          )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailsPage(
                                  data: data,
                                  clinicId: widget.clinicid,
                                ),
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
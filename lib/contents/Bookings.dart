import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BookingsPage extends StatefulWidget {
  final String clinicid;
  const BookingsPage({super.key, required this.clinicid});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  TextEditingController searchController = TextEditingController();
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
  Future<void> generatePdf(List<DocumentSnapshot> filteredBookings, String clinicName, DateTime fromDate, DateTime toDate) async {
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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
      DocumentSnapshot clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicid)
          .get();

      String clinicName = (clinicDoc.data() as Map<String, dynamic>)['clinicName'] ?? 'Clinic';

      // Fetch bookings within date range
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicid)
          .collection('bookings')
          .where('bookingDate', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(fromDate))
          .where('bookingDate', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(toDate))
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () =>_selectDateRangeAndGenerateReport(context),
          tooltip: 'Pick Date & Generate PDF',
          child: Icon(Icons.picture_as_pdf),
        ),
        appBar: AppBar(
          title: Text('Clinic Bookings'),
          bottom: TabBar(
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
                          title: Text(data['patientName'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Age: ${data['age'] ?? 'N/A'}'),
                              Text('Date: ${data['bookingDate']}'),
                              Text('Doctor: ${data['doctorName']}'),
                              Text('Phone number:${data['phoneNumber']}'),
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

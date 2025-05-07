import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../common/colors.dart';
import '../common/text_styles.dart';
import '../main.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // Filtering helpers
  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  DateTime? selectedDate;

  Future<void> _generatePdfReport(DateTime date) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(
            'Report for: ${date.toLocal().toString().split('')[0]}',
            style: pw.TextStyle(fontSize: 24),
          ),
        ),
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final filePath = "${outputDir.path}/report_${date.toIso8601String()}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await OpenFile.open(filePath);
  }

  Future<void> _selectDateAndGenerateReport(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _generatePdfReport(picked);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectDateAndGenerateReport(context),
        tooltip: 'Pick Date & Print',
        child: Icon(Icons.calendar_today),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text("All Bookings",style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body:Padding(
        padding: EdgeInsets.all(width*0.05),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                style: AppTextStyles.smallBodyText.copyWith(color: Colors.white),
                controller: searchController,
                onChanged: updateSearchQuery,
                decoration: InputDecoration(
                  hintText: "Search by patient name",
                  hintStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: AppColors.lightpacha,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(
                height: height,
                width: width,
                child: ListView.builder(
                  itemCount: 10,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: height*0.2,
                        width: width*0.8,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(width*0.03),
                            color: AppColors.lightpacha
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Patient name:",style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Phone number:",style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Doctor name:", style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Token number:", style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Online/Offline:", style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

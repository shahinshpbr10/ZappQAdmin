import 'package:flutter/material.dart';
import '../common/colors.dart';
import 'locationpicker_bottomsheet.dart';

class AppointmentBottomSheet extends StatelessWidget {
  const AppointmentBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ---------- Fixed Top Bar ----------
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // ---------- Scrollable Content ----------
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Coupon Field ----------
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Enter coupon code",
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainlightpacha,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Apply",style: TextStyle(color: AppColors.white),),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true, // important for DraggableScrollableSheet
                                backgroundColor: Colors.transparent, // remove default background
                                builder: (context) => const LocationBottomSheet(),
                              );
                            },
                            child: const Icon(Icons.location_on_outlined,
                                color: Colors.black),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ---------- Location ----------
                      const Row(
                        children: [
                          Icon(Icons.location_pin,
                              size: 18, color: Colors.blue),
                          SizedBox(width: 4),
                          Text("Location : Perinthalmanna",
                              style: TextStyle(
                                  color: Colors.blue, fontSize: 14)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ---------- Date Selection ----------
                      const Text("Choose Date",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _dateChip("Aug 24", true),
                            _dateChip("Aug 25", false),
                            _dateChip("Aug 26", false),
                            _dateChip("Aug 27", false),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- Time Selection ----------
                      const Text("Choose Time",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _timeChip("10:30 AM - 11:00 AM", false),
                            _timeChip("11:00 AM - 12:00 PM", true),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- Payment Details ----------
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _paymentRow("Consultation Fee", "₹350.00"),
                            _paymentRow("Platform Fee", "₹10.00"),
                            _paymentRow("Coupon Discount", "₹0.00"),
                            const Divider(),
                            _paymentRow("Grand Total", "₹360.00",
                                bold: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- Book Button ----------
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainlightpacha,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Book Appointment",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Helper Widgets ----------
  static Widget _dateChip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.mainlightpacha : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black, fontSize: 14)),
    );
  }

  static Widget _timeChip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.mainlightpacha : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black, fontSize: 14)),
    );
  }

  static Widget _paymentRow(String title, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ---------- Usage Example ----------
void showAppointmentBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AppointmentBottomSheet(),
  );
}

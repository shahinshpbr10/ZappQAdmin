import 'package:flutter/material.dart';

class LocationBottomSheet extends StatefulWidget {
  const LocationBottomSheet({super.key});

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  String selectedLocation = "Home (Mother)";

  final List<String> locations = ["Home (Mother)", "Home", "Workplace"];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.55,
      maxChildSize: 0.6, // allow expansion if needed
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ---------- Drag Handle ----------
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // ---------- Main scrollable content ----------
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select or set location",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // ---------- Location Chips ----------
                      Wrap(
                        spacing: 8,
                        children: [
                          ...locations.map(
                                (loc) => ChoiceChip(
                              label: Text(loc),
                              selected: selectedLocation == loc,
                              onSelected: (value) {
                                if (value) {
                                  setState(() {
                                    selectedLocation = loc;
                                  });
                                }
                              },
                              selectedColor: Colors.green.shade200,
                            ),
                          ),
                          ActionChip(
                            label: const Text("+ Add Location"),
                            onPressed: () {
                              // Add location logic
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ---------- Map Preview ----------
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/Image.png",
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------- Confirm Button ----------
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            debugPrint("Selected Location: $selectedLocation");
                          },
                          child: const Text(
                            "Select Location",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
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
}

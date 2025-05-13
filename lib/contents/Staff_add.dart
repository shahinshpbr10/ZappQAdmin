import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class StaffCreation extends ConsumerStatefulWidget {
  final String clinicId;
  final Map<String, dynamic>? doctorData; // Add optional doctor data

  const StaffCreation({required this.clinicId, this.doctorData, super.key});

  @override
  _AccountCreationState createState() => _AccountCreationState();
}

class _AccountCreationState extends ConsumerState<StaffCreation> {
  final _formKey = GlobalKey<FormState>();
  late Uint8List imageData;
  final ImagePicker _picker = ImagePicker();
  String? fileName;
  XFile? _selectedImage = XFile("");
  String? downloadUrl = "";
  TimeOfDay? _quickFromTime;
  TimeOfDay? _quickToTime;
  int? _quickTokenLimit;
  final Set<String> _quickSelectedDays = {};
  String _selectedRole = "doctor";

  @override
  void initState() {
    super.initState();
    _fetchSpecializations();
    _nameController.text = "Dr. ";

    print('Doctor Data: ${widget.doctorData}');

    // Pre-fill the form if doctor data is provided
    if (widget.doctorData != null) {
      print('Pre-filling form with doctor data...');

      _nameController.text = widget.doctorData!['name'] ?? '';
      _emailController.text = widget.doctorData!['email'] ?? '';
      _phoneController.text = widget.doctorData!['phone'] ?? '';
      _specializationController.text =
          widget.doctorData!['specialization'] ?? '';
      _experienceController.text = widget.doctorData!['experience'] ?? '';
      _licenseNumberController.text = widget.doctorData!['licenseNumber'] ?? '';
      _aboutController.text = widget.doctorData!['about'] ?? '';
      _consultationFeesController.text =
          widget.doctorData!['consultationFees']?.toString() ?? '';
      downloadUrl = widget.doctorData!['profilePhoto'] ?? "";
      _selectedImage = XFile(downloadUrl!);
      _selectedRole = widget.doctorData!['role'] ?? "doctor";

      // Print to confirm fields are being set
      print('Name: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('Phone: ${_phoneController.text}');

      // Pre-fill consultation times
      if (widget.doctorData!.containsKey('consultationTimes')) {
        final consultationTimes =
            widget.doctorData!['consultationTimes'] as Map<String, dynamic>;
        consultationTimes.forEach((day, sessions) {
          if (sessions != null) {
            final daySessions = List<Map<String, dynamic>>.from(
              sessions.values,
            );
            _daySessions[day] =
                daySessions.map((session) {
                  return {
                    'from': TimeOfDay(
                      hour: (session['from'] as int).floor(),
                      minute: ((session['from'] as int) * 60 % 60).round(),
                    ),
                    'to': TimeOfDay(
                      hour: (session['to'] as int).floor(),
                      minute: ((session['to'] as int) * 60 % 60).round(),
                    ),
                    'tokenLimit': session['tokenLimit'],
                  };
                }).toList();
          }
        });
      }

      // Pre-fill available days
      if (widget.doctorData!.containsKey('availableDays')) {
        // Handle array of days directly without splitting
        _selectedDays = Set<String>.from(
          widget.doctorData!['availableDays'] as List<dynamic>,
        );
      }
    } else {
      print('No doctor data provided.');
    }
  }

  List<String> _specializations = [];
  final List<String> _roles = ['doctor', 'nurse', 'admin', 'receptionist'];

  final Map<String, String> _roleImages = {
    'doctor': 'assets/lotties/doctor_explaining.json',
    'nurse': 'assets/lotties/assisment.json',
    'admin': 'assets/lotties/doctor_explaining.json',
  };

  Future<void> _fetchSpecializations() async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('specializations')
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('specializations')) {
          final specializationsArray = data['specializations'] as List;

          // Extracting 'name' field from each map in the array
          final names =
              specializationsArray
                  .map((item) => item['name'] as String)
                  .toList();

          setState(() {
            _specializations =
                names; // Assigning the names to the state variable
          });
        }
      }
    } catch (e) {
      print('Error fetching specializations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching specializations from Firestore'),
        ),
      );
    }
  }

  ///photo URL line compressing
  String _formatDesc(String text) {
    if (text.length <= 27) return text;
    if (text.length <= 54)
      return '${text.substring(0, 27)}\n${text.substring(27)}';
    return '${text.substring(0, 27)}\n${text.substring(27, 54)}...';
  }

  ///fill consultation quick
  Future<void> _showQuickAddDialog() async {
    _quickSelectedDays.clear();

    await showDialog(
      context: context,
      builder: (context) {
        TimeOfDay? tempFromTime;
        TimeOfDay? tempToTime;
        int? tempTokenLimit;
        final tempSelectedDays = <String>{};

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: Colors.blue.shade50,
              titleTextStyle: TextStyle(
                fontFamily: "Nunito",
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              title: Text('Quick Add Sessions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('From Time'),
                      trailing: Text(tempFromTime?.format(context) ?? 'Select'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          dialogSetState(() => tempFromTime = time);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('To Time'),
                      trailing: Text(tempToTime?.format(context) ?? 'Select'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          dialogSetState(() => tempToTime = time);
                        }
                      },
                    ),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Token Limit',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        tempTokenLimit = int.tryParse(value);
                      },
                    ),

                    ..._daysOfWeek.map(
                      (day) => CheckboxListTile(
                        title: Text(day),
                        value: tempSelectedDays.contains(day),
                        onChanged: (selected) {
                          dialogSetState(() {
                            if (selected!) {
                              tempSelectedDays.add(day);
                            } else {
                              tempSelectedDays.remove(day);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (tempFromTime != null &&
                        tempToTime != null &&
                        tempTokenLimit != null &&
                        tempSelectedDays.isNotEmpty) {
                      // Update the main widget's state
                      setState(() {
                        _quickFromTime = tempFromTime;
                        _quickToTime = tempToTime;
                        _quickTokenLimit = tempTokenLimit;

                        for (final day in tempSelectedDays) {
                          _daySessions[day] = [
                            {
                              'from': tempFromTime,
                              'to': tempToTime,
                              'tokenLimit': tempTokenLimit,
                            },
                          ];
                        }

                        _selectedDays.addAll(tempSelectedDays);
                      });

                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill all fields and select at least one day',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ///Function for pick image(for doctor profile)
  Future<void> pickProfile() async {
    try {
      // Pick an image from the gallery
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _selectedImage = pickedImage;
          fileName =
              "${DateFormat("dd-MM-yy").format(DateTime.now())}_${pickedImage.name}";
          downloadUrl = null;
        });
        showAnimatedProgressDialog(context, message: "Compressing Image...");
        // Read the image as bytes
        imageData = await pickedImage.readAsBytes();
        // Check if image needs compression (over 1MB)
        if (imageData.lengthInBytes > 1000000) {
          print(
            "Image size before compression: ${imageData.lengthInBytes} bytes",
          );
          Uint8List? compressedImage = await compressImage(imageData, context);
          if (compressedImage != null) {
            setState(() {
              imageData = compressedImage;
            });
            print("Image compressed to: ${imageData.lengthInBytes} bytes");
          }
        } else {
          Navigator.pop(context);
        }
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking or uploading image: $e");
    }
  }

  final Map<String, List<Map<String, dynamic>>> _daySessions = {
    'Monday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Tuesday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Wednesday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Thursday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Friday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Saturday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
    'Sunday': [
      {'from': null, 'to': null, 'tokenLimit': null},
    ],
  };

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Set<String> _selectedDays = {};

  final _emailController = TextEditingController();
  final _passwordController =
      TextEditingController(); // New password controller
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _consultationFeesController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _aboutController = TextEditingController();

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  ///----------------session part--------------///

  Widget _buildSessionRow(String day, int sessionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row for From and To buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _selectTime(context, day, sessionIndex, 'from'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: Text(
                _daySessions[day]![sessionIndex]['from'] == null
                    ? 'From'
                    : _daySessions[day]![sessionIndex]['from']!.format(context),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _selectTime(context, day, sessionIndex, 'to'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: Text(
                _daySessions[day]![sessionIndex]['to'] == null
                    ? 'To'
                    : _daySessions[day]![sessionIndex]['to']!.format(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row for token input and delete button
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Token Limit',
                  prefixIcon: Icon(Icons.token, color: Colors.blueAccent),
                ),
                initialValue: _daySessions[day]![sessionIndex]['tokenLimit']?.toString(),
                onChanged: (value) {
                  setState(() {
                    _daySessions[day]![sessionIndex]['tokenLimit'] =
                        int.tryParse(value) ?? 0;
                  });
                },
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _daySessions[day]!.removeAt(sessionIndex);
                });
              },
            ),
          ],
        ),
        const Divider(thickness: 1),
      ],
    );
  }


  List<Widget> _buildDaysCheckboxes() {
    return _daysOfWeek.map((day) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(day),
            value: _selectedDays.contains(day),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedDays.add(day);
                } else {
                  _selectedDays.remove(day);
                  _daySessions[day] =
                      []; // Clear sessions for that day if unchecked
                }
              });
            },
          ),
          if (_selectedDays.contains(day)) ...[
            ...List.generate(
              _daySessions[day]!.length,
              (sessionIndex) => Column(
                children: [
                  _buildSessionRow(
                    day,
                    sessionIndex,
                  ), // Show from/to picker for each session
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _buildAddSessionButton(day), // Add more sessions
          ],
          const Divider(),
        ],
      );
    }).toList();
  }

  Widget _buildAddSessionButton(String day) {
    return TextButton(
      onPressed: () {
        setState(() {
          _daySessions[day]!.add({
            'from': null,
            'to': null,
            'tokenLimit': null,
          });
        });
      },
      child: Text('Add Session'),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    int sessionIndex,
    String timeType,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _daySessions[day]![sessionIndex][timeType] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _daySessions[day]![sessionIndex][timeType] = picked;
      });
    }
  }

  List<Widget> _getRoleSpecificFields(String role) {
    switch (role) {
      case 'doctor':
        return [
          _buildTextField('Doctor Name', _nameController, Icons.person),

          ///Doctor profile system
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  pickProfile();
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.height * 0.2,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        _selectedImage == null || _selectedImage!.path.isEmpty
                            ? Icon(
                              Icons.upload_file_rounded,
                              color: Colors.blueAccent,
                              size: 32,
                            )
                            : Image.network(_selectedImage!.path),
                  ),
                ),
              ),
              Text(
                _selectedImage == null || _selectedImage!.path == ""
                    ? "  Upload Doctor profile"
                    : _selectedImage!.name.isNotEmpty
                    //     ? " Selected Image: \n ${_selectedImage!.name.length >= 28 ?
                    // _selectedImage!.name.replaceFirstMapped(RegExp(r'^(.{28})'),
                    //         (match) => '${match.group(1)}\n') : _selectedImage!.name}"
                    ? _formatDesc(_selectedImage!.name)
                    : "",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          _buildTextField('Doctor Email', _emailController, Icons.email),
          _buildTextField(
            'Phone Number',
            _phoneController,
            Icons.phone_iphone_outlined,
          ),
          _buildSpecializationDropdown(),
          _buildTextField('Experience', _experienceController, Icons.timeline),
          _buildTextField(
            'License Number',
            _licenseNumberController,
            Icons.card_membership,
          ),
          _buildTextField(
            'Consultation Fees',
            _consultationFeesController,
            Icons.money,
          ),
          _buildTextField('Description', _aboutController, Icons.description),
          const SizedBox(height: 10),
          _buildSectionTitle('Consultation Times'),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _showQuickAddDialog();
              },
              icon: Icon(Icons.add, color: Colors.blue),
              label: Text(
                'Add All Day Quick',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          ..._buildDaysCheckboxes(),
        ];
      case 'nurse':
        return [
          _buildTextField('Nurse Name', _nameController, Icons.person),
          _buildTextField('Email', _emailController, Icons.email),
          _buildTextField('Phone', _phoneController, Icons.phone),
        ];
      case 'receptionist':
        return [
          _buildTextField('Nurse Name', _nameController, Icons.person),
          _buildTextField('Email', _emailController, Icons.email),
          _buildTextField('Phone', _phoneController, Icons.phone),
        ];
      case 'admin':
        return [
          _buildTextField('Admin Name', _nameController, Icons.person),
          _buildTextField('Email', _emailController, Icons.email),
        ];
      default:
        return [];
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSpecializationDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        isDense: true,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.local_hospital,
            color: Colors.blueAccent,
            size: 20,
          ),
          labelText: 'Specialization',
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        value:
            _specializationController.text.isNotEmpty
                ? _specializationController.text
                : null,
        items:
            _specializations.map((String specialization) {
              return DropdownMenuItem<String>(
                value: specialization,
                child: Text(
                  specialization,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            _specializationController.text = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a specialization';
          }
          return null;
        },
      ),
    );
  }

  void _clearFormFields() {
    _emailController.clear();
    _passwordController.clear(); // Clear password field
    _phoneController.clear();
    _nameController.clear();
    _doctorEmailController.clear();
    _consultationFeesController.clear();
    _specializationController.clear();
    _experienceController.clear();
    _licenseNumberController.clear();
    _aboutController.clear();
    _daySessions.forEach((key, value) {
      value.clear();
    });
    _selectedDays.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    try {
      showAnimatedProgressDialog(context, message: "Submitting form...");
      final clinicDocRef = FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId);
      final clinicSnapshot = await clinicDocRef.get();

      if (!clinicSnapshot.exists) {
        Navigator.pop(context);
        throw Exception('Clinic not found');
      }

      final clinicData = clinicSnapshot.data() as Map<String, dynamic>;

      QuerySnapshot existingStaffSnapshot =
          await clinicDocRef
              .collection("${_selectedRole}s")
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

      String staffId;

      if (existingStaffSnapshot.docs.isNotEmpty) {
        staffId = existingStaffSnapshot.docs.first.id;
        print('Updating existing staff with ID: $staffId');
      } else {
        staffId = clinicDocRef.collection('staff').doc().id;
        print('Creating new staff with ID: $staffId');
      }

      Map<String, Map<String, dynamic>?> consultationTimes =
          _prepareConsultationTimes();

      final Map<String, dynamic> staffDetails = {
        'staffId': staffId,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'name': _nameController.text.trim(),
        'clinicName': clinicData['name'],
        'clinicId': widget.clinicId,
        'role': _selectedRole,
      };

      if (_selectedRole == 'doctor') {
        if (_selectedImage != null && _selectedImage!.path != "") {
          try {
            // Firebase Storage reference
            final storageRef = FirebaseStorage.instance.ref().child(
              'doctor_profile/$fileName',
            );
            UploadTask uploadTask = storageRef.putData(imageData);

            TaskSnapshot taskSnapshot = await uploadTask;

            // Get the download URL of the uploaded image
            downloadUrl = await taskSnapshot.ref.getDownloadURL();
            print("Image uploaded successfully. Download URL: $downloadUrl");
          } catch (e) {
            print("Error uploading image $e");
            downloadUrl = null;
          }
        }

        staffDetails.addAll({
          'specialization': _specializationController.text.trim(),
          'experience': _experienceController.text.trim(),
          'phone': _phoneController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'availableDays': _convertAvailableDaysToArray(),
          'about': _aboutController.text.trim(),
          'consultationFees': _consultationFeesController.text.trim(),
          'consultations': 0,
          'consultationTimes': consultationTimes,
          'profilePhoto':
              downloadUrl ?? widget.doctorData?['profilePhoto'] ?? "",
        });
      }

      if (_selectedRole == 'nurse') {
        staffDetails.addAll({'availableDays': _convertAvailableDaysToArray()});
      }

      // Receptionist role specific fields
      if (_selectedRole == 'receptionist') {
        staffDetails.addAll({});
      }

      if (_selectedRole == 'admin') {
        staffDetails.addAll({
          // Add fields specific to admin if needed
        });
      }

      // Update or create a new document based on whether staff exists
      await clinicDocRef
          .collection("${_selectedRole}s")
          .doc(staffId)
          .set(staffDetails);

      // Update the clinic document with the appropriate staff reference array
      await clinicDocRef.update({
        _selectedRole == 'admin'
            ? 'admins'
            : _selectedRole == 'doctor'
            ? 'doctors'
            : _selectedRole == 'receptionist'
            ? 'receptionists' // Separate array for receptionists
            : 'staffs': FieldValue.arrayUnion([_emailController.text.trim()]),
      });
      Navigator.pop(context);
      _showSuccessDialog();
      _clearFormFields();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(
            'The ${_selectedRole[0].toUpperCase() + _selectedRole.substring(1)} was created successfully!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    int hours = time.hour;
    int minutes = time.minute;

    // Convert minutes to a 2-digit format representing a percentage of an hour
    String minuteString = ((minutes * 100) / 60).round().toString().padLeft(
      2,
      '0',
    );

    // Combine hours and formatted minutes as a string, then parse it back to double
    return double.parse('$hours.$minuteString');
  }

  Map<String, Map<String, dynamic>?> _prepareConsultationTimes() {
    Map<String, Map<String, dynamic>?> consultationTimes = {};
    _daySessions.forEach((day, sessions) {
      bool hasValidSessions = false;
      Map<String, dynamic> dayData = {};

      for (int i = 0; i < sessions.length; i++) {
        if (sessions[i]['from'] != null && sessions[i]['to'] != null) {
          hasValidSessions = true;
          dayData['session_$i'] = {
            'from': _timeOfDayToDouble(sessions[i]['from']),
            'to': _timeOfDayToDouble(sessions[i]['to']),
            'tokenLimit': sessions[i]['tokenLimit'],
          };
        }
      }

      // Only include the day if there are valid sessions, otherwise set it to null
      consultationTimes[day] = hasValidSessions ? dayData : null;
    });

    return consultationTimes;
  }

  List<String> _convertAvailableDaysToArray() {
    // Convert the Set to a sorted List based on the _daysOfWeek order
    return _daysOfWeek.where((day) => _selectedDays.contains(day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    items:
                        _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role[0].toUpperCase() + role.substring(1),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _getRoleSpecificFields(_selectedRole),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> compressImage(
  Uint8List imageBytes,
  BuildContext context,
) async {
  try {
    // Check if compression is needed
    if (imageBytes.lengthInBytes <= 1000000) {
      Navigator.pop(context); // Close dialog
      return imageBytes; // Return original if already under 1MB
    }

    print('Original Image Size: ${imageBytes.lengthInBytes} bytes');

    // Decode image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      print('Failed to decode image.');
      Navigator.pop(context);
      return null;
    }

    // Target size: 1MB (1,000,000 bytes)
    int targetSize = 1000000;

    // Start with 80% quality
    int quality = 80;

    // First try just compressing without resizing
    Uint8List compressedImageBytes = Uint8List.fromList(
      img.encodeJpg(image, quality: quality),
    );

    // If still too large, resize and compress
    if (compressedImageBytes.lengthInBytes > targetSize) {
      // Calculate scale factor based on original size
      double scaleFactor = 0.8; // Start with 80% of original dimensions

      while (compressedImageBytes.lengthInBytes > targetSize &&
          scaleFactor > 0.3) {
        // Resize the image
        int newWidth = (image.width * scaleFactor).round();
        int newHeight = (image.height * scaleFactor).round();

        img.Image resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
        );
        compressedImageBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: quality),
        );

        // If still too large, reduce scale factor
        if (compressedImageBytes.lengthInBytes > targetSize) {
          scaleFactor -= 0.1;
        }
      }
    }

    print('Compressed Image Size: ${compressedImageBytes.lengthInBytes} bytes');

    // Close dialog and show success message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Image compressed from ${(imageBytes.lengthInBytes / 1000000).toStringAsFixed(2)}MB to ${(compressedImageBytes.lengthInBytes / 1000000).toStringAsFixed(2)}MB',
        ),
      ),
    );

    return compressedImageBytes;
  } catch (e) {
    print("Error compressing image: $e");
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
    return null;
  }
}

void showAnimatedProgressDialog(
  BuildContext context, {
  String message = 'Loading...',
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                        strokeWidth: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}

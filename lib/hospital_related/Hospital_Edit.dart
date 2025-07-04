import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:image/image.dart' as img;

class EditProfilePage extends StatefulWidget {
  final String clinicid;
  const EditProfilePage({super.key, required this.clinicid});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _additionalLocationController = TextEditingController(); // if needed


  Uint8List? _profileImageBytes;
  bool _isImageUploaded = false;
  bool _isLoading = false;
  bool _isCompressing = false; // For compressing animation
  bool _isImageTooLarge = false;
  String? _selectedLocation;
  String? _profileImageUrl;
  Uint8List? _medicalLicenseBytes;
  Uint8List? _otherDocumentBytes;

  final List<String> _locations = [
    "Perinthalmanna",
    "Manjeri",
    "Malappuram",
    "Kozhikode",
    "Mannarkkad",
    "Melattur"
  ];
  int _selectedDayIndex = 0;

  final List<DaySchedule> _weeklySchedule = [
    DaySchedule(day: 'Mon'),
    DaySchedule(day: 'Tue'),
    DaySchedule(day: 'Wed'),
    DaySchedule(day: 'Thu'),
    DaySchedule(day: 'Fri'),
    DaySchedule(day: 'Sat'),
    DaySchedule(day: 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchClinicData();
  }

  Future<void> _fetchClinicData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot clinicDoc = await FirebaseFirestore.instance.collection('clinics').doc(widget.clinicid).get();

      if (!clinicDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinic data not found.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> currentData = clinicDoc.data() as Map<String, dynamic>;

      setState(() {
        _nameController.text = currentData['name'] ?? '';
        _addressController.text = currentData['address'] ?? '';
        _contactEmailController.text = currentData['email'] ?? '';
        _phoneController.text = currentData['phone'] ?? '';
        _selectedLocation = currentData['location'] ?? '';
        _profileImageUrl = currentData['profilePhoto'];
        _descriptionController.text = currentData['description'] ?? '';
        _additionalLocationController.text = currentData['locationExtra'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch clinic data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();

      // Check if image is larger than 1MB
      if (imageBytes.lengthInBytes > 1000000) {
        print("Image too large: ${imageBytes.lengthInBytes} bytes.");
        setState(() {
          _isImageTooLarge = true;
          _isImageUploaded = false;
        });
        return;
      }

      // Show the Lottie loading animation while compressing the image
      setState(() {
        _isCompressing = true;
      });

      // Compress the image to 20KB
      Uint8List? compressedImage = await compressImage(imageBytes);
      if (compressedImage != null) {
        setState(() {
          _profileImageBytes = compressedImage;
          _isImageUploaded = true;
          _isImageTooLarge = false;
          print("Image successfully compressed to ${compressedImage.lengthInBytes} bytes.");
        });
      } else {
        setState(() {
          _isImageTooLarge = true;
          print("Image compression failed.");
        });
      }

      // Stop loading after compression is complete
      setState(() {
        _isCompressing = false;
      });
    }
  }

  Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    try {
      print('Original Image Size: ${imageBytes.lengthInBytes} bytes');

      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image.');
        return null;
      }

      // Resize the image to 400x400 for better quality
      img.Image resizedImage = img.copyResize(image, width: 400);

      int quality = 70;
      Uint8List compressedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

      // Compress until the image size is between 19KB and 20KB
      while (compressedImageBytes.lengthInBytes > 20000 && quality > 0) {
        quality -= 5;
        compressedImageBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        print("Compressed image size (quality $quality): ${compressedImageBytes.lengthInBytes} bytes");
      }

      if (compressedImageBytes.lengthInBytes > 20000) {
        print("Unable to compress image below 20KB.");
        return null;
      }

      return compressedImageBytes;
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot clinicDoc = await FirebaseFirestore.instance.collection('clinics').doc(widget.clinicid).get();
print(clinicDoc);

print("ggggggggggggggggggggggggggggggggggggggg");
      if (!clinicDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinic data not found.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> currentData = clinicDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> updatedData = {};

      String? profilePhotoUrl = await _uploadProfileImage();
      if (profilePhotoUrl != null && profilePhotoUrl != currentData['profilePhoto']) {
        updatedData['profilePhoto'] = profilePhotoUrl;
      }

      if (_nameController.text.trim().isNotEmpty && _nameController.text != currentData['name']) {
        updatedData['name'] = _nameController.text.trim();
      }

      if (_addressController.text.trim().isNotEmpty && _addressController.text != currentData['address']) {
        updatedData['address'] = _addressController.text.trim();
      }

      if (_contactEmailController.text.trim().isNotEmpty && _contactEmailController.text != currentData['email']) {
        updatedData['email'] = _contactEmailController.text.trim();
      }

      if (_phoneController.text.trim().isNotEmpty && _phoneController.text != currentData['phone']) {
        updatedData['phone'] = _phoneController.text.trim();
      }

      if (_selectedLocation != null && _selectedLocation != currentData['location']) {
        updatedData['location'] = _selectedLocation;
      }

      if (_descriptionController.text.trim().isNotEmpty && _descriptionController.text != currentData['description']) {
        updatedData['description'] = _descriptionController.text.trim();
      }

      if (_additionalLocationController.text.trim().isNotEmpty && _additionalLocationController.text != currentData['locationExtra']) {
        updatedData['locationExtra'] = _additionalLocationController.text.trim();
      }


      if (updatedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes made to update.')),
        );
      } else {
        await FirebaseFirestore.instance.collection('clinics').doc(widget.clinicid).update(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImageBytes == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('clinic_logos/${widget.clinicid}_logo.png');
      final uploadTask = await storageRef.putData(_profileImageBytes!);
      String downloadURL = await uploadTask.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _additionalLocationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Edit Clinic Profile", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Clinic Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildProfileImage(),
              const SizedBox(height: 16),
              _buildPersonalInfo(),
              const SizedBox(height: 16),
              _buildContactInfo(),
              const SizedBox(height: 16),
              _buildScheduleInfo(),  // Re-added Edit Schedule
              const SizedBox(height: 16),
              _buildDocumentUpload(),  // Re-added Document Upload
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build a text field with validation
  Widget _buildTextField(TextEditingController controller, String label, String errorText, int maxLines) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      ),
      validator: (value) => value == null || value.isEmpty ? errorText : null,
    );
  }

  // Method to build a dropdown field
  Widget _buildDropdownField(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((String location) => DropdownMenuItem<String>(value: location, child: Text(location))).toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      ),
      onChanged: onChanged,
    );
  }


  Widget _buildProfileImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _profileImageBytes != null
                  ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                  : (_profileImageUrl != null
                  ? Image.network(_profileImageUrl!, fit: BoxFit.cover)
                  : Image.asset('assets/profile.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 20),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 2, color: Colors.blueGrey),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image),
                    const SizedBox(width: 8),
                    Text(_isImageUploaded ? 'Logo Uploaded' : 'Upload Clinic Logo'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isImageTooLarge)
          const Text(
            'Please upload an image smaller than 1MB!',
            style: TextStyle(color: Colors.red),
          ),
        if (_isCompressing)
          Center(
            child: Column(
              children: [
                Lottie.asset('assets/loading2.json', width: 100, height: 100),
                const SizedBox(height: 10),
                const Text('Uploading logo...', style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Clinic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildTextField(_nameController, 'Clinic Name', 'Please enter clinic name', 1),
        const SizedBox(height: 20),
        _buildDropdownField('Clinic Location', _selectedLocation, _locations, (value) => setState(() => _selectedLocation = value)),
        const SizedBox(height: 20),
        _buildTextField(_addressController, 'Clinic Address', 'Please enter address', 3),
        const SizedBox(height: 20),
        _buildTextField(_descriptionController, 'Clinic Description', 'Please enter description', 3),
        const SizedBox(height: 20),
        _buildTextField(_additionalLocationController, 'Additional Location', 'Please enter location', 1),

      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildTextField(_contactEmailController, 'Clinic E-mail', 'Please enter clinic e-mail', 1),
        const SizedBox(height: 20),
        _buildTextField(_phoneController, 'Clinic Number', 'Please enter clinic number', 1),
      ],
    );
  }

  Widget _buildScheduleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Edit Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_weeklySchedule.length, (index) {
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: CircleAvatar(
                backgroundColor: _selectedDayIndex == index ? Colors.blue : Colors.grey,
                child: Text(_weeklySchedule[index].day.substring(0, 3), style: const TextStyle(color: Colors.white)),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _weeklySchedule[_selectedDayIndex].open24Hours,
              onChanged: (value) => setState(() {
                _weeklySchedule[_selectedDayIndex].open24Hours = value ?? false;
                if (value == true) {
                  _weeklySchedule[_selectedDayIndex].startTime = null;
                  _weeklySchedule[_selectedDayIndex].endTime = null;
                }
              }),
            ),
            const Text('Open for 24 hours'),
          ],
        ),
        if (!_weeklySchedule[_selectedDayIndex].open24Hours) ...[
          _buildTimeField("Opening Time", _weeklySchedule[_selectedDayIndex].startTime),
          _buildTimeField("Closing Time", _weeklySchedule[_selectedDayIndex].endTime),
        ],
      ],
    );
  }

  Widget _buildTimeField(String label, double? selectedTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          TextButton(
            onPressed: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime != null
                    ? TimeOfDay(hour: selectedTime.floor(), minute: ((selectedTime - selectedTime.floor()) * 60).round())
                    : TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() {
                  if (label == "Opening Time") {
                    _weeklySchedule[_selectedDayIndex].startTime = picked.hour + picked.minute / 60.0;
                  } else {
                    _weeklySchedule[_selectedDayIndex].endTime = picked.hour + picked.minute / 60.0;
                  }
                });
              }
            },
            child: Text(
              selectedTime != null
                  ? "${selectedTime.floor()}:${((selectedTime - selectedTime.floor()) * 60).round().toString().padLeft(2, '0')}"
                  : 'Select Time',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(_medicalLicenseBytes == null ? 'Upload Medical License' : 'Medical License Uploaded'),
              onPressed: () => _pickDocument(isMedicalLicense: true),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(_otherDocumentBytes == null ? 'Upload Other Document' : 'Other Document Uploaded'),
              onPressed: () => _pickDocument(isMedicalLicense: false),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDocument({required bool isMedicalLicense}) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final documentBytes = await pickedFile.readAsBytes();
      setState(() {
        if (isMedicalLicense) {
          _medicalLicenseBytes = documentBytes;
        } else {
          _otherDocumentBytes = documentBytes;
        }
      });
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isLoading ? const CircularProgressIndicator() : const Text('Save Profile'),
          onPressed: _isLoading ? null : _saveProfile,
        ),
      ],
    );
  }
}

class DaySchedule {
  String day;
  double? startTime;
  double? endTime;
  bool open24Hours;

  DaySchedule({required this.day, this.startTime, this.endTime, this.open24Hours = false});
}

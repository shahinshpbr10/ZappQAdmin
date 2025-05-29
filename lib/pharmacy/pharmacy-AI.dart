import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';

class PharmacyAI extends StatefulWidget {
  const PharmacyAI({super.key});

  @override
  State<PharmacyAI> createState() => _PharmacyAIState();
}

class _PharmacyAIState extends State<PharmacyAI> {

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _UploadOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () => _pickFromCamera(context),
                  ),
                  _UploadOption(
                    icon: Icons.photo,
                    label: "Photo",
                    onTap: () => _pickFromGallery(context),
                  ),
                  _UploadOption(
                    icon: Icons.folder,
                    label: "Files",
                    onTap: () => _pickFromFiles(context),
                  ),
                  _UploadOption(
                    icon: Icons.link,
                    label: "Drive",
                    onTap: () => _pickFromDrive(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Use the following option to upload the required data input',
                style: TextStyle(color: Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _pickFromCamera(BuildContext context) async {
    await Permission.camera.request();
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Handle photo
      debugPrint("Camera Image: ${photo.path}");
    }
  }

  static Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint("Gallery Image: ${image.path}");
    }
  }

  static Future<void> _pickFromFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      debugPrint("File Picked: ${result.files.single.path}");
    }
  }

  static Future<void> _pickFromDrive(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      allowCompression: false,
      type: FileType.any,
    );
    if (result != null) {
      debugPrint("Drive File: ${result.files.single.path}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Zapp-AI',
          style: TextStyle(
            color: Color(0xFF00E100), // bright green
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () {
              // TODO: handle chat button tap
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Hi there!\nHow Can I assist you  today?',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showUploadOptions(context);
                          },
                          child: Icon(Icons.add, color: Colors.black45),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Ask ZappQ AI',
                              hintStyle: TextStyle(color: Colors.black38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: width * 0.14,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Image(
                      image: AssetImage("assets/images/bi_send-plus.png"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

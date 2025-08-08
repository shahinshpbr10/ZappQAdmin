import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../common/colors.dart';

class SpecializationsPage extends StatefulWidget {
  @override
  _SpecializationsPageState createState() => _SpecializationsPageState();
}

class _SpecializationsPageState extends State<SpecializationsPage> {
  List<Map<String, dynamic>> _specializations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSpecializations();
  }

  Future<void> fetchSpecializations() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('specializations')
            .get();

    final data = doc.data();
    if (data != null && data['specializations'] != null) {
      setState(() {
        _specializations = List<Map<String, dynamic>>.from(
          data['specializations'],
        );
        _isLoading = false;
      });
    }
  }

  void _editSpecialization(int index) {
    final item = _specializations[index];
    _showEditDialog(index, item['name'], item['iconUrl']);
  }

  void _addSpecialization() {
    _showEditDialog(null, '', '');
  }

  Future<void> _showEditDialog(int? index, String name, String iconUrl) async {
    TextEditingController nameController = TextEditingController(text: name);
    String? uploadedImageUrl = iconUrl;
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                index == null ? 'Add Specialization' : 'Edit Specialization',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          pickedImage = File(pickedFile.path);
                          setStateDialog(() {});
                        }
                      },
                      child:
                          pickedImage != null
                              ? Image.file(
                                pickedImage!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              )
                              : (uploadedImageUrl?.isNotEmpty ?? false)
                              ? CachedNetworkImage(
                                imageUrl: uploadedImageUrl ?? '',
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[300],
                                child: Icon(Icons.add_a_photo),
                              ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    _deleteSpecialization(index!);
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Upload image if picked
                    if (pickedImage != null) {
                      final fileName =
                          "${DateTime.now().millisecondsSinceEpoch}.png";
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('specialization_icons')
                          .child(fileName);

                      await ref.putFile(pickedImage!);
                      uploadedImageUrl = await ref.getDownloadURL();
                    }

                    final newItem = {
                      'name': nameController.text,
                      'iconUrl': uploadedImageUrl ?? '',
                    };

                    if (index != null) {
                      _specializations[index] = newItem;
                    } else {
                      _specializations.add(newItem);
                    }

                    await FirebaseFirestore.instance
                        .collection('settings')
                        .doc('specializations')
                        .update({'specializations': _specializations});

                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSpecialization(int index) async {
    final item = _specializations[index];
    final String imageUrl = item['iconUrl'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete Specialization"),
            content: Text("Are you sure you want to delete '${item['name']}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed:() {
                  Navigator.pop(context, true);
                  Navigator.pop(context, true);
                },
                child: Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // 1. Delete from Firebase Storage if image exists
    if (imageUrl.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        debugPrint("Error deleting image from storage: $e");
      }
    }

    // 2. Remove from local list
    _specializations.removeAt(index);

    // 3. Update Firestore
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('specializations')
        .update({'specializations': _specializations});

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightpacha,
        title: Text(
          ' Specializations',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.white),
            onPressed: _addSpecialization,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _specializations.isEmpty
              ? Center(child: Text('No specializations found.'))
              : ListView.builder(
                itemCount: _specializations.length,
                itemBuilder: (context, index) {
                  final item = _specializations[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item['iconUrl'],
                          width: 48,
                          height: 48,
                          placeholder:
                              (context, url) => CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                      title: Text(item['name']),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editSpecialization(index),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

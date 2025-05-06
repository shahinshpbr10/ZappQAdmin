import 'package:flutter/material.dart';

class DoctorEdit extends StatefulWidget {
  const DoctorEdit({super.key});

  @override
  State<DoctorEdit> createState() => _DoctorEditState();
}

class _DoctorEditState extends State<DoctorEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Doctor"),),
    );
  }
}

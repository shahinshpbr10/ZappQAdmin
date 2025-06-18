import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phoneNumber;
  final String address;
  final String bookingType;
  final String bookingFor;
  final bool isPackage;
  final String selectedPaymentMethod;
  final DateTime createdAt;
  final DateTime selectedDate;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    required this.address,
    required this.bookingType,
    required this.bookingFor,
    required this.isPackage,
    required this.selectedPaymentMethod,
    required this.createdAt,
    required this.selectedDate,
  });

  factory Patient.fromMap(String id, Map<String, dynamic> data) {
    return Patient(
      id: id,
      name: data['patientName'],
      age: data['age'],
      gender: data['gender'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      bookingType: data['bookingType'],
      bookingFor: data['bookingFor'],
      isPackage: data['isPackage'],
      selectedPaymentMethod: data['selectedPaymentMethod'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      selectedDate: (data['selectedDate'] as Timestamp).toDate(),
    );
  }
}

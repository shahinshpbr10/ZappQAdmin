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
  final String testName;
  final String testTime;
  final num serviceCharge;
  final String status; // ✅ NEW FIELD

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
    required this.testName,
    required this.testTime,
    required this.serviceCharge,
    required this.status, // ✅ Add to constructor
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
      testName: data['serviceName'] ?? '',
      testTime: data['selectedTimeSlot'] ?? '',
      serviceCharge: (data['servicePrice'] ?? 0),
      status: data['status'] ?? 'Pending', // ✅ default fallback
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    String? bookingType,
    String? bookingFor,
    bool? isPackage,
    String? selectedPaymentMethod,
    DateTime? createdAt,
    DateTime? selectedDate,
    String? testName,
    String? testTime,
    num? serviceCharge,
    String? status, // ✅ new field
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bookingType: bookingType ?? this.bookingType,
      bookingFor: bookingFor ?? this.bookingFor,
      isPackage: isPackage ?? this.isPackage,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      createdAt: createdAt ?? this.createdAt,
      selectedDate: selectedDate ?? this.selectedDate,
      testName: testName ?? this.testName,
      testTime: testTime ?? this.testTime,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      status: status ?? this.status, // ✅ include in copy
    );
  }
}

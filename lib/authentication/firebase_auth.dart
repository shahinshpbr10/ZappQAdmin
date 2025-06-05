import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> adminLogin({
  required String name,
  required String id,
  required String fcmToken,
}) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot adminSnapshot = await firestore.collection('admin').get();

    if (adminSnapshot.docs.isEmpty) {
      return 'No admin users found';
    }

    for (QueryDocumentSnapshot doc in adminSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data['name'] == name) {
        if (data['id'] == id) {
          try {
            await doc.reference.update({
              'fcmToken': fcmToken,
              'lastLogin': FieldValue.serverTimestamp(),
            });
            prefs.setString('admin', data['name']);
            return 'Login Success';
          } catch (e) {
            return 'Login credentials valid but failed to store FCM token: ${e.toString()}';
          }
        } else {
          return 'Invalid credentials - ID mismatch';
        }
      }
    }
    return 'User not exist';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

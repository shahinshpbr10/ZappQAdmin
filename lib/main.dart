import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'landing_page.dart';

var height;
var width;

/// Background handler (optional but recommended)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'admin_channel',
        title: message.notification!.title,
        body: message.notification!.body,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Subscribe this device to "admin" topic
  FirebaseMessaging.instance.subscribeToTopic('admin');

  await AwesomeNotifications().requestPermissionToSendNotifications();

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('✅ User granted FCM notification permission');
  } else {
    debugPrint('❌ User declined or has not accepted permission');
  }

  // 📌 Subscribe this device to admin topic
  FirebaseMessaging.instance.subscribeToTopic('admin');


  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'admin_channel',
        channelName: 'Admin Notifications',
        channelDescription: 'Notifications for new bookings',
        defaultColor: Colors.green,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );

  // Handle FCM background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  // Foreground FCM listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'admin_channel',
          title: notification.title,
          body: notification.body,
        ),
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // height and width here won’t work — must move to HomePage
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayoutBuilder(
        builder: (context, constraints) {
          height = constraints.maxHeight;
          width = constraints.maxWidth;
          return const HomePage();
        },
      ),
    );
  }
}

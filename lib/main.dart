import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappq_admin_app/SplashScreen/splash.dart';
import 'package:zappq_admin_app/authentication/auth.page.dart';
import 'package:zappq_admin_app/hospital_related/Bookings.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'onboard.dart';

var height;
var width;

// Global navigator key for navigation from static methods
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // Create awesome notification for background messages
  if (message.notification != null) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'admin_channel',
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? 'You have a new message',
        payload: {
          'type': message.data['type'] ?? '',
          'clinicId': message.data['clinicId'] ?? '',
          'bookingId': message.data['bookingId'] ?? '',
          'bookingFor': message.data['bookingFor'] ?? '',
          'patientName': message.data['patientName'] ?? '',
          'selectedDate': message.data['selectedDate'] ?? '',
          'selectedTimeSlot': message.data['selectedTimeSlot'] ?? '',
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( options: DefaultFirebaseOptions.currentPlatform,);


  // Set the background messaging handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Awesome Notifications with proper icon
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'admin_channel',
        channelName: 'Admin Notifications',
        channelDescription: 'Notifications for new bookings and admin alerts',
        defaultColor: Color(0xFF3669C9),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        onlyAlertOnce: false,
        playSound: true,
        criticalAlerts: true,
      ),
    ],
    debug: false,
  );

  // Request notification permissions
  await _requestNotificationPermissions();
  runApp(ProviderScope(child: const MyApp()));
}

/// Request notification permissions
Future<void> _requestNotificationPermissions() async {
  // Request Awesome Notifications permission
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Request FCM permission
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('User granted FCM notification permission');
  } else {
    debugPrint('User declined or has not accepted permission');
  }

  print('User granted permission: ${settings.authorizationStatus}');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupForegroundNotifications();
    _setupNotificationActions();
  }

  /// Setup foreground FCM notifications
  void _setupForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        // Create awesome notification for foreground messages
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'admin_channel',
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? 'You have a new message',
            payload: {
              'type': message.data['type'] ?? '',
              'clinicId': message.data['clinicId'] ?? '',
              'bookingId': message.data['bookingId'] ?? '',
              'clinicName': message.data['clinicName'] ?? '',
              'bookingFor': message.data['bookingFor'] ?? '',
              'patientName': message.data['patientName'] ?? '',
              'selectedDate': message.data['selectedDate'] ?? '',
              'selectedTimeSlot': message.data['selectedTimeSlot'] ?? '',
            },
          ),
        );
      }
    });

    // Handle notification opened app from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });
  }

  /// Setup notification action listeners
  void _setupNotificationActions() {
    // Listen to notification taps
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Called when notification is created
  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification,
      ) async {
    print('Notification created: ${receivedNotification.title}');
  }

  /// Called when notification is displayed
  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification,
      ) async {
    print('Notification displayed: ${receivedNotification.title}');
  }

  /// Called when notification is dismissed
  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
      ReceivedAction receivedAction,
      ) async {
    print('Notification dismissed: ${receivedAction.title}');
  }

  /// Called when user taps on notification
  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction,
      ) async {
    print('Notification action received: ${receivedAction.actionType}');

    // Handle notification tap based on payload
    if (receivedAction.payload != null) {
      final payload = receivedAction.payload!;

      // Handle different notification types
      if (payload['type'] == 'new_booking') {
        // Navigate to clinic booking details
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => BookingsPage(clinicid: payload['clinicId'] ?? ''),
          ),
        );
      } else if (payload['type'] == 'smart_clinic_booking') {
        // Handle smart clinic booking navigation
        print('Smart clinic booking tapped:');
        print('- Patient: ${payload['patientName']}');
        print('- Booking For: ${payload['bookingFor']}');
        print('- Date: ${payload['selectedDate']}');
        print('- Time: ${payload['selectedTimeSlot']}');
      }
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data['type'] == 'new_booking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingsPage(clinicid: data['clinicId']),
        ),
      );
    } else if (data['type'] == 'smart_clinic_booking') {
      // Handle smart clinic booking tap
      print('Smart clinic booking tapped from terminated state:');
      print('- Patient: ${data['patientName']}');
      print('- Booking For: ${data['bookingFor']}');

    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/home': (context) => OnBoardingPage(),
      },
    );
  }
}

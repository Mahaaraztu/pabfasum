import 'dart:convert';
import 'package:pabfasum/firebase_options.dart';
import 'package:pabfasum/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Izin notifikasi sementara diberikan');
  } else {
    print('Izin notifikasi ditolak');
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(0, title, body, platform);
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data['title'] ?? 'Pesan Baru';
  final body = data['body'] ?? '';
  final sender = data['senderName'] ?? 'Pengirim tidak diketahui';
  final time = data['sentAt'] ?? '';
  final photoUrl = data['senderPhotoUrl'] ?? '';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  final styleInfo = largeIconBitmap != null
      ? BigPictureStyleInformation(
    largeIconBitmap,
    contentTitle: title,
    summaryText: '$body\nDari: $sender - $time',
    largeIcon: largeIconBitmap,
    hideExpandedLargeIcon: true,
  )
      : BigTextStyleInformation(
    '$body\nDari: $sender\nWaktu: $time',
    contentTitle: title,
  );

  final androidDetails = AndroidNotificationDetails(
    'detailed_channel',
    'Notifikasi Detail',
    channelDescription: 'Notifikasi dengan detail tambahan',
    styleInformation: styleInfo, // Corrected from simpleStyleInfo to styleInfo
    largeIcon: largeIconBitmap, // Corrected from Importance.max to largeIconBitmap
    priority: Priority.max,
  );

  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(1, title, body, platform);
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {
    return null;
  }
  return null;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification!.title,
      message.notification!.body,
    );
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await requestNotificationPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings settings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  ); // InitializationSettings
  await flutterLocalNotificationsPlugin.initialize(settings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String status = "Memulai...";
  String topic = "berita-fasum";

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(topic);
    setState(() => status = "Subscribed to topic: $topic");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        showNotificationFromData(message.data);
      } else {showBasicNotification(
        message.notification!.title,
        message.notification!.body,
      );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fasum',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ), // ThemeData
      home: SplashScreen(),
    ); // MaterialApp
  }
}
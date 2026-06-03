import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:kpUser/DriverApp/Account/UI/account_page.dart';
import 'package:kpUser/DriverApp/Auth/login_navigator.dart';
import 'package:kpUser/DriverApp/Locale/locales.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'baseurl/baseurl.dart';

const String notificationChannelId = '1233';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings androidInitSettings =
AndroidInitializationSettings('@mipmap/ic_launcher');

const InitializationSettings notificationInitSettings =
InitializationSettings(android: androidInitSettings);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBKqYfO8j93m080n2I7kianw8WIV0i3sh8',
          appId: '1:397432293778:android:1e4f36a6d719e1773d194b',
          messagingSenderId: '397432293778',
          projectId: 'kpkb-dfc71',
          storageBucket: 'kpkb-dfc71.firebasestorage.app',
        ),
      );
    }

    debugPrint("🟡 BACKGROUND FCM RECEIVED");
    debugPrint("🟡 MESSAGE ID => ${message.messageId}");
    debugPrint("🟡 DATA => ${message.data}");
    debugPrint("🟡 NOTIFICATION TITLE => ${message.notification?.title}");
    debugPrint("🟡 NOTIFICATION BODY => ${message.notification?.body}");

    await setupNotificationChannel(requestPermission: false, isBackground: true);

    // Firebase auto-shows system notification when message has notification payload.
    // Only show local notification for data-only messages to avoid duplicates.
    if (message.notification == null) {
      final String title = message.data['title'] ?? 'New Order';
      final String body = message.data['body'] ?? 'New order received';

      await showOrderNotification(
        title: title,
        body: body,
        source: 'BACKGROUND',
      );
    }
  } catch (e) {
    debugPrint("❌ BACKGROUND HANDLER ERROR => $e");
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBKqYfO8j93m080n2I7kianw8WIV0i3sh8',
        appId: '1:397432293778:android:1e4f36a6d719e1773d194b',
        messagingSenderId: '397432293778',
        projectId: 'kpkb-dfc71',
        storageBucket: 'kpkb-dfc71.firebasestorage.app',
      ),
    );
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupNotificationChannel(requestPermission: true);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? result = prefs.getBool('islogin');
  final String? deviceId = await getDeviceId();

  if (result ?? false) {
    await updateDeviceId(deviceId ?? '');
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: kMainTextColor.withOpacity(0.5)),
  );

  runApp(const MyApp());
}

Future<void> setupNotificationChannel({
  bool requestPermission = true,
  bool isBackground = false,
}) async {
  debugPrint("🔔 SETUP NOTIFICATION CHANNEL START");
  debugPrint("🔔 REQUEST PERMISSION => $requestPermission");

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Order Notification',
    description: 'Order notification channel with custom ringtone',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ringtone'),
  );

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (requestPermission) {
    await androidImplementation?.requestNotificationsPermission();
  }

  await androidImplementation?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    notificationInitSettings,
    // Background isolate has no navigator, so skip the tap callback
    onDidReceiveNotificationResponse: isBackground
        ? null
        : (NotificationResponse response) {
            debugPrint("🔵 LOCAL NOTIFICATION CLICKED");
            debugPrint("🔵 PAYLOAD => ${response.payload}");

            final Map<String, dynamic> data = _decodePayload(response.payload);

            openNewOrderScreen(
              data['title']?.toString() ?? 'New Order',
              data['body']?.toString() ?? 'New order received',
            );
          },
  );

  debugPrint("✅ SETUP NOTIFICATION CHANNEL DONE");
}

Future<void> showOrderNotification({
  required String title,
  required String body,
  required String source,
}) async {
  debugPrint("🔔 SHOW LOCAL NOTIFICATION FROM => $source");
  debugPrint("🔔 TITLE => $title");
  debugPrint("🔔 BODY => $body");

  try {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'Order Notification',
          channelDescription: 'Order notification channel with custom ringtone',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('ringtone'),
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode({
        'title': title,
        'body': body,
        'source': source,
      }),
    );

    debugPrint("✅ LOCAL NOTIFICATION SUCCESS FROM => $source");
  } catch (e) {
    debugPrint("❌ LOCAL NOTIFICATION ERROR FROM $source => $e");
  }
}

Map<String, dynamic> _decodePayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) return {};

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (e) {
    debugPrint("❌ PAYLOAD DECODE ERROR => $e");
  }

  return {};
}

void openNewOrderScreen(String title, String body) {
  final navigator = navigatorKey.currentState;

  if (navigator == null) {
    debugPrint("❌ NAVIGATOR NULL");
    return;
  }

  navigator.push(
    MaterialPageRoute(
      builder: (_) => NewOrderAlertScreen(title: title, body: body),
    ),
  );
}

Future<String?> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? deviceId = '';

  if (Platform.isAndroid) {
    await deviceInfo.androidInfo;
    deviceId = await FirebaseMessaging.instance.getToken();
  } else if (Platform.isIOS) {
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? '';
  }

  debugPrint("📱 FCM DEVICE TOKEN => $deviceId");
  return deviceId;
}

Future<void> updateDeviceId(String deviceId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final response = await http.post(
    Uri.parse(driverlogin),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': prefs.getString('delivery_boy_phone'),
      'device_id': deviceId,
    }),
  );

  debugPrint("UPDATE DEVICE RESPONSE CODE => ${response.statusCode}");
  debugPrint("UPDATE DEVICE RESPONSE BODY => ${response.body}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool? result;
  bool _notificationSetupDone = false;

  @override
  void initState() {
    super.initState();

    _checkLocationPermission();
    setupNotification();
    getShared();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (result != null && result!) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GomarketHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Gomarket()),
        );
      }
    });
  }

  Future<void> getShared() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    result = prefs.getBool('islogin');
    debugPrint("IS LOGIN => $result");
  }

  Future<void> setupNotification() async {
    if (_notificationSetupDone) return;
    _notificationSetupDone = true;

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("🔔 NOTIFICATION PERMISSION => ${settings.authorizationStatus}");

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    final RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint("🔴 TERMINATED NOTIFICATION OPENED");
      debugPrint("🔴 MESSAGE ID => ${initialMessage.messageId}");
      debugPrint("🔴 DATA => ${initialMessage.data}");
      debugPrint("🔴 TITLE => ${initialMessage.notification?.title}");
      debugPrint("🔴 BODY => ${initialMessage.notification?.body}");

      Future.delayed(const Duration(seconds: 3), () {
        final String title =
            initialMessage.notification?.title ??
                initialMessage.data['title'] ??
                'New Order';

        final String body =
            initialMessage.notification?.body ??
                initialMessage.data['body'] ??
                'New order received';

        openNewOrderScreen(title, body);
      });
    } else {
      debugPrint("🔴 TERMINATED INITIAL MESSAGE NULL");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("🟢 FOREGROUND FCM RECEIVED");
      debugPrint("🟢 MESSAGE ID => ${message.messageId}");
      debugPrint("🟢 DATA => ${message.data}");
      debugPrint("🟢 NOTIFICATION TITLE => ${message.notification?.title}");
      debugPrint("🟢 NOTIFICATION BODY => ${message.notification?.body}");

      final String title =
          message.notification?.title ?? message.data['title'] ?? 'New Order';

      final String body =
          message.notification?.body ??
              message.data['body'] ??
              'New order received';

      await showOrderNotification(
        title: title,
        body: body,
        source: 'FOREGROUND',
      );

      openNewOrderScreen(title, body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔵 BACKGROUND NOTIFICATION CLICKED");
      debugPrint("🔵 MESSAGE ID => ${message.messageId}");
      debugPrint("🔵 DATA => ${message.data}");
      debugPrint("🔵 TITLE => ${message.notification?.title}");
      debugPrint("🔵 BODY => ${message.notification?.body}");

      final String title =
          message.notification?.title ?? message.data['title'] ?? 'New Order';

      final String body =
          message.notification?.body ??
              message.data['body'] ??
              'New order received';

      openNewOrderScreen(title, body);
    });
  }

  Future<void> _checkLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      debugPrint("LOCATION STATUS => Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        debugPrint("LOCATION STATUS => Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("LOCATION STATUS => Location permission permanently denied.");
      return;
    }

    debugPrint("LOCATION STATUS => Location permission granted.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "images/logos/playstore.png",
          height: 130,
          width: 100,
        ),
      ),
    );
  }
}

class NewOrderAlertScreen extends StatelessWidget {
  final String title;
  final String body;

  const NewOrderAlertScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kButtonColor,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 95,
                  width: 95,
                  decoration: BoxDecoration(
                    color: kButtonColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    size: 58,
                    color: kButtonColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "New Order Received",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kButtonColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    "View Order",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Gomarket extends StatelessWidget {
  const Gomarket({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginNavigator();
  }
}

class GomarketHome extends StatelessWidget {
  const GomarketHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountPage();
  }
}
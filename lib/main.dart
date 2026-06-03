// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:app_tracking_transparency/app_tracking_transparency.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_phoenix/flutter_phoenix.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:upgrader/upgrader.dart';
//
// import 'Auth/MobileNumber/UI/phone_number.dart';
// import 'HomeOrderAccount/home_order_account.dart';
// import 'Routes/routes.dart';
// import 'SplashScreen/splash_screen.dart';
// import 'Themes/colors.dart';
// import 'baseurlp/baseurl.dart';
//
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback =
//           (X509Certificate cert, String host, int port) => true;
//   }
// }
//
// Future<void> main() async {
//   HttpOverrides.global = MyHttpOverrides();
//
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Easy Localization
//   await EasyLocalization.ensureInitialized();
//
//   // Firebase Init
//   await Firebase.initializeApp(
//     options: Platform.isAndroid || kIsWeb
//         ? const FirebaseOptions(
//       apiKey: 'AIzaSyBKqYfO8j93m080n2I7kianw8WIV0i3sh8',
//       appId: '1:397432293778:android:1e4f36a6d719e1773d194b',
//       messagingSenderId: '397432293778',
//       projectId: 'kpkb-dfc71',
//       storageBucket: "kpkb-dfc71.firebasestorage.app",
//     )
//         : null,
//   );
//
//   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
//
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   bool isLogin = prefs.getBool('islogin') ?? false;
//
//   SystemChrome.setSystemUIOverlayStyle(
//     SystemUiOverlayStyle(
//       statusBarColor: kMainColor.withOpacity(0.5),
//     ),
//   );
//
//   await _requestPermission();
//
//   final razorpay = Razorpay();
//
//   runApp(
//     EasyLocalization(
//       supportedLocales: const [
//         Locale('en'),
//         Locale('hi'),
//       ],
//
//       path: 'assets/translations',
//
//       // First Time English Open
//       startLocale: const Locale('en'),
//
//       fallbackLocale: const Locale('en'),
//
//       child: Phoenix(
//         child: ScreenUtilInit(
//           designSize: const Size(360, 690),
//           minTextAdapt: true,
//           splitScreenMode: true,
//
//           builder: (context, child) {
//             return MaterialApp(
//               debugShowCheckedModeBanner: false,
//
//               locale: context.locale,
//
//               supportedLocales: context.supportedLocales,
//
//               localizationsDelegates:
//               context.localizationDelegates,
//
//               home: child,
//
//               routes: PageRoutes().routes(),
//             );
//           },
//
//           child: const SplashScreen(),
//         ),
//       ),
//     ),
//   );
//
//   RemoteMessage? initialMessage =
//   await FirebaseMessaging.instance.getInitialMessage();
//
//   if (initialMessage != null) {
//     // App received notification when killed
//   }
// }
//
// class GoMarket extends StatelessWidget {
//   const GoMarket({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return UpgradeCheckWrapper(
//       child: PhoneNumber(),
//     );
//   }
// }
//
// class GoMarketHome extends StatelessWidget {
//   const GoMarketHome({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const UpgradeCheckWrapper(
//       child: HomeStateless(),
//     );
//   }
// }
//
// class UpgradeCheckWrapper extends StatelessWidget {
//   final Widget child;
//
//   const UpgradeCheckWrapper({
//     super.key,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return UpgradeAlert(
//       dialogStyle: UpgradeDialogStyle.cupertino,
//       showIgnore: true,
//       showLater: true,
//       upgrader: Upgrader(
//       ),
//       child: child,
//     );
//   }
// }
//
// Future<void> updateDeviceId(String deviceId) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//
//   final response = await http.post(
//     Uri.parse(verifyPhone),
//     headers: {
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({
//       'phone': prefs.getString('user_phone'),
//       'device_id': deviceId,
//     }),
//   );
//
//   if (response.statusCode == 200) {
//     print('Device ID updated successfully');
//     print('Device ID :- $deviceId');
//   } else {
//     print('Failed to update Device ID');
//   }
// }
//
// void iosPermission() {
//   FirebaseMessaging firebaseMessaging =
//       FirebaseMessaging.instance;
//
//   firebaseMessaging
//       .setForegroundNotificationPresentationOptions(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
// }
//
// Future<void> _requestPermission() async {
//   var status2 =
//   await Permission.appTrackingTransparency.request();
//
//   var status =
//   await Permission.location.request();
//
//   var status1 =
//   await Permission.notification.request();
//
//   if (status2.isGranted) {
//     print('App Tracking Transparency permission granted');
//   }
//
//   if (status.isGranted) {
//     print('Location permission granted');
//   }
//
//   if (status1.isGranted) {
//     print('Notification permission granted');
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'Auth/MobileNumber/UI/phone_number.dart';
import 'HomeOrderAccount/home_order_account.dart';
import 'Routes/routes.dart';
import 'SplashScreen/splash_screen.dart';
import 'Themes/colors.dart';
import 'baseurlp/baseurl.dart';

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
    debugPrint("🟡 DATA => ${message.data}");

    await setupNotificationChannel(
      requestPermission: false,
      isBackground: true,
    );

    // Duplicate notification avoid:
    // Firebase notification payload ko khud show kar deta hai.
    // Local notification sirf data-only message ke liye show hoga.
    if (message.notification == null) {
      final String title = message.data['title'] ?? 'New Notification';
      final String body = message.data['body'] ?? 'You have a new notification';

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

  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: Platform.isAndroid || kIsWeb
        ? const FirebaseOptions(
      apiKey: 'AIzaSyBKqYfO8j93m080n2I7kianw8WIV0i3sh8',
      appId: '1:397432293778:android:1e4f36a6d719e1773d194b',
      messagingSenderId: '397432293778',
      projectId: 'kpkb-dfc71',
      storageBucket: "kpkb-dfc71.firebasestorage.app",
    )
        : null,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupNotificationChannel(requestPermission: true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLogin = prefs.getBool('islogin') ?? false;

  String? deviceId = await getDeviceId();

  if (isLogin && deviceId != null && deviceId.isNotEmpty) {
    await updateDeviceId(deviceId);
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: kMainColor.withOpacity(0.5),
    ),
  );

  await _requestPermission();

  final razorpay = Razorpay();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      path: 'assets/translations',
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      child: Phoenix(
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: child,
              routes: PageRoutes().routes(),
            );
          },
          child: const SplashScreen(),
        ),
      ),
    ),
  );

  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint("🔴 TERMINATED NOTIFICATION OPENED");
    debugPrint("🔴 DATA => ${initialMessage.data}");
  }

  setupFirebaseNotificationListeners();
}

Future<void> setupNotificationChannel({
  bool requestPermission = true,
  bool isBackground = false,
}) async {
  debugPrint("🔔 SETUP NOTIFICATION CHANNEL START");

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Order Notification',
    description: 'Order notification channel with custom ringtone',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ringtone'),
  );

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (requestPermission) {
    await androidImplementation?.requestNotificationsPermission();
  }

  await androidImplementation?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    notificationInitSettings,
    onDidReceiveNotificationResponse: isBackground
        ? null
        : (NotificationResponse response) {
      debugPrint("🔵 LOCAL NOTIFICATION CLICKED");
      debugPrint("🔵 PAYLOAD => ${response.payload}");

      final Map<String, dynamic> data = _decodePayload(response.payload);

      openNotificationScreen(
        data['title']?.toString() ?? 'New Notification',
        data['body']?.toString() ?? '',
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

void setupFirebaseNotificationListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint("🟢 FOREGROUND FCM RECEIVED");
    debugPrint("🟢 DATA => ${message.data}");
    debugPrint("🟢 TITLE => ${message.notification?.title}");
    debugPrint("🟢 BODY => ${message.notification?.body}");

    final String title =
        message.notification?.title ?? message.data['title'] ?? 'New Notification';

    final String body =
        message.notification?.body ?? message.data['body'] ?? '';

    await showOrderNotification(
      title: title,
      body: body,
      source: 'FOREGROUND',
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("🔵 BACKGROUND NOTIFICATION CLICKED");
    debugPrint("🔵 DATA => ${message.data}");

    final String title =
        message.notification?.title ?? message.data['title'] ?? 'New Notification';

    final String body =
        message.notification?.body ?? message.data['body'] ?? '';

    openNotificationScreen(title, body);
  });
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

void openNotificationScreen(String title, String body) {
  final navigator = navigatorKey.currentState;

  if (navigator == null) {
    debugPrint("❌ NAVIGATOR NULL");
    return;
  }

  navigator.push(
    MaterialPageRoute(
      builder: (_) => NotificationAlertScreen(
        title: title,
        body: body,
      ),
    ),
  );
}

Future<String?> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    await deviceInfo.androidInfo;
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("📱 FCM DEVICE TOKEN => $token");
    return token;
  } else if (Platform.isIOS) {
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    final deviceId = iosInfo.identifierForVendor ?? '';
    debugPrint("📱 IOS DEVICE ID => $deviceId");
    return deviceId;
  }

  return null;
}

Future<void> updateDeviceId(String deviceId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final response = await http.post(
    Uri.parse(verifyPhone),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'phone': prefs.getString('user_phone'),
      'device_id': deviceId,
    }),
  );

  if (response.statusCode == 200) {
    debugPrint('Device ID updated successfully');
    debugPrint('Device ID :- $deviceId');
  } else {
    debugPrint('Failed to update Device ID');
    debugPrint('Response Code :- ${response.statusCode}');
    debugPrint('Response Body :- ${response.body}');
  }
}

void iosPermission() {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  firebaseMessaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _requestPermission() async {
  var status2 = await Permission.appTrackingTransparency.request();

  var status = await Permission.location.request();

  var status1 = await Permission.notification.request();

  if (status2.isGranted) {
    debugPrint('App Tracking Transparency permission granted');
  }

  if (status.isGranted) {
    debugPrint('Location permission granted');
  }

  if (status1.isGranted) {
    debugPrint('Notification permission granted');
  }
}

class GoMarket extends StatelessWidget {
  const GoMarket({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeCheckWrapper(
      child: PhoneNumber(),
    );
  }
}

class GoMarketHome extends StatelessWidget {
  const GoMarketHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpgradeCheckWrapper(
      child: HomeStateless(),
    );
  }
}

class UpgradeCheckWrapper extends StatelessWidget {
  final Widget child;

  const UpgradeCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: true,
      showLater: true,
      upgrader: Upgrader(),
      child: child,
    );
  }
}

class NotificationAlertScreen extends StatelessWidget {
  final String title;
  final String body;

  const NotificationAlertScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor,
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
                    color: kMainColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 58,
                    color: kMainColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "New Notification",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kMainColor,
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
                    backgroundColor: kMainColor,
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
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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
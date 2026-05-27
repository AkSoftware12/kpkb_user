import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  // Easy Localization
  await EasyLocalization.ensureInitialized();

  // Firebase Init
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

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLogin = prefs.getBool('islogin') ?? false;

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

      // First Time English Open
      startLocale: const Locale('en'),

      fallbackLocale: const Locale('en'),

      child: Phoenix(
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,

          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,

              locale: context.locale,

              supportedLocales: context.supportedLocales,

              localizationsDelegates:
              context.localizationDelegates,

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
    // App received notification when killed
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
      upgrader: Upgrader(
      ),
      child: child,
    );
  }
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
    print('Device ID updated successfully');
    print('Device ID :- $deviceId');
  } else {
    print('Failed to update Device ID');
  }
}

void iosPermission() {
  FirebaseMessaging firebaseMessaging =
      FirebaseMessaging.instance;

  firebaseMessaging
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _requestPermission() async {
  var status2 =
  await Permission.appTrackingTransparency.request();

  var status =
  await Permission.location.request();

  var status1 =
  await Permission.notification.request();

  if (status2.isGranted) {
    print('App Tracking Transparency permission granted');
  }

  if (status.isGranted) {
    print('Location permission granted');
  }

  if (status1.isGranted) {
    print('Notification permission granted');
  }
}
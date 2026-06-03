import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:otpless_flutter/otpless_flutter.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../DriverApp/Account/UI/account_page.dart';
import '../../../HomeOrderAccount/home_order_account.dart';
import '../../../Routes/routes.dart';
import '../../../Themes/colors.dart';
import '../../../Themes/style.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/currencybean.dart';

class OtpScreen extends StatelessWidget {
  final String number;
  OtpScreen(this.number);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: true,
      //   backgroundColor: Colors.transparent,
      //   elevation: 0.0,
      //   title: Text('Verification'),
      // ),
      body: OtpVerify(),
    );
  }
}

//otp verification class
class OtpVerify extends StatefulWidget {
  // final VoidCallback onVerificationDone;

  // OtpVerify(this.onVerificationDone);

  @override
  _OtpVerifyState createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _controller = TextEditingController();
  late FirebaseMessaging messaging;
  bool isDialogShowing = false;
  dynamic token = '';
  var showDialogBox = false;
  var verificaitonPin = "";
  late String phoneNo;
  late String smsOTP = "";
  String verificationId = "";
  String errorMessage = '';
  String contact = '';
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  late Timer _timer;
  bool isLoading = false;

  @override
  // initState function ke andar ka code
  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;

    // Naya, safe तरीका use karein
    getSafeFirebaseToken().then((fetchedToken) {
      if (fetchedToken != null) {
        setState(() {
          token = fetchedToken;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Could not get notification token. Please try again.",
        );
      }
    });
    getd();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Yeh function class ke bahar ya andar kahin bhi daal sakte hain
  Future<String?> getSafeFirebaseToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Step 1: Request permission (for iOS & web)
      // Yeh zaroori hai, warna token milega hi nahi
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Step 2: iOS ke liye APNS token ka wait karein
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          print("APNS token nahi mila. Check permissions and Xcode setup.");
          return null;
        }
      }

      // Step 3: Ab FCM token get karein
      String? fcmToken = await messaging.getToken();
      print("Firebase Token Successfully Fetched: $fcmToken");
      return fcmToken;
    } catch (e) {
      print("Error getting Firebase token: $e");
      return null;
    }
  }


  bool _isLoading = false; // Variable to track the loading state

  void startLoading() {
    // Function to simulate start of loading
    setState(() {
      _isLoading = true;
    });
    // Simulating some task that takes time
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void getd() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    contact = pref.getString("user_phone")!;

    print(contact);
    // generateOtp('+91$contact');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   automaticallyImplyLeading: true,
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   centerTitle: true,
      //   title: const Text(
      //     'Verification',
      //     style: TextStyle(
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [

          /// LOADER
          if (showDialogBox)
            Container(
              color: Colors.black.withOpacity(.15),
              child: Center(
                child: CircularProgressIndicator(
                  color: kButtonColor,
                ),
              ),
            ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// ICON
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: kButtonColor.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: kButtonColor,
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// TITLE
                  const Text(
                    "Verify Phone Number",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Enter the 6-digit OTP sent to your mobile number",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// OTP FIELD
                  PinCodeTextField(
                    autofocus: true,
                    controller: _controller,
                    hideCharacter: false,
                    highlight: true,
                    highlightColor: kButtonColor,
                    defaultBorderColor: Colors.grey.shade300,
                    hasTextBorderColor: kButtonColor,
                    maxLength: 6,
                    pinBoxRadius: 14,
                    pinBoxWidth: 48,
                    pinBoxHeight: 56,
                    hasUnderline: false,
                    wrapAlignment: WrapAlignment.spaceAround,
                    keyboardType: TextInputType.number,
                    pinBoxDecoration:
                    ProvidedPinBoxDecoration.roundedPinBoxDecoration,
                    pinTextStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    onDone: (text) {
                      SystemChannels.textInput.invokeMethod(
                        'TextInput.hide',
                      );

                      verificaitonPin = text;
                      smsOTP = text;
                    },
                  ),

                  const SizedBox(height: 28),

                  /// RESEND TEXT
                  Text(
                    "Didn't receive the code?",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () {
                      // generateOtp('+91$contact');
                    },
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: kButtonColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  /// VERIFY BUTTON
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        showDialogBox = true;
                      });

                      hitService(context);
                    },
                    child: Container(
                      height: 58,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kButtonColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kButtonColor.withOpacity(.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void hitService(BuildContext context) async {
    if (token == null || token.toString().isEmpty) {
      String? fetchedToken = await getSafeFirebaseToken();

      if (fetchedToken != null) {
        if (mounted) {
          setState(() {
            token = fetchedToken;
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "Could not get device token. Please try again.",
          toastLength: Toast.LENGTH_LONG,
        );

        if (mounted) {
          setState(() => showDialogBox = false);
        }
        return;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Uri myUri = Uri.parse(verifyPhone);

    try {
      final response = await http.post(
        myUri,
        body: {
          'user_phone': prefs.getString('user_phone') ?? '',
          'otp': _controller.text.trim(),
          'device_id': token ?? '',
        },
      );

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 1) {
          final data = jsonData['data'] ?? {};

          final int role = int.tryParse(data['role'].toString()) ?? 0;

          await prefs.setInt("role", role);
          await prefs.setBool("phoneverifed", true);
          await prefs.setBool("islogin", true);

          if (role == 0) {
            // USER DATA SAVE
            await prefs.setInt(
              "user_id",
              int.tryParse(data['user_id'].toString()) ?? 0,
            );

            await prefs.setString("card_no", data['card_no']?.toString() ?? '');
            await prefs.setString("rank_id", data['rank_id']?.toString() ?? '');
            await prefs.setString(
              "regimental_no",
              data['regimental_no']?.toString() ?? '',
            );
            await prefs.setString("card", data['card']?.toString() ?? '');

            await prefs.setString("user_name", data['user_name']?.toString() ?? '');
            await prefs.setString("user_email", data['user_email']?.toString() ?? '');
            await prefs.setString("user_image", data['user_image']?.toString() ?? '');
            await prefs.setString("user_phone", data['user_phone']?.toString() ?? '');

            if (jsonData['Currency'] != null) {
              CurrencyData currencyData = CurrencyData.fromJson(jsonData['Currency']);

              await prefs.setString(
                "curency",
                currencyData.currency_sign?.toString() ?? '₹',
              );
            }
          } else if (role == 1) {
            // DRIVER DATA SAVE
            await prefs.setInt(
              "delivery_boy_id",
              int.tryParse(data['delivery_boy_id'].toString()) ?? 0,
            );

            await prefs.setString(
              "delivery_boy_name",
              data['delivery_boy_name']?.toString() ?? '',
            );
            await prefs.setString(
              "delivery_boy_image",
              data['delivery_boy_image']?.toString() ?? '',
            );
            await prefs.setString(
              "delivery_boy_phone",
              data['delivery_boy_phone']?.toString() ?? '',
            );
            await prefs.setString(
              "delivery_boy_status",
              data['delivery_boy_status']?.toString() ?? '',
            );
            await prefs.setString("lat", data['lat']?.toString() ?? '0');
            await prefs.setString("lng", data['lng']?.toString() ?? '0');
            await prefs.setString(
              "cityadmin_id",
              data['cityadmin_id']?.toString() ?? '',
            );
          }

          if (!mounted) return;

          setState(() => showDialogBox = false);

          if (role == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeStateless()),
                  (Route<dynamic> route) => false,
            );
          } else if (role == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => AccountPage()),
                  (Route<dynamic> route) => false,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: jsonData['message']?.toString() ?? "Invalid OTP",
          );

          if (mounted) {
            setState(() => showDialogBox = false);
          }
        }
      } else {
        Fluttertoast.showToast(
          msg: "Server Error: ${response.statusCode}",
        );

        if (mounted) {
          setState(() => showDialogBox = false);
        }
      }
    } catch (e) {
      print("API call mein error: $e");

      Fluttertoast.showToast(
        msg: "Something went wrong. Please try again.",
      );

      if (mounted) {
        setState(() => showDialogBox = false);
      }
    }
  }  void showAlertDialog(BuildContext context, String message) {
    // set up the AlertDialog
    final CupertinoAlertDialog alert = CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text('\n$message'),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop("Discard");
          },
        ),
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

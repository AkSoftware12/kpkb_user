import 'dart:async';
import 'dart:convert';

import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pin_code_text_field/pin_code_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationPage extends StatelessWidget {
  final VoidCallback onVerificationDone;

  const VerificationPage(this.onVerificationDone, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: OtpVerify(onVerificationDone));
  }
}

class OtpVerify extends StatefulWidget {
  final VoidCallback onVerificationDone;

  const OtpVerify(this.onVerificationDone, {super.key});

  @override
  State<OtpVerify> createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _controller = TextEditingController();

  FirebaseMessaging? messaging;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  dynamic token = '';
  bool showDialogBox = false;

  String verificaitonPin = "";
  String? smsOTP;
  String? verificationId;
  String errorMessage = '';
  String contact = '';

  @override
  void initState() {
    super.initState();

    messaging = FirebaseMessaging.instance;
    messaging?.getToken().then((value) {
      token = value ?? '';
      debugPrint("Token Is => $token");
    });

    getd();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getd() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    contact = pref.getString("delivery_boy_phone") ?? '';

    debugPrint(contact);

    if (contact.isNotEmpty) {
      generateOtp('+91$contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "Verification",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.30)),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.black,
                  size: 46,
                ),
              ),

              const SizedBox(height: 18),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  "Verify your phone number",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  contact.isEmpty
                      ? "Enter the OTP code sent to your mobile number."
                      : "Enter the OTP code sent to +91 $contact",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withOpacity(.88),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(38),
                    ),
                    border: Border.all(width: 1, color: Colors.grey),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          "OTP Code",
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Please enter 6 digit verification code",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 34),

                        PinCodeTextField(
                          autofocus: false,
                          controller: _controller,
                          hideCharacter: false,
                          highlight: true,
                          highlightColor: kButtonColor,
                          defaultBorderColor: Colors.grey.shade300,
                          hasTextBorderColor: kButtonColor,
                          maxLength: 6,
                          pinBoxRadius: 14,
                          pinBoxWidth: 45,
                          pinBoxHeight: 55,
                          hasUnderline: false,
                          wrapAlignment: WrapAlignment.spaceBetween,
                          pinBoxDecoration:
                              ProvidedPinBoxDecoration.defaultPinBoxDecoration,
                          pinTextStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          pinTextAnimatedSwitcherTransition:
                              ProvidedPinBoxTextAnimation.scalingTransition,
                          pinTextAnimatedSwitcherDuration: const Duration(
                            milliseconds: 250,
                          ),
                          highlightAnimationBeginColor: kButtonColor,
                          highlightAnimationEndColor: Colors.white,
                          keyboardType: TextInputType.number,
                          onDone: (text) {
                            SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                            verificaitonPin = text;
                            smsOTP = text;
                          },
                        ),

                        const SizedBox(height: 28),

                        Text(
                          "Didn't receive any code?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 6),

                        InkWell(
                          onTap: () {
                            if (contact.isNotEmpty) {
                              generateOtp('+91$contact');
                              Fluttertoast.showToast(
                                msg: "OTP sent again",
                                backgroundColor: Colors.black87,
                                textColor: Colors.white,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: kButtonColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        GestureDetector(
                          onTap: showDialogBox
                              ? null
                              : () {
                                  if (_controller.text.trim().length < 6) {
                                    Fluttertoast.showToast(
                                      msg: "Please enter valid OTP",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Colors.black87,
                                      textColor: Colors.white,
                                      fontSize: 14.0,
                                    );
                                    return;
                                  }

                                  setState(() {
                                    showDialogBox = true;
                                  });

                                  hitService(_controller.text.trim(), context);
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: LinearGradient(
                                colors: showDialogBox
                                    ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ]
                                    : [kButtonColor, kButtonColor],
                              ),
                            ),
                            child: Center(
                              child: showDialogBox
                                  ? SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: kButtonColor,
                                      ),
                                    )
                                  : const Text(
                                      "Verify OTP",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.grey.shade500,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Your verification is secure",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> hitService(String verificationPin, BuildContext context) async {
    try {
      setState(() => showDialogBox = true);

      if (token == null || token.toString().isEmpty) {
        token = await messaging?.getToken() ?? '';
      }

      if (token == null || token.toString().isEmpty) {
        setState(() => showDialogBox = false);
        Fluttertoast.showToast(msg: "Device token not found");
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      final response = await http.post(
        Uri.parse(driverlogin),
        body: {
          'phone': prefs.getString('delivery_boy_phone') ?? '',
          'otp': verificationPin, // âœ… yaha controller nahi
          'device_id': token.toString(),
        },
      );

      debugPrint("STATUS ${response.statusCode}");
      debugPrint("BODY ${response.body}");

      if (!mounted) return;

      setState(() => showDialogBox = false);

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (jsonData['status'].toString() == "1") {
          final data = jsonData['data'];

          await prefs.setInt("duty", 0);
          await prefs.setInt(
            "delivery_boy_id",
            int.tryParse("${data['delivery_boy_id']}") ?? 0,
          );
          await prefs.setString(
            "delivery_boy_name",
            "${data['delivery_boy_name'] ?? ''}",
          );
          await prefs.setString(
            "delivery_boy_image",
            "${data['delivery_boy_image'] ?? ''}",
          );
          await prefs.setString(
            "delivery_boy_phone",
            "${data['delivery_boy_phone'] ?? ''}",
          );
          await prefs.setString(
            "delivery_boy_pass",
            "${data['delivery_boy_pass'] ?? ''}",
          );
          await prefs.setString("device_id", "${data['device_id'] ?? ''}");
          await prefs.setString(
            "delivery_boy_status",
            "${data['delivery_boy_status'] ?? ''}",
          );
          await prefs.setString(
            "is_confirmed",
            "${data['is_confirmed'] ?? '0'}",
          );
          await prefs.setInt(
            "cityadmin_id",
            int.tryParse("${data['cityadmin_id'] ?? 0}") ?? 0,
          );
          await prefs.setInt(
            "phoneverifed",
            int.tryParse("${data['phone_verify'] ?? 0}") ?? 0,
          );
          await prefs.setBool("islogin", true);

          if (jsonData['currency'] != null) {
            final currency = jsonData['currency'];
            await prefs.setString(
              "curency",
              "${currency['currency_sign'] ?? ''}",
            );
          }

          widget.onVerificationDone();

          // Navigator.of(context).pushAndRemoveUntil(
          //   MaterialPageRoute(builder: (_) => AccountPage()),
          //       (Route<dynamic> route) => false,
          // );

          Fluttertoast.showToast(
            msg: jsonData['message'] ?? "Login successfully",
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        } else {
          await prefs.setInt("phoneverifed", 0);
          await prefs.setBool("islogin", false);

          Fluttertoast.showToast(
            msg: jsonData['message'] ?? "Invalid OTP",
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: jsonData['message'] ?? "Server error. Please try again.",
          backgroundColor: Colors.black87,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");

      if (!mounted) return;

      setState(() => showDialogBox = false);

      Fluttertoast.showToast(
        msg: "Something went wrong: $e",
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    }
  }

  Future<void> generateOtp(String contact) async {
    var smsOTPSent = (String verId, [int? forceCodeResend]) {
      verificationId = verId;
      debugPrint("Verification Id: $verificationId");
    };

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: contact,
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        codeSent: smsOTPSent,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (AuthCredential phoneAuthCredential) {},
        verificationFailed: (FirebaseAuthException exception) {
          if (mounted) {
            // handleError(exception);
          }
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        // handleError(e);
      }
    }
  }

  void handleError(FirebaseAuthException error) {
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
      case 'invalid-verification-code':
        FocusScope.of(context).requestFocus(FocusNode());
        setState(() {
          errorMessage = 'Invalid Code';
        });
        showAlertDialog(context, 'Invalid Code');
        break;

      default:
        showAlertDialog(context, error.message.toString());
        break;
    }
  }

  void showAlertDialog(BuildContext context, String message) {
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

    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return alert;
    //   },
    // );
  }
}

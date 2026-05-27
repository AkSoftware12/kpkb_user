import 'dart:convert';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Locale/locales.dart';
import '../../../Themes/colors.dart';
import '../../../baseurlp/baseurl.dart';
import '../../KpKbRegistration/kpkb_register.dart';
import 'otp_screen.dart';

class PhoneNumber_New extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PhoneNumber(),
    );
  }
}

class PhoneNumber extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PhoneNumberState();
  }
}

class PhoneNumberState extends State<PhoneNumber> {
  static const String id = 'phone_number';
  final TextEditingController _controller = TextEditingController();
  String isoCode = '+91';
  int numberLimit = 10;
  var showDialogBox = false;

  @override
  void initState() {
    super.initState();
    getCountryCode();
  }



// coomit

  void getCountryCode() async {
    setState(() {
      showDialogBox = true;
    });

    String url = country_code;
    Uri myUri = Uri.parse(url);
    http.get(myUri).then((response) {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        print('${response.body}');
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonData['Data'] as List;
          if (tagObjsJson.isNotEmpty) {
            setState(() {
              showDialogBox = false;
              numberLimit = int.parse('${tagObjsJson[0]['number_limit']}');
              isoCode = tagObjsJson[0]['country_code'];
            });
          } else {
            setState(() {
              showDialogBox = false;
            });
          }
        } else {
          setState(() {
            showDialogBox = false;
          });
        }
      } else {
        setState(() {
          showDialogBox = false;
        });
      }
    }).catchError((e) {
      print(e);
      setState(() {
        showDialogBox = false;
      });
    });

    setState(() {
      showDialogBox = false;
      numberLimit = 10;
      isoCode = '+91';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: WillPopScope(
        onWillPop: _handlePopBack,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 0.sp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                       SizedBox(height: 100.sp),
                      ClipOval(
                        child: Image.asset(
                          "images/logos/playstore.png",
                          height: 150.sp,
                          width: 150.sp,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // const SizedBox(height: 10),

                      /// TITLE
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            black_color,
                            black_color.withOpacity(.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          "Welcome",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: .8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Login to continue KPKB ITBPF App",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.7,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 50.sp),

                      /// MOBILE FIELD
                      Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 10.sp),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kButtonColor.withOpacity(.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [

                              /// COUNTRY CODE
                              Container(
                                padding:  EdgeInsets.symmetric(
                                  horizontal: 14.sp,
                                  vertical: 15.sp,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.call,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isoCode,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: TextFormField(
                                  controller: _controller,
                                  keyboardType: TextInputType.number,
                                  enabled: !showDialogBox,
                                  maxLength: numberLimit,

                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(numberLimit),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .8,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                    hintText: 'Enter your mobile number',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                       // SizedBox(height: 24.sp),

                      /// LOADER
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: showDialogBox
                            ? Column(
                          children: [
                            CircularProgressIndicator(
                              color: kButtonColor,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Please wait...",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : const SizedBox(),
                      ),

                      SizedBox(height: 30.sp),

                      /// CONTINUE BUTTON
                      Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 10.sp),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50.sp,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              shadowColor: kMainColor.withOpacity(.45),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            onPressed: () async {
                              if (!showDialogBox) {
                                SystemChannels.textInput
                                    .invokeMethod('TextInput.hide');

                                if (_controller.text.length < numberLimit) {
                                  Fluttertoast.showToast(
                                    msg: "Enter valid mobile number!",
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

                                store(_controller.text);
                                hitService(
                                  isoCode,
                                  _controller.text,
                                  context,
                                );
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: kButtonColor,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                       SizedBox(height: 15.sp),

                      /// REGISTER BUTTON
                      Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 10.sp),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50.sp,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: kButtonColor.withOpacity(.4),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KpkbRegisterScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.person_add_alt_1_rounded,
                              color: kButtonColor,
                            ),
                            label: Text(
                              "New Registration",
                              style: TextStyle(
                                color: kButtonColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Spacer pushes the GIF to bottom when extra space available
                      const Spacer(),

                      Image.asset(
                        "images/logos/Delivery.gif",
                        fit: BoxFit.cover,
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );  }

  void hitService(
      String isoCode, String phoneNumber, BuildContext context) async {
    String? url = userRegistration;
    var client = http.Client();
    Uri myUri = Uri.parse(url);
    client.post(myUri, body: {'user_phone': '${phoneNumber}'}).then(
            (response) async {
          print('Response Body 1: - ${response.body} - ${response.statusCode}');
          if (response.statusCode == 200) {
            print('Response Body: - ${response.body}');
            var jsonData = jsonDecode(response.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString("user_phone", '${phoneNumber}');
            prefs.setInt("number_limit", numberLimit);
            if (jsonData['status'] == 1) {
              setState(() {
                showDialogBox = false;
              });
              // Navigator.pushNamed(context, LoginRoutes.verification);


              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OtpScreen(phoneNumber)),
              );
            } else {
              setState(() {
                showDialogBox = false;
              });
              /// USER NOT REGISTERED POPUP
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          /// ICON
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_off_rounded,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),

                          const SizedBox(height: 18),

                          /// TITLE
                          const Text(
                            "User Not Registered",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// MESSAGE
                          Text(
                            jsonData['message'] ?? "Your account is not registered.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 25),

                          /// BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);

                                /// REGISTER SCREEN
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (_) => RegisterScreen(),
                                //   ),
                                // );
                              },
                              child: const Text(
                                "OK",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          } else {
            setState(() {
              showDialogBox = false;
            });


          }
        }).catchError((e) {
      print(e);
      setState(() {
        showDialogBox = false;
      });
    });
  }

  buildButton(CountryCode isoCode) {
    return Row(
      children: <Widget>[
        Text(
          '$isoCode',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<bool> _handlePopBack() async {
    bool isVal = false;
    if (showDialogBox) {
      setState(() {
        showDialogBox = false;
      });
    } else {
      isVal = true;
    }
    return isVal;
  }

  Future<void> store(String phoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("user_phone", '${phoneNumber}');
  }
}



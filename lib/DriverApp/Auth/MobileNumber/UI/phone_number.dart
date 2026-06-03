import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:kpUser/DriverApp/Locale/locales.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhoneNumber_New extends StatelessWidget {
  const PhoneNumber_New({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: PhoneNumber());
  }
}

class PhoneNumber extends StatefulWidget {
  final VoidCallback? onVerificationRequested;

  const PhoneNumber({super.key, this.onVerificationRequested});

  @override
  State<PhoneNumber> createState() => PhoneNumberState();
}

class PhoneNumberState extends State<PhoneNumber> {
  static const String id = 'phone_number';

  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> scafoldKey = GlobalKey<ScaffoldState>();

  String isoCode = '+91';
  bool showDialogBox = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      key: scafoldKey,
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: _handlePopBack,
        child: Stack(
          children: [
            Container(
              height: h,
              width: w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 22, 0, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h - 60),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.14),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "images/logos/playstore.png",
                          height: 105,
                          width: 105,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        appname,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        AppLocalizations.of(context)?.bodyText1 ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        AppLocalizations.of(context)?.bodyText2 ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 34),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.10),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Login with mobile number",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Enter your registered mobile number to continue.",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 22),

                              Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CountryCodePicker(
                                      onChanged: (value) {
                                        isoCode = value.dialCode ?? '+91';
                                      },
                                      initialSelection: '+91',
                                      showFlag: false,
                                      showFlagDialog: true,
                                      favorite: const ['+91', 'US'],
                                      builder: (value) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 9,
                                          ),
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kMainColor.withOpacity(.10),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            // border: Border.all(width: 1,color: Colors.grey.shade500)
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                value?.dialCode ?? '+91',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: kMainColor,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: Colors.grey.shade300,
                                    ),

                                    Expanded(
                                      child: TextFormField(
                                        controller: _controller,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        maxLength: 10,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: "",
                                          hintText:
                                              AppLocalizations.of(
                                                context,
                                              )?.mobileText ??
                                              "Mobile Number",
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 17,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              SizedBox(
                                height: 56,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: showDialogBox
                                      ? null
                                      : () {
                                          SystemChannels.textInput.invokeMethod(
                                            'TextInput.hide',
                                          );

                                          if (_controller.text.trim().length <
                                              10) {
                                            _showToast(
                                              "Enter valid mobile number!",
                                            );
                                            return;
                                          }

                                          hitService(
                                            _controller.text.trim(),
                                            context,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kButtonColor,
                                    disabledBackgroundColor: kMainColor
                                        .withOpacity(.55),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Continue",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Image.asset(
                        "images/logos/Delivery.gif",
                        // width: w * .86,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (showDialogBox) _loadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(.35),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kMainColor, strokeWidth: 3),
              const SizedBox(width: 18),
              const Expanded(
                child: Text(
                  "Loading, please wait...",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void hitService(String phoneNumber, BuildContext context) async {
    setState(() => showDialogBox = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("delivery_boy_phone", phoneNumber);

      final response = await http.post(
        Uri.parse(delievery_boy_phone_verify),
        body: {'phone': phoneNumber},
      );

      debugPrint("$phoneNumber ${response.body}");

      if (!mounted) return;

      setState(() => showDialogBox = false);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1") {
          widget.onVerificationRequested?.call();
        } else {
          showAlertDialog(context);
        }
      } else {
        _showToast("Server error. Please try again.");
      }
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() => showDialogBox = false);
      _showToast("Something went wrong. Please try again.");
    }
  }

  void showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Notice",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Your number is not verified yet. Please contact customer care.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
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

  Future<bool> _handlePopBack() async {
    if (showDialogBox) {
      setState(() => showDialogBox = false);
      return false;
    }
    return true;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';


class SupportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SupportPageState();
  }
}

class SupportPageState extends State<SupportPage> {
  static const String id = 'support_page';
  var number = '';
  dynamic userIds;
  bool _inProgress = false;
  var messageController = TextEditingController();
  var numberController = TextEditingController();
  int number_limit = 0;

  @override
  void initState() {
    super.initState();
    getPrefValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Support',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(width:1,color: Colors.grey.shade300 )

              ),
              child: Column(
                children: [
                  Container(
                    height: 105,
                    width: 105,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                        border: Border.all(width:1,color: Colors.grey.shade300 )

                    ),
                    child: Image.asset(
                      "images/logos/playstore.png",
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.support_agent_rounded,
                          color: kMainColor,
                          size: 48,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'How can we help you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Write your query below. Our support team will help you soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.90),
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.055),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Or Write us your queries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your words means a lot to us.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    cursorColor: kMainColor,
                    controller: numberController,
                    maxLength: number_limit,
                    maxLines: 1,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: "Phone Number",
                      prefixIcon: Icon(
                        Icons.phone_rounded,
                        color: kButtonColor,
                      ),
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: kMainColor, width: 1.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    cursorColor: kMainColor,
                    controller: messageController,
                    maxLines: 5,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Your Message',
                      hintText: 'Enter your message here',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 76),
                        child: Icon(
                          Icons.message_rounded,
                          color: kButtonColor,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: kMainColor, width: 1.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _inProgress
                        ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kButtonColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Platform.isIOS
                          ? CupertinoActivityIndicator(color: kButtonColor)
                          : CircularProgressIndicator(
                        color: kButtonColor,
                        strokeWidth: 2.8,
                      ),
                    )
                        : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 19),
                      label: const Text('Submit'),
                      onPressed: () {
                        setState(() {
                          _inProgress = true;
                        });
                        handleSubmit();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getPrefValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    String? user_phone = prefs.getString('user_phone');
    setState(() {
      number_limit = prefs.getInt('number_limit')!;
      number_limit = number_limit+(user_phone!.length);
      userIds = userId;
      number = user_phone;
      numberController.text = user_phone;
    });
  }

  void handleSubmit() {
    if (numberController.text.length > 9 &&
        messageController.text.length > 50) {
      var url = support;
      var client = http.Client();
      Uri myUri = Uri.parse(url);

      client.post(myUri, body: {
        'user_id': '${userIds}',
        'user_number': '${numberController.text}',
        'message': '${messageController.text}',
      }).then((value) {
        if (value.statusCode == 200) {
          var jsonData = jsonDecode(value.body);
          if (jsonData['status'] == "1") {
            setState(() {
              _inProgress = false;
              messageController.clear();
              Navigator.pop(context);
              Fluttertoast.showToast(
                  msg: "Submitted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.black26,
                  textColor: Colors.white,
                  fontSize: 14.0
              );
            });
          } else {
            setState(() {
              _inProgress = false;
              Fluttertoast.showToast(
                  msg: 'Please try again!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.black26,
                  textColor: Colors.white,
                  fontSize: 14.0
              );
            });
          }
        } else {
          setState(() {
            _inProgress = false;
            Fluttertoast.showToast(
                msg: 'Please try again!',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black26,
                textColor: Colors.white,
                fontSize: 14.0
            );
          });
        }
      }).catchError((e) {
        setState(() {
          _inProgress = false;
        });
      });
    } else {
      setState(() {
        _inProgress = false;
      });
      Fluttertoast.showToast(
          msg:  'Please enter valid mobile no. and message is not less then 100 words',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black26,
          textColor: Colors.white,
          fontSize: 14.0
      );
    }
  }
}

import 'package:kpUser/DriverApp/Account/UI/account_page.dart';
import 'package:kpUser/DriverApp/Auth/MobileNumber/UI/phone_number.dart';
import 'package:kpUser/DriverApp/Auth/Verification/UI/verification_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class LoginData {
  final String phoneNumber;
  final String name;
  final String email;

  LoginData(this.phoneNumber, this.name, this.email);
}

class LoginNavigator extends StatefulWidget {
  @override
  State<LoginNavigator> createState() => _LoginNavigatorState();
}

class _LoginNavigatorState extends State<LoginNavigator> {
  bool _showVerification = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      Firebase.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showVerification) {
          setState(() => _showVerification = false);
          return false;
        }
        return true;
      },
      child: _showVerification
          ? VerificationPage(() {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => AccountPage()),
                (Route<dynamic> route) => false,
              );
            })
          : PhoneNumber(
              onVerificationRequested: () {
                setState(() => _showVerification = true);
              },
            ),
    );
  }
}

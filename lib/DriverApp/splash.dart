import 'package:flutter/material.dart';

Future<void> main() async {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Splash()));
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "images/logos/playstore.png",
          height: 130.0,
          width: 99.7,
        ),
      ),
    );
  }
}

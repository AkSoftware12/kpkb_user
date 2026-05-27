import 'package:flutter/material.dart';

class MyGradients {
  static const LinearGradient rainbow = LinearGradient(
    colors: [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient button = LinearGradient(
    colors: [

      Colors.greenAccent,
      Colors.yellow,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

double fixPadding = 10.0;

SizedBox heightSpace = SizedBox(height: 10.0);
SizedBox widthSpace = SizedBox(width: 10.0);
dynamic headingSize = 16.0;
dynamic titleSize = 14.0;

var apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

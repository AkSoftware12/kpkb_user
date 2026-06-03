import 'dart:convert';

import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AboutUsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AboutUsPageState();
  }
}

class AboutUsPageState extends State<AboutUsPage> {
  dynamic htmlString = '';

  @override
  void initState() {
    super.initState();
    getTnc();
  }

  void getTnc() async {
    var client = http.Client();
    var url = aboutus;
    client
        .get(Uri.parse(url))
        .then((value) {
          print('${value.body}');
          if (value.statusCode == 200 &&
              jsonDecode(value.body)['status'] == "1") {
            var jsonData = jsonDecode(value.body);
            var dataList = jsonData['data'] as List;

            setState(() {
              htmlString = dataList[0]['termcondition'];
            });
          }
        })
        .catchError((e) {
          print(e);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0.0,
        title: Text('About Us', style: Theme.of(context).textTheme.bodyLarge),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                color: Colors.white,
                child: Image(
                  image: AssetImage("images/logos/playstore.png"),
                  height: 220,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '\n${htmlString}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

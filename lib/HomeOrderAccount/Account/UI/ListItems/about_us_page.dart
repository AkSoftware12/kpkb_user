import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';



class AboutUsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AboutUsPageState();
  }

}

class AboutUsPageState extends State<AboutUsPage>{

  dynamic htmlString = '';

  @override
  void initState() {
    super.initState();
    getTnc();
  }

  void getTnc() async {
    var client = http.Client();
    var url = aboutus;
    Uri myUri = Uri.parse(url);
    client.get(myUri).then((value) {
      if (value.statusCode == 200 && jsonDecode(value.body)['status'] == "1") {
        var jsonData = jsonDecode(value.body);
        var dataList = jsonData['data'] as List;
        setState(() {
          htmlString = dataList[0]['termcondition'];
        });
      }
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: white_color,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding:  EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                          Icons.info_outline_rounded,
                          color: kMainColor,
                          size: 48,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'About Us',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learn more about our services and mission.',
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

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.055),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Html(
                data: htmlString,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(15),
                    color: const Color(0xff374151),
                    lineHeight: const LineHeight(1.55),
                    fontWeight: FontWeight.w400,
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 12),
                    fontSize: FontSize(15),
                    color: const Color(0xff374151),
                    lineHeight: const LineHeight(1.55),
                  ),
                  "h1": Style(
                    fontSize: FontSize(22),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
                  ),
                  "h2": Style(
                    fontSize: FontSize(20),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
                  ),
                  "h3": Style(
                    fontSize: FontSize(18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff111827),
                  ),
                  "li": Style(
                    fontSize: FontSize(15),
                    color: const Color(0xff374151),
                    lineHeight: const LineHeight(1.5),
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
                  ),
                  "a": Style(
                    color: kMainColor,
                    textDecoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

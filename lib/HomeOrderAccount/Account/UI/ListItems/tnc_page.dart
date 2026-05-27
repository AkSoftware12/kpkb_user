import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';

class TncPage extends StatefulWidget {
  const TncPage({super.key});

  @override
  State<TncPage> createState() => TncPageState();
}

class TncPageState extends State<TncPage> {
  String htmlString = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getTnc();
  }

  Future<void> getTnc() async {
    try {
      final response = await http.get(Uri.parse(termcondition));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1") {
          final List dataList = jsonData['data'] ?? [];

          setState(() {
            htmlString = dataList.isNotEmpty
                ? dataList[0]['termcondition']?.toString() ?? ''
                : '';
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint(e.toString());
    }
  }

  Future<void> _refresh() async {
    await getTnc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? _buildLoader()
          : RefreshIndicator(
        color: kMainColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildContentCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
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
                  Icons.description_rounded,
                  color: Colors.black,
                  size: 48,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Terms & Conditions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please read our terms carefully before using the app.',
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
    );
  }

  Widget _buildContentCard() {
    return Container(
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
      child: htmlString.trim().isEmpty
          ? _buildEmpty()
          : Html(
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
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: kMainColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 14),
            Text(
              'Loading terms...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Terms Found',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xff1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
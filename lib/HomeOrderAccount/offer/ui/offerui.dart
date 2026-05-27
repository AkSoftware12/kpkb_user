import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Themes/colors.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/notification_bean.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => OfferScreenState();
}

class OfferScreenState extends State<OfferScreen> {
  List<Notificationd> notificationList = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    setNotificationListner();
    getData();
    getNotificationList();
  }

  Future<void> getData() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      message = pref.getString("message") ?? '';
    });
  }

  void setNotificationListner() async {
    // Firebase notification listener code if needed
  }

  void firebaseMessagingListner(FirebaseMessaging firebaseMessaging) async {
    // FirebaseMessaging listener if needed
  }

  Future<void> getNotificationList() async {
    setState(() => isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      final response = await http.post(
        Uri.parse(notificationlist),
        body: {
          'user_id': '${userId ?? ''}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1") {
          final List data = jsonData['data'] ?? [];

          final List<Notificationd> list = data
              .map((tagJson) => Notificationd.fromJson(tagJson))
              .toList();

          setState(() {
            notificationList = list;
            isLoading = false;
          });
        } else {
          setState(() {
            notificationList.clear();
            isLoading = false;
          });

          Fluttertoast.showToast(
            msg: jsonData['message']?.toString() ?? 'No notification found!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } else {
        setState(() => isLoading = false);

        Fluttertoast.showToast(
          msg: 'No Notification found!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      Fluttertoast.showToast(
        msg: 'Something went wrong!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> _onRefresh() async {
    await getData();
    await getNotificationList();
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
          'Offers & Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? _buildLoader()
                : notificationList.isNotEmpty
                ? RefreshIndicator(
              color: kMainColor,
              onRefresh: _onRefresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                itemCount: notificationList.length,
                itemBuilder: (context, index) {
                  final item = notificationList[index];
                  return _OfferCard(item: item);
                },
              ),
            )
                : RefreshIndicator(
              color: kButtonColor,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  _EmptyOfferWidget(),
                ],
              ),
            ),
          ),

          if (message.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
              'Loading offers...',
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
}

class _OfferCard extends StatelessWidget {
  final Notificationd item;

  const _OfferCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final String title = item.noti_title?.toString() ?? '';
    final String description = item.noti_message?.toString() ?? '';
    final String image = item.image?.toString() ?? '';

    final bool hasImage = image.isNotEmpty && image != 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                imageBaseUrl + image,
                height: 165,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return Container(
                    height: 165,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kMainColor,
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 165,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_offer_rounded,
                        color: kMainColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'New Offer' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff1F2937),
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  description.isEmpty ? 'No details available.' : description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Available Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kMainColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOfferWidget extends StatelessWidget {
  const _EmptyOfferWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 46,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Offers Available',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xff1F2937),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Pull down to refresh and check latest offers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future onDidReceiveLocalNotification(
    int id,
    String title,
    String body,
    String payload,
    ) async {}

Future selectNotification(String payload) async {
  if (payload.isNotEmpty) {}
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  debugPrint('ob notification payload:');
}
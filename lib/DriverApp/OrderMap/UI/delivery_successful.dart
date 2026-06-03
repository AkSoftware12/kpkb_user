import 'dart:async';
import 'dart:math';

import 'package:kpUser/DriverApp/Account/UI/account_page.dart';
import 'package:kpUser/DriverApp/Components/bottom_bar.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:flutter/material.dart';

class DeliverySuccessful extends StatefulWidget {
  final dynamic cartId;
  final dynamic vendorName;
  final dynamic vendorAddress;
  final dynamic userName;
  final dynamic userAddress;
  final dynamic userphone;
  final dynamic vendorlat;
  final dynamic vendorlng;
  final dynamic dlat;
  final dynamic dlng;
  final dynamic userlat;
  final dynamic userlng;
  final dynamic remprice;
  final dynamic paymentstatus;
  final dynamic paymentMethod;

  const DeliverySuccessful({
    super.key,
    this.cartId,
    this.vendorName,
    this.vendorAddress,
    this.userName,
    this.userAddress,
    this.userphone,
    this.vendorlat,
    this.vendorlng,
    this.dlat,
    this.dlng,
    this.userlat,
    this.userlng,
    this.remprice,
    this.paymentstatus,
    this.paymentMethod,
  });

  @override
  State<StatefulWidget> createState() {
    return DeliverySuccessfulState();
  }
}

class DeliverySuccessfulState extends State<DeliverySuccessful> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic userlat;
  dynamic userlng;
  dynamic dlat;
  dynamic dlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic distance;

  Future<void> _listenLocation() async {}

  @override
  void initState() {
    cart_id = widget.cartId;
    vendorName = widget.vendorName;
    vendorAddress = widget.vendorAddress;
    userName = widget.userName;
    userAddress = widget.userAddress;
    userphone = widget.userphone;
    vendorlat = widget.vendorlat;
    vendorlng = widget.vendorlng;
    dlat = widget.dlat;
    dlng = widget.dlng;
    userlat = widget.userlat;
    userlng = widget.userlng;
    remprice = widget.remprice;
    paymentstatus = widget.paymentstatus;
    paymentMethod = widget.paymentMethod;
    super.initState();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    _listenLocation();

    return WillPopScope(
      onWillPop: () async {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return AccountPage();
            },
          ),
          (Route<dynamic> route) => false,
        );
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, size: 24, color: kMainColor),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AccountPage();
                      },
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              title: Text(
                'Order - #${cart_id}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Spacer(flex: 1),
            Padding(
              padding: EdgeInsets.all(60.0),
              child: Image.asset(
                'images/delivery done.png',
                height: 236.7,
                width: 210.7,
              ),
            ),
            Text(
              'Delivered Successfully !',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: kMainTextColor,
                letterSpacing: 0.1,
              ),
            ),
            Text(
              '\nThank you for deliver safely & on time.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: kMainTextColor),
            ),
            Spacer(),
            BottomBar(
              text: 'Back to home',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AccountPage();
                    },
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

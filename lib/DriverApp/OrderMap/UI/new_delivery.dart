import 'dart:convert';
import 'dart:math';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpUser/DriverApp/orderpage/itemdetailspage.dart';
import 'package:kpUser/DriverApp/OrderMap/UI/accepted.dart';
import 'package:kpUser/DriverApp/Components/bottom_bar.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/Multistoreorder.dart';
import 'package:kpUser/DriverApp/beanmodel/orderbean.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NewDeliveryPage extends StatelessWidget {
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
  final dynamic orderId;
  final dynamic itemDetails;

  const NewDeliveryPage({
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
    this.orderId,
    this.itemDetails,
  });

  @override
  Widget build(BuildContext context) {
    return NewDeliveryBody(
      cartId: cartId,
      vendorName: vendorName,
      vendorAddress: vendorAddress,
      userName: userName,
      userAddress: userAddress,
      userphone: userphone,
      vendorlat: vendorlat,
      vendorlng: vendorlng,
      dlat: dlat,
      dlng: dlng,
      userlat: userlat,
      userlng: userlng,
      remprice: remprice,
      paymentstatus: paymentstatus,
      paymentMethod: paymentMethod,
      orderId: orderId,
      itemDetails: itemDetails,
    );
  }
}

class NewDeliveryBody extends StatefulWidget {
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
  final dynamic orderId;
  final dynamic itemDetails;

  const NewDeliveryBody({
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
    this.orderId,
    this.itemDetails,
  });

  @override
  _NewDeliveryBodyState createState() => _NewDeliveryBodyState();
}

class _NewDeliveryBodyState extends State<NewDeliveryBody> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic order_id;

  List<OrderDeatisSub>? orderDeatisSub;
  dynamic distance;
  dynamic currency;

  GoogleMapController? _controller;
  List<LatLng> polylineCoordinates = [];
  final Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  bool _added = false;
  bool _dataLoaded = false;

  List<OrderDetail> orders = [];

  @override
  void initState() {
    super.initState();
    getCurrency();
  }

  getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('curency');
    });
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

  void _loadArguments(BuildContext context) {
    if (_dataLoaded) return;

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
    order_id = widget.orderId;
    orderDeatisSub = widget.itemDetails;

    _dataLoaded = true;

    if (orders.isEmpty) {
      getorders(order_id);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadArguments(context);

    final ProgressDialog pr = ProgressDialog(
      context,
      type: ProgressDialogType.normal,
      isDismissible: false,
      showLogs: true,
    );

    pr.style(
      message: 'Loading please wait...',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress: 0.0,
      maxProgress: 100.0,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      progressTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
      ),
      messageTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
      ),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              'Order - #${cart_id} New',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: TextButton.icon(
                  icon: Icon(
                    Icons.shopping_basket,
                    color: kMainColor,
                    size: 13.0,
                  ),
                  label: Text(
                    'Order Info',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Itemdetail(
                          cartId: '${cart_id}',
                          itemDetails: orders,
                          currency: currency,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: GoogleMap(
                  mapType: MapType.normal,
                  markers: markers,
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      double.parse(vendorlat.toString()),
                      double.parse(vendorlng.toString()),
                    ),
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) async {
                    addPolyLine(polylineCoordinates);
                    setState(() {
                      _controller = controller;
                    });
                  },
                ),
              ),

              Text(
                'Shops Locations',
                style: orderMapAppBarTextStyle.copyWith(
                  fontSize: 20.0,
                  letterSpacing: 0.05,
                  fontWeight: FontWeight.w900,
                ),
              ),

              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400, minHeight: 100),
                child: ListView.builder(
                  itemCount: orders.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.3),
                              child: Image.asset(
                                'images/vegetables_fruitsact.png',
                                height: 42.3,
                                width: 33.7,
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    '${orders[index].vendorName}',
                                    style: orderMapAppBarTextStyle.copyWith(
                                      letterSpacing: 0.07,
                                    ),
                                  ),
                                ),
                                subtitle: Row(
                                  children: <Widget>[
                                    Container(
                                      child: ImageIcon(
                                        AssetImage(
                                          'images/custom/ic_pickup_pointact.png',
                                        ),
                                        size: 13.3,
                                        color: kMainColor,
                                      ),
                                    ),
                                    Container(
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(
                                            width: 160,
                                            child: Text(
                                              '${orders[index].vendorAddress}',
                                              maxLines: 2,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontSize: 10.0,
                                                    letterSpacing: 0.05,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                FittedBox(
                                  fit: BoxFit.fill,
                                  child: Row(
                                    children: <Widget>[
                                      MaterialButton(
                                        onPressed: () {
                                          _getDirection(
                                            'https://www.google.com/maps/search/?api=1&query=${orders[index].vendorLat},${orders[index].vendorLng}',
                                          );
                                        },
                                        color: kMainColor,
                                        textColor: Colors.white,
                                        child: Icon(Icons.navigation, size: 15),
                                        padding: EdgeInsets.all(10),
                                        shape: CircleBorder(),
                                      ),
                                    ],
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.fill,
                                  child: Row(
                                    children: <Widget>[
                                      MaterialButton(
                                        onPressed: () {
                                          _launchURL(
                                            "tel://${orders[index].vendorPhone}",
                                          );
                                        },
                                        color: kMainColor,
                                        textColor: Colors.white,
                                        child: Icon(Icons.phone, size: 15),
                                        padding: EdgeInsets.all(10),
                                        shape: CircleBorder(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(thickness: 1.2),
                      ],
                    );
                  },
                ),
              ),

              ConstrainedBox(
                constraints: BoxConstraints(),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'User Location',
                        style: orderMapAppBarTextStyle.copyWith(
                          fontSize: 20.0,
                          letterSpacing: 0.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 16.3),
                            child: Image.asset(
                              'images/vegetables_fruitsact.png',
                              height: 42.3,
                              width: 33.7,
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                '${userName}',
                                style: orderMapAppBarTextStyle.copyWith(
                                  letterSpacing: 0.07,
                                ),
                              ),
                              subtitle: Row(
                                children: <Widget>[
                                  Container(
                                    child: ImageIcon(
                                      AssetImage(
                                        'images/custom/ic_pickup_pointact.png',
                                      ),
                                      size: 13.3,
                                      color: kMainColor,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        child: Column(
                                          children: <Widget>[
                                            SizedBox(
                                              width: 160,
                                              child: Text(
                                                '${userAddress}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontSize: 10.0,
                                                      letterSpacing: 0.05,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              FittedBox(
                                fit: BoxFit.fill,
                                child: Row(
                                  children: <Widget>[
                                    MaterialButton(
                                      onPressed: () {
                                        _getDirection(
                                          'https://www.google.com/maps/search/?api=1&query=${userlat},${userlng}',
                                        );
                                      },
                                      color: kMainColor,
                                      textColor: Colors.white,
                                      child: Icon(Icons.navigation, size: 15),
                                      padding: EdgeInsets.all(10),
                                      shape: CircleBorder(),
                                    ),
                                  ],
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.fill,
                                child: Row(
                                  children: <Widget>[
                                    MaterialButton(
                                      onPressed: () {
                                        _launchURL("tel://${userphone}");
                                      },
                                      color: kMainColor,
                                      textColor: Colors.white,
                                      child: Icon(Icons.phone, size: 15),
                                      padding: EdgeInsets.all(10),
                                      shape: CircleBorder(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      BottomBar(
                        text: "Mark as Picked",
                        onTap: () {
                          pr.show();
                          hitService(cart_id, pr);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void hitService(cartid, ProgressDialog pr) async {
    var url = delivery_accepted;

    print("API URL ==> $url");
    print("Sending cart_id ==> $cartid");

    var client = http.Client();

    client
        .post(
      Uri.parse(url),
      body: {
        'cart_id': '$cartid',
      },
    )
        .then((value) {

      print("STATUS CODE ==> ${value.statusCode}");
      print("RESPONSE ==> ${value.body}");

      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);

        print("JSON STATUS ==> ${jsonData['status']}");

        if (jsonData['status'].toString() == "1") {
          pr.hide();

          Fluttertoast.showToast(msg: 'Order Accepted New');

          Future.delayed(const Duration(milliseconds: 300), () {
            if (!context.mounted) return;
            print("BEFORE NAVIGATION");
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AcceptedPage(
                  cartId: cartid,
                  vendorName: vendorName,
                  vendorAddress: vendorAddress,
                  vendorlat: vendorlat,
                  vendorlng: vendorlng,
                  dlat: dlat,
                  dlng: dlng,
                  userlat: userlat,
                  userlng: userlng,
                  userName: userName,
                  userAddress: userAddress,
                  userphone: userphone,
                  itemDetails: orderDeatisSub,
                  remprice: remprice,
                  paymentstatus: paymentstatus,
                  paymentMethod: paymentMethod,
                  orderId: order_id,
                ),
              ),
            );
            print("AFTER NAVIGATION");
          });
        }
      }
    }).catchError((e) {
      pr.hide();

      print("ERROR ==> $e");
    });
  }
  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");

    Polyline polyline = Polyline(
      polylineId: id,
      color: kMainColor,
      points: polylineCoordinates,
      width: 5,
    );

    polylines[id] = polyline;
    setState(() {});
  }

  void getorders(orderid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');

    var url = ordersfortodaydetails;
    var client = http.Client();

    client
        .post(
          Uri.parse(url),
          body: {
            'order_id': orderid.toString(),
            'delivery_boy_id': boyId.toString(),
          },
        )
        .then((value) {
          if (value.statusCode == 200) {
            var tagObjsJson = jsonDecode(value.body) as List;

            List<Multistoreorder> tagObjs = tagObjsJson
                .map((tagJson) => Multistoreorder.fromJson(tagJson))
                .toList();

            List<OrderDetail> temp = [];

            tagObjs.forEach((element) {
              element.orderDetails?.forEach((element) async {
                temp.add(element);

                polylineCoordinates.add(
                  LatLng(
                    double.parse(element.vendorLat),
                    double.parse(element.vendorLng),
                  ),
                );

                markers.add(
                  Marker(
                    markerId: MarkerId(element.vendorId.toString()),
                    position: LatLng(
                      double.parse(element.vendorLat),
                      double.parse(element.vendorLng),
                    ),
                    infoWindow: InfoWindow(title: element.vendorName),
                    icon: BitmapDescriptor.defaultMarker,
                  ),
                );

                polylineCoordinates.add(
                  LatLng(
                    double.parse(userlat.toString()),
                    double.parse(userlng.toString()),
                  ),
                );

                markers.add(
                  Marker(
                    markerId: MarkerId(userlng.toString()),
                    position: LatLng(
                      double.parse(userlat.toString()),
                      double.parse(userlng.toString()),
                    ),
                    infoWindow: InfoWindow(title: userName),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                );
              });
            });

            addPolyLine(polylineCoordinates);

            setState(() {
              orders.clear();
              orders = temp;
            });
          }
        })
        .catchError((e) {
          print(e);
        });
  }

  _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (error, stack) {
      print(error);
    }
  }

  _getDirection(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (error, stack) {
      print(error);
    }
  }
}

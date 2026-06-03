import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:kpUser/DriverApp/orderpage/restaurantorderpage/restonwaypage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart' as loc;
import 'package:kpUser/DriverApp/Components/bottom_bar.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/todayrestorder.dart';
import 'package:kpUser/DriverApp/orderpage/restaurantorderpage/rest_slide_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

class AcceptedPageRest extends StatelessWidget {
  final dynamic cartId;
  final dynamic vendorName;
  final dynamic vendorAddress;
  final dynamic userName;
  final dynamic userAddress;
  final dynamic userphone;
  final dynamic vendorlat;
  final dynamic vendorlng;
  final dynamic vendorPhone;
  final dynamic dlat;
  final dynamic dlng;
  final dynamic userlat;
  final dynamic userlng;
  final dynamic remprice;
  final dynamic totalPrice;
  final dynamic paymentstatus;
  final dynamic paymentMethod;
  final dynamic userId;
  final dynamic itemDetails;
  final dynamic addons;

  const AcceptedPageRest({
    super.key,
    this.cartId,
    this.vendorName,
    this.vendorAddress,
    this.userName,
    this.userAddress,
    this.userphone,
    this.vendorlat,
    this.vendorlng,
    this.vendorPhone,
    this.dlat,
    this.dlng,
    this.userlat,
    this.userlng,
    this.remprice,
    this.totalPrice,
    this.paymentstatus,
    this.paymentMethod,
    this.userId,
    this.itemDetails,
    this.addons,
  });

  @override
  Widget build(BuildContext context) {
    return AcceptedBodyRest(
      cartId: cartId,
      vendorName: vendorName,
      vendorAddress: vendorAddress,
      userName: userName,
      userAddress: userAddress,
      userphone: userphone,
      vendorlat: vendorlat,
      vendorlng: vendorlng,
      vendorPhone: vendorPhone,
      dlat: dlat,
      dlng: dlng,
      userlat: userlat,
      userlng: userlng,
      remprice: remprice,
      totalPrice: totalPrice,
      paymentstatus: paymentstatus,
      paymentMethod: paymentMethod,
      userId: userId,
      itemDetails: itemDetails,
      addons: addons,
    );
  }
}

class AcceptedBodyRest extends StatefulWidget {
  final dynamic cartId;
  final dynamic vendorName;
  final dynamic vendorAddress;
  final dynamic userName;
  final dynamic userAddress;
  final dynamic userphone;
  final dynamic vendorlat;
  final dynamic vendorlng;
  final dynamic vendorPhone;
  final dynamic dlat;
  final dynamic dlng;
  final dynamic userlat;
  final dynamic userlng;
  final dynamic remprice;
  final dynamic totalPrice;
  final dynamic paymentstatus;
  final dynamic paymentMethod;
  final dynamic userId;
  final dynamic itemDetails;
  final dynamic addons;

  const AcceptedBodyRest({
    super.key,
    this.cartId,
    this.vendorName,
    this.vendorAddress,
    this.userName,
    this.userAddress,
    this.userphone,
    this.vendorlat,
    this.vendorlng,
    this.vendorPhone,
    this.dlat,
    this.dlng,
    this.userlat,
    this.userlng,
    this.remprice,
    this.totalPrice,
    this.paymentstatus,
    this.paymentMethod,
    this.userId,
    this.itemDetails,
    this.addons,
  });

  @override
  _AcceptedRestBodyState createState() => _AcceptedRestBodyState();
}

class _AcceptedRestBodyState extends State<AcceptedBodyRest> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendor_phone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic total_price;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic user_id;
  List<TodayRestaurantOrderDetails>? orderDeatisSub;
  List<AddonList>? addons;
  dynamic distance;
  dynamic currency;
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  GoogleMapController? _controller;
  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;

  double latitude = 0.0;

  double longitude = 0.0;

  @override
  void initState() {
    getCurrency();
    super.initState();
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

  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
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
    setState(() {
      cart_id = widget.cartId;
      vendorName = widget.vendorName;
      vendorAddress = widget.vendorAddress;
      userName = widget.userName;
      userAddress = widget.userAddress;
      userphone = widget.userphone;
      vendorlat = widget.vendorlat;
      vendorlng = widget.vendorlng;
      vendor_phone = widget.vendorPhone;
      dlat = widget.dlat;
      dlng = widget.dlng;
      userlat = widget.userlat;
      userlng = widget.userlng;
      remprice = widget.remprice;
      total_price = widget.totalPrice;
      paymentstatus = widget.paymentstatus;
      paymentMethod = widget.paymentMethod;
      user_id = widget.userId;
      orderDeatisSub = widget.itemDetails;
      addons = widget.addons;
      distance = calculateDistance(
        double.parse(vendorlat),
        double.parse(vendorlng),
        double.parse(userlat),
        double.parse(userlng),
      ).toStringAsFixed(2);
      latitude = double.parse(vendorlat);
      longitude = double.parse(vendorlng);
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              'Order - #${cart_id}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: TextButton.icon(
                  icon: Icon(
                    isOpen ? Icons.close : Icons.shopping_basket,
                    color: kMainColor,
                    size: 13.0,
                  ),
                  label: Text(
                    isOpen ? 'Close' : 'Order Info',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isOpen)
                        isOpen = false;
                      else
                        isOpen = true;
                    });
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
                  markers: Set<Marker>.of(markers.values),
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      double.parse(vendorlat),
                      double.parse(vendorlng),
                    ),
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) async {
                    _addMarker(
                      LatLng(double.parse(vendorlat), double.parse(vendorlng)),
                      "source",
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    );
                    _addMarker(
                      LatLng(double.parse(userlat), double.parse(userlng)),
                      "dest",
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    );
                    getDirections();

                    setState(() {
                      _controller = controller;
                    });
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
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
                            title: Text(
                              '${vendorName}',
                              style: orderMapAppBarTextStyle.copyWith(
                                letterSpacing: 0.07,
                              ),
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                Text(
                                  '${distance}km ',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                        color: kMainColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '(20 min)',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                        color: Color(0xffc1c1c1),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: TextButton(
                            onPressed: () {
                              _getDirection(
                                'https://www.google.com/maps/search/?api=1&query=${vendorlat},${vendorlng}',
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: kMainColor,
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.navigation,
                                  color: kWhiteColor,
                                  size: 14.0,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Direction',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: kWhiteColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: kCardBackgroundColor, thickness: 1.0),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            left: 36.0,
                            bottom: 6.0,
                            top: 6.0,
                            right: 20.0,
                          ),
                          child: ImageIcon(
                            AssetImage('images/custom/ic_pickup_pointact.png'),
                            size: 13.3,
                            color: kMainColor,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${vendorName}',
                                style: orderMapAppBarTextStyle.copyWith(
                                  fontSize: 10.0,
                                  letterSpacing: 0.05,
                                ),
                              ),
                              SizedBox(height: 5.0),
                              Text(
                                '${vendorAddress}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 10.0,
                                      letterSpacing: 0.05,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        FittedBox(
                          fit: BoxFit.fill,
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.phone,
                                  color: kMainColor,
                                  size: 15.0,
                                ),
                                onPressed: () {
                                  _launchURL("tel://${vendor_phone}");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.0),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            left: 36.0,
                            bottom: 12.0,
                            top: 12.0,
                            right: 20.0,
                          ),
                          child: ImageIcon(
                            AssetImage('images/custom/ic_droppointact.png'),
                            size: 13.3,
                            color: kMainColor,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${userName}',
                                style: orderMapAppBarTextStyle.copyWith(
                                  fontSize: 10.0,
                                  letterSpacing: 0.05,
                                ),
                              ),
                              SizedBox(height: 5.0),
                              SizedBox(
                                width: 230,
                                child: Text(
                                  '${userAddress}',
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 10.0,
                                        letterSpacing: 0.05,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        FittedBox(
                          fit: BoxFit.fill,
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.navigation,
                                  color: kMainColor,
                                  size: 18.0,
                                ),
                                onPressed: () {
                                  _getDirection(
                                    'https://www.google.com/maps/search/?api=1&query=${userlat},${userlng}',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    BottomBar(
                      text: "Marked as Picked",
                      onTap: () {
                        pr.show();
                        print("cart_id is : $cart_id");
                        hitService(cart_id, pr);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          isOpen
              ? OrderInfoContainerRest(
                  orderDeatisSub!,
                  remprice,
                  paymentMethod,
                  paymentstatus,
                  currency,
                  addons!,
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  // void hitService(cartid, ProgressDialog pr) async {
  //   try {
  //     pr.show();
  //
  //     var url = resturant_delivery_out;
  //     var client = http.Client();
  //
  //     print("API URL: $url");
  //     print("SENDING cart_id: $cartid");
  //
  //     final response = await client.post(
  //       Uri.parse(url),
  //       body: {'cart_id': cartid.toString()},
  //     );
  //
  //     print("STATUS CODE: ${response.statusCode}");
  //     print("RESPONSE: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       var jsonData = jsonDecode(response.body);
  //
  //       if (jsonData['status'] == "1") {
  //         pr.hide();
  //
  //         Fluttertoast.showToast(msg: "Order Picked");
  //
  //           "cart_id": cart_id,
  //           "vendorName": vendorName,
  //           "vendorAddress": vendorAddress,
  //           "vendorlat": vendorlat,
  //           "vendorlng": vendorlng,
  //           "vendor_phone": vendor_phone,
  //           "dlat": dlat,
  //           "dlng": dlng,
  //           "userlat": userlat,
  //           "userlng": userlng,
  //           "userName": userName,
  //           "userAddress": userAddress,
  //           "userphone": userphone,
  //           "itemDetails": orderDeatisSub,
  //           "remprice": remprice,
  //           "total_price": total_price,
  //           "paymentstatus": paymentstatus,
  //           "paymentMethod": paymentMethod,
  //           "user_id": user_id,
  //           "ui_type": "2",
  //           "addons": addons
  //         });
  //       } else {
  //         pr.hide();
  //         Fluttertoast.showToast(msg: "Store error. Try again.");
  //       }
  //     } else {
  //       pr.hide();
  //       Fluttertoast.showToast(msg: "Server error ${response.statusCode}");
  //     }
  //
  //   } catch (e) {
  //     pr.hide();
  //     print("API ERROR: $e");
  //     Fluttertoast.showToast(msg: "Network error");
  //   }
  // }

  void hitService(cartid, ProgressDialog pr) async {
    var url = resturant_delivery_out;
    var client = http.Client();
    client
        .post(Uri.parse(url), body: {'cart_id': '${cartid}'})
        .then((value) {
          if (value.statusCode == 200) {
            var jsonData = jsonDecode(value.body);
            if (jsonData['status'] == "1") {
              pr.hide();
              Fluttertoast.showToast(
                msg: 'Order Picked',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black26,
                textColor: Colors.white,
                fontSize: 14.0,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OnWayPageRest(
                    cartId: cart_id,
                    vendorName: vendorName,
                    vendorAddress: vendorAddress,
                    vendorlat: vendorlat,
                    vendorlng: vendorlng,
                    vendorPhone: vendor_phone,
                    dlat: dlat,
                    dlng: dlng,
                    userlat: userlat,
                    userlng: userlng,
                    userName: userName,
                    userAddress: userAddress,
                    userphone: userphone,
                    itemDetails: orderDeatisSub,
                    remprice: remprice,
                    totalPrice: total_price,
                    paymentstatus: paymentstatus,
                    paymentMethod: paymentMethod,
                    userId: user_id,
                    addons: addons,
                  ),
                ),
              );
            } else {
              pr.hide();
              Fluttertoast.showToast(
                msg: 'Some error occurred please contact with store.',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black26,
                textColor: Colors.white,
                fontSize: 14.0,
              );
            }
          }
        })
        .catchError((e) {
          pr.hide();
          print(e);
        });
  }

  _launchURL(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }

  _getDirection(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
    );
    markers[markerId] = marker;
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    // PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    //  apikey,
    //   PointLatLng(double.parse(vendorlat), double.parse(vendorlng)),
    //   PointLatLng(double.parse(userlat), double.parse(userlng)),
    //   travelMode: TravelMode.driving,
    // );
    //
    // if (result.points.isNotEmpty) {
    //   result.points.forEach((PointLatLng point) {
    //     polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    //   });
    // } else {
    //   print(result.errorMessage);
    // }
    addPolyLine(polylineCoordinates);
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
}

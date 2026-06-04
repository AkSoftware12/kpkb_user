import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kpUser/HomeOrderAccount/Home/UI/slide_up_panel.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Themes/colors.dart';
import '../../../Themes/constantfile.dart';
import '../../../Themes/style.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/orderbean.dart';
import '../../../cancelproduct/cancelproduct.dart';
import '../../home_order_account.dart';

class OrderMapPage extends StatelessWidget {
  final String? instruction;
  final String? pageTitle;
  final OngoingOrders? ongoingOrders;
  final dynamic currency;
  final dynamic user_id;

  OrderMapPage(
      {this.instruction,
        this.pageTitle,
        this.ongoingOrders,
        this.currency,
        this.user_id});

  @override
  Widget build(BuildContext context) {
    return OrderMap(pageTitle!, ongoingOrders!, currency, user_id);
  }
}

class OrderMap extends StatefulWidget {
  final String pageTitle;
  OngoingOrders ongoingOrders;
  final dynamic currency;
  final dynamic user_id;

  OrderMap(this.pageTitle, this.ongoingOrders, this.currency, this.user_id);

  @override
  _OrderMapState createState() => _OrderMapState(user_id);
}

class _OrderMapState extends State<OrderMap> {
  bool showAction = false;
  double _destLatitude = 30.3165, _destLongitude = 78.0322;
  double _originLatitude = 0.0, _originLongitude = 0.0;
  final loc.Location location = loc.Location();
  GoogleMapController? _controller;
  Timer? timer;

  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;
  final dynamic user_id;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  _OrderMapState(this.user_id);

  @override
  void initState() {
    super.initState();
    _destLatitude = double.parse(
        double.parse((widget.ongoingOrders.delivery_lat.toString()))
            .toStringAsFixed(4));
    _destLongitude = double.parse(
        double.parse((widget.ongoingOrders.delivery_lng.toString()))
            .toStringAsFixed(4));

    _originLatitude = double.parse(
        double.parse((widget.ongoingOrders.vendor_lat.toString()))
            .toStringAsFixed(4));
    _originLongitude = double.parse(
        double.parse((widget.ongoingOrders.vendor_lng.toString()))
            .toStringAsFixed(4));
    //_listenLocation();
    getDirections();
    timer = Timer.periodic(Duration(seconds: 3), (Timer t) => orderdetail());
  }

  @override
  void dispose() {
    timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance
          .collection('location')
          .doc(user_id.toString())
          .set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': 'john'
      });
      // _originLatitude = currentlocation.latitude!;
      // _originLongitude = currentlocation.longitude!;
    });
  }

  _getLocation() async {
    try {
      await FirebaseFirestore.instance
          .collection('location')
          .doc(user_id.toString())
          .set({
        'latitude': double.parse(
            double.parse((widget.ongoingOrders.vendor_lat.toString()))
                .toStringAsFixed(4)),
        'longitude': double.parse(
            double.parse((widget.ongoingOrders.vendor_lng.toString()))
                .toStringAsFixed(4)),
        'name': 'john'
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> orderdetail() async {
    print("order Details");

    final preferences = await SharedPreferences.getInstance();

    final Uri myUri = Uri.parse(orderdetails);

    try {
      final response = await http.post(
        myUri,
        body: {
          'user_id': preferences.getInt('user_id').toString(),
          'cart_id': widget.ongoingOrders.cart_id.toString(),
        },
      );

      print(response.body);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        List<dynamic> tagObjsJson = [];

        if (decoded is List) {
          tagObjsJson = decoded;
        } else if (decoded is Map<String, dynamic>) {
          tagObjsJson = decoded['data'] is List ? decoded['data'] : [];
        }

        if (tagObjsJson.isNotEmpty) {
          final List<OngoingOrders> orders = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();

          if (!mounted) return;

          setState(() {
            widget.ongoingOrders = orders[0];
            widget.ongoingOrders.order_status = orders[0].order_status;
          });
        } else {
          print("Order detail empty data");
        }
      }
    } catch (e) {
      print("Order detail error: $e");
    }
  }

  Future<void> openWhatsAppChat() async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '8178218314',
      queryParameters: {
        'text': '',
      },
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
              return HomeOrderAccount(0, 1);
            }), (Route<dynamic> route) => true);
        return true;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: AppBar(
            titleSpacing: 0.0,
            backgroundColor: Colors.white,
            title: Text(
              'Order #${widget.ongoingOrders.cart_id}',
              style: TextStyle(
                  fontSize: 18.sp,
                  color: black_color,
                  fontWeight: FontWeight.w400),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 10.w, top: 10.h, bottom: 10.h),
                child: TextButton(
                  onPressed: () {
                    orderdetail();
                  },
                  child: Text(
                    'Refresh',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: kMainColor,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: (widget.ongoingOrders.order_status == "Completed")
            ? Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 0.sp),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              // openWhatsAppChat();
                            },
                            child: Image.asset("images/map.png",
                                width: MediaQuery.of(context).size.width,
                                alignment: Alignment.center,
                                fit: BoxFit.fill),
                          ),
                        ),
                      ),
                      (widget.ongoingOrders.order_status == "Completed")
                          ? Text(
                        "Completed",
                        style: TextStyle(fontSize: 32.sp),
                      )
                          : Text(
                        "Waiting for order to be picked...",
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0.0,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      color: white_color,
                      width: MediaQuery.of(context).size.width,
                      child: PreferredSize(
                        preferredSize: Size.fromHeight(0.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 16.3.w),
                                  child: Image.asset(
                                    'images/maincategory/vegetables_fruitsact.png',
                                    height: 42.3.h,
                                    width: 33.7.w,
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text(
                                      widget.pageTitle,
                                      style: orderMapAppBarTextStyle
                                          .copyWith(letterSpacing: 0.07),
                                    ),
                                    subtitle: Text(
                                      (widget.ongoingOrders
                                          .delivery_date !=
                                          "null" &&
                                          widget.ongoingOrders
                                              .time_slot !=
                                              "null" &&
                                          widget.ongoingOrders
                                              .delivery_date !=
                                              null &&
                                          widget.ongoingOrders
                                              .time_slot !=
                                              null)
                                          ? '${widget.ongoingOrders.delivery_date} | ${widget.ongoingOrders.time_slot}'
                                          : '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                          fontSize: 11.7.sp,
                                          letterSpacing: 0.06,
                                          color: Color(0xffc1c1c1)),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${widget.ongoingOrders.order_status}',
                                          style: orderMapAppBarTextStyle
                                              .copyWith(color: kMainColor),
                                        ),
                                        SizedBox(height: 7.h),
                                        Text(
                                          '${widget.ongoingOrders.data.length} items | ${widget.currency} ${widget.ongoingOrders.new_price}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                              fontSize: 11.7.sp,
                                              letterSpacing: 0.06,
                                              color:
                                              Color(0xffc1c1c1)),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Divider(
                              color: kCardBackgroundColor,
                              thickness: 1.0,
                            ),
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 36.w,
                                      bottom: 6.h,
                                      top: 6.h,
                                      right: 12.w),
                                  child: ImageIcon(
                                    AssetImage(
                                        'images/custom/ic_pickup_pointact.png'),
                                    size: 13.3.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${widget.ongoingOrders.data[0].vendor_loc.toString()}'
                                        '\t',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                        fontSize: 10.sp,
                                        letterSpacing: 0.05),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 36.w,
                                      bottom: 12.h,
                                      top: 12.h,
                                      right: 12.w),
                                  child: ImageIcon(
                                    AssetImage(
                                        'images/custom/ic_droppointact.png'),
                                    size: 13.3.sp,
                                    color: kMainColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${widget.ongoingOrders.address}\t',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                        fontSize: 10.sp,
                                        letterSpacing: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SlideUpPanel(widget.ongoingOrders, widget.currency),
                ],
              ),
            ),
            Container(
              height: 60.h,
              color: kCardBackgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${widget.ongoingOrders.data.length} items  |  ${widget.currency} ${widget.ongoingOrders.price}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(
                        fontWeight: FontWeight.w500, fontSize: 15.sp),
                  ),
                ],
              ),
            )
          ],
        )
            : Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 0.sp),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              // openWhatsAppChat();
                            },
                            child: Image.asset(
                                "assets/order_tracking_image.jpg",
                                width: MediaQuery.of(context).size.width,
                                alignment: Alignment.center,
                                fit: BoxFit.fill),
                          ),
                        ),
                      ),
                      (widget.ongoingOrders.order_status == "Completed")
                          ? Text(
                        "Completed",
                        style: TextStyle(fontSize: 32.sp),
                      )
                          : Text(
                        "Waiting for order to be picked...",
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0.0,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      color: white_color,
                      width: MediaQuery.of(context).size.width,
                      child: PreferredSize(
                        preferredSize: Size.fromHeight(0.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 16.3.w),
                                  child: Image.asset(
                                    'images/maincategory/vegetables_fruitsact.png',
                                    height: 42.3.h,
                                    width: 33.7.w,
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text(
                                      '${widget.pageTitle}',
                                      style: orderMapAppBarTextStyle
                                          .copyWith(letterSpacing: 0.07),
                                    ),
                                    subtitle: Text(
                                      (widget.ongoingOrders
                                          .delivery_date !=
                                          "null" &&
                                          widget.ongoingOrders
                                              .time_slot !=
                                              "null" &&
                                          widget.ongoingOrders
                                              .delivery_date !=
                                              null &&
                                          widget.ongoingOrders
                                              .time_slot !=
                                              null)
                                          ? '${widget.ongoingOrders.delivery_date} | ${widget.ongoingOrders.time_slot}'
                                          : '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                          fontSize: 11.7.sp,
                                          letterSpacing: 0.06,
                                          color: Colors.black),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          '${widget.ongoingOrders.order_status}',
                                          style: orderMapAppBarTextStyle
                                              .copyWith(
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          '${widget.ongoingOrders.data.length} items | ${widget.currency} ${widget.ongoingOrders.new_price}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                            fontSize: 11.7.sp,
                                            letterSpacing: 0.06,
                                            color:
                                           Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Divider(
                              color: kCardBackgroundColor,
                              thickness: 1.0,
                            ),
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 36.w,
                                      bottom: 6.h,
                                      top: 6.h,
                                      right: 12.w),
                                  child: ImageIcon(
                                    AssetImage(
                                        'images/custom/ic_pickup_pointact.png'),
                                    size: 13.3.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${widget.ongoingOrders.data[0].vendor_loc.toString()}'
                                        '\t',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                        fontSize: 10.sp,
                                        letterSpacing: 0.05),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 36.w,
                                      bottom: 12.h,
                                      top: 12.h,
                                      right: 12.w),
                                  child: ImageIcon(
                                    AssetImage(
                                        'images/custom/ic_droppointact.png'),
                                    size: 13.3.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${widget.ongoingOrders.address}\t',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                        fontSize: 10.sp,
                                        letterSpacing: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SlideUpPanel(widget.ongoingOrders, widget.currency),
                ],
              ),
            ),
            Container(
              height: 60.h,
              color: kCardBackgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${widget.ongoingOrders.data.length} items  |  ${widget.currency} ${widget.ongoingOrders.new_price}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(
                        fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: widget.ongoingOrders.payment_status
                          .toString()
                          .toLowerCase() ==
                          "success"
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: widget.ongoingOrders.payment_status
                            .toString()
                            .toLowerCase() ==
                            "success"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.ongoingOrders.payment_status
                              .toString()
                              .toLowerCase() ==
                              "success"
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 12.sp,
                          color: widget.ongoingOrders.payment_status
                              .toString()
                              .toLowerCase() ==
                              "success"
                              ? Colors.green
                              : Colors.orange,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          widget.ongoingOrders.payment_status
                              .toString()
                              .toLowerCase() ==
                              "success"
                              ? "Paid"
                              : "POD",
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.ongoingOrders.payment_status
                                .toString()
                                .toLowerCase() ==
                                "success"
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
    Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  void mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    _originLatitude = snapshot.data!.docs
        .singleWhere((element) => element.id == widget.user_id)['latitude'];
    _originLongitude = snapshot.data!.docs
        .singleWhere((element) => element.id == widget.user_id)['longitude'];

    Timer(Duration(minutes: 4), () async {
      await _controller!
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(
            _originLatitude,
            _originLongitude,
          ),
          zoom: 15)));
    });

    getDirections();
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];

    _addMarker(LatLng(_originLatitude, _originLongitude), "source",
        await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(10, 10)), 'assets/delivery.png'));
    _addMarker(LatLng(_destLatitude, _destLongitude), "dest",
        BitmapDescriptor.defaultMarkerWithHue(30));

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
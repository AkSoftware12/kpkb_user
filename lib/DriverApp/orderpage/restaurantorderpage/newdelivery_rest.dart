import 'dart:convert';
import 'dart:math';

import 'package:kpUser/DriverApp/orderpage/restaurantorderpage/acceptpagerest.dart';
import 'package:kpUser/DriverApp/Components/bottom_bar.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/todayrestorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class NewDeliveryRestPage extends StatelessWidget {
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
  final dynamic userId;
  final dynamic itemDetails;
  final dynamic addons;

  const NewDeliveryRestPage({
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
    this.userId,
    this.itemDetails,
    this.addons,
  });

  @override
  Widget build(BuildContext context) {
    return NewDeliveryRestBody(
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
      userId: userId,
      itemDetails: itemDetails,
      addons: addons,
    );
  }
}

class NewDeliveryRestBody extends StatefulWidget {
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
  final dynamic userId;
  final dynamic itemDetails;
  final dynamic addons;

  const NewDeliveryRestBody({
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
    this.userId,
    this.itemDetails,
    this.addons,
  });

  @override
  _NewDeliveryRestBodyState createState() => _NewDeliveryRestBodyState();
}

class _NewDeliveryRestBodyState extends State<NewDeliveryRestBody> {
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
  dynamic user_id;
  List<TodayRestaurantOrderDetails>? orderDeatisSub;
  List<AddonList>? addons;
  dynamic distance;

  GoogleMapController? _controller;
  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;

  @override
  void initState() {
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
      dlat = widget.dlat;
      dlng = widget.dlng;
      userlat = widget.userlat;
      userlng = widget.userlng;
      remprice = widget.remprice;
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
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              'New Order - #${cart_id}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      body: Column(
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

                setState(() {
                  _controller = controller;
                });

                getDirections();
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
                              '${distance} km',
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
                    Column(
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

                        SizedBox(
                          width: 250,
                          child: Text(
                            '${vendorAddress}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 10.0, letterSpacing: 0.05),
                          ),
                        ),
                        // Text(
                        //   '${vendorAddress}',
                        //   style: Theme.of(context)
                        //       .textTheme
                        //       .bodySmall
                        //       ?.copyWith(fontSize: 10.0, letterSpacing: 0.05),
                        // ),
                      ],
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
                    Column(
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
                          width: 250,
                          child: Text(
                            '${userAddress}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 10.0, letterSpacing: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                BottomBar(
                  text: "Accept Delivery",
                  onTap: () {
                    pr.show();
                    hitServiceRest(cart_id, pr);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void hitServiceRest(cartid, ProgressDialog pr) async {
    var url = delivery_accepted_by_dboy;
    var client = http.Client();
    client
        .post(Uri.parse(url), body: {'cart_id': '${cartid}'})
        .then((value) {
          if (value.statusCode == 200) {
            var jsonData = jsonDecode(value.body);
            if (jsonData['status'] == "1") {
              pr.hide();
              Fluttertoast.showToast(
                msg: 'Order Accepted',
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
                  builder: (_) => AcceptedPageRest(
                    cartId: cart_id,
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
                    userId: user_id,
                    addons: addons,
                  ),
                ),
              );
            } else {
              pr.hide();
              Fluttertoast.showToast(
                msg: 'Order Not Accepted',
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

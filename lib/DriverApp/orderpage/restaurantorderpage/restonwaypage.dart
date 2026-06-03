import 'dart:async';
import 'dart:math';

import 'package:kpUser/DriverApp/signature/signatureview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kpUser/DriverApp/Components/bottom_bar.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:kpUser/DriverApp/beanmodel/todayrestorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OnWayPageRest extends StatelessWidget {
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

  const OnWayPageRest({
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
    return OnWayBodyRest(
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

class OnWayBodyRest extends StatefulWidget {
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

  const OnWayBodyRest({
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
  _OnWayBodyRestState createState() => _OnWayBodyRestState();
}

class _OnWayBodyRestState extends State<OnWayBodyRest> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic vendor_phone;
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

  // final loc.Location location = loc.Location();
  // StreamSubscription<loc.LocationData>? _locationSubscription;
  GoogleMapController? _controller; // FIX: nullable controller

  List<LatLng> polylineCoordinates = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  bool _added = false;

  double? latitude;
  double? longitude;

  bool _initializedArgs = false; // FIX: to avoid reading args every build
  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    getCurrency();
    // _getLocation();
    // _listenLocation(); // enable if you want live updates from device
  }

  // FIX: ModalRoute arguments ko yahan parse kiya, build ke andar setState nahi
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
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

      try {
        distance = calculateDistance(
          double.parse(vendorlat.toString()),
          double.parse(vendorlng.toString()),
          double.parse(userlat.toString()),
          double.parse(userlng.toString()),
        ).toStringAsFixed(2);
      } catch (_) {
        distance = '0.0';
      }

      _initializedArgs = true;
    }
  }

  @override
  void dispose() {
    // FIX: dispose async nahi hota, yahan subscription cancel
    // _locationSubscription?.cancel();
    super.dispose();
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
      progressWidget: const CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress: 0.0,
      maxProgress: 100.0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      progressTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
      ),
      messageTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
      ),
    );

    // FIX: agar arguments abhi tak init nahi hue to loader dikhao
    // if (!_initializedArgs) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              'Order - #$cart_id',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 20.0,
                ),
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
                      isOpen = !isOpen;
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
                      double.tryParse(vendorlat.toString()) ?? 0.0,
                      double.tryParse(vendorlng.toString()) ?? 0.0,
                    ),
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) async {
                    _controller = controller;
                    _added = true;

                    _addMarker(
                      LatLng(
                        double.tryParse(vendorlat.toString()) ?? 0.0,
                        double.tryParse(vendorlng.toString()) ?? 0.0,
                      ),
                      "source",
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    );
                    _addMarker(
                      LatLng(
                        double.tryParse(userlat.toString()) ?? 0.0,
                        double.tryParse(userlng.toString()) ?? 0.0,
                      ),
                      "dest",
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    );

                    await getDirections(); // FIX: call after controller ready
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(left: 16.3),
                          child: Image(
                            image: AssetImage(
                              'images/vegetables_fruitsact.png',
                            ),
                            height: 42.3,
                            width: 33.7,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              '$userName',
                              style: orderMapAppBarTextStyle.copyWith(
                                letterSpacing: 0.07,
                              ),
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                Text(
                                  '$distance km ',
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
                                        color: const Color(0xffc1c1c1),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: kMainColor,
                            ),
                            onPressed: () {
                              _getDirection(
                                'https://www.google.com/maps/search/?api=1&query=$userlat,$userlng',
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.navigation,
                                  color: kWhiteColor,
                                  size: 14.0,
                                ),
                                const SizedBox(width: 4.0),
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
                                '$vendorName',
                                style: orderMapAppBarTextStyle.copyWith(
                                  fontSize: 10.0,
                                  letterSpacing: 0.05,
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                '$vendorAddress',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 10.0,
                                      letterSpacing: 0.05,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
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
                                  _launchURL("tel://$vendor_phone");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
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
                              '$userName',
                              style: orderMapAppBarTextStyle.copyWith(
                                fontSize: 10.0,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 1.6,
                              child: Text(
                                '$userAddress',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 10.0,
                                      letterSpacing: 0.05,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
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
                                  _launchURL("tel://$userphone");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    BottomBar(
                      text: "Mark as Delivered",
                      onTap: () async {
                        debugPrint('Ravi');
                        // await FirebaseFirestore.instance.collection('location').doc(user_id.toString()).delete();
                        // _locationSubscription?.cancel();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignatureView(
                              cartId: cart_id,
                              vendorName: vendorName,
                              vendorAddress: vendorAddress,
                              vendorlat: vendorlat,
                              vendorlng: vendorlng,
                              dlat: dlat,
                              dlng: dlng,
                              userName: userName,
                              userAddress: userAddress,
                              userphone: userphone,
                              remprice: remprice,
                              totalPrice: total_price,
                              paymentstatus: paymentstatus,
                              paymentMethod: paymentMethod,
                              uiType: "2",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Agar order info panel chahiye to yahan show karo:
          // if (isOpen && orderDeatisSub != null && addons != null)
          //   OrderInfoContainerRest(
          //     orderDeatisSub!,
          //     remprice,
          //     paymentMethod,
          //     paymentstatus,
          //     currency,
          //     addons!,
          //   ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        debugPrint('Could not launch $url');
      }
    } catch (error, stack) {
      debugPrint('Launch error: $error\n$stack');
    }
  }

  Future<void> _getDirection(String url) async {
    await _launchURL(url);
  }

  // Future<void> _getLocation() async {
  //   try {
  //     // FIX: permission handle
  //     bool serviceEnabled = await location.serviceEnabled();
  //     if (!serviceEnabled) {
  //       serviceEnabled = await location.requestService();
  //       if (!serviceEnabled) return;
  //     }
  //
  //     loc.PermissionStatus permissionGranted = await location.hasPermission();
  //     if (permissionGranted == loc.PermissionStatus.denied) {
  //       permissionGranted = await location.requestPermission();
  //       if (permissionGranted != loc.PermissionStatus.granted) return;
  //     }
  //
  //     final loc.LocationData locationResult = await location.getLocation();
  //     latitude = locationResult.latitude ?? 0.0;
  //     longitude = locationResult.longitude ?? 0.0;
  //     setState(() {});
  //   } catch (e) {
  //     debugPrint('Location error: $e');
  //   }
  // }
  //
  // Future<void> _listenLocation() async {
  //   _locationSubscription = location.onLocationChanged.handleError((onError) {
  //     debugPrint('Location stream error: $onError');
  //     _locationSubscription?.cancel();
  //     _locationSubscription = null;
  //   }).listen((loc.LocationData currentlocation) async {
  //     latitude = currentlocation.latitude ?? 0.0;
  //     longitude = currentlocation.longitude ?? 0.0;
  //
  //     try {
  //       await FirebaseFirestore.instance
  //           .collection('location')
  //           .doc(user_id.toString())
  //           .set(
  //         {
  //           'latitude': latitude,
  //           'longitude': longitude,
  //           'name': 'john',
  //         },
  //         SetOptions(merge: true),
  //       );
  //     } catch (e) {
  //       debugPrint('Firestore location write error: $e');
  //     }
  //
  //     if (_added && _controller != null && latitude != null && longitude != null) {
  //       _controller!.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(
  //             target: LatLng(latitude!, longitude!),
  //             zoom: 14,
  //           ),
  //         ),
  //       );
  //     }
  //   });
  // }

  void _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    final markerId = MarkerId(id);
    final marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
    );
    markers[markerId] = marker;
    setState(() {});
  }

  Future<void> mymap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    if (latitude == null || longitude == null) return;

    _addMarker(
      LatLng(latitude!, longitude!),
      "source",
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    _addMarker(
      LatLng(
        double.tryParse(userlat.toString()) ?? 0.0,
        double.tryParse(userlng.toString()) ?? 0.0,
      ),
      "dest",
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude!, longitude!), zoom: 12),
        ),
      );
    }
  }

  Future<void> getDirections() async {
    if (latitude == null ||
        longitude == null ||
        userlat == null ||
        userlng == null) {
      // Location not ready yet
      return;
    }

    polylineCoordinates.clear();

    // Agar Google Directions API use karna ho to yahan uncomment karo
    /*
    final result = await polylinePoints.getRouteBetweenCoordinates(
      apikey,
      PointLatLng(latitude!, longitude!),
      PointLatLng(
        double.parse(userlat.toString()),
        double.parse(userlng.toString()),
      ),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (final PointLatLng point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      debugPrint('Polyline error: ${result.errorMessage}');
    }
    */

    // Agar API nahi hai to sirf straight line polyline bhi dikha sakte ho:
    polylineCoordinates.add(LatLng(latitude!, longitude!));
    polylineCoordinates.add(
      LatLng(
        double.parse(userlat.toString()),
        double.parse(userlng.toString()),
      ),
    );

    addPolyLine(polylineCoordinates);
  }

  void addPolyLine(List<LatLng> coords) {
    final id = PolylineId("poly");
    final polyline = Polyline(
      polylineId: id,
      color: kMainColor,
      points: coords,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }
}

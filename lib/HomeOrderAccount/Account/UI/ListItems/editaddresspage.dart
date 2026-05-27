import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


import '../../../../Components/custom_appbar.dart';
import '../../../../Themes/colors.dart';
import '../../../../Themes/constantfile.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/address.dart';

class EditAddresspage extends StatefulWidget {
  final dynamic lat;
  final dynamic lng;
  final dynamic pincode;
  final dynamic houseno;
  final dynamic address;
  final dynamic state;
  final dynamic address_id;
  final dynamic vendorid;
  final dynamic area_id;
  final dynamic city_id;
  final dynamic type;

  EditAddresspage(this.lat,this.lng,this.pincode, this.houseno, this.address, this.state,
      this.address_id, this.vendorid, this.city_id, this.area_id, this.type);

  @override
  State<StatefulWidget> createState() {
    return EditAddresspageState(lat,lng,pincode, houseno, address, state, type);
  }
}

class EditAddresspageState extends State<EditAddresspage> {
  var pincodeController = TextEditingController();
  var houseController = TextEditingController();
  var streetController = TextEditingController();
  var street1Controller = TextEditingController();
  var stateController = TextEditingController();

  List<CityList> cityListt = [];
  List<AreaList> areaList = [];

  List<String> addressTyp = [
    'Home',
    'Office',
    'Other',
  ];
  String selectCity = 'Select city';
  String addressType = 'Select address type';
  String selectArea = 'Select near by area';

  bool showDialogBox = false;

  // Error flags for validation
  bool houseError = false;
  bool addressTypeError = false;
  bool cityError = false;

  dynamic selectAreaId;
  dynamic selectCityId;
  dynamic lat;
  dynamic lng;
  CameraPosition? kGooglePlex;


  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  bool isCard = false;
  Completer<GoogleMapController> _controller = Completer();

  var isVisible = false;

  var currentAddress = '';
  var message = '';

  EditAddresspageState(lat,lng, pincode, houseno, address, state, type) {
    pincodeController.text = '${pincode}';
    houseController.text = '${houseno}';
    stateController.text = state;
    address = address.replaceAll('${pincode},', '');
    address = address.replaceAll('${pincode}', '');
    address = address.replaceAll('${houseno},', '');
    address = address.replaceAll('${state},', '');
    streetController.text = address;
    addressType = type;
    this.lat = double.parse(lat);
    this.lng = double.parse(lng);
  }
  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {

      message = prefs.getString("message")!;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();

    getCityList();
  }
  Future<void> _goToTheLake(lat, lng) async {
    final CameraPosition _kLake = CameraPosition(
        target: LatLng(lat, lng),
        zoom: 14.151926040649414);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));

  }

  void getPlaces(context) async {
    final Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      onError: onError,
      mode: Mode.overlay, // or Mode.fullscreen
      language: 'en',
      components: [Component(Component.country, 'in')],
    );

    if (p != null) displayPrediction(p);
  }
  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.errorMessage ?? 'Unknown error'),
      ),
    );
  }

  Future<Null> displayPrediction(Prediction p) async {
    GoogleMapsPlaces _places = GoogleMapsPlaces(
      apiKey: apiKey,
      apiHeaders: await GoogleApiHeaders().getHeaders(),
    );
    PlacesDetailsResponse detail =
    await _places.getDetailsByPlaceId(p.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    _getCameraMoveLocation(LatLng(lat, lng));
    print("${p.description} - $lat/$lng");

    final marker = Marker(
      markerId: MarkerId('location'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarker,
    );
    setState(() {
      markers[MarkerId('location')] = marker;
      _goToTheLake(lat, lng);
    });

  }

  void _getLocation(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnabled) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        Timer(const Duration(seconds: 1), () async {
          double lat = position.latitude;
          double lng = position.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));

          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty) {
              Placemark placemark = placemarks[0];
              setState(() {
                houseController.text = placemark.subThoroughfare ?? '';
                streetController.text = placemark.street ?? '';
                stateController.text = placemark.administrativeArea ?? '';
                pincodeController.text = placemark.postalCode ?? '';
                currentAddress = [
                  placemark.name,
                  placemark.subThoroughfare,
                  placemark.street,
                  placemark.subLocality,
                  placemark.locality,
                  placemark.administrativeArea,
                  placemark.postalCode,
                  placemark.country
                ].where((e) => e != null && e.isNotEmpty).join(', ');
              });
              _goToTheLake(lat, lng);
            } else {
            }
          } catch (e) {
          }
        });
      } else {
        await Geolocator.openLocationSettings().then((value) {
          if (value) {
            _getLocation(context);
          } else {
            Fluttertoast.showToast(
                msg: 'Location permission is required!',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.black26,
                textColor: Colors.white,
                fontSize: 14.0);
          }
        }).catchError((e) {
          Fluttertoast.showToast(
              msg: 'Location permission is required!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.black26,
              textColor: Colors.white,
              fontSize: 14.0);
        });
      }
    } else if (permission == LocationPermission.denied) {
      LocationPermission permissiond = await Geolocator.requestPermission();
      if (permissiond == LocationPermission.whileInUse ||
          permissiond == LocationPermission.always) {
        _getLocation(context);
      } else {
        Fluttertoast.showToast(
            msg: 'Location permission is required!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            fontSize: 14.0);
      }
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings().then((value) {
        _getLocation(context);
      }).catchError((e) {
        Fluttertoast.showToast(
            msg: 'Location permission is required!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            fontSize: 14.0);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(110.0),
        child: CustomAppBar(
          color: Colors.white,
          titleWidget: Text(
            'Add Address',
            style: TextStyle(fontSize: 16.7, color: Colors.black),
          ),
          actions: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: kButtonColor,
                  ),
                  iconSize: 30,
                  onPressed: () {
                    _getLocation(context);
                  },
                ))
          ],
          bottom: PreferredSize(
              child: GestureDetector(
                onTap: (){
                  getPlaces(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 52,
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: scaffoldBgColor,
                      borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    children: [
                      Icon(Icons.search,size: 25,),
                      SizedBox(width: 20),
                      Text(
                          'Search Location'
                      ),
                    ],
                  ),
                ),
              ),
              preferredSize:
              Size(MediaQuery.of(context).size.width * 0.85, 52)),
        ),
      ),
      body:
      SingleChildScrollView(
        primary: true,
        child:
        Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 200,
                          child:
                          GoogleMap(
                            gestureRecognizers: < Factory < OneSequenceGestureRecognizer >> [
                              new Factory < OneSequenceGestureRecognizer > (
                                    () => new EagerGestureRecognizer(),
                              ),
                            ].toSet(),
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(lat,lng),
                              zoom: 14.0,
                            ),
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: true,
                            compassEnabled: false,
                            mapToolbarEnabled: false,
                            buildingsEnabled: false,
                            markers: markers.values.toSet(),
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                              final marker = Marker(
                                markerId: MarkerId('location'),
                                position: LatLng(lat, lng),
                                icon: BitmapDescriptor.defaultMarker,
                              );
                              setState(() {
                                markers[MarkerId('location')] = marker;
                              });

                            },
                            onCameraIdle: () {
                              getMapLoc();
                            },
                            onCameraMove: (post) {
                              lat = post.target.latitude;
                              lng = post.target.longitude;

                              final marker = Marker(
                                markerId: MarkerId('location'),
                                position: LatLng(lat, lng),
                                icon: BitmapDescriptor.defaultMarker,
                              );
                              setState(() {
                                markers[MarkerId('location')] = marker;
                              });
                            },
                          ),
                        ),

                        SizedBox(
                          height: 30,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.95,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: addressTypeError ? Colors.red : kHintColor,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<String>(
                            hint: Text(addressType),
                            isExpanded: true,
                            underline: Container(
                              height: 0.0,
                              color: scaffoldBgColor,
                            ),
                            items: addressTyp.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                addressType = value!;
                                addressTypeError = false;
                              });
                              print(addressType);
                            },
                          ),
                        ),
                        if (addressTypeError)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Select address type',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.95,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: cityError ? Colors.red : kHintColor,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<CityList>(
                            hint: Text(
                              selectCity,
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                            ),
                            isExpanded: true,
                            underline: Container(
                              height: 0.0,
                              color: scaffoldBgColor,
                            ),
                            items: cityListt.map((value) {
                              return DropdownMenuItem<CityList>(
                                value: value,
                                child: Text(value.city_name,
                                    overflow: TextOverflow.clip),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectCity = value!.city_name;
                                selectCityId = value.city_id;
                                areaList.clear();
                                selectArea = 'Select near by area';
                                selectAreaId = '';
                                cityError = false;
                              });
                              getAreaList(value!.city_id);
                              print(value);
                            },
                          ),
                        ),
                        if (cityError)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Select city',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(
                          height: 15,
                        ),

                        Container(
                          margin: const EdgeInsets.all(12),
                          height: 60.sp,
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(
                              color: Colors.grey, // or any color you like
                              width: 1.sp,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              currentAddress.isNotEmpty ? currentAddress : '',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Full Address TextField (House me jaayega)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width:
                              MediaQuery.of(context).size.width * 0.95,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: houseError
                                      ? Colors.red
                                      : kHintColor,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: houseController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                                minLines: 1,
                                onChanged: (value) {
                                  if (houseError &&
                                      value.trim().isNotEmpty) {
                                    setState(() {
                                      houseError = false;
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  hintText:
                                  'Enter full address (House no, Flat, Building...)',
                                  border: InputBorder.none,
                                  contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (houseError)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 14, top: 5),
                                child: Text(
                                  'Enter your full address',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),

                      ],
                    ),
                    Positioned.fill(
                      child: Visibility(
                        visible: showDialogBox,
                        child: AbsorbPointer(
                          absorbing: true, // background click block
                          child: Container(
                            color: Colors.black.withOpacity(0.35), // overlay
                            alignment: Alignment.center,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.86,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                                decoration: BoxDecoration(
                                  color: white_color,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 34,
                                      width: 34,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: kMainColor,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Text(
                                        'Loading, please wait...',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black87, // bug fixed: white text on white bg
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: (MediaQuery.of(context).size.height - 77) * 0.1,
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {
                      // Step by step validation - har field alag check hogi

                      // 1. Address Type
                      if (addressType == 'Select address type') {
                        setState(() {
                          addressTypeError = true;
                        });
                        Fluttertoast.showToast(
                            msg: "Select address type",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        return;
                      }

                      // 2. City
                      if (selectCity == 'Select city' ||
                          selectCityId == null ||
                          '$selectCityId'.isEmpty) {
                        setState(() {
                          cityError = true;
                        });
                        Fluttertoast.showToast(
                            msg: "Select city",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        return;
                      }

                      // 3. House (full address)
                      if (houseController.text.trim().isEmpty) {
                        setState(() {
                          houseError = true;
                        });
                        Fluttertoast.showToast(
                            msg: "Enter your full address",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        return;
                      }

                      // 4. Pincode / State (location se aate hain)
                      if (pincodeController.text.trim().isEmpty ||
                          stateController.text.trim().isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Select a valid location on map",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        return;
                      }

                      // Sab sahi hai -> save karo
                      setState(() {
                        showDialogBox = true;
                      });
                      addAddres(
                          selectAreaId,
                          selectCityId,
                          houseController.text,
                          currentAddress,
                          pincodeController.text,
                          stateController.text,
                          context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 52,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          color: kButtonColor),
                      child: Text(
                        'Save Address',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kWhiteColor,
                            fontSize: 15.sp
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(12),
                alignment: Alignment.bottomCenter,
                child:    Text(
                  message.toString(),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                )
                ,
              )

            ],
          ),
        ),
      ),
    );
  }

  void getCityList() async {
    var url = cityList;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {
      'vendor_id': '54',
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<CityList> tagObjs =
          tagObjsJson.map((tagJson) => CityList.fromJson(tagJson)).toList();
          if (tagObjs != null && tagObjs.length > 0) {
            setState(() {
              cityListt.clear();
              cityListt = tagObjs;
              areaList.clear();
              selectAreaId = '';
              selectArea = 'Select near by area';
            });
            List<CityList> tagObjs1 = tagObjs
                .where((element) =>
            element.city_id.toString() == '${widget.city_id}')
                .toList();
            if (tagObjs1 != null && tagObjs1.length > 0) {
              setState(() {
                selectCity = tagObjs1[0].city_name;
                selectCityId = tagObjs1[0].city_id;
                streetController.text =
                    streetController.text.replaceAll('${selectCity},', '');
                streetController.text =
                    streetController.text.replaceAll('${selectCity}', '');
              });
              if (selectCityId != null &&
                  selectCityId != '' &&
                  selectCityId != null) {
                getAreaList1(selectCityId);
              }
            }
          } else {
            setState(() {
              cityListt.clear();
              areaList.clear();
              selectCity = 'Select city';
              selectCityId = '';
              selectAreaId = '';
              selectArea = 'Select near by area';
            });
          }
        }
      }
    });
  }

  void getAreaList1(dynamic city_id) async {
    var url = areaLists;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {
      'vendor_id': '${widget.vendorid}',
      'city_id': '$city_id',
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<AreaList> tagObjs =
          tagObjsJson.map((tagJson) => AreaList.fromJson(tagJson)).toList();
          if (tagObjs != null && tagObjs.length > 0) {
            setState(() {
              areaList.clear();
              areaList = tagObjs;
            });
            List<AreaList> tagObjs1 = tagObjs
                .where((element) =>
            element.area_id.toString() == '${widget.area_id}')
                .toList();
            if (tagObjs1 != null && tagObjs1.length > 0) {
              setState(() {
                selectAreaId = tagObjs1[0].area_id;
                selectArea = tagObjs1[0].area_name;
                streetController.text =
                    streetController.text.replaceAll(',${selectArea},', '');
                streetController.text =
                    streetController.text.replaceAll('${selectArea},', '');
                streetController.text =
                    streetController.text.replaceAll('${selectArea}', '');
              });
            }
          } else {
            setState(() {
              areaList.clear();
              selectAreaId = '';
              selectArea = 'Select near by area';
            });
          }
        }
      }
    });
  }

  void getAreaList(dynamic city_id) async {
    var url = areaLists;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {
      'vendor_id': '${widget.vendorid}',
      'city_id': '$city_id',
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<AreaList> tagObjs =
          tagObjsJson.map((tagJson) => AreaList.fromJson(tagJson)).toList();
          if (tagObjs != null && tagObjs.length > 0) {
            setState(() {
              areaList.clear();
              areaList = tagObjs;
            });
          } else {
            setState(() {
              areaList.clear();
              selectAreaId = '';
              selectArea = 'Select near by area';
            });
          }
        }
      }
    });
  }


  void addAddres(dynamic area_id, dynamic city_id, house_no, street, pincode,
      state, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var url = editAddress;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {
      'address_id': '${widget.address_id}',
      'user_id': '${prefs.getInt('user_id')}',
      'user_name': '${prefs.getString('user_name')}',
      'user_number': '${prefs.getString('user_phone')}',
      'area_id': '$area_id',
      'city_id': '$city_id',
      'houseno': '$house_no',
      'street': '$street',
      'state': '$state',
      'pin': '$pincode',
      'lat': '$lat',
      'lng': '$lng',
      'address_type': '${addressType}',
    }).then((value) {
      if (value.statusCode == 200) {
        print('Response Body: - ${value.body}');
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          prefs.setString("area_id", "$area_id");
          prefs.setString("city_id", "$city_id");
          setState(() {
            showDialogBox = false;
          });
          Navigator.pop(context);

        } else {
          print(jsonData['message']);
          setState(() {
            showDialogBox = false;
          });
        }
      } else {
        print(value.body.toString());

        setState(() {
          showDialogBox = false;
        });
      }
    }).catchError((e) {
      print(e.toString());

      setState(() {
        showDialogBox = false;
      });
      print(e);
    });
  }
  void getMapLoc() async {
    _getCameraMoveLocation(LatLng(lat, lng));
  }
  void _getCameraMoveLocation(LatLng data) async {
    Timer(const Duration(seconds: 1), () async {
      lat = data.latitude.toDouble();
      lng = data.longitude.toDouble();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("lat", lat!.toStringAsFixed(8));
      prefs.setString("lng", lng!.toStringAsFixed(8));

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat!, lng!);
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          setState(() {
            streetController.text = currentAddress ?? '';
            stateController.text = placemark.administrativeArea ?? '';
            pincodeController.text = placemark.postalCode ?? '';
            currentAddress = [
              placemark.name,
              placemark.subThoroughfare,
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.administrativeArea,
              placemark.postalCode,
              placemark.country
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          });
        } else {
        }
      } catch (e) {
      }
    });
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart' as loc;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../Auth/MobileNumber/UI/phone_number.dart';
import '../../../Auth/login_navigator.dart';
import '../../../BlinkitProduct/blinkit_product.dart';
import '../../../BlinkitUI/blinkit_cat.dart';
import '../../../Components/card_content.dart';
import '../../../Components/custom_appbar.dart';
import '../../../Components/reusable_card.dart';
import '../../../Maps/UI/location_page.dart';
import '../../../Routes/routes.dart';
import '../../../Themes/colors.dart';
import '../../../Themes/constantfile.dart';
import '../../../Themes/style.dart';
import '../../../Utils/HexColorCode/HexColor.dart';
import '../../../Utils/scrolling_text.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/adminsetting.dart';
import '../../../bean/bannerbean.dart';
import '../../../bean/latlng.dart';
import '../../../bean/nearstorebean.dart';
import '../../../bean/venderbean.dart';
import '../../../bean/vendorbanner.dart';
import '../../../databasehelper/dbhelper.dart';
import '../../../main.dart';
import '../../Account/UI/account_page.dart';
import '../../home_order_account.dart';
import '../Closed.dart';
import 'Stores/stores.dart';
import 'appcategory/appcategory.dart';


class HomePage2 extends StatelessWidget {
  int value;

  HomePage2(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Home(value);
  }
}

class Home extends StatefulWidget {
  int value;

  Home(this.value);

  @override
  _HomeState createState() => _HomeState(this.value);
}

class _HomeState extends State<Home> {
  Adminsetting? admins;
  int _value = -1;

  String? cityName = 'NO LOCATION SELECTED';
  String? currency = '';
  late List<NearStores> rest_nearStores = [];
  String ClosedImage = '';
  List<BannerDetails> ClosedBannerImage = [];

  String pickImage = '';
  String subsImage = '';
  String bigImage = '';
  String TopImage = '';
  String subsenddate = '';
  var lat = 30.3253;
  var lng = 78.0413;
  List<BannerDetails> listImage = [];
  List<BannerDetails> pickBannerImage = [];
  List<BannerDetails> topBannerImage = [];
  List<VendorList> nearStores = [];
  List<NearStores> nearBlinkitStores = [];

  List<VendorList> newnearStores = [];
  List<Vendors> substores = [];
  List<VendorList> nearStoresShimmer = [
    VendorList(),
    VendorList(),
    VendorList(),
    VendorList(),
  ];
  List<String> listImages = ['', '', '', '', ''];
  bool isCartCount = false;
  int cartCount = 0;
  bool isFetch = true;

  final dynamic vendor_category_id = 14;
  final dynamic blinkit_vendor_category_id = 24;

  // final dynamic ui_type;

  List<VendorBanner> listImage1 = [];
  List<NearStores> nearStores1 = [];
  List<NearStores> nearStoresSearch1 = [];
  List<NearStores> nearStoresShimmer1 = [
    NearStores(
        "", "", 0, "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""),
    NearStores(
        "", "", 0, "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""),
    NearStores(
        "", "", 0, "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""),
    NearStores(
        "", "", 0, "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""),
    NearStores(
        "", "", 0, "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""),
  ];
  List<String> listImages1 = ['', '', '', '', ''];
  double userLat = 0.0;
  double userLng = 0.0;
  bool isFetchStore = true;
  TextEditingController searchController = TextEditingController();
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  static String id = "";

  bool subscriptionbanner = true;
  bool subscriptionStore = false;

  int value;

  _HomeState(this.value);

  @override
  void initState() {
    super.initState();
    checksubscription();

    if (value == 0) {
      _getLocation(context);
      calladminsetting();
    } else {
      getData();
      calladminsetting();
    }
  }

  //
  void getCartCount() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.queryRowBothCount().then((value) {
      setState(() {
        if (value > 0) {
          cartCount = value;
          isCartCount = true;
        } else {
          cartCount = 0;
          isCartCount = false;
        }
      });
    });
  }

  //
  void getCurrency() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var currencyUrl = currencyuri;
    var client = http.Client();
    Uri myUri = Uri.parse(currencyUrl);

    client.get(myUri).then((value) {
      var jsonData = jsonDecode(value.body);
      if (value.statusCode == 200 && jsonData['status'] == "1") {
        preferences.setString(
            'curency', '${jsonData['data'][0]['currency_sign']}');

        setState(() {
          currency = '${jsonData['data'][0]['currency_sign']}';
        });
      }
    }).catchError((e) {});
  }

  void callThisMethod(bool isVisible) {
    getData();
  }

  void _getLocation(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      bool isLocationServiceEnableds =
      await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnableds) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        double lt = position.latitude;
        String latstring = lt.toStringAsFixed(8); // '2.35'
        double lats = double.parse(latstring);

        double ln = position.longitude;
        String lanstring = ln.toStringAsFixed(8); // '2.35'
        double lngs = double.parse(lanstring);

        prefs.setString("lat", latstring);
        prefs.setString("lng", lanstring);

        setState(() {
          lat = lats;
          lng = lngs;
        });

        //double lat = position.latitude;
        //double lat = 29.006057;
        //double lng = position.longitude;
        //double lng = 77.027535;

        List<Placemark> placemarks = await placemarkFromCoordinates(lats, lngs);
        setState(() {
          cityName = (placemarks.elementAt(0).subLocality.toString()) +
              " ( " +
              (placemarks.elementAt(0).locality.toString()) +
              " )".toUpperCase();

          prefs.setString("addr", cityName.toString());
        });
      } else {
        await Geolocator.openLocationSettings().then((value) {
          if (value) {
            _getLocation(context);
          } else {
            // Toast.show('Location permission is required!', context,
            //     duration: Toast.LENGTH_SHORT);
          }
        }).catchError((e) {
          // Toast.show('Location permission is required!', context,
          //     duration: Toast.LENGTH_SHORT);
        });
      }
    } else if (permission == LocationPermission.denied) {
      LocationPermission permissiond = await Geolocator.requestPermission();
      if (permissiond == LocationPermission.whileInUse ||
          permissiond == LocationPermission.always) {
        _getLocation(context);
      } else {
        // Toast.show('Location permission is required!', context,
        //     duration: Toast.LENGTH_SHORT);
      }
    } else if (permission == LocationPermission.deniedForever) {
      // await Geolocator.openAppSettings().then((value) {
      //   _getLocation(context);
      // }).catchError((e) {
      //   // Toast.show('Location permission is required!', context,
      //   //     duration: Toast.LENGTH_SHORT);
      // });
    }
  }
  hitNavigator2(BuildContext context, NearStores item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('${prefs.getString("res_vendor_id")}');
    print('res vendor id is:${item.vendor_id}');
    if (isCartCount &&
        prefs.getString("res_vendor_id") != null &&
        prefs.getString("res_vendor_id") != "" &&
        prefs.getString("res_vendor_id") != '${item.vendor_id}') {
      showMyDialog(context, item, currency);

      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => Restaurant_Sub(item, currencySymbol)))
      //     .then((value) {
      //   getCartCount();
      // });
    }
  }

  showMyDialog(BuildContext context, NearStores item, currencySymbol) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            content: Text(
              'Your cart contains dishes from a different resturant. Do you want to discard the selection and add dishes from this resturant.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Clear Cart'),
                onPressed: () {
                  deleteAllRestProduct(context, item, currencySymbol);
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  void deleteAllRestProduct(
      BuildContext context, NearStores item, currencySymbol) async {
    DatabaseHelper database = DatabaseHelper.instance;
    database.deleteAllRestProdcut();
    database.deleteAllAddOns();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("res_vendor_id", '${item.vendor_id}');
    prefs.setString("res_pack_charge", '${item.packaging_charges}');
    prefs.setString("store_resturant_name", '${item.vendor_name}');

  }


  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(375, 812), // Set your design size here
      minTextAdapt: true, // Ensure this is initialized
    );
    return VisibilityDetector(
        key: Key(_HomeState.id),
        onVisibilityChanged: (VisibilityInfo info) {
          bool isVisible = info.visibleFraction != 0;
          callThisMethod(isVisible);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.0),
            child: CustomAppBar(
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.location_searching,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // _getCurrentPosition();

                    _getLocation(context);
                  },
                ),
                // IconButton(
                //   icon: Icon(
                //     Icons.warning,
                //     color: Colors.white,
                //   ),
                //   onPressed: () {
                //     FirebaseCrashlytics.instance.crash();
                //
                //   },
                // ),
                IconButton(
                  icon: Icon(
                    Icons.account_circle,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                    String? skip = prefs.getString('skip');

                    if (skip != null) {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoMarket(),
                        ),
                      );
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => SkipLogin(),
                      //   ),
                      // );
                      // Show toast message
                      Fluttertoast.showToast(
                        msg: "Please login",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 22.0,
                      );
                    } else {
                      Navigator.pushNamed(context, PageRoutes.accountPage);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => AccountPage(),
                      //   ),
                      // );
                    }

                    // do something
                  },
                ),
              ],
              color: kMainColor,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),
              ),
              titleWidget: GestureDetector(
                onTap: () async {
                  print("SENDINGLATLNG  " + lat.toString() + lng.toString());
                  BackLatLng back = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LocationPage(lat, lng)));

                  getBackResult(back.lat, back.lng);
                },
                child: Text(
                  cityName!,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          body: admins == null
              ? SpinKitFadingCircle(
            color: Colors.orangeAccent,
            size: 30.0,
          )
              : Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  (admins!.surge == 1)
                      ? Wrap(children: <Widget>[
                    Text(
                      admins!.bottomMessage.toString(),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          fontSize: 16, color: Colors.blue),
                    )
                  ])
                      : Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 24.0),
                      child: Text(
                        admins!.surgeMsg.toString(),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.black),
                      )),

                  // Container(
                  //   width: MediaQuery
                  //       .of(context)
                  //       .size
                  //       .width,
                  //   height: 60,
                  //   alignment: Alignment.center,
                  //   child:
                  //   Padding(
                  //     padding: EdgeInsets.only(top: 8.0, left: 0.0),
                  //     child:
                  //     Row(
                  //       children: <Widget>[
                  //
                  //         GestureDetector(
                  //           onTap: ()async {
                  //
                  //             await showDialog(
                  //                 context: context,
                  //                 builder: (_) => Dialog(
                  //                   child: Container(
                  //                     decoration: BoxDecoration(
                  //                       color: white_color,
                  //                       borderRadius:
                  //                       BorderRadius.circular(20.0),
                  //                     ),
                  //                     child: Image.network(
                  //                       TopImage,
                  //                       fit: BoxFit.fill,
                  //                     ),
                  //                   ),
                  //                 )
                  //             );
                  //           },
                  //           child:
                  //           Container(
                  //             child:
                  //             Stack(
                  //               children: <Widget>[
                  //                 // Container(
                  //                 //   alignment: Alignment.center,
                  //                 //     child: Container(
                  //                 //       height: 50,
                  //                 //       color: Colors.red,
                  //                 //     )
                  //                 //
                  //                 //
                  //                 //
                  //                 //   // Image.asset(
                  //                 //   //   'assets/backgg.png',
                  //                 //   //   fit: BoxFit.fitWidth,
                  //                 //   //   width: MediaQuery.of(context).size.width * 0.85 ,
                  //                 //   // ),
                  //                 // ),
                  //                 Container(
                  //                   // padding: EdgeInsets.all(0),
                  //                   width: MediaQuery.of(context).size.width * 0.90,
                  //                   alignment: Alignment.center,
                  //                   color: Colors.cyan,
                  //                   child: ScrollingText(
                  //                     text: admins!.topMessage.toString().toUpperCase(),
                  //                     textStyle: TextStyle(fontSize: 20,color: Colors.white),
                  //                     // admins!.topMessage.toString(),
                  //                     // maxLines: 2,
                  //                     // style:  orderMapAppBarTextStyle
                  //                     //     .copyWith(color: Colors.white,fontWeight: FontWeight.w900,fontSize: 15,fontFamily: 'OpenSans'),
                  //                   ),
                  //                 )
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                        onTap: () async {
                          // await showDialog(
                          //     context: context,
                          //     builder: (_) => Dialog(
                          //           child: Container(
                          //             decoration: BoxDecoration(
                          //               color: white_color,
                          //               borderRadius:
                          //                   BorderRadius.circular(20.0),
                          //             ),
                          //             child: Image.network(
                          //               TopImage,
                          //               fit: BoxFit.fill,
                          //             ),
                          //           ),
                          //         ));
                        },
                        child: Container(
                            height: 60,
                            color: Colors.red,
                            child: Center(
                              child: ScrollingText(
                                text: admins!.topMessage
                                    .toString()
                                    .toUpperCase(),
                                textStyle: TextStyle(
                                    fontSize: 22, color: Colors.white),
                                // admins!.topMessage.toString(),
                                // maxLines: 2,
                                // style:  orderMapAppBarTextStyle
                                //     .copyWith(color: Colors.white,fontWeight: FontWeight.w900,fontSize: 15,fontFamily: 'OpenSans'),
                              ),
                            ))),
                  ),
                  SizedBox(height: 20),

                  // Container(
                  //   width: MediaQuery.of(context).size.width * 0.85,
                  //   height: 52,
                  //   padding: EdgeInsets.only(left: 5),
                  //   child: TypeAheadField<Vendors>(
                  //     builder: (context, controller, focusNode) {
                  //       return TextField(
                  //         controller: controller,
                  //         focusNode: focusNode,
                  //         autofocus: false,
                  //         decoration: InputDecoration(
                  //           border: OutlineInputBorder(),
                  //           labelText: 'Search Store, Restaurant...',
                  //           prefixIcon: Icon(
                  //             Icons.search,
                  //             color: kHintColor,
                  //           ),
                  //           suffixIcon: controller.text.isNotEmpty
                  //               ? IconButton(
                  //             icon: Icon(Icons.clear, color: Colors.grey),
                  //             onPressed: () {
                  //               controller.clear();
                  //             },
                  //           )
                  //               : null,
                  //         ),
                  //         onChanged: (value) {
                  //           // Force rebuild to show/hide clear button
                  //           (context as Element).markNeedsBuild();
                  //         },
                  //       );
                  //     },
                  //
                  //     suggestionsCallback: (pattern) async {
                  //       print("Search pattern: $pattern");
                  //       var results = await BackendService.getSuggestions(pattern, lat, lng);
                  //       print("Search results: $results");
                  //       return results;
                  //     },
                  //
                  //     itemBuilder: (context, Vendors suggestion) {
                  //       return ListTile(
                  //         title: Text('${suggestion.str1}'),
                  //         subtitle: Text('${suggestion.str2}'),
                  //       );
                  //     },
                  //
                  //     hideOnError: false,
                  //
                  //     onSelected: (Vendors detail) async {
                  //       if (detail.uiType == "grocery" ||
                  //           detail.uiType == "Grocery" ||
                  //           detail.uiType == 1) {
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) => AppCategory(
                  //               detail.vendorCategoryId,
                  //               detail.vendorName.toString(),
                  //               detail.vendorId,
                  //               detail.distance,
                  //             ),
                  //           ),
                  //         );
                  //       } else if (detail.uiType == "resturant" ||
                  //           detail.uiType == "Resturant" ||
                  //           detail.uiType == 2) {
                  //         for (int i = 0; i < rest_nearStores.length; i++) {
                  //           if (rest_nearStores.elementAt(i).vendor_id == detail.vendorId) {
                  //             if (rest_nearStores.elementAt(i).online_status == 'OFF') {
                  //               Fluttertoast.showToast(
                  //                 msg: "Store open at ${rest_nearStores.elementAt(i).opening_time.toString()}",
                  //                 toastLength: Toast.LENGTH_LONG,
                  //                 gravity: ToastGravity.CENTER,
                  //                 backgroundColor: Colors.red,
                  //                 textColor: Colors.white,
                  //                 fontSize: 16.sp,
                  //               );
                  //             } else {
                  //               hitNavigator2(context, rest_nearStores.elementAt(i));
                  //             }
                  //           }
                  //         }
                  //       }
                  //     },
                  //   ),
                  // ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 52,
                    padding: EdgeInsets.only(left: 5),
                    child: TypeAheadField<Vendors>(
                      builder: (context, controller, focusNode) {
                        Timer? _debounce; // Debounce timer
                        // Cache for search results
                        final Map<String, List<Vendors>> _cache = {};

                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: false,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Search Store, Restaurant...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: kHintColor,
                            ),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                controller.clear();
                                (context as Element).markNeedsBuild();
                              },
                            )
                                : null,
                          ),
                          onChanged: (value) {
                            // Debounce the onChanged event
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(Duration(milliseconds: 300), () {
                              (context as Element).markNeedsBuild();
                            });
                          },
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        final Map<String, List<Vendors>> _cache = {}; // Static cache
                        if (pattern.isEmpty) return []; // Return empty list for no input

                        // Check cache first
                        if (_cache.containsKey(pattern)) {
                          print("Returning cached results for: $pattern");
                          return _cache[pattern]!;
                        }

                        print("Search pattern: $pattern");
                        var results = await BackendService.getSuggestions(pattern, lat, lng);
                        print("Search results: $results");

                        // Cache the results
                        _cache[pattern] = results;
                        return results;
                      },
                      itemBuilder: (context, Vendors suggestion) {
                        return ListTile(
                          title: Text('${suggestion.str1 ?? ''}'),
                          subtitle: Text('${suggestion.str2 ?? ''}'),
                        );
                      },
                      hideOnError: false,
                      onSelected: (Vendors detail) async {
                        if (detail.uiType == "grocery" ||
                            detail.uiType == "Grocery" ||
                            detail.uiType == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppCategory(
                                detail.vendorCategoryId,
                                detail.vendorName.toString(),
                                detail.vendorId,
                                detail.distance,
                              ),
                            ),
                          );
                        } else if (detail.uiType == "resturant" ||
                            detail.uiType == "Resturant" ||
                            detail.uiType == 2) {
                          for (int i = 0; i < rest_nearStores.length; i++) {
                            if (rest_nearStores.elementAt(i).vendor_id == detail.vendorId) {
                              if (rest_nearStores.elementAt(i).online_status == 'OFF') {
                                Fluttertoast.showToast(
                                  msg: "Store open at ${rest_nearStores.elementAt(i).opening_time.toString()}",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.CENTER,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              } else {
                                hitNavigator2(context, rest_nearStores.elementAt(i));
                              }
                              break;
                            }
                          }
                        }
                      },
                    ),
                  ),


                  Padding(
                    padding:  EdgeInsets.only(left: 20.sp,right: 20.sp,top: 10.sp),
                    child:SizedBox(
                      width: double.infinity,
                      height: 70.sp,
                      child: GestureDetector(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      BlinkitCategory('', '24','','')));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0), // Set the border radius here

                          child: Image.asset(
                            'assets/jhatfat_store.jpeg', // Replace with your image URL
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),


                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        childAspectRatio: 100 / 90,
                        controller:
                        ScrollController(keepScrollOffset: false),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: List.generate(nearStores!.length + 1,
                                (index) {
                              // If it's the last item, show the "Add Photo" button
                              if (index == nearStores!.length) {
                                return Container();
                              } else {
                                // Show the photo
                                return ReusableCard(
                                  cardChild: CardContent(
                                    image:
                                    '${imageBaseUrl}${nearStores[index].categoryImage}',
                                    text: '${nearStores[index].categoryName}',
                                    uiType: nearStores[index].uiType,
                                    vendorCategoryId:
                                    '${nearStores[index].vendorCategoryId}',
                                    context: context,
                                  ),
                                );
                              }
                            })

                      // childAspectRatio: itemWidth/(itemHeight),
                      // children: (nearStores.length > 0)
                      //     ? nearStores.map((e) {
                      //         return ReusableCard(
                      //           cardChild: CardContent(
                      //             image:
                      //                 '${imageBaseUrl}${e.categoryImage}',
                      //             text: '${e.categoryName}',
                      //             uiType: e.uiType,
                      //             vendorCategoryId:
                      //                 '${e.vendorCategoryId}',
                      //             context: context,
                      //           ),
                      //         );
                      //       }).toList()
                      //     : nearStoresShimmer.map((e) {
                      //         return ReusableCard(
                      //             cardChild: Shimmer(
                      //               duration: Duration(seconds: 3),
                      //               //Default value
                      //               color: Colors.white,
                      //               //Default value
                      //               enabled: true,
                      //               //Default value
                      //               direction:
                      //                   ShimmerDirection.fromLTRB(),
                      //               //Default Value
                      //               child: Container(
                      //                 color: kTransparentColor,
                      //               ),
                      //             ),
                      //             onPress: () {});
                      //       }).toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 2),
                    child: Builder(
                      builder: (context) {
                        return InkWell(
                          onTap: () {
                            if (pickBannerImage[0].vendorCategoryId ==
                                '18' ||
                                pickBannerImage[0].vendorCategoryId ==
                                    18) {
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    height: 500,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: <Widget>[
                                          Image.asset("images/id.png"),
                                          Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                                'You need to be above 18 years of age',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 18,
                                                    fontWeight:
                                                    FontWeight.w400)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                                'Do not buy tobacco products on behalf of underage persons.',
                                                style: TextStyle(
                                                    color:
                                                    Colors.blueGrey,
                                                    fontSize: 16)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                                'Your location must not be in and around school or college premises.',
                                                style: TextStyle(
                                                    color:
                                                    Colors.blueGrey,
                                                    fontSize: 16)),
                                          ),
                                          Divider(),
                                          Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(
                                                'Jhatfat reserves the right to report your account in case you are below 18 years of age and purchasing cigrattes',
                                                style: TextStyle(
                                                    color:
                                                    Colors.blueGrey,
                                                    fontSize: 14)),
                                          ),
                                          new GestureDetector(
                                            onTap: () {
                                              Navigator.popAndPushNamed(
                                                  context,
                                                  PageRoutes.tncPage);
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: Text('Read T&C',
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12)),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            mainAxisSize:
                                            MainAxisSize.min,
                                            children: [
                                              Spacer(),
                                              ElevatedButton(
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        30.0),
                                                  ),
                                                  backgroundColor:
                                                  kWhiteColor,
                                                  padding:
                                                  EdgeInsets.all(10),
                                                ),
                                                child: const Text(
                                                  "No,I'm not",
                                                  style: TextStyle(
                                                      color: Color(
                                                          0xffeca53d),
                                                      fontWeight:
                                                      FontWeight
                                                          .w400),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context),
                                              ),
                                              Spacer(),
                                              ElevatedButton(
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        30.0),
                                                  ),
                                                  backgroundColor:
                                                  kMainColor,
                                                  padding:
                                                  EdgeInsets.all(10),
                                                ),
                                                child: const Text(
                                                    "Yes,I'm above 18"),
                                                onPressed: () => {
                                                  Navigator.pop(context),
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) => new AppCategory(
                                                              pickBannerImage[
                                                              0]
                                                                  .vendorCategoryId,
                                                              pickBannerImage[
                                                              0]
                                                                  .vendorName,
                                                              pickBannerImage[
                                                              0]
                                                                  .vendorId,
                                                              "22")))
                                                },
                                              ),
                                              Spacer(),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              print("Grocery button pressed");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AppCategory(
                                          pickBannerImage[0]
                                              .vendorCategoryId,
                                          pickBannerImage[0].vendorName,
                                          pickBannerImage[0].vendorId,
                                          "22")));
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 10),
                            child: Material(
                              borderRadius: BorderRadius.circular(20.0),
                              clipBehavior: Clip.hardEdge,
                              child: Container(
                                  height: 100,
                                  width: MediaQuery.of(context).size.width *
                                      0.90,
//                                            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: white_color,
                                    border: Border.all(
                                        color: Colors.orangeAccent),
                                    borderRadius:
                                    BorderRadius.circular(20.0),
                                  ),
                                  child: pickImage == ""
                                      ? Center(
                                    child: SpinKitFadingCircle(
                                      color: Colors.orangeAccent,
                                      size: 30.0,
                                    ),
                                  )
                                      :
                                  CachedNetworkImage(
                                    imageUrl: '$pickImage',
                                    width: double.infinity,
                                    fit: BoxFit.fill,
                                    alignment: Alignment.center,
                                    placeholder: (context, url) => Center(child: SpinKitFadingCircle(
                                      color: Colors.orangeAccent,
                                      size: 30.0,
                                    )),
                                    errorWidget: (context, url, error) => Image.asset(
                                      'assets/default-image_600.png',
                                      width: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                  )

                                // Image.network(
                                //         pickImage,
                                //         fit: BoxFit.fill,
                                //       ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),



                  Visibility(
                    visible: (!isFetch && listImage.length == 0)
                        ? false
                        : true,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 5),
                      child: CarouselSlider(
                          options: CarouselOptions(
                            height: 200.0,
                            autoPlay: true,
                            initialPage: 0,
                            viewportFraction: 0.9,
                            enableInfiniteScroll: true,
                            reverse: false,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration:
                            Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            scrollDirection: Axis.horizontal,
                          ),
                          items: (listImage.length > 0)
                              ? listImage.map((e) {
                            return Builder(
                              builder: (context) {
                                return InkWell(
                                  onTap: () async {

                                    if(e.uiType==1){
                                      print("store hit");
                                      hitNavigatorStore(
                                          context,
                                          e.bannerName.toString(),
                                          e.vendorCategoryId.toString(),
                                          e.vendorId.toString(),
                                          '2.5'
                                      );
                                    }else if (e.uiType == "resturant" ||
                                        e.uiType == "Resturant" ||
                                        e.uiType == 2) {



                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      print('${prefs.getString("res_vendor_id")}');
                                      print('res vendor id is:${e.vendorId}');
                                      if (isCartCount &&
                                          prefs.getString("res_vendor_id") != null &&
                                          prefs.getString("res_vendor_id") != "" &&
                                          prefs.getString("res_vendor_id") != '${e.vendorId}') {
                                        // showMyDialog(context, rest_nearStores.elementAt(i), currency);

                                        // Navigator.push(
                                        //     context,
                                        //     MaterialPageRoute(
                                        //         builder: (context) => Restaurant_Sub(item, currencySymbol)))
                                        //     .then((value) {
                                        //   getCartCount();
                                        // });
                                      } else {
                                        prefs.setString("res_vendor_id", '${e.vendorId}');
                                        prefs.setString("res_pack_charge", '${'0'}');
                                        prefs.setString("store_resturant_name", '${e.vendorName}');
                                        print('${prefs.getString("res_vendor_id")}');


                                        for (int i = 0; i < rest_nearStores.length; i++) {
                                          print(
                                              "REST BANNER" + rest_nearStores.elementAt(i).vendor_id.toString());

                                          if (rest_nearStores.elementAt(i).vendor_id.toString() == e.vendorId.toString()) {

                                          }
                                        }

                                      }
                                    }

                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 10),
                                    child: Material(
                                      elevation: 5,
                                      borderRadius:
                                      BorderRadius.circular(
                                          20.0),
                                      clipBehavior: Clip.hardEdge,
                                      child: Container(
                                          height: 200,
                                          width:
                                          MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.90,
//                                            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                                          decoration: BoxDecoration(
                                            color: white_color,
                                            borderRadius:
                                            BorderRadius.circular(
                                                20.0),
                                          ),
                                          child:
                                          CachedNetworkImage(
                                            imageUrl:  imageBaseUrl + e.bannerImage,
                                            fit: BoxFit.fill,
                                            alignment: Alignment.center,
                                            placeholder: (context, url) => Center(child: SpinKitFadingCircle(
                                              color: Colors.orangeAccent,
                                              size: 30.0,
                                            )),
                                            errorWidget: (context, url, error) => Image.asset(
                                              'assets/default-image_600.png',
                                              fit: BoxFit.fill,
                                            ),
                                          )

                                        // Image.network(
                                        //   imageBaseUrl +
                                        //       e.bannerImage,
                                        //   fit: BoxFit.fill,
                                        // ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList()
                              : listImages.map((e) {
                            return Builder(builder: (context) {
                              return Container(
                                height: 200,
                                width: MediaQuery.of(context)
                                    .size
                                    .width *
                                    0.90,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(20.0),
                                ),
                                child: Shimmer(
                                  duration: Duration(seconds: 3),
                                  //Default value
                                  color: Colors.white,
                                  //Default value
                                  enabled: true,
                                  //Default value
                                  direction:
                                  ShimmerDirection.fromLTRB(),
                                  //Default Value
                                  child: Container(
                                    color: kTransparentColor,
                                  ),
                                ),
                              );
                            });
                          }).toList()),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 2),
                    child: Builder(
                      builder: (context) {
                        return InkWell(
                          onTap: () {


                            ////hitService1();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Material(
                              borderRadius: BorderRadius.circular(20.0),
                              clipBehavior: Clip.hardEdge,
                              child: Container(
//                                            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: white_color,
                                  borderRadius:
                                  BorderRadius.circular(20.0),
                                ),
                                child: Image.network(
                                  bigImage,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Text(
                    admins!.bottomMessage.toString(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  void getBackResult(latss, lngss) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    double lats = double.parse(prefs.getString('lat')!);
    double lngs = double.parse(prefs.getString('lng')!);
    //
    // prefs.setString("lat", latss.toStringAsFixed(8));
    // prefs.setString("lng", lngss.toStringAsFixed(8));

    print("LATLONG" + lat.toString() + lng.toString());
    List<Placemark> placemarks = await placemarkFromCoordinates(lats, lngs);

    print("LATLONG" + placemarks.toString());

    setState(() {
      cityName = (placemarks.elementAt(0).subLocality.toString()) +
          " ( " +
          (placemarks.elementAt(0).locality.toString()) +
          " )".toUpperCase();
      prefs.setString("addr", cityName.toString());
    });
    calladminsetting();
  }

  Future<void> pickbanner() async {
    var url2 = pickdropbanner;
    Uri myUri2 = Uri.parse(url2);
    var response = await http.get(myUri2);
    try {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response.body)['data'] as List;
          List<BannerDetails> tagObjs = tagObjsJson
              .map((tagJson) => BannerDetails.fromJson(tagJson))
              .toList();
          setState(() {
            pickBannerImage.clear();
            pickBannerImage = tagObjs;
            pickImage = imageBaseUrl + tagObjs[0].bannerImage;
          });
        }
      }
    } on Exception catch (_) {}
  }

  Future<void> Topbanner() async {
    var url2 = top_msg_banner;
    Uri myUri2 = Uri.parse(url2);
    var response = await http.get(myUri2);
    try {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response.body)['data'] as List;
          List<BannerDetails> tagObjs = tagObjsJson
              .map((tagJson) => BannerDetails.fromJson(tagJson))
              .toList();
          setState(() {
            topBannerImage.clear();
            topBannerImage = tagObjs;
            TopImage = imageBaseUrl + tagObjs[0].bannerImage;
          });
        }
      }
    } on Exception catch (_) {}
  }

  void hitService(String lat, String lng) async {
    var endpointUrl = vendorUrl;
    Map<String, String> queryParams = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString = Uri(queryParameters: queryParams).query;
    var requestUrl = endpointUrl +
        '?' +
        queryString; // result - https://www.myurl.com/api/v1/user?param1=1&param2=2
    print(requestUrl);
    Uri myUri = Uri.parse(requestUrl);

    var response = await http.get(myUri);
    {
      try {
        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          if (jsonData['status'] == "1") {
            var tagObjsJson = jsonDecode(response.body)['data'] as List;
            List<VendorList> tagObjs = tagObjsJson
                .map((tagJson) => VendorList.fromJson(tagJson))
                .toList();

            setState(() {
              nearStores.clear();
              nearStores = tagObjs;
            });
          }
        }
      } on Exception catch (_) {
        Timer(Duration(seconds: 5), () {
          hitService(lat.toString(), lng.toString());
        });
      }
    }

    var endpointUrl1 = newvendorUrl;
    Map<String, String> queryParams1 = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString1 = Uri(queryParameters: queryParams1).query;
    var requestUrl1 = endpointUrl1 +
        '?' +
        queryString1; // result - https://www.myurl.com/api/v1/user?param1=1&param2=2
    print(requestUrl1);
    Uri myUri1 = Uri.parse(requestUrl1);
    var response1 = await http.get(myUri1);
    {
      try {
        if (response1.statusCode == 200) {
          var jsonData = jsonDecode(response1.body);
          if (jsonData['status'] == "1") {
            var tagObjsJson = jsonDecode(response1.body)['data'] as List;
            List<VendorList> tagObjs = tagObjsJson
                .map((tagJson) => VendorList.fromJson(tagJson))
                .toList();
            setState(() {
              newnearStores.clear();
              newnearStores = tagObjs;
            });
          }
        }
      } on Exception catch (_) {
        Timer(Duration(seconds: 5), () {
          hitService(lat.toString(), lng.toString());
        });
      }
    }
  }

  void hitBannerUrl() async {
    setState(() {
      isFetch = true;
    });
    var url = bannerUrl;
    Uri myUri = Uri.parse(url);
    http.get(myUri).then((response) {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response.body)['data'] as List;
          List<BannerDetails> tagObjs = tagObjsJson
              .map((tagJson) => BannerDetails.fromJson(tagJson))
              .toList();
          if (tagObjs.isNotEmpty) {
            setState(() {
              listImage.clear();
              listImage = tagObjs;

              print('Bottom Image: $tagObjsJson');
            });
          } else {
            setState(() {
              isFetch = false;
            });
          }
        } else {
          setState(() {
            isFetch = false;
          });
        }
      } else {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      print(e);
      setState(() {
        isFetch = false;
      });
    });

    var url3 = bigbanner;
    Uri myUri3 = Uri.parse(url3);
    var response3 = await http.get(myUri3);
    try {
      if (response3.statusCode == 200) {
        var jsonData = jsonDecode(response3.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response3.body)['data'] as List;
          List<BannerDetails> tagObjs = tagObjsJson
              .map((tagJson) => BannerDetails.fromJson(tagJson))
              .toList();
          setState(() {
            bigImage = imageBaseUrl + tagObjs[0].bannerImage;
          });
        }
      }
    } on Exception catch (_) {}

    var url1 = subsbanner;
    Uri myUri1 = Uri.parse(url1);

    var response1 = await http.get(myUri1);
    try {
      if (response1.statusCode == 200) {
        var jsonData = jsonDecode(response1.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response1.body)['data'] as List;
          List<BannerDetails> tagObjs = tagObjsJson
              .map((tagJson) => BannerDetails.fromJson(tagJson))
              .toList();
          setState(() {
            subsImage = tagObjs[0].bannerImage;
          });
        }
      }
    } on Exception catch (_) {}
  }

  void hitNavigator(context, category_name, ui_type, vendor_category_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (ui_type == "grocery" || ui_type == "Grocery" || ui_type == "1") {
      prefs.setString("vendor_cat_id", '${vendor_category_id}');
      prefs.setString("ui_type", '${ui_type}');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  StoresPage(category_name, vendor_category_id)));
    }
  }

  void hitService1() async {
    setState(() {
      isFetchStore = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = nearByStore;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {
      'lat': '${prefs.getString('lat')}',
      'lng': '${prefs.getString('lng')}',
      'vendor_category_id': '${vendor_category_id}',
      'ui_type': '4'
    }).then((value) {
      print('${value.statusCode} ${value.body}');
      if (value.statusCode == 200) {
        print('Response Body: - ${value.body}');
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<NearStores> tagObjs = tagObjsJson
              .map((tagJson) => NearStores.fromJson(tagJson))
              .toList();
          setState(() {
            nearStores1.clear();
            nearStoresSearch1.clear();
            nearStores1 = tagObjs;
            nearStoresSearch1 = List.from(nearStores1);
          });
        }
      }
      setState(() {
        isFetchStore = false;
      });
    }).catchError((e) {
      setState(() {
        isFetchStore = false;
      });
      print(e);
      Timer(Duration(seconds: 5), () {
        hitService(lat.toString(), lng.toString());
      });
    });

    hitNavigator1(context, lat, lng, nearStores1[0].vendor_name,
        nearStores1[0].vendor_id, nearStores1[0].distance);
  }

  void getData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    try {
      setState(() {
        cityName = pref.getString("addr")!;
        lat = double.parse(pref.getString("lat")!);
        lng = double.parse(pref.getString("lng")!);
      });
      print("HOME_ORDER_HOME" + lat.toString() + lng.toString());
    } catch (e) {
      print(e);
    }

    if (pref.getString("lat") == null ||
        pref.getString("lat").toString().isEmpty) {
      _getLocation(context);
    }
  }

  void hitbannerVendor(BannerDetails detail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (detail.uiType == "grocery" ||
        detail.uiType == "Grocery" ||
        detail.uiType == 1) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => new AppCategory(detail.vendorCategoryId,
                  detail.vendorName, detail.vendorId, "2.5")));
    } else if (detail.uiType == "resturant" ||
        detail.uiType == "Resturant" ||
        detail.uiType == 2) {
      print("REST BANNER");
      print("REST BANNER" + detail.vendorId.toString());

      for (int i = 0; i < rest_nearStores.length; i++) {
        print(
            "REST BANNER" + rest_nearStores.elementAt(i).vendor_id.toString());

        if (rest_nearStores.elementAt(i).vendor_id.toString() ==
            detail.vendorId.toString()) {

        }
      }
    }
  }




  hitNavigatorStore(BuildContext context, vendor_name, vendorCategoryId, vendor_id,
      distance) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isCartCount &&
        prefs.getString("vendor_id") != null &&
        prefs.getString("vendor_id") != "" &&
        prefs.getString("vendor_id") != '${vendor_id}') {
      ///showAlertDialog(context, vendor_name, vendor_id, distance);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AppCategory(
                  vendorCategoryId, vendor_name, vendor_id, distance)))
          .then((value) {
        getCartCount();
      });
    } else {
      prefs.setString("vendor_id", '${vendor_id}');
      prefs.setString("store_name", '${vendor_name}');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AppCategory(
                  vendorCategoryId, vendor_name, vendor_id, distance)))
          .then((value) {
        getCartCount();
      });
    }
  }
  void hitRestaurantService() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print(
        'data - ${prefs.getString('lat')} - ${prefs.getString('lng')} - ${prefs.getString('vendor_cat_id')} - ${prefs.getString('ui_type')}');
    var url = nearByStore;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {
      'lat': '${prefs.getString('lat')}',
      'lng': '${prefs.getString('lng')}',
      'vendor_category_id': '12',
      'ui_type': '2'
    }).then((value) {
      print('${value.statusCode} ${value.body}');
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<NearStores> tagObjs = tagObjsJson
              .map((tagJson) => NearStores.fromJson(tagJson))
              .toList();

          setState(() {
            rest_nearStores.clear();
            rest_nearStores = tagObjs;
          });
          print('Response Body: - ' + rest_nearStores.toString());
        } else {}
      } else {}
    }).catchError((e) {
      print(e);
      Timer(Duration(seconds: 5), () {
        hitRestaurantService();
      });
    });
  }

  hitNavigator1(
      BuildContext context, lat, lng, vendor_name, vendor_id, distance) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("pr_vendor_id", '${vendor_id}');
    prefs.setString("pr_store_name", '${vendor_name}');

    // Navigator.of(context).push(MaterialPageRoute(builder: (context) {
    //   return ParcelLocation();
    // }));

    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) =>
    //             AddressFrom(vendor_name, vendor_id, distance)));
  }

  void callSearch() {
    var url = Search_key;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'prod_name': searchController.text.toString()
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        print('Response Body: - ${value.body}');
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['vendor'] as List;
          List<Vendors> tagObjs =
          tagObjsJson.map((tagJson) => Vendors.fromJson(tagJson)).toList();
          if (tagObjs.isNotEmpty) {
            print(tagObjs.elementAt(0).vendorName);
          }
        }
      }
    });
  }

  void checksubscription() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var url = checksubs;
      Uri myUri = Uri.parse(url);

      var response = await http.post(myUri, body: {
        'user_phone': prefs.getString('user_phone')
      });

      if (response.statusCode == 200) {
        // Ensure response is JSON before decoding
        if (response.headers['content-type'] != null &&
            response.headers['content-type']!.contains('application/json')) {
          var jsonData = jsonDecode(response.body);

          if (jsonData['status'] == "1") {
            setState(() {
              subscriptionbanner = false;
              subscriptionStore = true;
              callSubStore();
            });
          } else if (jsonData['status'] == "2") {
            setState(() {
              subscriptionbanner = false;
              subscriptionStore = false;
              subsenddate = '';
            });
          } else {
            setState(() {
              subscriptionbanner = true;
              subscriptionStore = false;
              subsenddate = '';
            });
          }

          if (jsonData['enddate'] != null &&
              jsonData['enddate'].toString().isNotEmpty) {
            setState(() {
              subsenddate = jsonData['enddate'].toString();
            });
          }

          if (jsonData['allowmultishop'] != null &&
              jsonData['allowmultishop'].toString().isNotEmpty) {
            prefs.setString(
                "allowmultishop", jsonData['allowmultishop'].toString());
          } else {
            prefs.setString("allowmultishop", "0");
          }
        } else {
          print("Unexpected content type: ${response.headers['content-type']}");
        }
      } else {
        print("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in checksubscription: $e");
    }
  }

  void callSubStore() async {
    var url = subsstore;
    Map<String, String> queryParams = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    Uri myUri = Uri.parse(url);
    final finalUri = myUri.replace(queryParameters: queryParams); //USE THIS

    print("SUBSTORE: " + finalUri.toString());

    var value = await http.get(finalUri);
    var jsonData = jsonDecode(value.body.toString());
    if (jsonData['status'] == "1") {
      var tagObjsJson = jsonDecode(value.body)['data'] as List;
      List<Vendors> tagObjs =
      tagObjsJson.map((tagJson) => Vendors.fromJson(tagJson)).toList();
      setState(() {
        substores.clear();
        substores = tagObjs;
      });
    }
  }

  void calladminsetting() async {
    var url = adminsettings;
    Uri myUri = Uri.parse(url);
    var value = await http.get(myUri);
    var jsonData = jsonDecode(value.body.toString());
    if (jsonData['status'] == "1") {
      admins = Adminsetting.fromJson(jsonData['data']);
      /* print("ADMIN RES: " + admins!.cityadminId.toString());*/
      if (admins!.status == 1) {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        messaging.getToken().then((value) {
          print(value);
        });
        getCurrency();
        Topbanner();
        hitService(lat.toString(), lng.toString());
        hitBannerUrl();
        pickbanner();
        hitRestaurantService();

        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString("message", admins!.bottomMessage.toString());

        // location.changeSettings(
        //     interval: 300, accuracy: loc.LocationAccuracy.high);
        // location.enableBackgroundMode(enable: true);
        setState(() {});
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Closed()),
                (Route<dynamic> route) => false);
      }
    }
  }


}

class BackendService {
  static Future<List<Vendors>> getSuggestions(
      String query, double lat, double lng) async {
    if (query.isEmpty && query.length < 2) {
      print('Query needs to be at least 3 chars');
      return Future.value([]);
    }

    var url = Search_key;
    Uri myUri = Uri.parse(url);
    var response = await http.post(myUri, body: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'prod_name': query
    });

    List<Vendors> vendors = [];
    List<Vendors> resturant = [];
    List<Vendors> product = [];
    List<Vendors> cat = [];
    List<Vendors> restcat = [];

    if (response.statusCode == 200) {
      Iterable json1 = jsonDecode(response.body)['vendor'];
      Iterable json2 = jsonDecode(response.body)['restproduct'];
      Iterable json3 = jsonDecode(response.body)['product'];
      Iterable json4 = jsonDecode(response.body)['cat'];
      Iterable json5 = jsonDecode(response.body)['restcat'];

      if (json1.isNotEmpty) {
        vendors.clear();
        vendors =
        List<Vendors>.from(json1.map((model) => Vendors.fromJson(model)));
      }
      if (json2.isNotEmpty) {
        resturant.clear();
        resturant =
        List<Vendors>.from(json2.map((model) => Vendors.fromJson(model)));
        vendors.addAll(resturant);
      }
      if (json3.isNotEmpty) {
        product.clear();
        product =
        List<Vendors>.from(json3.map((model) => Vendors.fromJson(model)));
        vendors.addAll(product);
      }
      if (json4.isNotEmpty) {
        cat.clear();
        cat = List<Vendors>.from(json4.map((model) => Vendors.fromJson(model)));
        vendors.addAll(cat);
      }
      if (json5.isNotEmpty) {
        restcat.clear();
        restcat =
        List<Vendors>.from(json5.map((model) => Vendors.fromJson(model)));
        vendors.addAll(restcat);
      }
    }
    return Future.value(vendors);
  }
}

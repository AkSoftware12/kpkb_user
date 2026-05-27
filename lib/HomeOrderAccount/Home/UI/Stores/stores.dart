import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../../BlinkitUI/blinkit_cat.dart';
import '../../../../Components/custom_appbar.dart';
import '../../../../Pages/oneViewCart.dart';
import '../../../../Routes/routes.dart';
import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/bannerbean.dart';
import '../../../../bean/nearstorebean.dart';
import '../../../../bean/vendorbanner.dart';
import '../../../../databasehelper/dbhelper.dart';
import '../../../home_order_account.dart';
import '../appcategory/appcategory.dart';

class StoresPage extends StatefulWidget {
  final String pageTitle;
  final dynamic vendor_category_id;

  StoresPage(this.pageTitle, this.vendor_category_id);

  @override
  State<StatefulWidget> createState() {
    return StoresPageState(pageTitle, vendor_category_id);
  }
}

class StoresPageState extends State<StoresPage> {
  final String pageTitle;
  final dynamic vendor_category_id;

  List<VendorBanner> listImage = [];
  List<NearStores> nearStores = [];
  List<NearStores> nearStoresSearch = [];
  List<NearStores> nearStoresShimmer = [
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
  List<String> listImages = ['', '', '', '', ''];
  bool isFetch = true;
  bool isFetchStore = true;

  StoresPageState(this.pageTitle, this.vendor_category_id);

  TextEditingController searchController = TextEditingController();
  bool isCartCount = false;
  int cartCount = 0;
  double userLat = 0.0;
  double userLng = 0.0;
  var _dotPosition = 0;

  String message = "";

  int _currentIndex = 0;

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

  @override
  void initState() {
    print("vendor id is : $vendor_category_id");
    getShareValue();
    super.initState();
    hitService();
    hitBannerUrl1();
    getCartCount();
    hitRestaurantService();
  }

  getShareValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userLat = double.parse('${prefs.getString('lat')}');
      userLng = double.parse('${prefs.getString('lng')}');
      message = prefs.getString("message")!;
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String calculateTime(lat1, lon1, lat2, lon2) {
    double kms = calculateDistance(lat1, lon1, lat2, lon2);
    double kms_per_min = 0.5;
    double mins_taken = kms / kms_per_min;
    double min = mins_taken;
    if (min < 60) {
      return "" + '${min.toInt()}' + " mins";
    } else {
      double tt = min % 60;
      String minutes = '${tt.toInt()}';
      minutes = minutes.length == 1 ? "0" + minutes : minutes;
      return '${(min.toInt() / 60)}' + " hour " + minutes + "mins";
    }
  }

  void getCartCount() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.queryRowCount().then((value) {
      setState(() {
        if (value != null && value > 0) {
          cartCount = value;
          isCartCount = true;
        } else {
          cartCount = 0;
          isCartCount = false;
        }
      });
    });
  }

  late List<NearStores> rest_nearStores = [];
  String? currency = '';

  @override
  void dispose() {
    super.dispose();
  }

  void hitNavigator1(
    context,
    category_name,
    ui_type,
    vendor_category_id,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (ui_type == "grocery" || ui_type == "Grocery" || ui_type == "1") {
      prefs.setString("vendor_cat_id", '${vendor_category_id}');
      prefs.setString("ui_type", '${ui_type}');
      if (vendor_category_id == '18' || vendor_category_id == 18) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 500,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset("images/id.png"),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('You need to be above 18 years of age',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.w400)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Do not buy tobacco products on behalf of underage persons.',
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Your location must not be in and around school or college premises.',
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Jhatfat reserves the right to report your account in case you are below 18 years of age and purchasing cigrattes',
                          style:
                              TextStyle(color: Colors.blueGrey, fontSize: 14)),
                    ),
                    new GestureDetector(
                      onTap: () {
                        Navigator.popAndPushNamed(context, PageRoutes.tncPage);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Read T&C',
                            style:
                                TextStyle(color: Colors.green, fontSize: 12)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            backgroundColor: kWhiteColor,
                            padding: EdgeInsets.all(10),
                          ),
                          child: const Text(
                            "No,I'm not",
                            style: TextStyle(
                                color: Color(0xffeca53d),
                                fontWeight: FontWeight.w400),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            backgroundColor: kMainColor,
                            padding: EdgeInsets.all(10),
                          ),
                          child: const Text("Yes,I'm above 18"),
                          onPressed: () => {
                            Navigator.pop(context),
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StoresPage(
                                        category_name, vendor_category_id)))
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
        print("Not cigarette");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    StoresPage(category_name, vendor_category_id)));
      }
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
                  detail.vendorName, detail.vendorId, '2.5')));
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

  List<NearStores> removeDuplicateTransactions(List<NearStores> transactions) {
    final seen = <String>{};
    return transactions.where((transaction) => seen.add(transaction.vendor_id.toString())).toList();
  }
  void hitNavigator2(BuildContext context, NearStores item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isCartCount &&
        prefs.getString("res_vendor_id") != null &&
        prefs.getString("res_vendor_id") != "" &&
        prefs.getString("res_vendor_id") != '${item.vendor_id}') {
      // showMyDialog(context, item, currency);
    } else {
      prefs.setString("res_vendor_id", '${item.vendor_id}');
      prefs.setString("res_pack_charge", '${item.packaging_charges}');
      prefs.setString("store_resturant_name", '${item.vendor_name}');

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

  @override
  Widget build(BuildContext context) {
    List<NearStores> uniqueTransactions = removeDuplicateTransactions(nearStores);

    return WillPopScope(
      onWillPop: () async {
        if (searchController != null && searchController.text.length > 0) {
          setState(() {
            searchController.clear();
            nearStores.clear();
            nearStores = List.from(nearStoresSearch);
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: CustomAppBar(
            color: Colors.white,
            titleWidget: Text(
              pageTitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Stack(
                  children: [
                    IconButton(
                        icon: ImageIcon(
                          AssetImage('images/icons/ic_cart blk.png'),
                        ),
                        onPressed: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? skip = prefs.getString('skip');
                          if (skip != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => oneViewCart(),
                              ),
                            );
                          } else {
                            Navigator.pushNamed(context, PageRoutes.viewCart)
                                .then((value) {
                              getCartCount();
                            });
                          }
                        }),
                    // Positioned(
                    //     right: 5,
                    //     top: 2,
                    //     child: Visibility(
                    //       visible: isCartCount,
                    //       child: CircleAvatar(
                    //         minRadius: 4,
                    //         maxRadius: 8,
                    //         backgroundColor: kMainColor,
                    //         child: Text(
                    //           '$cartCount',
                    //           overflow: TextOverflow.ellipsis,
                    //           style: TextStyle(
                    //               fontSize: 7,
                    //               color: kWhiteColor,
                    //               fontWeight: FontWeight.w200),
                    //         ),
                    //       ),
                    //     ))
                  ],
                ),
              ),
            ],
            // bottom: PreferredSize(
            //     child: Container(
            //       width: MediaQuery.of(context).size.width * 0.85,
            //       height: 52,
            //       padding: EdgeInsets.only(left: 5),
            //       decoration: BoxDecoration(
            //           color: scaffoldBgColor,
            //           borderRadius: BorderRadius.circular(50)),
            //       child: TextFormField(
            //         decoration: InputDecoration(
            //           border: InputBorder.none,
            //           prefixIcon: Icon(
            //             Icons.search,
            //             color: kHintColor,
            //           ),
            //           hintText: 'Search store...',
            //         ),
            //         controller: searchController,
            //         cursorColor: kMainColor,
            //         autofocus: false,
            //         onChanged: (value) {
            //           nearStores = nearStoresSearch
            //               .where((element) => element.vendor_name
            //                   .toString()
            //                   .toLowerCase()
            //                   .contains(value.toLowerCase()))
            //               .toList();
            //         },
            //       ),
            //     ),
            //     preferredSize:
            //         Size(MediaQuery.of(context).size.width * 0.85, 52)),
          ),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height - 110,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 18.0),
                  child: Text(
                    'Also Explore:',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                if (data.isNotEmpty)
                  Column(children: [
                    const SizedBox(
                      height: 1,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: AspectRatio(
                        aspectRatio: 2.5,
                        child: CarouselSlider(
                            items: data
                                .map((item) => Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 10),
                                          child: Material(
                                            elevation: 5,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            clipBehavior: Clip.hardEdge,
                                            child: Container(
                                              height: 165,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.99,
                                              //                                            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                                              decoration: BoxDecoration(
                                                color: white_color,
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  if (item[
                                                          'vendor_category_id'] ==
                                                      24) {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => BlinkitCategory(
                                                                item[
                                                                    'banner_name'],
                                                                item['vendor_id']
                                                                    .toString(),
                                                                item['vendor_cat_id']
                                                                    .toString(),
                                                                '2.5')));
                                                  } else if (item['ui_type'] == '1') {

                                                    if(item['store_open'] == 'OFF'){
                                                      Fluttertoast.showToast(
                                                        msg: "Store open at ${item['opening_time'].toString()}",
                                                        toastLength: Toast.LENGTH_LONG,
                                                        gravity: ToastGravity.CENTER,
                                                        backgroundColor: Colors.red,
                                                        textColor: Colors.white,
                                                        fontSize: 16.sp,
                                                      );
                                                    }else {


                                                      SharedPreferences prefs =
                                                          await SharedPreferences.getInstance();
                                                      print("store hit");
                                                      hitNavigatorStore(
                                                          context,
                                                          item['banner_name'].toString(),
                                                          item['vendor_cat_id'].toString(),
                                                          item['vendor_id'].toString(),
                                                          '2.5'
                                                      );

                                                      prefs.setString(
                                                          "res_pack_charge",'0');
                                                    }



                                                  } else if (item['ui_type'] ==
                                                      '2') {
                                                    for (int i = 0;
                                                        i <
                                                            rest_nearStores
                                                                .length;
                                                        i++) {
                                                      print("REST BANNER" +
                                                          rest_nearStores
                                                              .elementAt(i)
                                                              .vendor_id
                                                              .toString());

                                                      if (rest_nearStores
                                                              .elementAt(i)
                                                              .vendor_id
                                                              .toString() ==
                                                          item['vendor_id']
                                                              .toString()) {

                                                        if(item['store_open'] == 'OFF'){
                                                          Fluttertoast.showToast(
                                                            msg: "Store open at ${item['opening_time'].toString()}",
                                                            toastLength: Toast.LENGTH_LONG,
                                                            gravity: ToastGravity.CENTER,
                                                            backgroundColor: Colors.red,
                                                            textColor: Colors.white,
                                                            fontSize: 16.sp,
                                                          );
                                                        }else{
                                                          for (var store in rest_nearStores) {
                                                            if (store.vendor_id.toString() ==  item['vendor_id'].toString()) {
                                                              hitNavigator2(context, store);
                                                              break;
                                                            }
                                                          }

                                                          // Navigator.push(
                                                          //     context,
                                                          //     MaterialPageRoute(
                                                          //         builder: (context) => Restaurant_Sub(
                                                          //             rest_nearStores
                                                          //                 .elementAt(
                                                          //                 i),
                                                          //             currency)));
                                                        }



                                                      }
                                                    }
                                                  } else if(item['ui_type']=='4'){

                                                    // prefs.setString("vendor_cat_id", '${vendor_category_id}');
                                                    // prefs.setString("ui_type", '${ui_type}');
                                                    Navigator.pushAndRemoveUntil(context,
                                                        MaterialPageRoute(builder: (context) {
                                                          return HomeOrderAccount(2,1);
                                                        }), (Route<dynamic> route) => true);


                                                  }

                                                  // Navigator.push(
                                                  //     context,
                                                  //     MaterialPageRoute(
                                                  //         builder: (context) => StoresPage(
                                                  //             )))
                                                  //     .then((value) {
                                                  //   getCartCount();
                                                  // });
                                                  // h
                                                  // itNavigator1(
                                                  //     context,
                                                  //     item['banner_name'],
                                                  //     item['ui_type'],
                                                  //     item['vendor_cat_id']
                                                  // );
                                                },
                                                child: Image.network(
                                                  imageBaseUrl +
                                                      item['banner_img'],
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                    //     Container(
                                    //   decoration: BoxDecoration(
                                    //       borderRadius:
                                    //       BorderRadius.circular(
                                    //           20.0),
                                    //       image: DecorationImage(image: NetworkImage( imageBaseUrl +
                                    //           item['banner_img']),fit:BoxFit.fitWidth)
                                    //   ),
                                    // )
                                    )
                                .toList(),
                            options: CarouselOptions(
                                height: 165.0,
                                aspectRatio: 2 / 1,
                                viewportFraction: 0.85,
                                initialPage: 0,
                                enableInfiniteScroll: true,
                                reverse: false,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration:
                                    const Duration(milliseconds: 800),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enlargeCenterPage: false,
                                enlargeFactor: 0.3,
                                onPageChanged:
                                    (val, carouselPageChangedReason) {
                                  setState(
                                    () {
                                      _dotPosition = val;
                                    },
                                  );
                                })),
                      ),
                    ),
                    const SizedBox(height: 1),
                    DotsIndicator(
                      dotsCount: data.isEmpty ? 1 : data.length,
                      position: _dotPosition.toDouble(),
                      decorator: const DotsDecorator(
                        activeColor: Colors.orange,
                        color: Colors.blueGrey,
                        spacing: EdgeInsets.all(2),
                        activeSize: Size(8, 8),
                        size: Size(6, 6),
                      ),
                    ),
                  ]),
//                 Column(
//                   children: [
//
//                     Padding(
//                       padding: EdgeInsets.only(top: 10, bottom: 5),
//                       child: CarouselSlider(
//                           options: CarouselOptions(
//                             height: 150.0,
//                             autoPlay: true,
//                             initialPage: 0,
//                             viewportFraction: 0.9,
//                             enableInfiniteScroll: true,
//                             reverse: false,
//                             autoPlayInterval: Duration(seconds: 3),
//                             autoPlayAnimationDuration:
//                             Duration(milliseconds: 800),
//                             autoPlayCurve: Curves.fastOutSlowIn,
//                             scrollDirection: Axis.horizontal,
//                           ),
//                           items: (data.length > 0)
//                               ? data.map((e) {
//                             return Builder(
//                               builder: (context) {
//                                 return InkWell(
//                                   onTap: () {
//                                     // hitNavigator(
//                                     //     context,
//                                     //     e['banner_name'],
//                                     //     e['ui_type'],
//                                     //     e['vendor_cat_id']);
//                                   },
//                                   child: Padding(
//                                     padding: EdgeInsets.symmetric(
//                                         horizontal: 5,
//                                         vertical: 10),
//                                     child: Material(
//                                       elevation: 5,
//                                       borderRadius:
//                                       BorderRadius.circular(
//                                           20.0),
//                                       clipBehavior: Clip.hardEdge,
//                                       child: Container(
//                                         height: 200,
//                                         width:
//                                         MediaQuery.of(context)
//                                             .size
//                                             .width *
//                                             0.90,
// //                                            padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
//                                         decoration: BoxDecoration(
//                                           color: white_color,
//                                           borderRadius:
//                                           BorderRadius.circular(
//                                               20.0),
//                                         ),
//                                         child: Image.network(
//                                           imageBaseUrl +
//                                               e['banner_img'],
//                                           fit: BoxFit.fill,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             );
//                           }).toList()
//                               : data.map((e) {
//                             return Builder(builder: (context) {
//                               return Container(
//                                 height: 200,
//                                 width: MediaQuery.of(context)
//                                     .size
//                                     .width *
//                                     0.90,
//                                 margin: EdgeInsets.symmetric(
//                                     horizontal: 5.0),
//                                 decoration: BoxDecoration(
//                                   borderRadius:
//                                   BorderRadius.circular(20.0),
//                                 ),
//                                 child: Shimmer(
//                                   duration: Duration(seconds: 3),
//                                   //Default value
//                                   color: Colors.white,
//                                   //Default value
//                                   enabled: true,
//                                   //Default value
//                                   direction:
//                                   ShimmerDirection.fromLTRB(),
//                                   //Default Value
//                                   child: Container(
//                                     color: kTransparentColor,
//                                   ),
//                                 ),
//                               );
//                             });
//                           }).toList()),
//                     ),
//
//                   ],
//                 ),
                const SizedBox(height: 10),
                PreferredSize(
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 52,
                        padding: EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                            color: scaffoldBgColor,
                            borderRadius: BorderRadius.circular(50)),
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: kHintColor,
                            ),
                            hintText: 'Search store...',
                          ),
                          controller: searchController,
                          cursorColor: kMainColor,
                          autofocus: false,
                          onChanged: (value) {
                            nearStores = nearStoresSearch
                                .where((element) => element.vendor_name
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          },
                        ),
                      ),
                    ),
                    preferredSize:
                        Size(MediaQuery.of(context).size.width * 0.85, 52)),
                Padding(
                  padding: EdgeInsets.only(left: 20.0, top: 1.0),
                  child: Text(
                    '${uniqueTransactions.length} Stores found',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: kHintColor, fontSize: 18),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                (nearStores != null && nearStores.length > 0)
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: ListView.separated(
                            shrinkWrap: true,
                            primary: false,
                            scrollDirection: Axis.vertical,
                            itemCount: uniqueTransactions.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () async {
                                  if ((uniqueTransactions[index].online_status ==
                                          "off" ||
                                      uniqueTransactions[index].online_status ==
                                          "Off" ||
                                      uniqueTransactions[index].online_status ==
                                          "OFF")) {
                                  } else if (uniqueTransactions[index].inrange == 0) {
                                  } else {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    print("store hit");
                                    hitNavigator(
                                        context,
                                        uniqueTransactions[index].vendor_name,
                                        uniqueTransactions[index].vendor_category_id,
                                        uniqueTransactions[index].vendor_id,
                                        uniqueTransactions[index].distance);
                                    prefs.setString(
                                        "res_pack_charge",
                                        uniqueTransactions[index]
                                            .packaging_charges
                                            .toString());
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Material(
                                  elevation: 2,
                                  shadowColor: white_color,
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        color: white_color,
                                        padding: EdgeInsets.only(
                                            left: 20.0, top: 15, bottom: 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            // Image.network(
                                            //   imageBaseUrl +
                                            //       nearStores[index].vendor_logo,
                                            //   width: 93.3,
                                            //   height: 93.3,
                                            // ),

                                            Image.network(
                                              imageBaseUrl +
                                                  uniqueTransactions[index].vendor_logo,
                                              width: 93.3,
                                              height: 93.3,
                                              errorBuilder:
                                                  (BuildContext context,
                                                      Object exception,
                                                      StackTrace? stackTrace) {
                                                // Return a placeholder/default image when the network image fails to load
                                                return Image.network(
                                                  'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900',
                                                  width: 93.3,
                                                  height: 93.3,
                                                );
                                                // Replace 'default_image.png' with your default image asset path
                                              },
                                            ),
                                            SizedBox(width: 13.3),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                      uniqueTransactions[index]
                                                          .vendor_name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall!
                                                          .copyWith(
                                                              color:
                                                                  kMainTextColor,
                                                              fontSize: 18)),
                                                  SizedBox(height: 8.0),
                                                  Row(
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.location_on,
                                                        color: kIconColor,
                                                        size: 15,
                                                      ),
                                                      SizedBox(width: 10.0),
                                                      Text(
                                                          '${double.parse('${uniqueTransactions[index].distance}').toStringAsFixed(2)} km ',
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                  color:
                                                                      kLightTextColor,
                                                                  fontSize:
                                                                      13.0)),
                                                      Text('| ',
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                  color:
                                                                      kMainColor,
                                                                  fontSize:
                                                                      13.0)),
                                                      Expanded(
                                                        child: Text(
                                                            '${uniqueTransactions[index].vendor_loc}',
                                                            maxLines: 2,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall!
                                                                .copyWith(
                                                                    color:
                                                                        kLightTextColor,
                                                                    fontSize:
                                                                        13.0)),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 6),
                                                  Row(
                                                    children: <Widget>[
                                                      Icon(
                                                        Icons.access_time,
                                                        color: kIconColor,
                                                        size: 15,
                                                      ),
                                                      SizedBox(width: 10.0),
                                                      Text(
                                                          '${uniqueTransactions[index].duration}',
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                  color:
                                                                      kLightTextColor,
                                                                  fontSize:
                                                                      13.0)),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 18.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                                '${uniqueTransactions[index].online_status}',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall!
                                                                    .copyWith(
                                                                        color: Colors
                                                                            .green,
                                                                        fontSize:
                                                                            13.0)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.all(8),
                                                    child: Visibility(
                                                      visible: (nearStores[
                                                                          index]
                                                                      .online_status ==
                                                                  "off" ||
                                                              nearStores[index]
                                                                      .online_status ==
                                                                  "Off" ||
                                                              nearStores[index]
                                                                      .online_status ==
                                                                  "OFF")
                                                          ? true
                                                          : false,
                                                      child: Container(
                                                        margin:
                                                            EdgeInsets.all(8),
                                                        height: 80,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            10,
                                                        alignment:
                                                            Alignment.center,
                                                        color:
                                                            kCardBackgroundColor,
                                                        child: Text(
                                                          'Store open at ${nearStores[index].opening_time.toString()}',
                                                          style: TextStyle(
                                                              color: red_color,
                                                              fontSize: 15),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.all(8),
                                                    child: Visibility(
                                                      visible: (nearStores[
                                                                      index]
                                                                  .inrange ==
                                                              0)
                                                          ? true
                                                          : false,
                                                      child: Container(
                                                        margin:
                                                            EdgeInsets.all(8),
                                                        height: 80,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            10,
                                                        alignment:
                                                            Alignment.center,
                                                        color:
                                                            kCardBackgroundColor,
                                                        child: Text(
                                                          'Store Out of Delivery Range',
                                                          style: TextStyle(
                                                              color: red_color,
                                                              fontSize: 15),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return SizedBox(
                                height: 10,
                              );
                            }),
                      )
                    : Container(
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            isFetchStore
                                ? CircularProgressIndicator()
                                : Container(
                                    width: 0.5,
                                  ),
                            isFetchStore
                                ? SizedBox(
                                    width: 10,
                                  )
                                : Container(
                                    width: 0.5,
                                  ),
                            Text(
                              (!isFetchStore)
                                  ? 'No Store Found at your location'
                                  : 'Fetching Stores',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: kMainTextColor),
                            )
                          ],
                        ),
                      ),
                Container(
                  margin: EdgeInsets.all(12),
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    message.toString(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> data = [];

  Future<void> hitBannerUrl1() async {
    final response =
        await http.get(Uri.parse('${servicebanner}/${vendor_category_id}'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('data')) {
        setState(() {
          // Assuming 'data' is a list, update apiData accordingly
          data = responseData['data'];

          // await saveDataLocally(responseData['posts']);
        });
      } else {
        throw Exception('Invalid API response: Missing "data" key');
      }
    }
  }

  void hitService() async {
    setState(() {
      isFetchStore = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = nearByStore;
    Uri myUri = Uri.parse(url);
    print("Body parameters are: ${prefs.getString('lat')}");
    print("Body parameters are: ${prefs.getString('lng')}");
    print("Body parameters are: $vendor_category_id");
    print("Body parameters are: ${prefs.getString('ui_type')}");

    http.post(myUri, body: {
      'lat': '${prefs.getString('lat')}',
      'lng': '${prefs.getString('lng')}',
      'vendor_category_id': '${vendor_category_id}',
      'ui_type': '${prefs.getString('ui_type')}'
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<NearStores> tagObjs = tagObjsJson
              .map((tagJson) => NearStores.fromJson(tagJson))
              .toList();
          setState(() {
            nearStores.clear();
            nearStoresSearch.clear();
            nearStores = tagObjs;
            nearStoresSearch = List.from(nearStores);
          });
          print("Near Stores are : $nearStores");
        }
      }
      setState(() {
        isFetchStore = false;
      });
    }).catchError((e) {
      setState(() {
        isFetchStore = false;
      });
      Timer(Duration(seconds: 5), () {
        hitService();
      });
    });
  }

  void hitBannerUrl() async {
    var url = vendorBanner;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {'vendor_id': '$vendor_category_id'}).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(value.body)['data'] as List;
          List<VendorBanner> tagObjs = tagObjsJson
              .map((tagJson) => VendorBanner.fromJson(tagJson))
              .toList();
          if (tagObjs.isNotEmpty) {
            setState(() {
              listImage.clear();
              listImage = tagObjs;
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
      }
    }).catchError((e) {
      setState(() {
        isFetch = false;
      });
    });
  }

  showAlertDialog(BuildContext context, vendor_name, vendor_id, distance) {
    Widget clear = GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        deleteAllRestProduct(context, vendor_name, vendor_id, distance);
      },
      child: Material(
        elevation: 2,
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Text(
            'Clear',
            style: TextStyle(fontSize: 13, color: kWhiteColor),
          ),
        ),
      ),
    );

    Widget no = GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Text(
            'No',
            style: TextStyle(fontSize: 13, color: kWhiteColor),
          ),
        ),
      ),
    );
    AlertDialog alert = AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text("Inconvenience Notice"),
      content: Text(
          "Order from different store in single order is not allowed. Sorry for inconvenience"),
      actions: [clear, no],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  hitNavigator(BuildContext context, vendor_name, vendorCategoryId, vendor_id,
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

  void deleteAllRestProduct(
      BuildContext context, vendor_name, vendor_id, distance) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DatabaseHelper db = DatabaseHelper.instance;
    db.deleteAll().then((value) {
      prefs.setString("vendor_id", '${vendor_id}');
      prefs.setString("store_name", '${vendor_name}');
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) =>
      //             AppCategory(vendor_name, vendor_id, distance))).then((value) {
      //   getCartCount();
      // });
    });
  }
}

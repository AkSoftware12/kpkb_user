import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Themes/colors.dart';
import '../../../Themes/style.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/orderbean.dart';
import '../../../bean/resturantbean/orderhistorybean.dart';
import '../../Home/UI/order_placed_map.dart';


class OrderPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OrderPageState();
  }
}

class OrderPageState extends State<OrderPage>with SingleTickerProviderStateMixin {
  late TabController _tabController;


  List<OngoingOrders> onGoingOrders = [];
  List<OrderHistoryRestaurant> onRestGoingOrders = [];
  List<OrderHistoryRestaurant> onPharmaGoingOrders = [];
  // List<TodayOrderParcel> onParcelGoingOrders = [];

  List<String> VendorName=[];
  String message = "";

  var userId;
  String elseText = 'No ongoing order ...';
  dynamic currency = '';

  var khit = 0;
  bool isFetch = false;
  int countFetch = 0;

  List<String> tabDesign = [
    'Ongoing',
    'Cancelled',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    getData();
    getAllThreeData();
    getCompletedHistory();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });

  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
      // Call API for "Ongoing"
        getAllThreeData();
        break;
      case 1:
      // Call API for "Cancelled"
        getCancelledHistory();
        break;
      case 2:
      // Call API for "Completed"
        getCompletedHistory();
        break;
    }
  }
  void getData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState((){
      message = pref.getString("message")!;
    });

  }

  getOnGointOrders() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      currency = preferences.getString('curency');
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No ongoing order today...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    userId = preferences.getInt('user_id');
    setState(() {
      userId =  preferences.getInt('user_id');
    });

    print("userid:  "+userId.toString());

    var url = onGoingOrdersUrl;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            // onParcelGoingOrders.clear();
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          if (tagObjs.isNotEmpty) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            print("Ongoing orders are: $onGoingOrders");
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }
              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
          VendorName.toSet().toList();
        }
        if (countFetch == 4) {
          setState(() {
            isFetch = false;
          });
        }
      }
    })
      .catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCanceledOreders() async {
    setState(() {
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No canceled order till date...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
     userId = preferences.getInt('user_id');
    var url = cancelOrders;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      print('grocery cancelled orders are :${value.body}');
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            // onParcelGoingOrders.clear();
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
        }

      }else{
        setState(() {
          isFetch = false;
        });
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCompletedOrders() async {
    setState(() {
      elseText = 'No completed order till date...';
      List<OngoingOrders> onGoingOrderss = [];
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
     userId = preferences.getInt('user_id');
    var url = completeOrders;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) async {
      print('${value.body}');

      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            // onParcelGoingOrders.clear();
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {

            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              // await FirebaseFirestore.instance.collection('location').doc(onGoingOrders[i].cart_id.toString()).delete();

              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }

          }
        }
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }










  void getAllThreeData() {
    setState(() {
      isFetch = true;
      countFetch = 0;
    });
    getOnGointOrders();
  }

  void getCancelledHistory() async {
    setState(() {
      isFetch = true;
      countFetch = 0;
    });
    getCanceledOreders();
    // getRestCanceledOreders();
    // getPharmaCanceledOreders();
  }

  void getCompletedHistory() async {
    setState(() {
      isFetch = true;
      countFetch = 0;
    });
    getCompletedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:kWhiteColor,
        automaticallyImplyLeading: false,
        title: Center(child: Text('My Orders',style: TextStyle(color: Colors.black,fontSize: 15),)),

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20.sp), // Adjust height to fit the ListView
          child: Column(
            children: [

              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: "Ongoing"),
                  Tab(text: "Cancelled"),
                  Tab(text: "Completed"),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            child: Container(
                child:Visibility(
                    visible: (
                        (onRestGoingOrders != null &&
                            onRestGoingOrders.length > 0) ||
                        (onGoingOrders != null &&
                            onGoingOrders.length > 0) ||
                        (onPharmaGoingOrders != null &&
                            onPharmaGoingOrders.length > 0))
                        ? true
                        : false,
                    child: Column(
                      children: [
                        Visibility(
                          visible: (onGoingOrders != null &&
                              onGoingOrders.length > 0)
                              ? true
                              : false,
                          child:ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            // itemCount: onGoingOrders.length,
                            itemCount: 1,
                            // Ensure itemCount is set to the length of onGoingOrders
                            itemBuilder: (context, t) {
                              // Check if t is within the valid range of indices for onGoingOrders
                              if (t >= 0 && t < onGoingOrders.length) {
                                return GestureDetector(
                                  onTap: () {
                                    if (onGoingOrders[t].order_status ==
                                        'Cancelled') {
                                    } else {
                                      print("user_id on Tap is : ${onGoingOrders[t].cart_id.toString()}");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderMapPage(
                                                pageTitle:
                                                VendorName[t],
                                                ongoingOrders:
                                                onGoingOrders[t],
                                                currency: currency,
                                                user_id:onGoingOrders[t].cart_id.toString(),
                                              ),
                                        ),
                                      ).then((value) {
                                        if (khit == 0) {
                                          getAllThreeData();
                                        } else if (khit == 1) {
                                          getCancelledHistory();
                                        } else if (khit == 2) {
                                          getCompletedHistory();
                                        }
                                      });
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    child: Column(
                                      children: [
                                        Row(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                              const EdgeInsets.only(
                                                  left: 16.3),
                                              child: Image.asset(
                                                'images/maincategory/vegetables_fruitsact.png',
                                                height: 42.3,
                                                width: 33.7,
                                              ),
                                            ),
                                            Expanded(
                                              child: ListTile(
                                                title:Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Order Id - #${onGoingOrders[t].cart_id}',
                                                      style:
                                                      orderMapAppBarTextStyle
                                                          .copyWith(
                                                          letterSpacing:
                                                          0.07),
                                                    ),
                                                    Text(
                                                      onGoingOrders[t].data[t].product_name, // Replace this with your second text
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium!
                                                          .copyWith(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 15.0),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Text(
                                                  (onGoingOrders[t]
                                                      .delivery_date !=
                                                      null &&
                                                      onGoingOrders[t]
                                                          .time_slot !=
                                                          null)
                                                      ? '${onGoingOrders[t].delivery_date} | ${onGoingOrders[t].time_slot}'
                                                      : '',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                      fontSize: 11.7,
                                                      letterSpacing:
                                                      0.06,
                                                      color: Color(
                                                          0xffc1c1c1)),
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                                  children: <Widget>[
                                                    Text(
                                                      '${onGoingOrders[t].order_status}',
                                                      style: orderMapAppBarTextStyle
                                                          .copyWith(
                                                          color:
                                                          kMainColor),
                                                    ),
                                                    SizedBox(height: 7.0),
                                                    Text(
                                                      '${onGoingOrders[t].data.length} items | $currency ${onGoingOrders[t].price}',
                                                      style: Theme.of(
                                                          context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                          fontSize:
                                                          11.7,
                                                          letterSpacing:
                                                          0.06,
                                                          color: Color(
                                                              0xffc1c1c1)),
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
                                                  left: 36.0,
                                                  bottom: 6.0,
                                                  top: 12.0,
                                                  right: 12.0),
                                              child: ImageIcon(
                                                AssetImage(
                                                    'images/custom/ic_pickup_pointact.png'),
                                                size: 13.3,
                                                color: kMainColor,
                                              ),
                                            ),
                                            Text(
                                              VendorName[t]
                                              ,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                  fontSize: 10.0,
                                                  letterSpacing:
                                                  0.05),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  left: 36.0,
                                                  bottom: 12.0,
                                                  top: 12.0,
                                                  right: 12.0),
                                              child: ImageIcon(
                                                AssetImage(
                                                    'images/custom/ic_droppointact.png'),
                                                size: 13.3,
                                                color: kMainColor,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${onGoingOrders[t].address}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                    fontSize: 10.0,
                                                    letterSpacing:
                                                    0.05),
                                              ),
                                            ),
                                          ],
                                        ),
                                        (onGoingOrders.length - 1 == t)
                                            ? Divider(
                                          color:
                                          kCardBackgroundColor,
                                          thickness: 0,
                                        )
                                            : Divider(
                                          color:
                                          kCardBackgroundColor,
                                          thickness: 13.3,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // Return an empty container or handle out-of-bounds index as per your requirement
                                return Container();
                              }
                            },
                          ),),



                        // ListView.builder(
                        //     shrinkWrap: true,
                        //     primary: false,
                        //     itemBuilder: (context, t) {
                        //       return GestureDetector(
                        //         onTap: () {
                        //           if (onGoingOrders[t].order_status ==
                        //               'Cancelled') {
                        //           } else {
                        //             print("user_id on Tap is : ${onGoingOrders[t].cart_id.toString()}");
                        //             Navigator.push(
                        //               context,
                        //               MaterialPageRoute(
                        //                 builder: (context) =>
                        //                     OrderMapPage(
                        //                   pageTitle:
                        //                      VendorName[t],
                        //                   ongoingOrders:
                        //                       onGoingOrders[t],
                        //                   currency: currency,
                        //                       user_id:onGoingOrders[t].cart_id.toString(),
                        //                 ),
                        //               ),
                        //             ).then((value) {
                        //               if (khit == 0) {
                        //                 getAllThreeData();
                        //               } else if (khit == 1) {
                        //                 getCancelledHistory();
                        //               } else if (khit == 2) {
                        //                 getCompletedHistory();
                        //               }
                        //             });
                        //           }
                        //         },
                        //         behavior: HitTestBehavior.opaque,
                        //         child: Container(
                        //           child: Column(
                        //             children: [
                        //               Row(
                        //                 children: <Widget>[
                        //                   Padding(
                        //                     padding:
                        //                         const EdgeInsets.only(
                        //                             left: 16.3),
                        //                     child: Image.asset(
                        //                       'images/maincategory/vegetables_fruitsact.png',
                        //                       height: 42.3,
                        //                       width: 33.7,
                        //                     ),
                        //                   ),
                        //                   Expanded(
                        //                     child: ListTile(
                        //                       title:Column(
                        //                         crossAxisAlignment: CrossAxisAlignment.start,
                        //                         children: [
                        //                           Text(
                        //                             'Order Id - #${onGoingOrders[t].cart_id}',
                        //                             style:
                        //                             orderMapAppBarTextStyle
                        //                                 .copyWith(
                        //                                 letterSpacing:
                        //                                 0.07),
                        //                           ),
                        //                           Text(
                        //                             onGoingOrders[t].data[t].product_name, // Replace this with your second text
                        //                             style: Theme.of(context)
                        //                                 .textTheme
                        //                                 .headlineMedium!
                        //                                 .copyWith(
                        //                                 fontWeight: FontWeight.w500,
                        //                                 fontSize: 15.0),
                        //                           ),
                        //                         ],
                        //                       ),
                        //                       subtitle: Text(
                        //                         (onGoingOrders[t]
                        //                                         .delivery_date !=
                        //                                     null &&
                        //                                 onGoingOrders[t]
                        //                                         .time_slot !=
                        //                                     null)
                        //                             ? '${onGoingOrders[t].delivery_date} | ${onGoingOrders[t].time_slot}'
                        //                             : '',
                        //                         style: Theme.of(context)
                        //                             .textTheme
                        //                             .titleLarge!
                        //                             .copyWith(
                        //                                 fontSize: 11.7,
                        //                                 letterSpacing:
                        //                                     0.06,
                        //                                 color: Color(
                        //                                     0xffc1c1c1)),
                        //                       ),
                        //                       trailing: Column(
                        //                         mainAxisAlignment:
                        //                             MainAxisAlignment
                        //                                 .center,
                        //                         children: <Widget>[
                        //                           Text(
                        //                             '${onGoingOrders[t].order_status}',
                        //                             style: orderMapAppBarTextStyle
                        //                                 .copyWith(
                        //                                     color:
                        //                                         kMainColor),
                        //                           ),
                        //                           SizedBox(height: 7.0),
                        //                           Text(
                        //                             '${onGoingOrders[t].data.length} items | $currency ${onGoingOrders[t].price}',
                        //                             style: Theme.of(
                        //                                     context)
                        //                                 .textTheme
                        //                                 .titleLarge!
                        //                                 .copyWith(
                        //                                     fontSize:
                        //                                         11.7,
                        //                                     letterSpacing:
                        //                                         0.06,
                        //                                     color: Color(
                        //                                         0xffc1c1c1)),
                        //                           )
                        //                         ],
                        //                       ),
                        //                     ),
                        //                   )
                        //                 ],
                        //               ),
                        //               Divider(
                        //                 color: kCardBackgroundColor,
                        //                 thickness: 1.0,
                        //               ),
                        //               Row(
                        //                 children: <Widget>[
                        //                   Padding(
                        //                     padding: EdgeInsets.only(
                        //                         left: 36.0,
                        //                         bottom: 6.0,
                        //                         top: 12.0,
                        //                         right: 12.0),
                        //                     child: ImageIcon(
                        //                       AssetImage(
                        //                           'images/custom/ic_pickup_pointact.png'),
                        //                       size: 13.3,
                        //                       color: kMainColor,
                        //                     ),
                        //                   ),
                        //                   Text(
                        //                   VendorName[t]
                        //       ,
                        //                     style: Theme.of(context)
                        //                         .textTheme
                        //                         .bodySmall!
                        //                         .copyWith(
                        //                             fontSize: 10.0,
                        //                             letterSpacing:
                        //                                 0.05),
                        //                   ),
                        //                 ],
                        //               ),
                        //               Row(
                        //                 children: <Widget>[
                        //                   Padding(
                        //                     padding: EdgeInsets.only(
                        //                         left: 36.0,
                        //                         bottom: 12.0,
                        //                         top: 12.0,
                        //                         right: 12.0),
                        //                     child: ImageIcon(
                        //                       AssetImage(
                        //                           'images/custom/ic_droppointact.png'),
                        //                       size: 13.3,
                        //                       color: kMainColor,
                        //                     ),
                        //                   ),
                        //                   Expanded(
                        //                     child: Text(
                        //                       '${onGoingOrders[t].address}',
                        //                       style: Theme.of(context)
                        //                           .textTheme
                        //                           .bodySmall!
                        //                           .copyWith(
                        //                               fontSize: 10.0,
                        //                               letterSpacing:
                        //                                   0.05),
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //               (onGoingOrders.length - 1 == t)
                        //                   ? Divider(
                        //                       color:
                        //                           kCardBackgroundColor,
                        //                       thickness: 0,
                        //                     )
                        //                   : Divider(
                        //                       color:
                        //                           kCardBackgroundColor,
                        //                       thickness: 13.3,
                        //                     ),
                        //             ],
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //     itemCount: onGoingOrders.length)),
                        Visibility(
                          visible: (onRestGoingOrders != null &&
                              onRestGoingOrders.length > 0)
                              ? true
                              : false,
                          child: Column(
                            children: [
                              Divider(
                                color: kCardBackgroundColor,
                                thickness: 13.3,
                              ),

                              ListView.builder(
                                shrinkWrap: true,
                                primary: false,
                                itemBuilder: (context, t) {
                                  if (t < onRestGoingOrders.length) { // Check if t is within bounds
                                    return GestureDetector(
                                      onTap: () {
                                        if (onRestGoingOrders[t]
                                            .order_status ==
                                            'Cancelled') {
                                        } else {

                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      left: 16.3),
                                                  child: Image.asset(
                                                    'images/maincategory/vegetables_fruitsact.png',
                                                    height: 42.3,
                                                    width: 33.7,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: ListTile(

                                                    title:Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Order Id - #${onRestGoingOrders[t].cart_id}',
                                                          style: orderMapAppBarTextStyle
                                                              .copyWith(
                                                              letterSpacing:
                                                              0.07),
                                                        ),
                                                        Text(
                                                          onRestGoingOrders[t].data[t].product_name, // Replace this with your second text
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .headlineMedium!
                                                              .copyWith(
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 15.0),
                                                        ),
                                                      ],
                                                    ),

                                                    subtitle: Text(
                                                      (onRestGoingOrders[t]
                                                          .delivery_date !=
                                                          null &&
                                                          onRestGoingOrders[
                                                          t]
                                                              .time_slot !=
                                                              null)
                                                          ? '${onRestGoingOrders[t].delivery_date} | ${onRestGoingOrders[t].time_slot}'
                                                          : '',
                                                      style: Theme.of(
                                                          context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                          fontSize:
                                                          11.7,
                                                          letterSpacing:
                                                          0.06,
                                                          color: Color(
                                                              0xffc1c1c1)),
                                                    ),
                                                    trailing: Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                      children: <Widget>[
                                                        Text(
                                                          '${onRestGoingOrders[t].order_status}',
                                                          style: orderMapAppBarTextStyle
                                                              .copyWith(
                                                              color:
                                                              kMainColor),
                                                        ),
                                                        SizedBox(
                                                            height: 7.0),
                                                        Text(
                                                          '${onRestGoingOrders[t].data.length} items | $currency ${onRestGoingOrders[t].price}',
                                                          style: Theme.of(
                                                              context)
                                                              .textTheme
                                                              .titleLarge!
                                                              .copyWith(
                                                              fontSize:
                                                              11.7,
                                                              letterSpacing:
                                                              0.06,
                                                              color: Color(
                                                                  0xffc1c1c1)),
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
                                                      left: 36.0,
                                                      bottom: 6.0,
                                                      top: 12.0,
                                                      right: 12.0),
                                                  child: ImageIcon(
                                                    AssetImage(
                                                        'images/custom/ic_pickup_pointact.png'),
                                                    size: 13.3,
                                                    color: kMainColor,
                                                  ),
                                                ),
                                                Text(
                                                  '${onRestGoingOrders[t].vendor_name}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                      fontSize: 10.0,
                                                      letterSpacing:
                                                      0.05),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 36.0,
                                                      bottom: 12.0,
                                                      top: 12.0,
                                                      right: 12.0),
                                                  child: ImageIcon(
                                                    AssetImage(
                                                        'images/custom/ic_droppointact.png'),
                                                    size: 13.3,
                                                    color: kMainColor,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${onRestGoingOrders[t].address}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            (onRestGoingOrders.length - 1 ==
                                                t)
                                                ? Divider(
                                              color:
                                              kCardBackgroundColor,
                                              thickness: 0.0,
                                            )
                                                : Divider(
                                              color:
                                              kCardBackgroundColor,
                                              thickness: 13.3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Handle the case where t is out of bounds
                                    return Container(); // Or any other fallback widget
                                  }
                                },
                                // itemCount: onRestGoingOrders.length,
                                itemCount: 1,
                              ),

                              // ListView.builder(
                              //     shrinkWrap: true,
                              //     primary: false,
                              //     itemBuilder: (context, t) {
                              //
                              //       return GestureDetector(
                              //         onTap: () {
                              //           if (onRestGoingOrders[t]
                              //                   .order_status ==
                              //               'Cancelled') {
                              //           } else {
                              //             print(""
                              //                 "ongoing orders : ${onRestGoingOrders[t]}");
                              //             Navigator.push(
                              //               context,
                              //               MaterialPageRoute(
                              //                 builder: (context) =>
                              //                     OrderMapRestPage(
                              //                   pageTitle:
                              //                       '${onRestGoingOrders[t].vendor_name}',
                              //                   ongoingOrders:
                              //                       onRestGoingOrders[t],
                              //                   currency: currency,
                              //                       user_id:onRestGoingOrders[t].cart_id.toString(),
                              //                 ),
                              //               ),
                              //             ).then((value) {
                              //               if (khit == 0) {
                              //                 getAllThreeData();
                              //               } else if (khit == 1) {
                              //                 getCancelledHistory();
                              //               } else if (khit == 2) {
                              //                 getCompletedHistory();
                              //               }
                              //             });
                              //           }
                              //         },
                              //         behavior: HitTestBehavior.opaque,
                              //         child: Container(
                              //           child: Column(
                              //             children: [
                              //               Row(
                              //                 children: <Widget>[
                              //                   Padding(
                              //                     padding:
                              //                         const EdgeInsets.only(
                              //                             left: 16.3),
                              //                     child: Image.asset(
                              //                       'images/maincategory/vegetables_fruitsact.png',
                              //                       height: 42.3,
                              //                       width: 33.7,
                              //                     ),
                              //                   ),
                              //                   Expanded(
                              //                     child: ListTile(
                              //
                              //                       title:Column(
                              //                         crossAxisAlignment: CrossAxisAlignment.start,
                              //                         children: [
                              //                           Text(
                              //                             'Order Id - #${onRestGoingOrders[t].cart_id}',
                              //                             style: orderMapAppBarTextStyle
                              //                                 .copyWith(
                              //                                 letterSpacing:
                              //                                 0.07),
                              //                           ),
                              //                           Text(
                              //                             onRestGoingOrders[t].data[t].product_name, // Replace this with your second text
                              //                             style: Theme.of(context)
                              //                                 .textTheme
                              //                                 .headlineMedium!
                              //                                 .copyWith(
                              //                                 fontWeight: FontWeight.w500,
                              //                                 fontSize: 15.0),
                              //                           ),
                              //                         ],
                              //                       ),
                              //
                              //                       subtitle: Text(
                              //                         (onRestGoingOrders[t]
                              //                                         .delivery_date !=
                              //                                     null &&
                              //                                 onRestGoingOrders[
                              //                                             t]
                              //                                         .time_slot !=
                              //                                     null)
                              //                             ? '${onRestGoingOrders[t].delivery_date} | ${onRestGoingOrders[t].time_slot}'
                              //                             : '',
                              //                         style: Theme.of(
                              //                                 context)
                              //                             .textTheme
                              //                             .titleLarge!
                              //                             .copyWith(
                              //                                 fontSize:
                              //                                     11.7,
                              //                                 letterSpacing:
                              //                                     0.06,
                              //                                 color: Color(
                              //                                     0xffc1c1c1)),
                              //                       ),
                              //                       trailing: Column(
                              //                         mainAxisAlignment:
                              //                             MainAxisAlignment
                              //                                 .center,
                              //                         children: <Widget>[
                              //                           Text(
                              //                             '${onRestGoingOrders[t].order_status}',
                              //                             style: orderMapAppBarTextStyle
                              //                                 .copyWith(
                              //                                     color:
                              //                                         kMainColor),
                              //                           ),
                              //                           SizedBox(
                              //                               height: 7.0),
                              //                           Text(
                              //                             '${onRestGoingOrders[t].data.length} items | $currency ${onRestGoingOrders[t].remaining_amount}',
                              //                             style: Theme.of(
                              //                                     context)
                              //                                 .textTheme
                              //                                 .titleLarge!
                              //                                 .copyWith(
                              //                                     fontSize:
                              //                                         11.7,
                              //                                     letterSpacing:
                              //                                         0.06,
                              //                                     color: Color(
                              //                                         0xffc1c1c1)),
                              //                           )
                              //                         ],
                              //                       ),
                              //                     ),
                              //                   )
                              //                 ],
                              //               ),
                              //               Divider(
                              //                 color: kCardBackgroundColor,
                              //                 thickness: 1.0,
                              //               ),
                              //               Row(
                              //                 children: <Widget>[
                              //                   Padding(
                              //                     padding: EdgeInsets.only(
                              //                         left: 36.0,
                              //                         bottom: 6.0,
                              //                         top: 12.0,
                              //                         right: 12.0),
                              //                     child: ImageIcon(
                              //                       AssetImage(
                              //                           'images/custom/ic_pickup_pointact.png'),
                              //                       size: 13.3,
                              //                       color: kMainColor,
                              //                     ),
                              //                   ),
                              //                   Text(
                              //                     '${onRestGoingOrders[t].vendor_name}',
                              //                     style: Theme.of(context)
                              //                         .textTheme
                              //                         .bodySmall!
                              //                         .copyWith(
                              //                             fontSize: 10.0,
                              //                             letterSpacing:
                              //                                 0.05),
                              //                   ),
                              //                 ],
                              //               ),
                              //               Row(
                              //                 children: <Widget>[
                              //                   Padding(
                              //                     padding: EdgeInsets.only(
                              //                         left: 36.0,
                              //                         bottom: 12.0,
                              //                         top: 12.0,
                              //                         right: 12.0),
                              //                     child: ImageIcon(
                              //                       AssetImage(
                              //                           'images/custom/ic_droppointact.png'),
                              //                       size: 13.3,
                              //                       color: kMainColor,
                              //                     ),
                              //                   ),
                              //                   Expanded(
                              //                     child: Text(
                              //                       '${onRestGoingOrders[t].address}',
                              //                       style: Theme.of(context)
                              //                           .textTheme
                              //                           .bodySmall!
                              //                           .copyWith(
                              //                               fontSize: 10.0,
                              //                               letterSpacing:
                              //                                   0.05),
                              //                     ),
                              //                   ),
                              //                 ],
                              //               ),
                              //               (onRestGoingOrders.length - 1 ==
                              //                       t)
                              //                   ? Divider(
                              //                       color:
                              //                           kCardBackgroundColor,
                              //                       thickness: 0.0,
                              //                     )
                              //                   : Divider(
                              //                       color:
                              //                           kCardBackgroundColor,
                              //                       thickness: 13.3,
                              //                     ),
                              //             ],
                              //           ),
                              //         ),
                              //       );
                              //     },
                              //     itemCount: onRestGoingOrders.length),
                            ],
                          ),
                        ),

                        Visibility(
                          visible: (onPharmaGoingOrders != null &&
                              onPharmaGoingOrders.length > 0)
                              ? true
                              : false,
                          child: Column(
                            children: [
                              Divider(
                                color: kCardBackgroundColor,
                                thickness: 13.3,
                              ),
                              ListView.builder(
                                  shrinkWrap: true,
                                  primary: false,
                                  itemBuilder: (context, t) {
                                    return GestureDetector(
                                      onTap: () {
                                        if (onPharmaGoingOrders[t]
                                            .order_status ==
                                            'Cancelled') {
                                        } else {

                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      left: 16.3),
                                                  child: Image.asset(
                                                    'images/maincategory/vegetables_fruitsact.png',
                                                    height: 42.3,
                                                    width: 33.7,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: ListTile(

                                                    title:Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Order Id - #${onPharmaGoingOrders[t].cart_id}',
                                                          style: orderMapAppBarTextStyle
                                                              .copyWith(
                                                              letterSpacing:
                                                              0.07),
                                                        ),
                                                        Text(
                                                          onPharmaGoingOrders[t].data[t].product_name, // Replace this with your second text
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .headlineMedium!
                                                              .copyWith(
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 15.0),
                                                        ),
                                                      ],
                                                    ),


                                                    // title: Text(
                                                    //   'Order Id - #${onPharmaGoingOrders[t].cart_id}',
                                                    //   style: orderMapAppBarTextStyle
                                                    //       .copyWith(
                                                    //           letterSpacing:
                                                    //               0.07),
                                                    // ),
                                                    subtitle: Text(
                                                      (onPharmaGoingOrders[
                                                      t]
                                                          .delivery_date !=
                                                          null &&
                                                          onPharmaGoingOrders[
                                                          t]
                                                              .time_slot !=
                                                              null)
                                                          ? '${onPharmaGoingOrders[t].delivery_date} | ${onPharmaGoingOrders[t].time_slot}'
                                                          : '',
                                                      style: Theme.of(
                                                          context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                          fontSize:
                                                          11.7,
                                                          letterSpacing:
                                                          0.06,
                                                          color: Color(
                                                              0xffc1c1c1)),
                                                    ),
                                                    trailing: Column(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                      children: <Widget>[
                                                        Text(
                                                          '${onPharmaGoingOrders[t].order_status}',
                                                          style: orderMapAppBarTextStyle
                                                              .copyWith(
                                                              color:
                                                              kMainColor),
                                                        ),
                                                        SizedBox(
                                                            height: 7.0),
                                                        Text(
                                                          '${onPharmaGoingOrders[t].data.length} items | $currency ${onPharmaGoingOrders[t].remaining_amount}',
                                                          style: Theme.of(
                                                              context)
                                                              .textTheme
                                                              .titleLarge!
                                                              .copyWith(
                                                              fontSize:
                                                              11.7,
                                                              letterSpacing:
                                                              0.06,
                                                              color: Color(
                                                                  0xffc1c1c1)),
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
                                                      left: 36.0,
                                                      bottom: 6.0,
                                                      top: 12.0,
                                                      right: 12.0),
                                                  child: ImageIcon(
                                                    AssetImage(
                                                        'images/custom/ic_pickup_pointact.png'),
                                                    size: 13.3,
                                                    color: kMainColor,
                                                  ),
                                                ),
                                                Text(
                                                  '${onPharmaGoingOrders[t].vendor_name}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                      fontSize: 10.0,
                                                      letterSpacing:
                                                      0.05),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 36.0,
                                                      bottom: 12.0,
                                                      top: 12.0,
                                                      right: 12.0),
                                                  child: ImageIcon(
                                                    AssetImage(
                                                        'images/custom/ic_droppointact.png'),
                                                    size: 13.3,
                                                    color: kMainColor,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${onPharmaGoingOrders[t].address}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                        fontSize: 10.0,
                                                        letterSpacing:
                                                        0.05),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            (onPharmaGoingOrders.length -
                                                1 ==
                                                t)
                                                ? Divider(
                                              color:
                                              kCardBackgroundColor,
                                              thickness: 0.0,
                                            )
                                                : Divider(
                                              color:
                                              kCardBackgroundColor,
                                              thickness: 13.3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: onPharmaGoingOrders.length),
                            ],
                          ),
                        ),
                      ],
                    )),
            ),
          ),
          CancelOrders(),
          CompletedOrders(),
        ],
      ),

    );
  }
}


class CompletedOrders extends StatefulWidget {
  const CompletedOrders({super.key});

  @override
  State<CompletedOrders> createState() => _CompletedOrdersState();
}

class _CompletedOrdersState extends State<CompletedOrders> {



  List<OngoingOrders> onGoingOrders = [];
  List<OrderHistoryRestaurant> onRestGoingOrders = [];
  List<OrderHistoryRestaurant> onPharmaGoingOrders = [];

  List<String> VendorName=[];
  String message = "";

  var userId;
  String elseText = 'No ongoing order ...';
  dynamic currency = '';

  var khit = 0;
  bool isFetch = false;
  int countFetch = 0;

  @override
  void initState() {
    super.initState();
    getCompletedOrders();
  }




  getOnGointOrders() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      currency = preferences.getString('curency');
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No ongoing order today...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    userId = preferences.getInt('user_id');
    setState(() {
      userId =  preferences.getInt('user_id');
    });

    print("userid:  "+userId.toString());

    var url = onGoingOrdersUrl;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          if (tagObjs.isNotEmpty) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            print("Ongoing orders are: $onGoingOrders");
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }
              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
          VendorName.toSet().toList();
        }
        if (countFetch == 4) {
          setState(() {
            isFetch = false;
          });
        }
      }
    })
        .catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCanceledOreders() async {
    setState(() {
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No canceled order till date...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getInt('user_id');
    var url = cancelOrders;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      print('grocery cancelled orders are :${value.body}');
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
        }

      }else{
        setState(() {
          isFetch = false;
        });
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCompletedOrders() async {
    setState(() {
      elseText = 'No completed order till date...';
      List<OngoingOrders> onGoingOrderss = [];
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getInt('user_id');
    var url = completeOrders;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) async {
      print('${value.body}');

      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {

            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              // await FirebaseFirestore.instance.collection('location').doc(onGoingOrders[i].cart_id.toString()).delete();

              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }

          }
        }
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }










  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [


            if (onGoingOrders.isNotEmpty) ...[
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Text('Store Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              // ),
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                physics: NeverScrollableScrollPhysics(),
                itemCount: onGoingOrders.length,
                itemBuilder: (context, t) {
                  if (t >= 0 && t < onGoingOrders.length) {
                    return GestureDetector(
                      onTap: () {
                        if (onGoingOrders[t].order_status != 'Cancelled') {
                          print("user_id on Tap is : ${onGoingOrders[t].cart_id.toString()}");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderMapPage(
                                pageTitle: VendorName[t],
                                ongoingOrders: onGoingOrders[t],
                                currency: currency,
                                user_id: onGoingOrders[t].cart_id.toString(),
                              ),
                            ),
                          ).then((value) {
                            if (khit == 0) {
                              // getAllThreeData();
                            } else if (khit == 1) {
                              // getCancelledHistory();
                            } else if (khit == 2) {
                              // getCompletedHistory();
                            }
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        child: Column(
                          children: [
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.3),
                                  child: Image.asset(
                                    'images/maincategory/vegetables_fruitsact.png',
                                    height: 42.3,
                                    width: 33.7,
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order Id - #${onGoingOrders[t].cart_id}',
                                          style: orderMapAppBarTextStyle.copyWith(letterSpacing: 0.07),
                                        ),
                                        if (onGoingOrders[t].data.isNotEmpty) // Check if data is not empty
                                          Text(
                                            onGoingOrders[t].data[0].product_name, // Use a valid index within range
                                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      (onGoingOrders[t].delivery_date != null && onGoingOrders[t].time_slot != null)
                                          ? '${onGoingOrders[t].delivery_date} | ${onGoingOrders[t].time_slot}'
                                          : '',
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                        color: Color(0xffc1c1c1),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${onGoingOrders[t].order_status}',
                                          style: orderMapAppBarTextStyle.copyWith(color: kMainColor),
                                        ),
                                        SizedBox(height: 7.0),
                                        Text(
                                          '${onGoingOrders[t].data.length} items | $currency ${onGoingOrders[t].price}',
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
                            Divider(
                              color: kCardBackgroundColor,
                              thickness: 1.0,
                            ),
                            // Additional code for other rows and icons
                            (onGoingOrders.length - 1 == t)
                                ? Divider(color: kCardBackgroundColor, thickness: 0)
                                : Divider(color: kCardBackgroundColor, thickness: 13.3),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(); // Return an empty container if out of range
                  }
                },
              ),
            ]

          ],
        ),
      ),
    );
  }
}


class CancelOrders extends StatefulWidget {
  const CancelOrders({super.key});

  @override
  State<CancelOrders> createState() => _CancelOrdersState();
}

class _CancelOrdersState extends State<CancelOrders> {



  List<OngoingOrders> onGoingOrders = [];
  List<OrderHistoryRestaurant> onRestGoingOrders = [];
  List<OrderHistoryRestaurant> onPharmaGoingOrders = [];

  List<String> VendorName=[];
  String message = "";

  var userId;
  String elseText = 'No ongoing order ...';
  dynamic currency = '';

  var khit = 0;
  bool isFetch = false;
  int countFetch = 0;

  @override
  void initState() {
    super.initState();
    getCanceledOreders();
  }




  getOnGointOrders() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      currency = preferences.getString('curency');
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No ongoing order today...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    userId = preferences.getInt('user_id');
    setState(() {
      userId =  preferences.getInt('user_id');
    });

    print("userid:  "+userId.toString());

    var url = onGoingOrdersUrl;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          if (tagObjs.isNotEmpty) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            print("Ongoing orders are: $onGoingOrders");
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }
              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
          VendorName.toSet().toList();
        }
        if (countFetch == 4) {
          setState(() {
            isFetch = false;
          });
        }
      }
    })
        .catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCanceledOreders() async {
    setState(() {
      List<OngoingOrders> onGoingOrderss = [];
      elseText = 'No canceled order till date...';
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getInt('user_id');
    var url = cancelOrders;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {'user_id': '$userId'}).then((value) {
      print('grocery cancelled orders are :${value.body}');
      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {
            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }
          }
        }

      }else{
        setState(() {
          isFetch = false;
        });
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }

  getCompletedOrders() async {
    setState(() {
      elseText = 'No completed order till date...';
      List<OngoingOrders> onGoingOrderss = [];
      onGoingOrders.clear();
      onGoingOrders = onGoingOrderss;
      VendorName.clear();
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userId = preferences.getInt('user_id');
    var url = completeOrders;
    Uri myUri = Uri.parse(url);

    http.post(myUri, body: {'user_id': '$userId'}).then((value) async {
      print('${value.body}');

      if (value.statusCode == 200 && value.body != null) {
        if (value.body.contains("[{\"order_details\":\"no orders found\"}]") ||
            value.body.contains("{\"data\":[]}") ||
            value.body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]")) {
          setState(() {
            isFetch = false;
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();
          var name='';
          if (tagObjs.length > 0) {

            setState(() {
              onGoingOrders.clear();
              VendorName.clear();
              onGoingOrders = tagObjs;
            });
            String vendor = '';

            for (int i = 0; i < onGoingOrders.length; i++) {
              print("MAIN " + onGoingOrders[i].cart_id + " " +
                  onGoingOrders[i].vendor_name);
              // await FirebaseFirestore.instance.collection('location').doc(onGoingOrders[i].cart_id.toString()).delete();

              for (int j = 0; j < onGoingOrders[i].data.length; j++) {
                print("DATA " + onGoingOrders[i].data[j].order_cart_id + " " +
                    onGoingOrders[i].data[j].vendor_name);
                if (onGoingOrders[i].data[j].order_cart_id ==
                    onGoingOrders[i].cart_id) {
                  print("IF " + onGoingOrders[i].data[j].order_cart_id + " " +
                      onGoingOrders[i].cart_id);
                  if( !vendor.contains(onGoingOrders[i].data[j].vendor_name)) {
                    vendor = vendor +"\n"+ onGoingOrders[i].data[j].vendor_name;
                  }
                }
              }

              VendorName.add(vendor);
              vendor = '';
              print("NAME " + i.toString() + " " + vendor);
            }

          }
        }
      }
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
    }).catchError((e) {
      if (countFetch == 4) {
        setState(() {
          isFetch = false;
        });
      }
      print(e);
    });
    countFetch = countFetch + 1;
  }








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [


            if (onGoingOrders.isNotEmpty) ...[
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Text('Store Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              // ),
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                physics: NeverScrollableScrollPhysics(),
                itemCount: onGoingOrders.length,
                itemBuilder: (context, t) {
                  if (t >= 0 && t < onGoingOrders.length) {
                    return GestureDetector(
                      onTap: () {
                        if (onGoingOrders[t].order_status != 'Cancelled') {
                          print("user_id on Tap is : ${onGoingOrders[t].cart_id.toString()}");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderMapPage(
                                pageTitle: VendorName[t],
                                ongoingOrders: onGoingOrders[t],
                                currency: currency,
                                user_id: onGoingOrders[t].cart_id.toString(),
                              ),
                            ),
                          ).then((value) {
                            if (khit == 0) {
                              // getAllThreeData();
                            } else if (khit == 1) {
                              // getCancelledHistory();
                            } else if (khit == 2) {
                              // getCompletedHistory();
                            }
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        child: Column(
                          children: [
                            Row(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.3),
                                  child: Image.asset(
                                    'images/maincategory/vegetables_fruitsact.png',
                                    height: 42.3,
                                    width: 33.7,
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order Id - #${onGoingOrders[t].cart_id}',
                                          style: orderMapAppBarTextStyle.copyWith(letterSpacing: 0.07),
                                        ),
                                        if (onGoingOrders[t].data.isNotEmpty) // Check if data is not empty
                                          Text(
                                            onGoingOrders[t].data[0].product_name, // Use a valid index within range
                                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      (onGoingOrders[t].delivery_date != null && onGoingOrders[t].time_slot != null)
                                          ? '${onGoingOrders[t].delivery_date} | ${onGoingOrders[t].time_slot}'
                                          : '',
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                        color: Color(0xffc1c1c1),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${onGoingOrders[t].order_status}',
                                          style: orderMapAppBarTextStyle.copyWith(color: kMainColor),
                                        ),
                                        SizedBox(height: 7.0),
                                        Text(
                                          '${onGoingOrders[t].data.length} items | $currency ${onGoingOrders[t].price}',
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
                            Divider(
                              color: kCardBackgroundColor,
                              thickness: 1.0,
                            ),
                            // Additional code for other rows and icons
                            (onGoingOrders.length - 1 == t)
                                ? Divider(color: kCardBackgroundColor, thickness: 0)
                                : Divider(color: kCardBackgroundColor, thickness: 13.3),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(); // Return an empty container if out of range
                  }
                },
              ),
            ]

          ],
        ),
      ),
    );
  }
}
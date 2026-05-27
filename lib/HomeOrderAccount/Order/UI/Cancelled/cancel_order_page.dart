import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/orderbean.dart';
import '../../../../bean/resturantbean/orderhistorybean.dart';
import '../../../../Themes/style.dart';
import '../../../Home/UI/order_placed_map.dart';


class CancelledOrderPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OrderPageState();
  }
}

class OrderPageState extends State<CancelledOrderPage>with SingleTickerProviderStateMixin {
  late TabController _tabController;


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

  List<String> tabDesign = [
    'Ongoing',
    'Cancelled',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    getData();
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
      // Call API for "Ongoing
        getCanceledOreders();

        break;
      case 1:
      // Call API for "Cancelled"
      //   getRestCanceledOreders();

        // getCancelledHistory();
        break;
      case 2:
      // Call API for "Completed"
      //   getParcelCanceledOreders();

        break;
    }
  }
  void getData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState((){
      message = pref.getString("message")!;
    });

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











  void getCancelledHistory() async {
    setState(() {
      isFetch = true;
      countFetch = 0;
    });
    getCanceledOreders();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Cancel Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CancelOrders(),
          // CompletedOrders(),
        ],
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











  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: onGoingOrders.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xffEDEDED), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 70.0,
                  width: 70.0,
                  decoration: BoxDecoration(
                    color: kButtonColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 34.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'No Cancelled Orders',
                  style: orderMapAppBarTextStyle.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'You don\'t have any cancelled orders yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 12.5,
                    letterSpacing: 0.06,
                    color: const Color(0xffc1c1c1),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: onGoingOrders.length,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              itemBuilder: (context, t) {
                if (t < 0 || t >= onGoingOrders.length) return const SizedBox.shrink();

                final order = onGoingOrders[t];
                final bool isCancelled = order.order_status == 'Cancelled';

                final String vendorTitle =
                (t < VendorName.length) ? VendorName[t] : 'Order #${order.cart_id}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: isCancelled
                          ? null
                          : () {
                        print("user_id on Tap is : ${order.cart_id.toString()}");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderMapPage(
                              pageTitle: vendorTitle,
                              ongoingOrders: order,
                              currency: currency,
                              user_id: order.cart_id.toString(),
                            ),
                          ),
                        ).then((value) {
                          if (khit == 0) {
                          } else if (khit == 1) {
                          } else if (khit == 2) {}
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xffEDEDED), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 54.0,
                                    width: 54.0,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF6F8F4),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      'images/maincategory/vegetables_fruitsact.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order #${order.cart_id}',
                                          style: orderMapAppBarTextStyle.copyWith(
                                            letterSpacing: 0.07,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        if (order.data.isNotEmpty) ...[
                                          const SizedBox(height: 3.0),
                                          Text(
                                            order.data[0].product_name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isCancelled ? Colors.red : kMainColor)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Text(
                                      '${order.order_status}',
                                      style: orderMapAppBarTextStyle.copyWith(
                                        color: isCancelled ? Colors.red : kMainColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1.0,
                              margin: const EdgeInsets.symmetric(horizontal: 10.0),
                              color: const Color(0xffF0F0F0),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            size: 14.0, color: Color(0xffc1c1c1)),
                                        const SizedBox(width: 5.0),
                                        Expanded(
                                          child: Text(
                                            (order.delivery_date != null &&
                                                order.time_slot != null)
                                                ? '${order.delivery_date} | ${order.time_slot}'
                                                : 'Schedule not set',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(
                                              fontSize: 11.7,
                                              letterSpacing: 0.06,
                                              color: const Color(0xffc1c1c1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${order.data.length} items',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                          fontSize: 11.7,
                                          color: const Color(0xffc1c1c1),
                                        ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        '$currency ${order.price}',
                                        style: orderMapAppBarTextStyle.copyWith(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
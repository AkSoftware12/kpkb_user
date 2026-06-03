import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/Themes/style.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/orderbean.dart';
import 'package:kpUser/DriverApp/beanmodel/cashcollect.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order History',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        titleSpacing: 0.0,
      ),
      body: Insight(),
    );
  }
}

class Insight extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return InsightState();
  }
}

class InsightState extends State<Insight> {
  List<OrderDetails> todayOrder = [];
  dynamic currency;
  CashCollect? cashC;

  @override
  void initState() {
    super.initState();
    getCurrency();
    getCollectCash();
    getCompleteOrders();
  }

  getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currency = prefs.getString('curency');
    });
  }

  getCollectCash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');

    var client = http.Client();

    client.post(
      Uri.parse(cashcollect),
      body: {'delivery_boy_id': '$boyId'},
    ).then((value) {
      print(value.body);

      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        CashCollect cashCollect = CashCollect.fromJson(jsonData);

        if (cashCollect.status == "1") {
          setState(() {
            cashC = cashCollect;
          });
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  getCompleteOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');

    var client = http.Client();

    client.post(
      Uri.parse(completed_orders),
      body: {'delivery_boy_id': '$boyId'},
    ).then((value) {
      if (value.statusCode == 200 && value.body.isNotEmpty) {
        var jsonData = jsonDecode(value.body);
        print(jsonData.toString());

        if (value.body.toString().contains(
          "[{\"order_details\":\"no orders found\"}]",
        ) ||
            value.body.toString().contains(
              "[{\"no_order\":\"no orders found\"}]",
            )) {
          setState(() {
            todayOrder.clear();
          });
        } else {
          var jsonList = jsonData as List;

          List<OrderDetails> orderDetails =
          jsonList.map((e) => OrderDetails.fromJson(e)).toList();

          setState(() {
            todayOrder.clear();
            todayOrder = orderDetails;
          });
        }
      }
    }).catchError((e) {
      Fluttertoast.showToast(
        msg: 'No grocery order found!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black26,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCardBackgroundColor,
      body: SingleChildScrollView(
        primary: true,
        child: Column(
          children: [
            Divider(color: kCardBackgroundColor, thickness: 8.0),

            Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 20.0),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${(cashC != null && cashC!.data.count != null) ? cashC!.data.count : 0}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        'Orders',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff6a6c74),
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '$currency ${(cashC != null && cashC?.data.sum != null) ? cashC?.data.sum : 0}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        'Earnings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff6a6c74),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: kCardBackgroundColor, thickness: 6.7),

            todayOrder.isNotEmpty
                ? Container(
              padding: EdgeInsets.only(bottom: 100),
              margin: EdgeInsets.only(bottom: 100),
              height: MediaQuery.of(context).size.height - 140,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                primary: true,
                child: Column(
                  children: [
                    SizedBox(height: 10),

                    Text(
                      'Grocery Orders',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff6a6c74),
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 10),

                    ListView.separated(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: todayOrder.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          color: kWhiteColor,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            color: kWhiteColor,
                            child: Row(
                              children: <Widget>[
                                Padding(
                                  padding:
                                  const EdgeInsets.only(left: 16.3),
                                  child: Image.asset(
                                    'images/vegetables_fruitsact.png',
                                    height: 42.3,
                                    width: 33.7,
                                  ),
                                ),

                                Expanded(
                                  child: ListTile(
                                    title: Text(
                                      'Order Id - #${todayOrder[index].cart_id}',
                                      style: orderMapAppBarTextStyle
                                          .copyWith(letterSpacing: 0.07),
                                    ),
                                    subtitle: Text(
                                      '${todayOrder[index].delivery_date} | ${todayOrder[index].time_slot}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                        fontSize: 11.7,
                                        letterSpacing: 0.06,
                                        color: Color(0xffc1c1c1),
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '${todayOrder[index].order_status}',
                                          style: orderMapAppBarTextStyle
                                              .copyWith(
                                            color: kMainColor,
                                          ),
                                        ),
                                        SizedBox(height: 7.0),
                                        Text(
                                          '${todayOrder[index].total_items} items | $currency ${todayOrder[index].remaining_price}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
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
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Divider(
                          height: 8,
                          color: Colors.transparent,
                        );
                      },
                    ),

                    SizedBox(height: 5),
                  ],
                ),
              ),
            )
                : Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - 200,
              alignment: Alignment.center,
              child: Text('No History found!'),
            ),
          ],
        ),
      ),
    );
  }
}
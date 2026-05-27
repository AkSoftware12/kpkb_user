import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../HomeOrderAccount/Home/UI/order_placed_map.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Themes/colors.dart';
import '../baseurlp/baseurl.dart';
import '../bean/orderbean.dart';
import '../databasehelper/dbhelper.dart';

class OrderPlaced extends StatelessWidget {
  final dynamic payment_method;
  final dynamic payment_status;
  final dynamic order_id;
  final dynamic rem_price;
  final dynamic currency;
  final dynamic uiType;

  List<String> VendorName = [];

  OrderPlaced(
      this.payment_method,
      this.payment_status,
      this.order_id,
      this.rem_price,
      this.currency,
      this.uiType, {
        super.key,
      }) {
    deleteProducts(uiType);
  }

  void deleteProducts(uiType) async {
    DatabaseHelper db = DatabaseHelper.instance;
    if (uiType == "1") {
      db.deleteAll();
    } else if (uiType == "2") {
      db.deleteAllRestProdcut();
      db.deleteAllAddOns();
    } else if (uiType == "5") {
      clearCart(db);
    }
  }

  void clearCart(db) async {
    db.deleteAllPharma().then((value) {
      db.deleteAllAddonPharma();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeOrderAccount(0, 1)),
              (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF6F8FA),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
             color: Colors.white
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 5.h),
              child: Column(
                children: [

                  Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200,width: 1)
                    ),
                    child: Image.asset(
                      'images/order_placed.png',
                      height: 120.h,
                      fit: BoxFit.contain,

                    ),
                  ),

                  SizedBox(height: 10.h),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(width: 1,color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 20.sp,
                              ),
                              SizedBox(width: 7.w),
                              Text(
                                "Order Placed",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Text(
                          'Your Order has been Successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1.25,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF7F9FC),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: kMainColor,
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  'Order ID - $order_id',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: kMainTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Text(
                          'Thanks for choosing us for delivering your needs.\nYou can check your order status in my order section.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: kDisabledColor,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  _mainButton(
                    title: "Start Tracking",
                    icon: Icons.location_on_rounded,
                    onTap: () {
                      CallAPI('$order_id', context);
                    },
                  ),

                  SizedBox(height: 14.h),

                  _outlineButton(
                    title: "Go To Home",
                    icon: Icons.home_rounded,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeOrderAccount(0, 1),
                        ),
                            (Route<dynamic> route) => false,
                      );
                    },
                  ),

                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          elevation: 8,
          shadowColor: kMainColor.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 21.sp),
            SizedBox(width: 9.w),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kButtonColor, width: 1.4),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kButtonColor, size: 21.sp),
            SizedBox(width: 9.w),
            Text(
              title,
              style: TextStyle(
                color: kButtonColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void CallAPI(String orderid, BuildContext context) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? userId = preferences.getInt('user_id');

    var url = orderdetails;
    Uri myUri = Uri.parse(url);
    http.post(myUri, body: {'user_id': '$userId', 'cart_id': '$orderid'})
        .then((value) {
      if (value.statusCode == 200 && value.body != null) {
        if (uiType == "1") {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> orders = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();

          String vendor = '';

          for (int i = 0; i < orders.length; i++) {
            for (int j = 0; j < orders[i].data.length; j++) {
              if (orders[i].data[j].order_cart_id == orders[i].cart_id) {
                if (!vendor.contains(orders[i].data[j].vendor_name)) {
                  vendor = vendor + "\n" + orders[i].data[j].vendor_name;
                }
              }
            }
            VendorName.add(vendor);
            vendor = '';
            print("NAME " + i.toString() + " " + vendor);
          }

          VendorName.toSet().toList();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return OrderMapPage(
                  pageTitle: VendorName[0],
                  ongoingOrders: orders.elementAt(0),
                  currency: currency,
                  user_id: orders.elementAt(0).cart_id.toString(),
                );
              },
            ),
          );
        }

      }
    });
  }
}
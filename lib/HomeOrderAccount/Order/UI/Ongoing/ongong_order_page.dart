import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Themes/colors.dart';
import '../../../../Themes/style.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/orderbean.dart';
import '../../../Home/UI/order_placed_map.dart';

class OngoingOrderPage extends StatefulWidget {
  const OngoingOrderPage({super.key});

  @override
  State<OngoingOrderPage> createState() => _OngoingOrderPageState();
}

class _OngoingOrderPageState extends State<OngoingOrderPage> {
  List<OngoingOrders> onGoingOrders = [];
  List<String> vendorNames = [];

  dynamic currency = '';
  int? userId;

  bool isLoading = true;
  String errorText = '';

  @override
  void initState() {
    super.initState();
    getOnGoingOrders();
  }

  Future<void> getOnGoingOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorText = '';
        currency = prefs.getString('curency') ?? '';
        userId = prefs.getInt('user_id');
        onGoingOrders.clear();
        vendorNames.clear();
      });

      final response = await http.post(
        Uri.parse(onGoingOrdersUrl),
        body: {'user_id': '${userId ?? ''}'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = response.body;

        if (body.contains('[{"order_details":"no orders found"}]') ||
            body.contains('{"data":[]}') ||
            body.contains('[{"data":"No Cancelled Orders Yet"}]')) {
          setState(() {
            onGoingOrders.clear();
            vendorNames.clear();
            isLoading = false;
          });
          return;
        }

        final List decoded = jsonDecode(body);
        final orders = decoded
            .map((e) => OngoingOrders.fromJson(e))
            .toList()
            .cast<OngoingOrders>();

        final names = <String>[];

        for (final order in orders) {
          final vendors = <String>{};

          for (final item in order.data) {
            if (item.order_cart_id == order.cart_id &&
                item.vendor_name.toString().trim().isNotEmpty) {
              vendors.add(item.vendor_name.toString().trim());
            }
          }

          names.add(vendors.isEmpty ? order.vendor_name : vendors.join('\n'));
        }

        setState(() {
          onGoingOrders = orders;
          vendorNames = names;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorText = 'Failed to load orders';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorText = 'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'My Ongoing Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: kButtonColor,
        onRefresh: getOnGoingOrders,
        child: isLoading
            ? _loadingView()
            : errorText.isNotEmpty
            ? _errorView()
            : onGoingOrders.isEmpty
            ? _emptyView()
            : ListView.builder(
          padding: EdgeInsets.all(14.w),
          itemCount: onGoingOrders.length,
          itemBuilder: (context, index) {
            return _orderCard(index);
          },
        ),
      ),
    );
  }

  Widget _loadingView() {
    return ListView(
      children: [
        SizedBox(height: 280.h),
        Container(
          color: Colors.white.withOpacity(0.08),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: kButtonColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Loading orders...",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _emptyView() {
    return ListView(
      children: [
        SizedBox(height: 100.h),
        Image.asset(
          'assets/no_orders.png',
          height: 220.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            'No ongoing store order today',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorView() {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        SizedBox(height: 180.h),
        Icon(Icons.error_outline_rounded, size: 60.sp, color: Colors.red),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            errorText,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          onPressed: getOnGoingOrders,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _orderCard(int index) {
    final order = onGoingOrders[index];
    final vendorName = index < vendorNames.length ? vendorNames[index] : '';
    final productName = order.data.isNotEmpty ? order.data[0].product_name : 'Store Order';

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderMapPage(
              pageTitle: vendorName,
              ongoingOrders: order,
              currency: currency,
              user_id: order.cart_id.toString(),
            ),
          ),
        ).then((_) => getOnGoingOrders());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 54.w,
                  width: 54.w,
                  decoration: BoxDecoration(
                    color: kMainColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(9.w),
                    child: Image.asset(
                      'images/maincategory/vegetables_fruitsact.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Id - #${order.cart_id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: orderMapAppBarTextStyle.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${order.delivery_date ?? ''} | ${order.time_slot ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: kButtonColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${order.order_status}',
                        style: TextStyle(
                          color: kButtonColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${order.data.length} items',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currency ${order.price}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: order.payment_status.toString().toLowerCase() == "success"
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: order.payment_status.toString().toLowerCase() == "success"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.payment_status.toString().toLowerCase() == "success"
                                ? Icons.check_circle
                                : Icons.pending,
                            size: 14.sp,
                            color: order.payment_status.toString().toLowerCase() == "success"
                                ? Colors.green
                                : Colors.orange,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            order.payment_status.toString().toLowerCase() == "success"
                                ? "Paid"
                                : "POD",
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: order.payment_status.toString().toLowerCase() == "success"
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    )

                  ],
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: 12.h),
            _infoRow(
              icon: Icons.storefront_rounded,
              title: vendorName.trim().isEmpty ? 'Store' : vendorName.trim(),
            ),
            SizedBox(height: 10.h),
            _infoRow(
              icon: Icons.location_on_rounded,
              title: '${order.address}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kButtonColor, size: 18.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
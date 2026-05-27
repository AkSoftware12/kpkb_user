import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/orderbean.dart';
import '../../../../bean/resturantbean/orderhistorybean.dart';
import '../../../Home/UI/order_placed_map.dart';


class CompletedOrders extends StatefulWidget {
  const CompletedOrders({super.key});

  @override
  State<CompletedOrders> createState() => _CompletedOrdersState();
}

class _CompletedOrdersState extends State<CompletedOrders> {
  List<OngoingOrders> onGoingOrders = [];
  List<OrderHistoryRestaurant> onRestGoingOrders = [];
  List<OrderHistoryRestaurant> onPharmaGoingOrders = [];
  // List<TodayOrderParcel> onParcelGoingOrders = [];

  List<String> VendorName = [];
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
    _loadCompletedOrders();
  }

  Future<void> _loadCompletedOrders() async {
    if (!mounted) return;
    setState(() {
      isFetch = true;
      countFetch = 0;
      elseText = 'No completed order till date...';
    });

    await Future.wait([
      // getRestCompletedOrders(),
      getCompletedOrders(),
    ]);

    if (!mounted) return;
    setState(() => isFetch = false);
  }

  bool _isNoOrderResponse(String body) {
    return body.contains("[{\"order_details\":\"no orders found\"}]") ||
        body.contains("{\"data\":[]}") ||
        body.contains("[{\"data\":\"No Cancelled Orders Yet\"}]");
  }

  Future<void> getRestCompletedOrders() async {
    try {
      if (!mounted) return;
      setState(() {
        elseText = 'No completed order till date...';
        onRestGoingOrders.clear();
      });

      SharedPreferences preferences = await SharedPreferences.getInstance();
      userId = preferences.getInt('user_id');
      currency = preferences.getString('curency') ?? '';

      Uri myUri = Uri.parse(user_completed_orders);

      final value = await http.post(myUri, body: {'user_id': '$userId'});

      if (value.statusCode == 200) {
        if (_isNoOrderResponse(value.body)) {
          if (!mounted) return;
          setState(() => onRestGoingOrders.clear());
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OrderHistoryRestaurant> tagObjs = tagObjsJson
              .map((tagJson) => OrderHistoryRestaurant.fromJson(tagJson))
              .toList();

          if (!mounted) return;
          setState(() {
            onRestGoingOrders = tagObjs;
          });
        }
      }
    } catch (e) {
      debugPrint("getRestCompletedOrders error: $e");
    }
  }

  Future<void> getCompletedOrders() async {
    try {
      if (!mounted) return;
      setState(() {
        elseText = 'No completed order till date...';
        onGoingOrders.clear();
        VendorName.clear();
      });

      SharedPreferences preferences = await SharedPreferences.getInstance();
      userId = preferences.getInt('user_id');
      currency = preferences.getString('curency') ?? '';

      Uri myUri = Uri.parse(completeOrders);

      final value = await http.post(myUri, body: {'user_id': '$userId'});

      if (value.statusCode == 200) {
        if (_isNoOrderResponse(value.body)) {
          if (!mounted) return;
          setState(() {
            onGoingOrders.clear();
            VendorName.clear();
          });
        } else {
          var tagObjsJson = jsonDecode(value.body) as List;
          List<OngoingOrders> tagObjs = tagObjsJson
              .map((tagJson) => OngoingOrders.fromJson(tagJson))
              .toList();

          List<String> vendorNames = [];

          for (int i = 0; i < tagObjs.length; i++) {
            String vendor = '';

            for (int j = 0; j < tagObjs[i].data.length; j++) {
              if (tagObjs[i].data[j].order_cart_id == tagObjs[i].cart_id) {
                final name = tagObjs[i].data[j].vendor_name;
                if (!vendor.contains(name)) {
                  vendor = "$vendor\n$name";
                }
              }
            }

            vendorNames.add(vendor.trim());
          }

          if (!mounted) return;
          setState(() {
            onGoingOrders = tagObjs;
            VendorName = vendorNames;
          });
        }
      }
    } catch (e) {
      debugPrint("getCompletedOrders error: $e");
    }
  }

  Future<void> getOnGointOrders() async {}
  Future<void> getCanceledOreders() async {}
  Future<void> getOnRestGointOrders() async {}
  Future<void> getRestCanceledOreders() async {}
  Future<void> getOnPharmaGointOrders() async {}
  Future<void> getPharmaCanceledOreders() async {}
  Future<void> getPharmaCompletedOrders() async {}
  Future<void> getOnParcelGointOrders() async {}
  Future<void> getParcelCanceledOreders() async {}
  Future<void> getParcelCompletedOrders() async {}

  @override
  Widget build(BuildContext context) {
    final bool hasOrders =
         onGoingOrders.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Complete Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Stack(
        children: [
          RefreshIndicator(
            color: kButtonColor,
            onRefresh: _loadCompletedOrders,
            child:isFetch? Container(
              color: Colors.black.withOpacity(0.08),
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
            ):


            hasOrders
                ? ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                if (onGoingOrders.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionTitle("Store Orders", onGoingOrders.length),
                  const SizedBox(height: 10),
                  ...List.generate(onGoingOrders.length, (t) {
                    final order = onGoingOrders[t];

                    final vendorTitle = t < VendorName.length &&
                        VendorName[t].trim().isNotEmpty
                        ? VendorName[t]
                        : order.vendor_name;

                    return _PremiumOrderCard(
                      orderId: order.cart_id.toString(),
                      productName: order.data.isNotEmpty
                          ? order.data[0].product_name
                          : "Order items",
                      status: order.order_status.toString(),
                      items: order.data.length,
                      price: order.price.toString(),
                      currency: currency.toString(),
                      vendorName: vendorTitle.toString(),
                      address: order.address.toString(),
                      dateTime: (order.delivery_date != null &&
                          order.time_slot != null)
                          ? '${order.delivery_date} | ${order.time_slot}'
                          : '',
                      onTap: () {
                        if (order.order_status == 'Cancelled') return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderMapPage(
                              pageTitle: vendorTitle,
                              ongoingOrders: order,
                              currency: currency,
                              user_id: order.cart_id.toString(),
                            ),
                          ),
                        );
                      },
                      billUrl: order.bill.toString(),
                    );
                  }),
                ],
              ],
            )
                : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.22,
                ),
                _emptyOrderWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: kButtonColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long_rounded, color: kButtonColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xff172331),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Text(
            "$count Orders",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kButtonColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyOrderWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            color: kButtonColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 46,
            color: kButtonColor,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          elseText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xff1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Pull down to refresh orders",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PremiumOrderCard extends StatelessWidget {
  final String orderId;
  final String productName;
  final String status;
  final String billUrl;
  final int items;
  final String price;
  final String currency;
  final String vendorName;
  final String address;
  final String dateTime;
  final VoidCallback onTap;

  const _PremiumOrderCard({
    required this.orderId,
    required this.productName,
    required this.status,
    required this.items,
    required this.price,
    required this.currency,
    required this.vendorName,
    required this.address,
    required this.dateTime,
    required this.onTap,
    required this.billUrl,
  });

  Color get statusColor {
    final s = status.toLowerCase();

    if (s.contains('cancel')) return Colors.red;
    if (s.contains('complete') || s.contains('deliver')) return Colors.green;

    return kMainColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,

                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.local_mall_rounded,
                        color: Colors.black,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order Id - #$orderId",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (dateTime.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              dateTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),

                            if (status.toLowerCase() == "completed") ...[
                              const SizedBox(width: 3),

                              Card(
                                elevation: 6,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () async {
                                    final Uri url = Uri.parse(
                                      billUrl,
                                    );

                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: kButtonColor,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(
                                      Icons.print,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          "$items items | $currency $price",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.storefront_rounded,
                  iconColor: kButtonColor,
                  text: vendorName,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.redAccent,
                  text: address,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: Color(0xff374151),
            ),
          ),
        ),
      ],
    );
  }
}
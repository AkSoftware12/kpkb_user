import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kpUser/Pages/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomeOrderAccount/Account/UI/ListItems/saved_addresses_page.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Routes/routes.dart';
import '../Themes/colors.dart';
import '../baseurlp/baseurl.dart';
import '../bean/address.dart';
import '../bean/cartdetails.dart';
import '../bean/cartitem.dart';
import '../bean/orderarray.dart';
import '../bean/paymentstatus.dart';
import '../bean/resturantbean/restaurantcartitem.dart';
import '../databasehelper/dbhelper.dart';
import '../main.dart';


class oneViewCart extends StatefulWidget {
  const oneViewCart({super.key});

  @override
  State<oneViewCart> createState() => _oneViewCartState();
}

class _oneViewCartState extends State<oneViewCart> {
  Timer? timer;

  bool isCartFetch = true;
  bool _isPaying = false;
  bool _isChargesLoading = false;
  bool showDialogBox = false;
  bool _isClearing = false; // clear cart ke time ka loader

  String currency = '';
  String storeName = '';
  String message = '';
  String? Errormessage = '';

  double totalAmount = 0.0;
  double gstDiscountAmount = 0.0;
  double couponAmount = 0.0;
  double jhatfattDelivery = 0.0;
  double storedeliveryCharge = 0.0;
  double gstCharge = 0.0;
  double packcharge = 0.0;

  int surge_charges = 0;
  int night_charges = 0;
  int conv_charges = 0;
  int maxincash = 0;

  // ─────────────────────────────────────────────────────
  //  WEIGHT CONFIG
  //  Each item quantity = 100 gm  (qty 10 => 1000 gm => 1 kg)
  //  Max allowed cart weight = 20 kg
  // ─────────────────────────────────────────────────────
  static const double weightPerQtyGram = 100.0; // 1 qty = 100 gm
  static const double maxCartWeightKg = 20.0; // max allowed

  String dateTimeSt = '';

  ShowAddressNew? addressDelivery;

  List<CartItem> cartListI = [];
  List<RestaurantCartItem> cartListII = [];
  List<CartArray> cartarray = [];
  bool isLoading = false;
  List ongoingOrders = [];

  @override
  void initState() {
    super.initState();


    final now = DateTime.now();
    dateTimeSt =
    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _initData();
  }

  Future<void> _initData() async {
    await getStoreName();
    await getid();

    // ✅ Local cart DB data first load karo
    await getCartItem();
    await getResCartItem();
    getCatC();

    // ✅ Screen turant show hogi, shimmer/loading nahi aayega
    safeSetState(() => isCartFetch = false);

    // ✅ Address + delivery charges background me load honge
    _loadAddressAndChargesInBackground();
  }

  Future<void> _loadAddressAndChargesInBackground() async {
    await getAddress();

    if (addressDelivery != null && cartListI.isNotEmpty) {
      await ordercharg();
    }
  }


  Future<void> getOngoingOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic storedUserId = prefs.get('user_id');

      if (storedUserId == null || storedUserId.toString().isEmpty) {
        ongoingOrders = [];
        return;
      }

      final response = await http.post(
        Uri.parse(onGoingOrdersUrl),
        body: {
          'user_id': storedUserId.toString(),
        },
      );

      debugPrint("ONGOING STATUS => ${response.statusCode}");
      debugPrint("ONGOING RESPONSE => ${response.body}");

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          if (data is List) {
            ongoingOrders = data;
          } else if (data is Map) {
            ongoingOrders = [data];
          } else {
            ongoingOrders = [];
          }
        } else if (decoded is List) {
          ongoingOrders = decoded;
        } else {
          ongoingOrders = [];
        }
      } else {
        ongoingOrders = [];
      }

      debugPrint("ONGOING LENGTH => ${ongoingOrders.length}");
    } catch (e) {
      debugPrint("ONGOING ERROR => $e");
      ongoingOrders = [];
    }
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // double get payableAmount {
  //   return ((totalAmount - couponAmount) -
  //       jhatfattDelivery +
  //       gstCharge +
  //       storedeliveryCharge +
  //       packcharge +
  //       surge_charges +
  //       night_charges +
  //       conv_charges);
  // }

  double get payableAmount {
    return totalAmount + (storedeliveryCharge > 0 ? storedeliveryCharge : 0.0);
  }

  // ─────────────────────────────────────────────────────
  //  WEIGHT GETTERS
  // ─────────────────────────────────────────────────────

  /// Total cart weight in grams (1 qty = 100 gm)
  double get totalCartWeightGram {
    double totalGram = 0.0;
    for (final item in cartListI) {
      final int qty = int.tryParse('${item.add_qnty}') ?? 0;
      totalGram += qty * weightPerQtyGram;
    }
    return totalGram;
  }

  /// Total cart weight in kg
  double get totalCartWeightKg {
    return totalCartWeightGram / 1000;
  }

  /// True if cart weight is above the max limit (20 kg)
  bool get isWeightExceeded {
    return totalCartWeightKg > maxCartWeightKg;
  }

  Future<void> getStoreName() async {
    final prefs = await SharedPreferences.getInstance();

    safeSetState(() {
      storeName = prefs.getString('store_name') ?? '';
      currency = prefs.getString('curency') ?? '';
      packcharge = _toDouble(prefs.getString('res_pack_charge'));
    });
  }

  Future<void> getid() async {
    final prefs = await SharedPreferences.getInstance();

    safeSetState(() {
      message = prefs.getString("message") ?? '';
    });
  }

  Future<void> getCartItem() async {
    final db = DatabaseHelper.instance;
    final value = await db.queryAllRows();

    final items = value.map((e) => CartItem.fromJson(e)).toList();

    final List<CartArray> tempCartArray = [];
    final List<int> usedVendorIds = [];

    for (final item in items) {
      final vendorId = int.tryParse(item.vendor_id.toString()) ?? 0;
      if (usedVendorIds.contains(vendorId)) continue;

      final vendorItems =
      items.where((e) => e.vendor_id.toString() == item.vendor_id.toString()).toList();

      // double subtotal = 0.0;
      // double gsttotal = 0.0;
      // for (final vItem in vendorItems) {
      //   subtotal += _toDouble(vItem.price);
      // }

      double subtotal = 0.0;
      double gsttotal = 0.0;

      for (final vItem in vendorItems) {

        double price = _toDouble(vItem.price);

        int qty = int.tryParse(vItem.qnty.toString()) ?? 1;

        double gstPercent = double.tryParse(
          vItem.gst.toString().replaceAll('%', '').trim(),
        ) ?? 0;

        // Qty ke according total price
        double itemTotal = price * qty;

        // GST amount
        double gstAmount =
            itemTotal * gstPercent / (100 + gstPercent);

        subtotal += itemTotal;

        gsttotal += gstAmount;
      }

      tempCartArray.add(
        CartArray(
          item.vendor_id,
          item.store_name,
          vendorItems,
          subtotal,
          gsttotal,
          0,
        ),
      );

      usedVendorIds.add(vendorId);
    }

    safeSetState(() {
      cartListI = items;
      cartarray = tempCartArray;
    });
  }

  Future<void> getResCartItem() async {
    final db = DatabaseHelper.instance;
    final value = await db.getResturantOrderList();

    final items = value.map((e) => RestaurantCartItem.fromJson(e)).toList();

    for (int i = 0; i < items.length; i++) {
      final addons = await db.getAddOnListWithPrice(
        int.parse('${items[i].varient_id}'),
      );

      items[i].addon = addons.map((e) => AddonCartItem.fromJson(e)).toList();
    }

    safeSetState(() {
      cartListII = items;
    });
  }

  Future<void> getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(address_selection),
        body: {'user_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1" &&
            jsonData['data'] != null &&
            jsonData['data'].toString() != 'null') {
          final addressWelcome = AddressSelected.fromJson(jsonData);

          safeSetState(() {
            addressDelivery = addressWelcome.data;
          });
        }
      }
    } catch (_) {}
  }

  // void getCatC() {
  //   double total = 0.0;
  //
  //   for (final cart in cartarray) {
  //     total += cart.subtotal - cart.discount-gstDiscountAmount;
  //   }
  //
  //   safeSetState(() {
  //     totalAmount = total;
  //   });
  // }

  void getCatC() {
    double total = 0.0;
    double totalGstOff = 0.0;

    for (final cart in cartarray) {
      final double originalSubtotal = _toDouble(cart.subtotal);
      final double totalGst = _toDouble(cart.gsttotal);

      final double gstOffAmount = totalGst * 0.5;
      final double finalSubtotal = originalSubtotal - gstOffAmount;

      total += finalSubtotal;
      totalGstOff += gstOffAmount;
    }

    safeSetState(() {
      totalAmount = total;
      gstDiscountAmount = totalGstOff;
    });
  }

  Future<void> ordercharg() async {
    if (_isChargesLoading) return;

    safeSetState(() => _isChargesLoading = true);

    try {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt('user_id');

      print('userID $userId');

      if (userId == null || cartListI.isEmpty) return;

      final orderArray = cartListI.map((item) {
        return OrderArrayGrocery(
          int.parse('${item.add_qnty}'),
          int.parse('${item.varient_id}'),
          int.parse('${item.addedBasket}'),
        );
      }).toList();

      print('orderArray$orderArray');

      final response = await http.post(
        Uri.parse(ordercharges),
        body: {
          'user_id': userId.toString(),
          'order_array': orderArray.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        safeSetState(() {
          if (jsonData['status'].toString() == '1') {
            storedeliveryCharge = _toDouble(jsonData['delivery_charges']);
            gstCharge = _toDouble(jsonData['gst']);
            Errormessage = '';
          } else {
            storedeliveryCharge = 0.0;
            gstCharge = 0.0;
            Errormessage =
                jsonData['message']?.toString() ??
                    jsonData['meesage']?.toString() ??
                    'Delivery not available';
          }
        });
      }
    } catch (_) {
      safeSetState(() {
        Errormessage = 'Something went wrong';
      });
    } finally {
      safeSetState(() => _isChargesLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  //  CLEAR CART  (ab confirmation dialog ke saath)
  // ─────────────────────────────────────────────────────
  Future<void> _confirmClearCart() async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: "clear_cart",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// TOP ICON
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// TITLE
                  Text(
                    "Clear Cart?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade900,
                      letterSpacing: .3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// MESSAGE
                  Text(
                    "Are you sure you want to remove all items from your cart?\nThis action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// BUTTONS
                  Row(
                    children: [

                      /// CANCEL
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// CLEAR
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(.30),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Clear Cart",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },

      transitionBuilder: (_, animation, __, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );

    if (confirm == true) {
      await clearCart();
    }
  }
  Future<void> clearCart() async {
    safeSetState(() {
      _isClearing = true;
    });

    final db = DatabaseHelper.instance;
    await db.deleteAll();
    await db.deleteAllRestProdcut();
    await db.deleteAllAddOns();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('service');
    await prefs.remove('res_vendor_id');
    await prefs.remove('vendor_id');

    safeSetState(() {
      cartListI.clear();
      cartListII.clear();
      cartarray.clear();
      totalAmount = 0.0;
      storedeliveryCharge = 0.0;
      gstDiscountAmount = 0.0;
      isCartFetch = false;
      _isClearing = false;
    });

    _showToast('Cart cleared');
  }

  void addOrMinusProduct(
      dynamic is_id,
      dynamic is_pres,
      dynamic isBasket,
      dynamic addedbas,
      dynamic product_name,
      dynamic unit,
      dynamic price,
      dynamic quantity,
      dynamic itemCount,
      dynamic varient_image,
      dynamic varient_id,
      dynamic vendorid,
      dynamic storename,
      ) async {
    final db = DatabaseHelper.instance;

    final data = {
      DatabaseHelper.productName: product_name,
      DatabaseHelper.storeName: storename,
      DatabaseHelper.vendor_id: vendorid,
      DatabaseHelper.price: price,
      DatabaseHelper.unit: unit,
      DatabaseHelper.quantitiy: quantity,
      DatabaseHelper.addQnty: itemCount,
      DatabaseHelper.productImage: varient_image,
      DatabaseHelper.is_id: is_id,
      DatabaseHelper.is_pres: is_pres,
      DatabaseHelper.isBasket: isBasket,
      DatabaseHelper.addedBasket: addedbas,
      DatabaseHelper.varientId: varient_id,
    };

    final count = await db.getcount(varient_id);

    if (count == 0) {
      await db.insert(data);
    } else {
      if (itemCount <= 0) {
        await db.delete(varient_id);
      } else {
        await db.updateData(data, int.parse('$varient_id'));
      }
    }

    await getCartItem();
    getCatC();
    await ordercharg();
    //
    // if (cartListI.isEmpty && mounted) {
    //   Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(builder: (_) => HomeOrderAccount(3, 1)),
    //         (_) => false,
    //   );
    // }
  }

  Future<void> createCart(BuildContext context) async {
    if (cartListI.isEmpty || totalAmount <= 0) return;

    safeSetState(() => showDialogBox = true);

    try {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt('user_id');

      if (userId == null || userId == 0) {
        _showToast("Login required");
        return;
      }

      final List<Map<String, dynamic>> orderArray = cartListI.map((item) {
        return {
          "qty": int.tryParse('${item.add_qnty}') ?? 0,
          "varient_id": int.tryParse('${item.varient_id}') ?? 0,
          "basket": int.tryParse('${item.addedBasket}') ?? 0,
        };
      }).toList();

      final now = DateTime.now();

      final String timeSlot =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      debugPrint("createCart URL: $addToCart");
      debugPrint("userID: $userId");
      debugPrint("orderArray: ${jsonEncode(orderArray)}");

      final response = await http.post(
        Uri.parse(addToCart),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'user_id': userId.toString(),
          'order_array': jsonEncode(orderArray),
          'delivery_date': dateTimeSt.toString(),
          'time_slot': timeSlot,
          'ui_type': "1",
          'del_c': storedeliveryCharge.toString(),
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint("createCart statusCode: ${response.statusCode}");
      debugPrint("createCart response: ${response.body}");

      if (response.statusCode != 200) {
        _showToast("Server error ${response.statusCode}");
        return;
      }

      if (response.body.trim().isEmpty) {
        _showToast("Empty server response");
        return;
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['status'].toString() == "1") {
        final data = jsonData['data'];

        if (data == null || (data is List && data.isEmpty)) {
          _showToast("Cart detail empty");
          return;
        }

        if (data is! Map<String, dynamic>) {
          _showToast("Invalid cart detail response");
          return;
        }

        final details = CartDetail.fromJson(data);

        getVendorPayment2(
          '54',
          details,
          orderArray.toString(),
          payableAmount.toStringAsFixed(2),
        );
      } else {
        _showToast(jsonData['message']?.toString() ?? 'Order failed');
      }
    } on TimeoutException {
      debugPrint("createCart TimeoutException");
      _showToast("Server timeout");
    } on http.ClientException catch (e) {
      debugPrint("createCart ClientException: $e");
      _showToast("Server connection closed");
    } on FormatException catch (e) {
      debugPrint("createCart FormatException: $e");
      _showToast("Invalid server response");
    } catch (e, s) {
      debugPrint("createCart exception: $e");
      debugPrint("stack: $s");
      _showToast("Order failed");
    } finally {
      safeSetState(() => showDialogBox = false);
    }
  }

  void getVendorPayment2(
      String vendorId,
      CartDetail details,
      String orderArray,
      dynamic totalAmount,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(paymentvia),
        body: {'vendor_id': vendorId},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1") {
          final list = jsonData['data'] as List;

          final paymentList =
          list.map((e) => PaymentVia.fromJson(e)).toList();

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                vendorId,
                details.order_id,
                details.cart_id,
                double.parse(totalAmount.toString()),
                paymentList,
                orderArray,
                maxincash,
              ),
            ),
          );
        }
      }
    } catch (_) {
      _showToast("Payment method not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCart = cartListI.isNotEmpty || cartListII.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF6F7F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: white_color,
          centerTitle: true,
          automaticallyImplyLeading: true,
          title: Text(
            "confirm_order".tr(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            // clear button: confirmation dialog ke saath
            TextButton(
              onPressed: (hasCart && !_isClearing) ? _confirmClearCart : null,
              child:  Text(
                'clear'.tr(),
                style: TextStyle(
                  color: hasCart ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        body: isCartFetch
            ? Center(
          child: CircularProgressIndicator(color: kMainColor),
        )
            : !hasCart
            ? _emptyCart()
            : Stack(
          children: [

            Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(18.r),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomeOrderAccount(0, 1)),
                          (_) => false,
                    );

                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kButtonColor,
                          kButtonColor,

                        ],
                      ),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Row(
                      children: [

                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),

                        SizedBox(width: 14.w),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Continue Shopping",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              SizedBox(height: 3.h),

                              Text(
                                "Explore more amazing products",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            "Shop Now",
                            style: TextStyle(
                              color: kButtonColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      _cartItemsCard(),
                      // const SizedBox(height: 14),
                      // _paymentInfoCard(),
                      const SizedBox(height: 14),
                      _addressCard(),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 20),
                      _bottomPayBar(),
                      const SizedBox(height: 80),

                    ],
                  ),
                ),
              ],
            ),
            if (showDialogBox)
              Container(
                color: Colors.black.withOpacity(.25),
                child:  Center(
                  child: CircularProgressIndicator(color: kMainColor,),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cartItemsCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _sectionTitle("Cart Items (${cartListI.length.toString()})"),
          ...cartarray.map((cart) {
            return Column(
              children: [
                ...cart.cartitems.map((item) {
                  final unitPrice =
                      _toDouble(item.price) / (item.add_qnty == 0 ? 1 : item.add_qnty);

                  return _cartItemTile(
                    item: item,
                    title: item.product_name.toString(),
                    price: unitPrice,
                    qty: item.add_qnty,
                    unit: '${item.qnty} ${item.unit}',
                    image: item.product_img,
                    gst:item.gst.toString(),
                    size:item.size.toString(),
                    color:item.color.toString(),
                  );
                }).toList(),



                Builder(
                  builder: (context) {
                    double originalSubtotal = cart.subtotal;
                    double totalGst = cart.gsttotal;

                    /// GST 50% OFF
                    double gstOffAmount = totalGst * 0.5;
                    gstDiscountAmount=gstOffAmount;

                    /// Final Amount
                    double finalSubtotal = originalSubtotal - gstOffAmount;

                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            /// ITEM TOTAL
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Row(
                                children: [

                                  Text(
                                    "Item Total",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),

                                  SizedBox(width: 5.w),

                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      "GST Inc.",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  Text(
                                    "$currency ${originalSubtotal.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 0.h),

                            /// GST AMOUNT
                            Row(
                              children: [

                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.black,
                                  size: 12.sp,
                                ),

                                SizedBox(width: 5.w),

                                Expanded(
                                  child: Text(
                                    "Total GST Amount",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                Text(
                                  "$currency ${totalGst.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 0.h),

                            /// GST SAVINGS
                            Row(
                              children: [

                                Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.black,
                                  size: 12.sp,
                                ),

                                SizedBox(width: 5.w),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        "GST Savings",
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),

                                      Text(
                                        "50% GST OFF Applied",
                                        style: TextStyle(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  "- $currency ${gstOffAmount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 0.h),
                              child: Divider(
                                color: Colors.black12,
                                thickness: 1,
                              ),
                            ),

                            _priceRow("sub_total".tr(), finalSubtotal),
                            if (storedeliveryCharge > 0)
                              _priceRow("delivery_charges".tr(), storedeliveryCharge),

                            /// TOTAL WEIGHT ROW
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.scale_outlined,
                                    size: 16,
                                    color: isWeightExceeded
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Total Weight",
                                      style: TextStyle(
                                        color: isWeightExceeded
                                            ? Colors.red
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${totalCartWeightKg.toStringAsFixed(2)} kg",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isWeightExceeded
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// WEIGHT WARNING MESSAGE
                            if (isWeightExceeded)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                    top: 4, bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Your cart weight is above 20 kg. Please remove some items.",
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "amount_to_pay".tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  _isChargesLoading
                                      ?  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2,color: kMainColor,),
                                  )
                                      : Text(
                                    "$currency ${payableAmount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: kButtonColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
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
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _cartItemTile({
    required dynamic item,
    required String title,
    required String image,
    required String gst,
    required String size,
    required String color,
    required double price,
    required int qty,
    required String unit,
  }) {

    final double gstPercent =
        double.tryParse(gst.toString().replaceAll('%', '').trim()) ?? 0;

    // Single item GST amount
    final double singleGstAmount =
        price * gstPercent / (100 + gstPercent);

    // Qty ke according total GST
    final double totalGstAmount = singleGstAmount * qty;

    // Qty ke according total price
    final double totalPrice = price * qty;

    // Item weight (1 qty = 100 gm)
    final double itemWeightGram = qty * weightPerQtyGram;
    final String itemWeightText = itemWeightGram >= 1000
        ? "${(itemWeightGram / 1000).toStringAsFixed(2)} kg"
        : "${itemWeightGram.toStringAsFixed(0)} gm";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// PRODUCT IMAGE
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: kButtonColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              image,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.black,
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          /// PRODUCT DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                /// TOTAL PRICE
                Row(
                  children: [
                    Text(
                      "$currency${totalPrice.toStringAsFixed(2)}",
                      style:  TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    const SizedBox(width: 4),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [


                          Text(
                            'GST Inc. $gst%',
                            style: GoogleFonts.cabin(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade700,
                            ),
                          ),

                          SizedBox(width: 2.w),

                          Container(
                            width: 1,
                            height: 10.h,
                            color: Colors.blue.shade200,
                          ),

                          SizedBox(width: 2.w),

                          Text(
                            '$currency ${totalGstAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w800,
                              fontSize: 8.5.sp,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                if ((size != null &&
                    size.toString().trim().isNotEmpty &&
                    size.toString().toLowerCase() != "null") ||
                    (color != null &&
                        color.toString().trim().isNotEmpty &&
                        color.toString().toLowerCase() != "null"))
                  Text(
                    [
                      if (size != null &&
                          size.toString().trim().isNotEmpty &&
                          size.toString().toLowerCase() != "null")
                        size,

                      if (color != null &&
                          color.toString().trim().isNotEmpty &&
                          color.toString().toLowerCase() != "null")
                        color,
                    ].join(" | "),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                //
                // const SizedBox(height: 4),
                //
                // /// GST AMOUNT + WEIGHT
                // Row(
                //   children: [
                //     Container(
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 7,
                //         vertical: 3,
                //       ),
                //       decoration: BoxDecoration(
                //         color: Colors.blue.shade50,
                //         borderRadius: BorderRadius.circular(6),
                //         border: Border.all(
                //           color: Colors.blue.shade200,
                //         ),
                //       ),
                //       child: Text(
                //         "GST Amount $currency ${totalGstAmount.toStringAsFixed(2)}",
                //         style: TextStyle(
                //           color: Colors.blue.shade700,
                //           fontWeight: FontWeight.w800,
                //           fontSize: 9.sp,
                //           letterSpacing: 0.3,
                //         ),
                //       ),
                //     ),
                //
                //   ],
                // ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          /// QTY BUTTON
          _qtyButton(item, qty),
        ],
      ),
    );
  }

  Widget _qtyButton(dynamic item, int qty) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: kButtonColor),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              final oldQty = item.add_qnty <= 0 ? 1 : item.add_qnty;
              final priceD = _toDouble(item.price) / oldQty;
              final newQty = oldQty - 1;

              addOrMinusProduct(
                item.is_id,
                item.is_pres,
                item.isBasket,
                item.addedBasket,
                item.product_name,
                item.unit,
                priceD * newQty,
                item.qnty,
                newQty,
                item.product_img,
                item.varient_id,
                item.vendor_id,
                item.store_name,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.remove, size: 22.sp, color: kButtonColor),
            ),
          ),
          Text(
            "$qty",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),

          InkWell(
            onTap: () {
              final oldQty = item.add_qnty <= 0 ? 1 : item.add_qnty;

              if (oldQty >= 10) {
                _showToast("You can add maximum 10 only");
                return;
              }

              // ✅ WEIGHT CHECK before adding (predict new weight)
              final double predictedKg =
                  (totalCartWeightGram + weightPerQtyGram) / 1000;
              if (predictedKg > maxCartWeightKg) {
                _showToast(
                    "Cart weight cannot exceed ${maxCartWeightKg.toStringAsFixed(0)} kg");
                return;
              }

              final priceD = _toDouble(item.price) / oldQty;
              final newQty = oldQty + 1;

              addOrMinusProduct(
                item.is_id,
                item.is_pres,
                item.isBasket,
                item.addedBasket,
                item.product_name,
                item.unit,
                priceD * newQty,
                item.qnty,
                newQty,
                item.product_img,
                item.varient_id,
                item.vendor_id,
                item.store_name,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add, size: 22.sp, color: kButtonColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _sectionTitle("payment_info".tr()),
          _priceRow("sub_total".tr(), totalAmount),
          if (storedeliveryCharge > 0)
            _priceRow("delivery_charges".tr(), storedeliveryCharge),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "amount_to_pay".tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                _isChargesLoading
                    ?  SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,color: kMainColor,),
                )
                    : Text(
                  "$currency ${payableAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: kButtonColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "delivery_to".tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedAddressesPage("", onReturn: () async {
                        await getAddress();
                        await ordercharg();
                      }),
                    ),
                  ).then((_) async {
                    await getAddress();
                    await ordercharg();
                  });
                },
                child: Text(
                  "change".tr(),
                  style: TextStyle(
                    color: kButtonColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            addressDelivery?.address?.toString() ?? "No address selected",
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          if (Errormessage != null && Errormessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              Errormessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomPayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        height: 45.sp,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isWeightExceeded ? Colors.grey : kButtonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: (_isPaying || isWeightExceeded) ? null : _onPayTap,
          child: _isPaying
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            isWeightExceeded
                ? "Weight limit exceeded (max 20 kg)"
                : "${'pay'.tr()} $currency ${payableAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrange.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 38,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  "Delivery Address",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Please select a delivery address to continue with your order.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 26),

                // Buttons row
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF555555),
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Select Address
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // close the dialog first
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SavedAddressesPage("", onReturn: () async {
                                  await getAddress();
                                  await ordercharg();
                                }),
                              ),
                            ).then((_) async {
                              await getAddress();
                              await ordercharg();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Select Address",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  WEIGHT LIMIT DIALOG
  // ─────────────────────────────────────────────────────
  void _showWeightLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.scale_outlined,
                    size: 38,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  "Weight Limit Exceeded",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Your cart weight is ${totalCartWeightKg.toStringAsFixed(2)} kg, which is above the ${maxCartWeightKg.toStringAsFixed(0)} kg limit.\nPlease remove some items to continue.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 26),

                // OK Button (full width)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPayTap() async {
    safeSetState(() => _isPaying = true);

    try {

      // ✅ WEIGHT VALIDATION FIRST - block if cart weight > 20 kg
      if (isWeightExceeded) {
        if (!mounted) return;
        _showWeightLimitDialog();
        return;
      }

      // FIRST CHECK ONGOING ORDER
      await getOngoingOrders();

      debugPrint(
        "ONGOING FINAL => ${ongoingOrders.length}",
      );

      // AGAR ORDER PEHLE SE HAI
      if (ongoingOrders.isNotEmpty) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  // ❌ Close icon - top right
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon:  Icon(
                        Icons.close,
                        color: kButtonColor,
                        size: 22,
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        "Ongoing Order Found",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Text(
                        "Your previous order is still ongoing. Please complete or cancel it before placing a new order.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // View Ongoing Order Button (full width)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context, rootNavigator: true).pushNamed(
                              PageRoutes.ongoingOrderPage,
                            );
                          },
                          child: const Text(
                            "View Ongoing Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
      final prefs =
      await SharedPreferences.getInstance();

      if (prefs.getString('skip') != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoMarket(),
          ),
        );
        return;
      }

      if (addressDelivery == null) {
        _showAddressDialog();
        return;
      }

      if (Errormessage != null &&
          Errormessage!.isNotEmpty) {
        _showToast(
          "$Errormessage. Add another address.",
        );
        return;
      }

      await prefs.remove('service');

      await createCart(context);

    } catch (e) {

      debugPrint("PAY ERROR => $e");

      _showToast("Something went wrong");

    } finally {

      safeSetState(() => _isPaying = false);
    }
  }
  Widget _emptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 86, color: kButtonColor),
            const SizedBox(height: 16),
            const Text(
              "No item in cart",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Click below to shop now",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 42, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomeOrderAccount(0, 1)),
                      (_) => false,
                );
              },
              child: const Text(
                "Shop Now",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "$currency ${_toDouble(amount).toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 15,
    );
  }
}
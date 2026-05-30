import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Themes/colors.dart';
import '../baseurlp/baseurl.dart';
import '../bean/cartdetails.dart';
import '../bean/couponlist.dart';
import '../bean/paymentstatus.dart';
import 'order_placed.dart';

class PaymentPage extends StatefulWidget {
  final dynamic vendor_ids;
  final dynamic order_id;
  final dynamic cart_id;
  final double totalAmount;
  final List<PaymentVia> tagObjs;
  final String orderArray;
  final dynamic maxincash;

  const PaymentPage(
      this.vendor_ids,
      this.order_id,
      this.cart_id,
      this.totalAmount,
      this.tagObjs,
      this.orderArray,
      this.maxincash, {
        super.key,
      });

  @override
  State<PaymentPage> createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  Razorpay? _razorpay;

  dynamic currency = '₹';
  String message = '';

  bool showDialogBox = false;
  bool showPaymentDialog = false;
  bool _inProgress = false;

  bool wallet = false;
  bool iswallet = false;
  bool isCoupon = false;

  double orderAmount = 0.0;
  double payableAmount = 0.0;
  double walletAmount = 0.0;
  double walletUsedAmount = 0.0;
  double coupAmount = 0.0;

  List<CouponList> couponL = [];

  final _formKey = GlobalKey<FormState>();
  final _verticalSizeBox = const SizedBox(height: 20.0);
  final _horizontalSizeBox = const SizedBox(width: 10.0);

  String _cardNumber = "";
  String _cvv = "";
  int _expiryMonth = 0;
  int _expiryYear = 0;

  @override
  void initState() {
    super.initState();
    orderAmount = widget.totalAmount;
    payableAmount = widget.totalAmount;
    _init();
  }

  Future<void> _init() async {
    getData().then((_) {
      if (mounted) setState(() {});
    });

    Future.wait([
      getCouponList(),
      getWalletAmount(),
    ]).then((_) {
      if (mounted) {
        _recalculatePayable();
        setState(() {});
      }
    }).catchError((e) {
      debugPrint("Init Error: $e");
    });
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  String amountText(double value) => value.toStringAsFixed(2);

  Future<void> getData() async {
    try {
      final pref = await SharedPreferences.getInstance();
      message = pref.getString("message") ?? '';
      currency = pref.getString('curency') ?? '₹';
    } catch (e) {
      debugPrint("Pref Error: $e");
    }
  }

  Future<void> getWalletAmount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      currency = prefs.getString('curency') ?? '₹';

      final response = await http
          .post(
        Uri.parse(showWalletAmount),
        body: {'user_id': '$userId'},
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == "1") {
          final dataList = jsonData['data'] as List;

          if (dataList.isNotEmpty) {
            walletAmount =
                double.tryParse('${dataList[0]['wallet_credits']}') ?? 0.0;

            iswallet = walletAmount > 0.0;
            _recalculatePayable();
          }
        }
      }
    } catch (e) {
      debugPrint("Wallet Error: $e");
    }
  }

  Future<void> getCouponList() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final vendorId = preferences.getString('vendor_id');
      currency = preferences.getString('curency') ?? '₹';

      final response = await http
          .post(
        Uri.parse(couponList),
        body: {
          'cart_id': '${widget.cart_id}',
          'vendor_id': '$vendorId',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == "1") {
          final list = jsonData['data'] as List;
          couponL = list.map((e) => CouponList.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Coupon Error: $e");
    }
  }

  void _recalculatePayable() {
    double amount = orderAmount;
    walletUsedAmount = 0.0;

    if (wallet && walletAmount > 0) {
      walletUsedAmount = walletAmount >= amount ? amount : walletAmount;
      amount = amount - walletUsedAmount;
    }

    payableAmount = amount < 0 ? 0 : amount;
  }

  PaymentVia? get _razorPayPayment {
    if (widget.tagObjs.isEmpty) return null;

    try {
      return widget.tagObjs.firstWhere(
            (e) => e.payment_mode.toString().toLowerCase().contains('razor'),
      );
    } catch (_) {
      return widget.tagObjs.first;
    }
  }

  Future<void> placedOrder(String paymentStatus, String paymentMethod) async {
    if (showDialogBox) return;

    if (mounted) {
      setState(() => showDialogBox = true);
    }

    try {
      final response = await http
          .post(
        Uri.parse(orderplaced),
        body: {
          'payment_method': paymentMethod,
          'wallet': wallet ? 'yes' : 'no',
          'payment_status': paymentStatus,
          'cart_id': widget.cart_id.toString(),
        },
      )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == "1") {
          final details = CartDetail.fromJson(jsonData['data']);

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('service');
          await prefs.remove('res_vendor_id');
          await prefs.remove('vendor_id');

          if (!mounted) return;

          setState(() => showDialogBox = false);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderPlaced(
                details.payment_method,
                details.payment_status,
                widget.cart_id,
                details.rem_price,
                currency,
                "1",
              ),
            ),
          );
        } else {
          setState(() => showDialogBox = false);
          _showSnack(jsonData['message']?.toString() ?? 'Order failed');
        }
      } else {
        setState(() => showDialogBox = false);
        _showSnack('Something went wrong!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => showDialogBox = false);
      _showSnack('Network error, please try again.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openCheckout(String keyRazorPay, double amount) async {
    if (keyRazorPay.trim().isEmpty) {
      _showSnack("Online payment not available");
      return;
    }

    if (payableAmount <= 0) {
      _showSnack("Amount should be greater than 0");
      return;
    }

    if (mounted) {
      setState(() => showDialogBox = true);
    }

    _razorpay?.clear();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final prefs = await SharedPreferences.getInstance();

    final options = {
      'key': keyRazorPay,
      'amount': amount.toInt(),
      'name': prefs.getString('user_name') ?? 'Customer',
      'description': 'Grocery Shopping',
      'prefill': {
        'contact': prefs.getString('user_phone') ?? '',
        'email': prefs.getString('user_email') ?? '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      if (mounted) {
        setState(() => showDialogBox = false);
      }
      _razorpay!.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => showDialogBox = false);
      }
      _showSnack("Payment error");
      debugPrint(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    placedOrder("success", "RazorPay");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => showDialogBox = false);
    }
    _showSnack('Payment failed. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    final canPayByWallet = wallet && payableAmount == 0;

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: white_color,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Amount to Pay $currency ${amountText(payableAmount)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _amountSummaryCard(),
                const SizedBox(height: 16),

                if (iswallet) _walletCard(),

                if (iswallet) const SizedBox(height: 16),

                if (payableAmount > 0) _cashCard(),

                if (payableAmount > 0) const SizedBox(height: 12),

                if (payableAmount > 0) _onlinePaymentCard(),

                // if (canPayByWallet) _walletPayButton(),

                const SizedBox(height: 24),
                // _footerMessage(),
              ],
            ),
          ),
          if (showPaymentDialog) _paymentDialog(),
          if (showDialogBox) _loaderOverlay(),
        ],
      ),
    );
  }

  Widget _amountSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(width: 1,color: Colors.grey)
      ),
      child: Column(
        children: [
          Row(
            children: [
               CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.payments_rounded, color: black_color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Payment Summary',
                  style: GoogleFonts.poppins(
                    color: black_color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _summaryRow('Order Amount', '$currency ${amountText(orderAmount)}'),


          const Divider(color: Colors.black, height: 24),
          _summaryRow(
            'Payable Amount',
            '$currency ${amountText(payableAmount)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withOpacity(.88),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: isBold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use Wallet',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wallet Balance: $currency ${amountText(walletAmount)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: wallet,
            activeColor: kMainColor,
            onChanged: (val) {
              setState(() {
                wallet = val;
                _recalculatePayable();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _cashCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: showDialogBox ? null : () => placedOrder("success", "COD"),
      // onTap: showDialogBox ? null : () => placedOrder("success", "RazorPay"),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: kButtonColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  // 'images/payment/amount.png',
                  'assets/pay_on.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pay on Delivery',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    'Accepted Your Credit / Debit Card or QR for Payment At Delivery ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
             Icon(Icons.arrow_forward_ios_rounded, size: 16,color: kButtonColor,),
          ],
        ),
      ),
    );
  }

  Widget _onlinePaymentCard() {
    final payment = _razorPayPayment;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: showDialogBox
          ? null
          : () {
        if (payment == null) {
          _showSnack("Online payment not available");
          return;
        }

        // openCheckout(
        //   payment.payment_key.toString(),
        //   payableAmount * 100,
        // );

        // placedOrder("success", "RazorPay");
        placedOrder("success", "Online");
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Online Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pay using UPI, Card, NetBanking or Wallet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }



  Widget _paymentDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Material(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    const Text(
                      'Card Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    _verticalSizeBox,
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Card number',
                      ),
                      onChanged: (value) => _cardNumber = value,
                    ),
                    _verticalSizeBox,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'CVV',
                            ),
                            onChanged: (value) => _cvv = value,
                          ),
                        ),
                        _horizontalSizeBox,
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Month',
                            ),
                            onChanged: (value) {
                              _expiryMonth = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        _horizontalSizeBox,
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Year',
                            ),
                            onChanged: (value) {
                              _expiryYear = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ],
                    ),
                    _verticalSizeBox,
                    _inProgress
                        ? SizedBox(
                      height: 50,
                      child: Center(
                        child: Platform.isIOS
                            ? const CupertinoActivityIndicator()
                            : const CircularProgressIndicator(),
                      ),
                    )
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                      ),
                      onPressed: () {
                        setState(() => _inProgress = true);
                      },
                      child: const Text(
                        'Proceed to payment',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loaderOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(.35),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kMainColor),
                  const SizedBox(width: 16),
                  const Text(
                    'Loading please wait...',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ntt_atom_flutter/ntt_atom_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../OrderFailed/order_failed.dart';
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
  static String get _nttaLogin => dotenv.env['NTTA_LOGIN'] ?? '';
  static String get _nttaPassword => dotenv.env['NTTA_PASSWORD'] ?? '';
  static String get _nttaProdId => dotenv.env['NTTA_PROD_ID'] ?? '';
  static String get _nttaClientCode => dotenv.env['NTTA_CLIENT_CODE'] ?? '';
  static String get _nttaMerchType => dotenv.env['NTTA_MERCH_TYPE'] ?? '';
  static String get _nttaMccCode => dotenv.env['NTTA_MCC_CODE'] ?? '';
  static String get _nttaRequestHashKey => dotenv.env['NTTA_REQUEST_HASH_KEY'] ?? '';
  static String get _nttaResponseHashKey => dotenv.env['NTTA_RESPONSE_HASH_KEY'] ?? '';
  static String get _nttaRequestEncryptionKey => dotenv.env['NTTA_REQUEST_ENCRYPTION_KEY'] ?? '';
  static String get _nttaResponseDecryptionKey => dotenv.env['NTTA_RESPONSE_DECRYPTION_KEY'] ?? '';

  dynamic currency = '₹';

  bool showDialogBox = false;

  bool wallet = false;
  bool iswallet = false;

  double orderAmount = 0.0;
  double payableAmount = 0.0;
  double walletAmount = 0.0;
  double walletUsedAmount = 0.0;

  List<CouponList> couponL = [];

  @override
  void initState() {
    super.initState();
    orderAmount = widget.totalAmount;
    payableAmount = widget.totalAmount;
    _init();
  }

  Future<void> _init() async {
    await getData();
    if (mounted) setState(() {});

    await Future.wait([
      getCouponList(),
      getWalletAmount(),
    ]);

    if (mounted) {
      _recalculatePayable();
      setState(() {});
    }
  }

  Future<void> getData() async {
    try {
      final pref = await SharedPreferences.getInstance();
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

  bool get _isOnlinePaymentEnabled => widget.tagObjs.isNotEmpty;

  Future<void> placedOrder(String paymentStatus, String paymentMethod) async {
    if (showDialogBox) return;
    if (mounted) setState(() => showDialogBox = true);

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
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> openNttaCheckout() async {
    if (payableAmount <= 0) {
      _showSnack("Amount should be greater than 0");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final txnId = '${widget.cart_id}${DateTime.now().millisecondsSinceEpoch}';

    try {
      final instance = AtomSDK();
      instance.checkOut(
        sdkOptions: AtomPaymentOptions(
          // --- Auth ---
          login: _nttaLogin,
          password: _nttaPassword,
          // --- Merchant ---
          prodid: _nttaProdId,
          clientcode: _nttaClientCode,
          merchType: _nttaMerchType,
          mccCode: _nttaMccCode,
          // --- Encryption keys ---
          requestHashKey: _nttaRequestHashKey,
          responseHashKey: _nttaResponseHashKey,
          requestEncryptionKey: _nttaRequestEncryptionKey,
          responseDecryptionKey: _nttaResponseDecryptionKey,
          // --- Transaction ---
          txncurr: 'INR',
          amount: payableAmount.toStringAsFixed(2),
          txnid: txnId,
          mode: AtomPaymentMode.live,
          // --- Customer ---
          custFirstName: prefs.getString('user_name') ?? 'Customer',
          custLastName: '',
          email:'kpkbddn@gmail.com',
          mobile: prefs.getString('user_phone') ?? '',
          address: prefs.getString('user_address') ?? '',
          custacc: '',
          // --- User defined fields (optional) ---
          udf1: widget.cart_id.toString(),
          udf2: '',
          udf3: '',
          udf4: '',
          udf5: '',
        ),
        onClose: (transactionStatus, data) {
          final isSuccess = transactionStatus.name.toLowerCase() == 'success';
          final fullResponse = jsonEncode(data); // pura response

          // success ho ya fail, dono case API ko bhejo
          sendGatewayResponse(
            gatewayResponse: fullResponse,
            // isSuccess: isSuccess,
          );
        },

        // onClose: (transactionStatus, data) {
        //   if (transactionStatus.name.toLowerCase() == 'success') {
        //     final fullResponse = jsonEncode(data);   // pura Map -> JSON string
        //
        //     final statusCode =
        //         '${data['payInstrument']?['responseDetails']?['statusCode']}';
        //
        //     if (statusCode == 'OTS0000') {
        //
        //       sendGatewayResponse(
        //         gatewayResponse: fullResponse,
        //       );
        //       // placedOrder("success", "Online",
        //       //     // gatewayResponse: fullResponse
        //       // );
        //     } else {
        //       if (mounted) setState(() => showDialogBox = false);
        //       _showSnack('Payment not confirmed (code: $statusCode)');
        //     }
        //   } else {
        //     if (mounted) setState(() => showDialogBox = false);
        //     _showSnack('Payment failed. Please try again.');
        //   }
        // },

        // onClose: (transactionStatus, data) {
        //   // ---- DEBUG: gateway se kya mila ----
        //   debugPrint('==================== ATOM RESPONSE ====================');
        //   debugPrint('transactionStatus       : $transactionStatus');
        //   debugPrint('transactionStatus.name  : ${transactionStatus.name}');
        //   debugPrint('data runtimeType         : ${data.runtimeType}');
        //   debugPrint('data (raw)               : $data');
        //
        //   try {
        //     // agar data ek Map/object hai to har key alag se
        //     if (data is Map) {
        //       data.forEach((key, value) {
        //         debugPrint('   $key  =  $value');
        //       });
        //     } else {
        //       // agar JSON string hai to decode karke dekho
        //       final decoded = jsonDecode(data.toString());
        //       debugPrint('decoded data : $decoded');
        //     }
        //   } catch (e) {
        //     debugPrint('data parse error: $e');
        //   }
        //   debugPrint('=======================================================');
        //   // ---- DEBUG END ----
        //
        //   if (transactionStatus.name.toLowerCase() == 'success') {
        //     placedOrder("success", "Online");
        //   } else {
        //     if (mounted) setState(() => showDialogBox = false);
        //     _showSnack('Payment failed. Please try again.');
        //   }
        // },



        // onClose: (transactionStatus, data) {
        //   if (transactionStatus.name.toLowerCase() == 'success') {
        //     placedOrder("success", "Online");
        //   } else {
        //     if (mounted) setState(() => showDialogBox = false);
        //     _showSnack('Payment failed. Please try again.');
        //   }
        // },
      );
    } catch (e) {
      if (mounted) setState(() => showDialogBox = false);
      _showSnack("Payment error");
      debugPrint(e.toString());
    }
  }

  Future<void> sendGatewayResponse({
    required String gatewayResponse,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(atomResponse),
        body: {
          'cart_id': widget.cart_id.toString(),
          'gateway_response': gatewayResponse,
          // 'txn_status': isSuccess ? 'success' : 'failed',
        },
      )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final int status = jsonData['status'] ?? 0;
        final String message = jsonData['message']?.toString() ?? '';

        if (status == 1) {
          placedOrder("success", "Online");
        } else if (status == 2) {
          if (mounted) setState(() => showDialogBox = false);
          _showSnack(message.isNotEmpty ? message : 'Payment failed. Please try again.');
          _onOrderFailed();
        } else {
          if (mounted) setState(() => showDialogBox = false);
          _showSnack('Unexpected response from server.');
          _onOrderFailed();
        }

      } else {
        if (mounted) setState(() => showDialogBox = false);
        _showSnack('Server error (${response.statusCode}). Please try again.');
        _onOrderFailed();
      }

    } on SocketException {
      if (!mounted) return;
      setState(() => showDialogBox = false);
      _showSnack('No internet connection.');
      _onOrderFailed();

    } catch (e) {
      if (!mounted) return;
      setState(() => showDialogBox = false);
      _showSnack('Something went wrong. Please try again.');
      debugPrint('verify error: $e');
      _onOrderFailed();
    }
  }

  void _onOrderFailed() {
    if (!mounted) return;
    setState(() => showDialogBox = false);
    // jaisa aapko chahiye - snackbar, dialog, ya failed screen
    // _showSnack('Order could not be placed. Payment will be refunded if deducted.');

    // agar failed screen chahiye:
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderFailed(widget.cart_id, payableAmount.toString())),
    );
  }

  String amountText(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(color: Colors.black, fontSize: 12),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
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
        border: Border.all(width: 1, color: Colors.grey),
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wallet Balance: $currency ${amountText(walletAmount)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Accepted Your Credit / Debit Card or QR for Payment At Delivery',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kButtonColor),
          ],
        ),
      ),
    );
  }

  Widget _onlinePaymentCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: showDialogBox
          ? null
          : () {
              if (!_isOnlinePaymentEnabled) {
                _showSnack("Online payment not available");
                return;
              }
              openNttaCheckout();
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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

import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpUser/DriverApp/OrderMap/UI/delivery_successful.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class SignatureView extends StatefulWidget {
  final dynamic cartId;
  final dynamic vendorName;
  final dynamic vendorAddress;
  final dynamic userName;
  final dynamic userAddress;
  final dynamic userphone;
  final dynamic vendorlat;
  final dynamic vendorlng;
  final dynamic dlat;
  final dynamic dlng;
  final dynamic remprice;
  final dynamic totalPrice;
  final dynamic paymentstatus;
  final dynamic paymentMethod;
  final dynamic uiType;

  const SignatureView({
    super.key,
    this.cartId,
    this.vendorName,
    this.vendorAddress,
    this.userName,
    this.userAddress,
    this.userphone,
    this.vendorlat,
    this.vendorlng,
    this.dlat,
    this.dlng,
    this.remprice,
    this.totalPrice,
    this.paymentstatus,
    this.paymentMethod,
    this.uiType,
  });

  @override
  SignatureViewState createState() => SignatureViewState();
}

class SignatureViewState extends State<SignatureView> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.red,
    exportBackgroundColor: kWhiteColor,
  );
  dynamic currencyd = '';
  final TextEditingController _cashController = TextEditingController();
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic remprice;
  dynamic total_price;
  dynamic paymentstatus;
  dynamic paymentMethod;
  dynamic distance;
  dynamic ui_type;

  bool showOtpField = false;
  bool isSendingOtp = false;

  @override
  void initState() {
    cart_id = widget.cartId;
    vendorName = widget.vendorName;
    vendorAddress = widget.vendorAddress;
    userName = widget.userName;
    userAddress = widget.userAddress;
    userphone = widget.userphone;
    vendorlat = widget.vendorlat;
    vendorlng = widget.vendorlng;
    dlat = widget.dlat;
    dlng = widget.dlng;
    remprice = widget.remprice;
    total_price = widget.totalPrice;
    paymentstatus = widget.paymentstatus;
    paymentMethod = widget.paymentMethod;
    ui_type = widget.uiType;
    getCurrency();
    super.initState();
    _controller.addListener(() => print("Value changed"));
  }

  getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencyd = prefs.getString('curency');
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
            c((lat2 - lat1) * p) / 2 +
            c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void dispose() {
    super.dispose();
    _cashController.dispose();
  }

  Future<void> sendDeliveryOtp() async {
    setState(() {
      isSendingOtp = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(delivery_otp));

      request.fields['cart_id'] = cart_id;

      var response = await request.send();

      final res = await http.Response.fromStream(response);

      print(res.body);

      final data = jsonDecode(res.body);

      if (data['status'].toString() == "1") {
        setState(() {
          showOtpField = true;
        });

        Fluttertoast.showToast(
          msg: data['message'] ?? "OTP Sent Successfully",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? "Failed",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print(e);

      Fluttertoast.showToast(
        msg: "Something went wrong",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    setState(() {
      isSendingOtp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ProgressDialog pr = ProgressDialog(
      context,
      type: ProgressDialogType.normal,
      isDismissible: false,
      showLogs: true,
    );
    pr.style(
      message: 'Loading please wait...',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress: 0.0,
      maxProgress: 100.0,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      progressTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
      ),
      messageTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
      ),
    );
    final bool isPOD = paymentMethod.toString().toLowerCase() == "pod";
    final bool isOnline = paymentMethod.toString().toLowerCase() == "online";
    String maskedPhone(String phone) {
      if (phone.length < 4) return phone;
      return '*' * (phone.length - 4) + phone.substring(phone.length - 4);
    }
    return Scaffold(
        backgroundColor: kCardBackgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: kWhiteColor,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order - #${cart_id}',
                    // 'Order',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Order Amount - ${currencyd} ${remprice}',
                    // 'Order',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _controller.clear());
                    },
                    child: Text(
                      'Clear View',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        body:Stack(
          children: [
            Positioned.fill(
              child: Signature(
                controller: _controller,
                backgroundColor: kWhiteColor,
              ),
            ),

            Center(
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -45 * math.pi / 180,
                  child: Opacity(
                    opacity:isPOD ? 0.2:0.6,
                    child: Text(
                      isPOD ? "POD" : "PAID",
                      style: TextStyle(
                        fontSize: 150.sp,
                        fontWeight: FontWeight.bold,
                        color: isPOD ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Visibility(
                visible: isPOD || isOnline,
                child: Column(
                  children: [
                    InkWell(
                      onTap: isSendingOtp ? null : sendDeliveryOtp,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kButtonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isSendingOtp
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Send Delivery OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    if (showOtpField)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sms_outlined,
                              color: Colors.orange.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "OTP has been sent to\n",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.normal,
                                        color:kButtonColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: maskedPhone(userphone),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color:kButtonColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 15),

                    if (showOtpField)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextFormField(
                          controller: _cashController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: InputDecoration(
                            hintText: 'Enter Customer OTP',
                            hintStyle: TextStyle(fontSize: 12.sp),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.zero),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: Text(
                "Signature here",
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ),

            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    hitSevice(cart_id, _cashController.text, pr, context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Card(
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 100,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kMainColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Mark as Delivered',
                        style: TextStyle(
                          color: kWhiteColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
    );
  }

  Future<void> hitSevice(cartID, cashAmt, ProgressDialog pr, BuildContext context) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final dBoyId = pref.getInt('delivery_boy_id');

      if (_controller == null || _controller.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please try again!',
          backgroundColor: Colors.black26,
          textColor: Colors.white,
        );
        return;
      }

      if (paymentMethod == "POD" && cashAmt.toString().trim().isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please fill the amount you have received from customer.',
          backgroundColor: Colors.black26,
          textColor: Colors.white,
        );
        return;
      }

      pr.show();

      final data = await _controller.toPngBytes();
      final imageS = base64Encode(data!);

      final response = await http.post(
        Uri.parse(delivery_completed),
        body: {
          'cart_id': cartID.toString(),
          'user_signature': imageS,
          'cash_amount': paymentMethod == "POD" ? cashAmt.toString() : cashAmt.toString(),
          'delivery_boy_id': dBoyId.toString(),
        },
      );

      if (pr.isShowing()) {
        await pr.hide();
      }

      debugPrint("STATUS CODE ==> ${response.statusCode}");
      debugPrint("RESPONSE ==> ${response.body}");

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['status'].toString() == "1") {
        if (!context.mounted) return;

        await Future.delayed(const Duration(milliseconds: 250));

        if (!context.mounted) return;

        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DeliverySuccessful(
              cartId: cartID,
              vendorName: vendorName,
              vendorAddress: vendorAddress,
              vendorlat: vendorlat,
              vendorlng: vendorlng,
              dlat: dlat,
              dlng: dlng,
              userName: userName,
              userAddress: userAddress,
              userphone: userphone,
              remprice: remprice,
              paymentstatus: paymentstatus,
              paymentMethod: paymentMethod,
            ),
          ),
        );
      } else {
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.18),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Icon
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
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    "Invalid OTP",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Message
                  Text(
                    jsonData['message']?.toString() ??
                        "Invalid OTP, please try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xffd32f2f),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "TRY AGAIN",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (pr.isShowing()) {
        await pr.hide();
      }

      debugPrint("hitSevice error ==> $e");

      Fluttertoast.showToast(
        msg: "Something went wrong!",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
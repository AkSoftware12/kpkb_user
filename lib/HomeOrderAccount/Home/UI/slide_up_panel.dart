import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../Themes/colors.dart';
import '../../../bean/orderbean.dart';

class SlideUpPanel extends StatefulWidget {
  final OngoingOrders ongoingOrders;
  final dynamic currency;

  SlideUpPanel(this.ongoingOrders, this.currency);

  @override
  _SlideUpPanelState createState() => _SlideUpPanelState();
}

class _SlideUpPanelState extends State<SlideUpPanel> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.20,
      initialChildSize: 0.20,
      maxChildSize: 1.0,
      builder: (context, controller) {
        return Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.only(left: 4.w),
          color: kCardBackgroundColor,
          child: SingleChildScrollView(
            controller: controller,
            child: Container(
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    child: Stack(
                      children: <Widget>[
                        Hero(
                          tag: 'Delivery Boy',
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10.h, top: 14.h),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 22.r,
                                backgroundImage:
                                AssetImage('images/profile.png'),
                              ),
                              title: Text(
                                widget.ongoingOrders.delivery_boy_name != null
                                    ? '${widget.ongoingOrders.delivery_boy_name}'
                                    : 'Delivery boy not assigned yet',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Delivery Partner',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                    fontSize: 11.7.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xffc2c2c2)),
                              ),
                              trailing: FittedBox(
                                fit: BoxFit.fill,
                                child: Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon:
                                      Icon(Icons.phone, color: kMainColor),
                                      onPressed: () {
                                        if (widget.ongoingOrders
                                            .delivery_boy_phone !=
                                            null &&
                                            widget.ongoingOrders
                                                .delivery_boy_phone
                                                .toString()
                                                .length >
                                                5) {
                                          _launchURL(
                                              "tel://${widget.ongoingOrders.delivery_boy_phone}");
                                        } else {
                                          Fluttertoast.showToast(
                                              msg:
                                              'Delivery boy not assigned yet',
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Colors.black26,
                                              textColor: Colors.white,
                                              fontSize: 14.sp);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Hero(
                            tag: 'arrow',
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              color: kMainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemCount: widget.ongoingOrders.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ongoingOrders.data[index].vendor_name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                    color: Colors.orange),
                              ),
                              Text(
                                widget.ongoingOrders.data[index].product_name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${widget.ongoingOrders.data[index].quantity} ${widget.ongoingOrders.data[index].unit} x ${widget.ongoingOrders.data[index].qty}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontSize: 13.3.sp),
                          ),
                          trailing: Text(
                            '${widget.currency} ${widget.ongoingOrders.data[index].price}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontSize: 13.3.sp),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: double.infinity,
                    padding:
                    EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: Text('PAYMENT INFO',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                            color: kDisabledColor,
                            fontSize: 13.3.sp,
                            letterSpacing: 0.67)),
                    color: Colors.white,
                  ),
                  Container(
                    color: Colors.white,
                    padding:
                    EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Sub Total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${widget.currency} ${widget.ongoingOrders.price_without_delivery}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ]),
                  ),
                  Container(
                    color: Colors.white,
                    padding:
                    EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Delivery Charge',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${widget.currency} ${widget.ongoingOrders.delivery_charge}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ]),
                  ),
                  (widget.ongoingOrders.gst > 0)
                      ? Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: 8.h, horizontal: 20.w),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'GST',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${widget.currency} ${widget.ongoingOrders.gst.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ]),
                  )
                      : Container(),
                  Container(
                    color: Colors.white,
                    padding:
                    EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                    child: (widget.ongoingOrders.payment_method == "Card" ||
                        widget.ongoingOrders.payment_method == "Wallet")
                        ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Payment Status',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
                          ),
                          Text(
                            '${widget.ongoingOrders.payment_status}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
                          ),
                        ])
                        : (widget.ongoingOrders.remaining_amount != 0)
                        ?Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Pay on Delivery',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.currency} ${widget.ongoingOrders.new_price}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                        : Row(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
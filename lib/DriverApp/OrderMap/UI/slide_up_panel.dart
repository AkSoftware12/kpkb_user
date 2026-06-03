import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/beanmodel/Multistoreorder.dart';
import 'package:flutter/material.dart';

class OrderInfoContainer extends StatefulWidget {
  final List<OrderDetail> orders;
  final dynamic remprice;
  final dynamic paymentMethod;
  final dynamic paymentstatus;
  final dynamic currency;

  OrderInfoContainer(
    this.orders,
    this.remprice,
    this.paymentMethod,
    this.paymentstatus,
    this.currency,
  );

  @override
  _OrderInfoContainerState createState() => _OrderInfoContainerState();
}

class _OrderInfoContainerState extends State<OrderInfoContainer> {
  @override
  Widget build(BuildContext context) {
    print("DETAILS" + widget.orders.toString());

    return Container(
      padding: EdgeInsets.only(left: 4.0),
      color: kCardBackgroundColor,
      height: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.width,
            child: Scrollbar(
              controller: ScrollController(),
              child: ListView.builder(
                itemCount: widget.orders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      widget.orders[index].vendorName,
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: Container(
                      height: 120,
                      child: ListView.builder(
                        itemCount: widget.orders[index].vendordetails?.length,
                        itemBuilder: (context, ind) {
                          return ListTile(
                            visualDensity: VisualDensity(
                              horizontal: 0,
                              vertical: -4,
                            ),
                            title: Text(
                              widget
                                  .orders[index]
                                  .vendordetails?[ind]
                                  .productName,
                              style: TextStyle(fontSize: 16),
                            ),
                            subtitle: Text(
                              '(${widget.orders[index].vendordetails?[ind].quantity}${widget.orders[index].vendordetails?[ind].unit} x ${widget.orders[index].vendordetails?[ind].qty})',
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 50.0,
            color: kMainColor,
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  (widget.paymentMethod == "COD")
                      ? 'Cash on Delivery'
                      : 'Payment Status',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: kWhiteColor),
                ),
                Text(
                  (widget.paymentMethod == "COD")
                      ? '${widget.currency} ${widget.remprice}'
                      : '${widget.paymentstatus}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: kWhiteColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

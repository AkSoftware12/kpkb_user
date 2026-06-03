import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/Multistoreorder.dart';
import 'package:flutter/material.dart';

class Itemdetail extends StatelessWidget {
  final dynamic cartId;
  final List<OrderDetail> itemDetails;
  final dynamic currency;

  const Itemdetail({
    super.key,
    required this.cartId,
    required this.itemDetails,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Item(cartId, itemDetails, currency));
  }
}

class Item extends StatefulWidget {
  final List<OrderDetail> orderDeatisSub;
  final dynamic currency;
  final dynamic cart_id;

  const Item(this.cart_id, this.orderDeatisSub, this.currency, {super.key});

  @override
  ItemDetails createState() =>
      ItemDetails(this.cart_id, this.orderDeatisSub, this.currency);
}

class ItemDetails extends State<Item> with SingleTickerProviderStateMixin {
  dynamic cart_id;
  List<OrderDetail> orderDeatisSub = [];
  dynamic currency;
  int indx = 0;
  List<Tab> tabs = <Tab>[];
  TabController? tabController;

  ItemDetails(this.cart_id, this.orderDeatisSub, this.currency);

  @override
  void initState() {
    super.initState();
    List<Tab> tabss = <Tab>[];

    for (final element in orderDeatisSub) {
      tabss.add(Tab(text: element.vendorName));
    }

    tabs.clear();
    tabs = tabss;
    tabController = TabController(length: tabs.length, vsync: this);
    tabController?.addListener(() {
      if (!tabController!.indexIsChanging) {
        setState(() {
          indx = tabController!.index;
        });
      }
    });
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: kCardBackgroundColor,
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0.5,
          centerTitle: false,
          iconTheme: IconThemeData(color: kMainTextColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: kMainTextColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '#$cart_id',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: kMainColor,
                ),
              ),
            ],
          ),
          // bottom: PreferredSize(
          //   preferredSize: Size.fromHeight(48.h),
          //   child: Container(
          //     color: kWhiteColor,
          //     alignment: Alignment.centerLeft,
          //     child: TabBar(
          //       controller: tabController,
          //       isScrollable: true,
          //       labelColor: kWhiteColor,
          //       unselectedLabelColor: kMainTextColor,
          //       labelStyle: TextStyle(
          //         fontSize: 12.sp,
          //         fontWeight: FontWeight.w600,
          //       ),
          //       unselectedLabelStyle: TextStyle(
          //         fontSize: 12.sp,
          //         fontWeight: FontWeight.w400,
          //       ),
          //       indicatorSize: TabBarIndicatorSize.tab,
          //       dividerColor: Colors.transparent,
          //       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          //       labelPadding: EdgeInsets.symmetric(horizontal: 6.w),
          //       indicator: BoxDecoration(
          //         color: kMainColor,
          //         borderRadius: BorderRadius.circular(30),
          //       ),
          //       tabs: tabs
          //           .map(
          //             (t) => Tab(
          //           child: Padding(
          //             padding: EdgeInsets.symmetric(horizontal: 14.w),
          //             child: Text(t.text ?? ''),
          //           ),
          //         ),
          //       )
          //           .toList(),
          //     ),
          //   ),
          // ),
        ),
        body: TabBarView(
          controller: tabController,
          children: List.generate(tabs.length, (tabIndex) {
            final vendor = orderDeatisSub[tabIndex];
            final items = vendor.vendordetails ?? [];

            return Column(
              children: [
                // Vendor summary header
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 4.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40.w,
                        width: 40.w,
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: kMainColor,
                          size: 20.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vendor.vendorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: kMainTextColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${items.length} item${items.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 16.h),
                    itemCount: items.length,
                    itemBuilder: (context, ind) {
                      final item = items[ind];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 72.w,
                                width: 72.w,
                                color: kCardBackgroundColor,
                                child: Image.network(
                                  '$imageBaseUrl${item.varientImage}',
                                  height: 72.w,
                                  width: 72.w,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Center(
                                      child: SizedBox(
                                        height: 22.w,
                                        width: 22.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: kMainColor,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, exception, stackTrace) {
                                    return Container(
                                      color: kCardBackgroundColor,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey.shade400,
                                        size: 28.w,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // Product info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.productName}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: kMainTextColor,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kCardBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.quantity}${item.unit}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: kMainTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kMainColor.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'x ${item.qty}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: kMainColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
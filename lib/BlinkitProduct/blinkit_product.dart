import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../Components/custom_appbar.dart';
import '../HomeOrderAccount/Account/UI/account_page.dart';
import '../HomeOrderAccount/Home/UI/Stores/stores.dart';
import '../HomeOrderAccount/Home/UI/appcategory/appcategory.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Pages/oneViewCart.dart';
import '../Routes/routes.dart';
import '../TextNumber/textfield.dart';
import '../Themes/colors.dart';
import '../Themes/constantfile.dart';
import '../Themes/style.dart';
import '../baseurlp/baseurl.dart';
import '../bean/bannerbean.dart';
import '../bean/cartitem.dart';
import '../bean/nearstorebean.dart';
import '../bean/productlistvarient.dart';
import '../bean/resturantbean/addonidlist.dart';
import '../bean/resturantbean/restaurantcartitem.dart';
import '../bean/subcategorylist.dart';
import '../bean/venderbean.dart';
import '../databasehelper/dbhelper.dart';
// import '../pharmacy/pharmastore.dart';
// import '../restaturantui/pages/restaurant.dart';
// import '../restaturantui/ui/resturanthome.dart';
import '../singleproductpage/singleproductpage.dart';




class ItemsPage2 extends StatefulWidget {
  final dynamic pageTitle;
  final dynamic vendor_id;
  final dynamic category_name;
  final dynamic category_id;
  final dynamic distance;

  ItemsPage2(this.pageTitle, this.vendor_id, this.category_name,
      this.category_id, this.distance);

  @override
  _ItemsPageState createState() =>
      _ItemsPageState(pageTitle, vendor_id, category_name, category_id);
}

class _ItemsPageState extends State<ItemsPage2> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabLabels = ['Tab 1', 'Tab 2', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3', 'Tab 3','Tab 1', 'Tab 2', 'Tab 3',];







  List<double> subTotals = [];

  late List<NearStores> rest_nearStores = [];
  double totalPrice = 0.0;

  int _selectedItemIndex = -1;
  int _quantity = 1;
  double _totalPrice = 0.0;
  double pricebottom = 0.0;

  var lat = 30.3253;
  var lng = 78.0413;

  List<String> _items = ['Item 1', 'Item 2', 'Item 3'];
  List<double> _itemPrices = [10.0, 15.0, 20.0];

  void _updateTotalPrice() {
    setState(() {
      if (_selectedItemIndex != -1) {
        _totalPrice = _quantity * pricebottom;
      } else {
        _totalPrice = 0.0;
      }
    });
  }

  int _value = 0;
  int itemCount = 0;
  int restrocart = 0;
  List<CartItem> cartListI = [];

  List<Tab> tabs = <Tab>[];

  dynamic pageTitle;
  dynamic vendor_id;
  dynamic category_name;
  dynamic category_id;

  dynamic currency = '';

  List<CartItem> tagObjs = [];
  List<int> vendors = [];
  List<VarientList> datas = [];

  List<VendorList> nearStores = [];
  List<VendorList> newnearStores = [];

  List<SubCategoryList> subCategoryListApp = [];
  List<SubCategoryList> subCategoryListDemo = [
    SubCategoryList(
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ),
    SubCategoryList(
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ),
    SubCategoryList(
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ),
  ];

  List<ProductWithVarient> productVarientList = [];
  List<ProductWithVarient> productVarientListSearch = [];

  bool isCartCount = false;
  var cartCount = 0;

  dynamic totalAmount = 0.0;
  TextEditingController searchController = TextEditingController();
  TextEditingController _controller = TextEditingController();

  TabController? tabController;

  bool addMinus = false;

  bool isFetchList = false;
  bool isSearchOpen = false;
  String message = "";
  String curency = "";
  List<CartItem> results = [];

  final List<String> _images = [
    'https://freepngimg.com/thumb/vegetable/9-2-vegetable-free-download-png.png',
    'https://i.pinimg.com/736x/9e/1f/5b/9e1f5b5a9d1d92191e410cc9a734ff50.jpg',
    'https://img.freepik.com/free-photo/green-broccoli-levitating-white-background_485709-79.jpg',
    'https://pngimg.com/uploads/cabbage/small/cabbage_PNG8803.png',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRe2DcljRuOkGIHmSRwTHL4lDNg8BiYtlz0KQ&usqp=CAU',
    'https://www.winedesign.com.au/wp-content/uploads/2016/05/DSC_0499.png',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcST7LTLdC8SNtKl0mKZ2FpS71sijEXYfD_EcwUQfhnqBQe30khWPxHmKr4rDuwjS7TUqC4&usqp=CAU',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSZbFBExP1N084WuUGJgRuwwTAY10cb0QOU9Q&usqp=CAU',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR8449UAxHMQgrcbgUt_KuTDbNZbDyEG6xFkQ&usqp=CAU',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRzwdyCPZkAPbl7UPwCxrGiQ28l1mPiXyQUQQ&usqp=CAU',
    'https://banner2.cleanpng.com/20180408/yte/kisspng-fast-food-restaurant-junk-food-kfc-hamburger-junk-food-5aca9ac191eb27.0987335415232273295977.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRHBfARWpfkb5M-2zA0UY62Es3ozcDOD2fsarzzY66zNesJO-xhpSwgVb8k2d291vx9RBI&usqp=CAU',
  ];

  _ItemsPageState(
      this.pageTitle, this.vendor_id, this.category_name, this.category_id);

  @override
  void initState() {
    super.initState();
    print("widget items : ${widget.pageTitle}");
    print("widget items : ${widget.vendor_id}");
    print("widget items : ${widget.category_name}");
    print("widget items : ${widget.category_id}");
    print("widget items : ${widget.distance}");
    _tabController = TabController(length: _tabLabels.length, vsync: this);

    hitServices();
    getCartCount();
    getCartItem2();
    hitBannerUrl();
    hitServiceBanner(lat.toString(), lng.toString());
  }

  int quantity = 1;
  int selectedQuality = 1;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  showMyDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            content: Text(
              'Grocery orders are to be placed separately.\nPlease clear/empty cart to add item. ',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Clear Cart'),
                onPressed: () {
                  ClearCart();
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  void ClearCart() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.deleteAllRestProdcut();
    getCartItem2();
    setState(() {
      restrocart = 0;
    });
  }

  void getCartCount() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.queryRowCount().then((value) {
      setState(() {
        if (value != null && value > 0) {
          cartCount = value;
          isCartCount = true;
        } else {
          cartCount = 0;
          isCartCount = false;
        }
      });
    });

    getCatC();
  }

  void getCartItem2() async {
    DatabaseHelper db = DatabaseHelper.instance;
    db.getResturantOrderList().then((value) {
      List<RestaurantCartItem> tagObjs =
      value.map((tagJson) => RestaurantCartItem.fromJson(tagJson)).toList();
      if (tagObjs.isNotEmpty) {
        setState(() {
          restrocart = 1;
        });
      }
    });
  }

  void getCatC() async {
    DatabaseHelper db = DatabaseHelper.instance;
    db.calculateTotal().then((value) {
      var tagObjsJson = value as List;
      setState(() {
        if (value != null) {
          totalAmount = tagObjsJson[0]['Total'];
        } else {
          totalAmount = 0.0;
        }
      });
    });
  }

  void setList2() {
    if (searchController != null && searchController.text.length > 0) {
      setState(() {
        searchController.clear();
        productVarientList.clear();
        productVarientList = List.from(productVarientListSearch);
      });
    } else {
      setState(() {
        isSearchOpen = false;
        productVarientList.clear();
        productVarientList = List.from(productVarientListSearch);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vertical TabBar Demo'),
      ),
      body: Row(
        children: <Widget>[
          Container(
            width: 80.sp,
            child: DefaultTabController(
              length: tabs.length,

              child: RotatedBox(
                quarterTurns: 1,
                child: TabBarView(
                  controller: _tabController,
                  // isScrollable: true,
                  // indicatorColor: Colors.transparent,
                  // labelColor: Colors.orange,
                  // unselectedLabelColor: Colors.black,
                  children: tabs.map((Tab tab) {
                    return Stack(children: [


                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Container(
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                              top: 0.0,
                              width: MediaQuery.of(context).size.width,
                              height: isCartCount
                                  ? (MediaQuery.of(context).size.height)
                                  : (MediaQuery.of(context).size.height),
                              child:
                              (!isFetchList &&
                                  productVarientList != null &&
                                  productVarientList.length > 0)
                                  ? ListView.builder(
                                padding: EdgeInsets.only(
                                    bottom: 500),
                                physics:
                                const AlwaysScrollableScrollPhysics(),
                                // new
                                controller:
                                new ScrollController(),
                                //
                                // new
                                itemCount:
                                productVarientList.length,
                                itemBuilder: (context, index) {
                                  final productVariant = productVarientList[index];
                                  final data = productVariant.data;
                                  final selectPos = productVariant.selectPos;

                                  // Guard clause to prevent RangeError
                                  if (data == null || data.isEmpty || selectPos < 0 || selectPos >= data.length) {
                                    return Container(
                                      child: Text(''),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      // Navigator.of(context).push(
                                      //     MaterialPageRoute(
                                      //         builder: (context) {
                                      //   return SingleProductPage(
                                      //       productVarientList[
                                      //           index],
                                      //       currency);
                                      // })).then((value) {
                                      //   setList(
                                      //       productVarientList);
                                      //   getCartCount();
                                      // });
                                    },
                                    behavior:
                                    HitTestBehavior.opaque,
                                    child: Stack(
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .start,
                                          children: <Widget>[
                                            Padding(
                                              padding: EdgeInsets
                                                  .only(
                                                  left:
                                                  20.0,
                                                  top: 30.0,
                                                  right:
                                                  14.0),
                                              child: (productVarientList !=
                                                  null &&
                                                  productVarientList
                                                      .length >
                                                      0)
                                                  ?
                                              // Image.network(
                                              //         imageBaseUrl +
                                              //             productVarientList[index]
                                              //                 .products_image,
                                              //         height:
                                              //             93.3,
                                              //         width: 93.3,
                                              //       )

                                              Image.network(
                                                imageBaseUrl +
                                                    productVarientList[index]
                                                        .products_image,
                                                width:
                                                93.3,
                                                height:
                                                93.3,
                                                errorBuilder: (BuildContext context,
                                                    Object
                                                    exception,
                                                    StackTrace?
                                                    stackTrace) {
                                                  // Return a placeholder/default image when the network image fails to load
                                                  return Image
                                                      .network(
                                                    'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900',
                                                    width:
                                                    93.3,
                                                    height:
                                                    93.3,
                                                  );
                                                  // Replace 'default_image.png' with your default image asset path
                                                },
                                              )
                                                  : Image(
                                                image: AssetImage(
                                                    'images/logos/playstore.png'),
                                                height:
                                                93.3,
                                                width:
                                                93.3,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: <Widget>[
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                        EdgeInsets.only(right: 20),
                                                        child:
                                                        Row(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                          children: [
                                                            productVarientList[index].is_veg == 1
                                                                ? Image.asset(
                                                              'assets/veg.png',
                                                              // Replace with your path to the vegetarian image
                                                              width: 20,
                                                              // Adjust as needed
                                                              height: 20, // Adjust as needed
                                                            )
                                                                : Image.asset(
                                                              'assets/non_veg.png',
                                                              // Replace with your path to the non-vegetarian image
                                                              width: 20,
                                                              // Adjust as needed
                                                              height: 20, // Adjust as needed
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 8.0),
                                                              child: SplitTextWidget(
                                                                text: productVarientList[index].product_name,

                                                                maxCharactersPerLine: 35,
                                                                style: TextStyle(fontSize: 13),
                                                              ),
                                                            ),
                                                            SizedBox(height: 5),
                                                            // Add some space between product name and indicator
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 8.0,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                          (productVarientList[index].data.length <= 0 || productVarientList[index].data[productVarientList[index].selectPos].strick_price <= productVarientList[index].data[productVarientList[index].selectPos].price || productVarientList[index].data[productVarientList[index].selectPos].strick_price == null)
                                                              ? ''
                                                              : '$currency ${productVarientList[index].data[productVarientList[index].selectPos].strick_price} ',
                                                          style:
                                                          TextStyle(decoration: TextDecoration.lineThrough)),
                                                      Text(
                                                        '$currency ${(productVarientList[index].data.length > 0) ? productVarientList[index].data[productVarientList[index].selectPos].price : 0}',
                                                        //style: TextStyle(decoration: TextDecoration.lineThrough)
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height:
                                                    20.0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        Positioned(
                                          left: 120,
                                          bottom: 5,
                                          child: Container(
                                              height: 30.0,
                                              padding: EdgeInsets
                                                  .symmetric(
                                                  horizontal:
                                                  12.0),
                                              decoration:
                                              BoxDecoration(
                                                color:
                                                kCardBackgroundColor,
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    30.0),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${productVarientList[index].data[0].quantity} ${productVarientList[index].data[0].unit}',
                                                  style: Theme.of(
                                                      context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              )),
                                        ),



                                        Positioned(
                                          height: 30,
                                          right: 20.0,
                                          bottom: 5,
                                          child: (productVarientList[
                                          index]
                                              .data !=
                                              null &&
                                              productVarientList[
                                              index]
                                                  .data
                                                  .length >
                                                  0 &&
                                              int.parse(
                                                  '${productVarientList[index].data[productVarientList[index].selectPos].stock}') >
                                                  0)
                                              ? (productVarientList[
                                          index]
                                              .add_qnty ==
                                              0
                                              ? Container(
                                            height:
                                            30,
                                            child: (productVarientList[index].data != null &&
                                                productVarientList[index].data.length > 0 &&
                                                int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}') > 0)
                                                ? (productVarientList[index].add_qnty == 0
                                                ? Container(
                                              height: 30.0,
                                              child: TextButton(
                                                child: Text(
                                                  'Add',
                                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor, fontWeight: FontWeight.bold),
                                                ),
                                                onPressed: () {
                                                  if (productVarientList[index].data.length == 1) {
                                                    if (restrocart == 1) {
                                                      print("ALREADY");
                                                      showMyDialog(context);
                                                    } else {
                                                      setState(() {
                                                        var stock = int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}');
                                                        if (stock > productVarientList[index].add_qnty) {
                                                          productVarientList[index].add_qnty++;
                                                          addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                        } else {
                                                          // Toast.show(
                                                          //     "No more stock available!",
                                                          //     context,
                                                          //     gravity: Toast
                                                          //         .BOTTOM);
                                                        }
                                                      });
                                                    }
                                                  } else {



                                                    showModalBottomSheet(
                                                      backgroundColor:   Colors.grey.shade100,

                                                      context: context,
                                                      // isScrollControlled: true,
                                                      // useRootNavigator: false,
                                                      builder: (BuildContext context) {

                                                        return StatefulBuilder(

                                                          builder: (BuildContext context, StateSetter setState) {
                                                            return Container(

                                                              child: Column(
                                                                children: [
                                                                  Container(
                                                                    child: Column(
                                                                      children: [
                                                                        Stack(
                                                                          children: <Widget>[
                                                                            Column(

                                                                              children: [
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  children: <Widget>[
                                                                                    Padding(
                                                                                      padding: EdgeInsets.all(10.sp),
                                                                                      child: (productVarientList != null && productVarientList.length > 0)
                                                                                          ? ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(15.0),
                                                                                        child: Image.network(
                                                                                          imageBaseUrl + productVarientList[index].products_image,
                                                                                          width: 60.sp,
                                                                                          height: 60.sp,
                                                                                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                                                                            // Return a placeholder/default image when the network image fails to load
                                                                                            return Image.network(
                                                                                              'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900',
                                                                                              width: 60.sp,
                                                                                              height: 60.sp,
                                                                                            );
                                                                                            // Replace 'default_image.png' with your default image asset path
                                                                                          },
                                                                                        ),
                                                                                      )
                                                                                          : ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(15.0),
                                                                                        child: Image(
                                                                                          image: AssetImage('images/logos/playstore.png'),
                                                                                          width: 60.sp,
                                                                                          height: 60.sp,
                                                                                        ),
                                                                                      ),
                                                                                    ),

                                                                                    Padding(
                                                                                      padding:  EdgeInsets.only(top: 10.sp),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Container(
                                                                                            padding: EdgeInsets.only(right: 20.sp),
                                                                                            child: SplitTextWidget(
                                                                                              text: productVarientList[index].product_name,
                                                                                              maxCharactersPerLine: 50,
                                                                                              style:TextStyle(fontSize: 13.sp),
                                                                                            ),
                                                                                            // child: Text(productVarientList[index].product_name, style: bottomNavigationTextStyle.copyWith(fontSize: 15)),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),

                                                                                  ],
                                                                                ),
                                                                                Divider(
                                                                                  height: 2,
                                                                                  color: Colors.grey.shade300,
                                                                                )

                                                                              ],
                                                                            ),

                                                                          ],
                                                                        ),

                                                                        SizedBox(height: 5.0),

                                                                        Padding(
                                                                          padding:  EdgeInsets.all(10.sp),
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(horizontal: 12.sp),
                                                                            decoration: BoxDecoration(
                                                                              color: Colors.white,
                                                                              borderRadius: BorderRadius.circular(20.0),
                                                                            ),
                                                                            child: Column(
                                                                              children: [

                                                                                Container(
                                                                                  width: width - (fixPadding * 2),
                                                                                  padding: EdgeInsets.all(fixPadding),

                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    children: <Widget>[

                                                                                      Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the start (left) of the column

                                                                                        children: [
                                                                                          // First Column
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the start (left) of the column
                                                                                            children: [
                                                                                              Container(
                                                                                                child: Text(
                                                                                                  'Quantity',
                                                                                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: kMainTextColor, fontSize: 13.sp),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          // SizedBox(width: 20), // Optional: Add some space between the two columns
                                                                                          // Second Column
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the start (left) of the column
                                                                                            children: [
                                                                                              Text(
                                                                                                'select any 1 option',
                                                                                                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: kHintColor, fontSize: 9.sp),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      ),




                                                                                      Container(
                                                                                        decoration: BoxDecoration(
                                                                                          borderRadius: BorderRadius.circular(7.0),
                                                                                          color: Colors.lightBlueAccent.shade100,
                                                                                          // Adjust the radius as needed
                                                                                          border: Border.all(
                                                                                            color: Colors.lightBlueAccent, // Adjust border color as needed
                                                                                          ),
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.all(5.0),
                                                                                          child:   Text(
                                                                                            'REQUIRED',
                                                                                            style: Theme.of(context)
                                                                                                .textTheme
                                                                                                .titleSmall!
                                                                                                .copyWith(color: kMainTextColor,fontSize: 9.sp),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),

                                                                                Divider(
                                                                                  height: 2,
                                                                                  color: Colors.grey.shade200,
                                                                                ),


                                                                                (productVarientList[index].data != null && productVarientList[index].data.length > 0)
                                                                                    ? ListView.builder(
                                                                                  shrinkWrap: true,
                                                                                  physics: NeverScrollableScrollPhysics(), // If it's inside another scrollable widget
                                                                                  itemCount: productVarientList[index].data.length,
                                                                                  itemBuilder: (context, i) {
                                                                                    var entry = productVarientList[index].data[i];
                                                                                    return Theme(
                                                                                      data: Theme.of(context).copyWith(
                                                                                        listTileTheme: ListTileTheme.of(context).copyWith(dense: true),
                                                                                      ),
                                                                                      child: RadioListTile<VarientList>(
                                                                                        controlAffinity: ListTileControlAffinity.trailing,
                                                                                        title: Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                          children: [
                                                                                            Text(
                                                                                              '${entry.quantity} ${entry.unit}',
                                                                                              style: Theme.of(context)
                                                                                                  .textTheme
                                                                                                  .titleSmall!
                                                                                                  .copyWith(color: kMainTextColor, fontSize: 13.sp),
                                                                                            ),
                                                                                            Text(
                                                                                              '₹ ${entry.price}',
                                                                                              style: Theme.of(context)
                                                                                                  .textTheme
                                                                                                  .titleSmall!
                                                                                                  .copyWith(color: kMainTextColor, fontSize: 13.sp),
                                                                                            ),

                                                                                          ],
                                                                                        ),
                                                                                        value: entry,
                                                                                        groupValue: productVarientList[index]
                                                                                            .data[productVarientList[index].selectPos],
                                                                                        onChanged: (value) {
                                                                                          setState(() {
                                                                                            productVarientList[index].selectPos = i;
                                                                                            DatabaseHelper db = DatabaseHelper.instance;
                                                                                            db
                                                                                                .getVarientCount(int.parse(
                                                                                                '${productVarientList[index].data[productVarientList[index].selectPos].varient_id}'))
                                                                                                .then((value) {
                                                                                              print('print t val $value');
                                                                                              if (value == null) {
                                                                                                setState(() {
                                                                                                  productVarientList[index].add_qnty = 0;
                                                                                                });
                                                                                              } else {
                                                                                                setState(() {
                                                                                                  productVarientList[index].add_qnty = value;
                                                                                                  isCartCount = true;
                                                                                                });
                                                                                              }
                                                                                            });
                                                                                          });
                                                                                        },
                                                                                        activeColor: Colors.orangeAccent,
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                )
                                                                                    : Text('No data available'),

                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),


                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    color: Colors.white,
                                                                    height:60.sp,


                                                                    child: Container(

                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[

                                                                          SizedBox(width: 10.sp,),

                                                                          Container(
                                                                            height: 40.sp,
                                                                            width: 100.sp,
                                                                            decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(10.0),
                                                                              // Adjust the radius as needed
                                                                              border: Border.all(
                                                                                color: Colors.blue.shade100, // Adjust border color as needed
                                                                              ),
                                                                            ),
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(0.0),
                                                                              child: Container(

                                                                                child: (productVarientList[index].data != null && productVarientList[index].data.length > 0 && int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}') > 0)
                                                                                    ? (productVarientList[index].add_qnty == 0
                                                                                    ? Container(
                                                                                  height: 30.sp,
                                                                                  child: TextButton(
                                                                                    child: Text(
                                                                                      'Add',
                                                                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor, fontWeight: FontWeight.bold,fontSize: 13.sp),
                                                                                    ),
                                                                                    onPressed: () {
                                                                                      if (restrocart == 1) {
                                                                                        print("ALREADY");
                                                                                        showMyDialog(context);
                                                                                      } else {
                                                                                        setState(() {
                                                                                          var stock = int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}');
                                                                                          if (stock > productVarientList[index].add_qnty) {
                                                                                            productVarientList[index].add_qnty++;
                                                                                            addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                                                          } else {
                                                                                            // Toast.show(
                                                                                            //     "No more stock available!",
                                                                                            //     context,
                                                                                            //     gravity: Toast
                                                                                            //         .BOTTOM);
                                                                                          }
                                                                                        });
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                )
                                                                                    : Center(
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: <Widget>[
                                                                                      InkWell(
                                                                                        onTap: () {
                                                                                          setState(() {
                                                                                            productVarientList[index].add_qnty--;
                                                                                            if (_quantity > 1) _quantity--;
                                                                                          });
                                                                                          addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                                                        },
                                                                                        child: Icon(
                                                                                          Icons.remove,
                                                                                          color: kMainColor,
                                                                                          size: 20.0,
                                                                                          //size: 23.3,
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(width: 8.0),
                                                                                      Text(productVarientList[index].add_qnty.toString(), style: Theme.of(context).textTheme.bodySmall),
                                                                                      SizedBox(width: 8.0),
                                                                                      InkWell(
                                                                                        onTap: () {
                                                                                          setState(() {
                                                                                            var stock = int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}');
                                                                                            if (stock > productVarientList[index].add_qnty) {
                                                                                              productVarientList[index].add_qnty++;
                                                                                              _quantity++;
                                                                                              addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                                                            } else {
                                                                                              // Toast.show(
                                                                                              //     "No more stock available!",
                                                                                              //     context,
                                                                                              //     gravity: Toast
                                                                                              //         .BOTTOM);
                                                                                            }
                                                                                          });
                                                                                        },
                                                                                        child: Icon(
                                                                                          Icons.add,
                                                                                          color: kMainColor,
                                                                                          size: 20.0,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ))
                                                                                    : Container(
                                                                                  child: Text(
                                                                                    'Out off stock',
                                                                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor, fontWeight: FontWeight.bold,fontSize: 13.sp),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                          ),


                                                                          Container(
                                                                            width: 200.sp,
                                                                            height: 40.sp,
                                                                            decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(10.0),
                                                                              color: Colors.lightBlueAccent.shade100,
                                                                              // Adjust the radius as needed
                                                                              border: Border.all(
                                                                                color: Colors.lightBlueAccent, // Adjust border color as needed
                                                                              ),
                                                                            ),
                                                                            child: Padding(
                                                                              padding:  EdgeInsets.all(10.sp),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                // // crossAxisAlignment: CrossAxisAlignment.center,
                                                                                // mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: <Widget>[
                                                                                  GestureDetector(
                                                                                    onTap: () async {
                                                                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                                                                      String? skip = prefs.getString('skip');
                                                                                      if (skip != null) {
                                                                                        Navigator.push(
                                                                                          context,
                                                                                          MaterialPageRoute(
                                                                                            builder: (context) => oneViewCart(),
                                                                                          ),
                                                                                        );
                                                                                      } else {
                                                                                        Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
                                                                                          setList(productVarientList);
                                                                                          getCartCount();
                                                                                        });



                                                                                        SharedPreferences prefs = await SharedPreferences.getInstance();
                                                                                        // Saving the string
                                                                                        await prefs.setString('service', 'service');
                                                                                      }
                                                                                    },
                                                                                    child: Text(
                                                                                      'GO TO CART $currency ${productVarientList[index].data[productVarientList[index].selectPos].price != null ? productVarientList[index].data[productVarientList[index].selectPos].price * _quantity : 0}',
                                                                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 13.sp),

                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(width: 10.sp,),

                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),


                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            )
                                                : Container(
                                              height: 30.0,
                                              padding: EdgeInsets.symmetric(horizontal: 11.0),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: kMainColor),
                                                borderRadius: BorderRadius.circular(30.0),
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        productVarientList[index].add_qnty--;
                                                      });
                                                      addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                    },
                                                    child: Icon(
                                                      Icons.remove,
                                                      color: kMainColor,
                                                      size: 20.0,
                                                      //size: 23.3,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.0),
                                                  Text(productVarientList[index].add_qnty.toString(), style: Theme.of(context).textTheme.bodySmall),
                                                  SizedBox(width: 8.0),
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        var stock = int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}');
                                                        if (stock > productVarientList[index].add_qnty) {
                                                          productVarientList[index].add_qnty++;
                                                          addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                        } else {
                                                          // Toast.show(
                                                          //     "No more stock available!",
                                                          //     context,
                                                          //     gravity: Toast
                                                          //         .BOTTOM);
                                                        }
                                                      });
                                                    },
                                                    child: Icon(
                                                      Icons.add,
                                                      color: kMainColor,
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                                : Container(
                                              child: Text(
                                                'Out off stock',
                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          )
                                              : Container(
                                            height:
                                            30.0,
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                11.0),
                                            decoration:
                                            BoxDecoration(
                                              border: Border.all(
                                                  color:
                                                  kMainColor),
                                              borderRadius:
                                              BorderRadius.circular(30.0),
                                            ),
                                            child:
                                            Row(
                                              children: <Widget>[
                                                InkWell(
                                                  onTap:
                                                      () {
                                                    setState(() {
                                                      productVarientList[index].add_qnty--;
                                                    });

                                                    addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                  },
                                                  child:
                                                  Icon(
                                                    Icons.remove,
                                                    color: kMainColor,
                                                    size: 20.0,
                                                    //size: 23.3,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: 8.0),
                                                Text(
                                                    productVarientList[index].add_qnty.toString(),
                                                    style: Theme.of(context).textTheme.bodySmall),
                                                SizedBox(
                                                    width: 8.0),
                                                InkWell(
                                                  onTap:
                                                      () {
                                                    setState(() {
                                                      var stock = int.parse('${productVarientList[index].data[productVarientList[index].selectPos].stock}');
                                                      if (stock > productVarientList[index].add_qnty) {
                                                        productVarientList[index].add_qnty++;

                                                        addOrMinusProduct(productVarientList[index].is_id, productVarientList[index].is_pres, productVarientList[index].isbasket, productVarientList[index].product_name, productVarientList[index].data[productVarientList[index].selectPos].unit, double.parse('${productVarientList[index].data[productVarientList[index].selectPos].price}'), int.parse('${productVarientList[index].data[productVarientList[index].selectPos].quantity}'), productVarientList[index].add_qnty, productVarientList[index].data[productVarientList[index].selectPos].varient_image, productVarientList[index].data[productVarientList[index].selectPos].varient_id, productVarientList[index].data[0].vendor_id);
                                                      } else {
                                                        // Toast.show(
                                                        //     "No more stock available!",
                                                        //     context,
                                                        //     gravity: Toast
                                                        //         .BOTTOM);
                                                      }
                                                    });
                                                  },
                                                  child:
                                                  Icon(
                                                    Icons.add,
                                                    color: kMainColor,
                                                    size: 20.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                              : Container(
                                            child: Text(
                                              'Out off stock',
                                              style: Theme.of(
                                                  context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                  color:
                                                  kMainColor,
                                                  fontWeight:
                                                  FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                                  : Container(
                                height: MediaQuery.of(context)
                                    .size
                                    .height /
                                    2,
                                width: MediaQuery.of(context)
                                    .size
                                    .width,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    isFetchList
                                        ? CircularProgressIndicator()
                                        : Container(
                                      width: 0.5,
                                    ),
                                    isFetchList
                                        ? SizedBox(
                                      width: 10,
                                    )
                                        : Container(
                                      width: 0.5,
                                    ),
                                    Text(
                                      (!isFetchList)
                                          ? 'No product available for this category'
                                          : 'Fetching Products..',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                          FontWeight.w600,
                                          color:
                                          kMainTextColor),
                                    )
                                  ],
                                ),
                              ))
                        ],
                      )),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void addOrMinusProduct(is_id, is_pres, isBasket, product_name, unit, price,
      quantity, itemCount, varient_image, varient_id, vendor) async {
    DatabaseHelper db = DatabaseHelper.instance;
    Future<int?> existing = db.getcount(int.parse('${varient_id}'));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_name = prefs.getString('store_name');

    existing.then((value) {
      var vae = {
        DatabaseHelper.productName: product_name,
        DatabaseHelper.storeName: store_name,
        DatabaseHelper.vendor_id: vendor,
        DatabaseHelper.price: (price * itemCount),
        DatabaseHelper.unit: unit,
        DatabaseHelper.quantitiy: quantity,
        DatabaseHelper.addQnty: itemCount,
        DatabaseHelper.productImage: varient_image,
        DatabaseHelper.is_pres: is_pres,
        DatabaseHelper.is_id: is_id,
        DatabaseHelper.isBasket: isBasket,
        DatabaseHelper.addedBasket: 0,
        DatabaseHelper.varientId: int.parse('${varient_id}')
      };

      bool allow = (prefs.getString("allowmultishop").toString() != "1");
      if (value == 0) {
        db.insert(vae);
        print("CARTITEN:::" + vae.toString());

        if (allow) {
          db.getVendorcount().then((value) {
            print("VENDORCOUNT" + value.toString());
            if (value != null && value <= 3) {
              //db.insert(vae);
              getCartCount();
            } else {
              db.delete(int.parse('${varient_id}'));
              showMyDialog2(context);
              setList(productVarientList);
            }
          });
        } else {
          db.insert(vae);
          getCartCount();
        }
      } else {
        if (itemCount == 0) {
          db.delete(int.parse('${varient_id}'));
          getCartCount();
        } else {
          db.updateData(vae, int.parse('${varient_id}')).then((vay) {
            print('vay - $vay');
            getCartCount();
          });
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  void hitServices() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      currency = preferences.getString('curency');
    });
    var url = subCategoryList;
    Uri myUri = Uri.parse(url);

    var response =
    await http.post(myUri, body: {'category_id': category_id.toString()});

    try {
      if (response.statusCode == 200) {
        print('Response Body: - ${response.body}');
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonDecode(response.body)['data'] as List;
          List<SubCategoryList> tagObjs = tagObjsJson
              .map((tagJson) => SubCategoryList.fromJson(tagJson))
              .toList();
          List<Tab> tabss = <Tab>[];
          List<SubCategoryList> toRemove = [];

          setState(() {
            for (SubCategoryList tagd in tagObjs) {
              if (tagd.istabacco.toString() != "1") {
                tabss.add(Tab(
                  text: tagd.subcatName,
                ));
                toRemove.add(tagd);
              } else {}
            }
            setState(() {
              subCategoryListApp.clear();
              tabs.clear();
              subCategoryListApp = toRemove;
              tabs = tabss;
              tabController = TabController(length: tabs.length, vsync: this);
            });
            setState(() {
              productVarientList = [];
              hitTabSeriveList(subCategoryListApp[0].subcatId);
            });

            tabController!.addListener(() {
              if (!tabController!.indexIsChanging) {
                setState(() {
                  productVarientList = [];
                  hitTabSeriveList(
                      subCategoryListApp[tabController!.index].subcatId);
                });
              }
            });
          });
        } else {
          setState(() {
            List<Tab> tabss = <Tab>[];
            tabss.add(Tab(
              text: category_name,
            ));
            subCategoryListApp.clear();
            tabs.clear();
            subCategoryListApp = [];
            tabs = tabss;

            tabController = TabController(length: tabs.length, vsync: this);
            tabController!.addListener(() {
              if (!tabController!.indexIsChanging) {
                setState(() {
                  productVarientList = [];
                  hitTabSeriveList(
                      subCategoryListApp[tabController!.index].subcatId);
                });
              }
            });
            setState(() {
              productVarientList = [];

              ///hitTabSeriveList(subCategoryListApp[0].subcat_id);
            });
          });
        }
      }
    } on Exception catch (_) {
      Timer(Duration(seconds: 5), () {
        hitServices();
      });
    }
  }

  List<dynamic> data = [];

  Future<void> hitBannerUrl() async {
    final response = await http.get(Uri.parse(servicebanner));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('data')) {
        setState(() {
          // Assuming 'data' is a list, update apiData accordingly
          data = responseData['data'];

          // await saveDataLocally(responseData['posts']);
        });
      } else {
        throw Exception('Invalid API response: Missing "data" key');
      }
    }
  }

  void hitTabSeriveList(subCatId) async {
    print("subcat is: ${subCatId.toString()}");
    setState(() {
      isFetchList = true;
    });
    var url = productListWithVarient;
    Uri myUri = Uri.parse(url);

    var response =
    await http.post(myUri, body: {'subcat_id': subCatId.toString()});
    try {
      if (response.statusCode == 200) {
        if (response.body.toString().contains('product_id')) {
          print('Response Body(chicken): - ${response.body}');
          var jsonData = jsonDecode(response.body);
          if (jsonData.toString().length > 4) {
            var tagObjsJson = jsonDecode(response.body) as List;
            List<ProductWithVarient> tagObjs = tagObjsJson
                .map((tagJson) => ProductWithVarient.fromJson(tagJson))
                .toList();
            setState(() {
              productVarientList.clear();
              productVarientListSearch.clear();
              productVarientList = tagObjs;
              print("productvarient list is 1 : ${productVarientList}");
              print(
                  "productvarient list is 1 : ${productVarientList[0].data.length}");
              /*       print("productvarient list is :${productVarientList[1]
                  .data[productVarientList[1]
                  .selectPos].strick_price}");*/
              setList(tagObjs);
            });
          }
          setState(() {
            isFetchList = false;
          });
        } else {
          setState(() {
            productVarientList.clear();
            isFetchList = false;
          });
        }
      }
    } on Exception catch (_) {
      Timer(Duration(seconds: 5), () {
        hitTabSeriveList(subCatId);
      });
    }
  }

  hitViewCart(BuildContext context) {
    if (isCartCount) {
      Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
        setList(productVarientList);
        getCartCount();
      });
    } else {
      // Toast.show('No Value in the cart!', context,
      //     duration: Toast.LENGTH_SHORT);
    }
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      message = prefs.getString("message")!;
      curency = prefs.getString("curency")!;
    });
  }

  void setList(List<ProductWithVarient> tagObjs) {
    for (int i = 0; i < tagObjs.length; i++) {
      if (tagObjs[i].data.length > 0) {
        print("PRES: " + tagObjs[i].is_pres.toString());
        DatabaseHelper db = DatabaseHelper.instance;
        db
            .getVarientCount(int.parse(
            '${tagObjs[i].data[tagObjs[i].selectPos].varient_id}'))
            .then((value) {
          print('print val $value');
          if (value == null) {
            setState(() {
              tagObjs[i].add_qnty = 0;
            });
          } else {
            setState(() {
              tagObjs[i].add_qnty = value;
              isCartCount = true;
            });
          }
        });
      }
    }
    productVarientListSearch = List.from(productVarientList);
  }

  void hitServiceBanner(String lat, String lng) async {
    var endpointUrl = vendorUrl;
    Map<String, String> queryParams = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString = Uri(queryParameters: queryParams).query;
    var requestUrl = endpointUrl +
        '?' +
        queryString; // result - https://www.myurl.com/api/v1/user?param1=1&param2=2
    print(requestUrl);
    Uri myUri = Uri.parse(requestUrl);

    var response = await http.get(myUri);
    {
      try {
        if (response.statusCode == 200) {
          var jsonData = jsonDecode(response.body);
          if (jsonData['status'] == "1") {
            var tagObjsJson = jsonDecode(response.body)['data'] as List;
            List<VendorList> tagObjs = tagObjsJson
                .map((tagJson) => VendorList.fromJson(tagJson))
                .toList();

            setState(() {
              nearStores.clear();
              nearStores = tagObjs;
            });
          }
        }
      } on Exception catch (_) {
        Timer(Duration(seconds: 5), () {
          // hitService(lat.toString(), lng.toString());
        });
      }
    }

    var endpointUrl1 = newvendorUrl;
    Map<String, String> queryParams1 = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString1 = Uri(queryParameters: queryParams1).query;
    var requestUrl1 = endpointUrl1 +
        '?' +
        queryString1; // result - https://www.myurl.com/api/v1/user?param1=1&param2=2
    print(requestUrl1);
    Uri myUri1 = Uri.parse(requestUrl1);
    var response1 = await http.get(myUri1);
    {
      try {
        if (response1.statusCode == 200) {
          var jsonData = jsonDecode(response1.body);
          if (jsonData['status'] == "1") {
            var tagObjsJson = jsonDecode(response1.body)['data'] as List;
            List<VendorList> tagObjs = tagObjsJson
                .map((tagJson) => VendorList.fromJson(tagJson))
                .toList();
            setState(() {
              newnearStores.clear();
              newnearStores = tagObjs;
            });
          }
        }
      } on Exception catch (_) {
        Timer(Duration(seconds: 5), () {
          hitService(lat.toString(), lng.toString(),);
        });
      }
    }
  }

  void hitbannerVendor(BannerDetails detail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (detail.uiType == "grocery" ||
        detail.uiType == "Grocery" ||
        detail.uiType == 1) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => new AppCategory(detail.vendorCategoryId,
                  detail.vendorName, detail.vendorId, "22")));
    }
    }
  }

  void hitNavigator(context, category_name, ui_type, vendor_category_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (ui_type == "grocery" || ui_type == "Grocery" || ui_type == "1") {
      prefs.setString("vendor_cat_id", '${vendor_category_id}');
      prefs.setString("ui_type", '${ui_type}');
      if (vendor_category_id == '18' || vendor_category_id == 18) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 500,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset("images/id.png"),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('You need to be above 18 years of age',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.w400)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Do not buy tobacco products on behalf of underage persons.',
                          style:
                          TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Your location must not be in and around school or college premises.',
                          style:
                          TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                          'Jhatfat reserves the right to report your account in case you are below 18 years of age and purchasing cigrattes',
                          style:
                          TextStyle(color: Colors.blueGrey, fontSize: 14)),
                    ),
                    new GestureDetector(
                      onTap: () {
                        Navigator.popAndPushNamed(context, PageRoutes.tncPage);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Read T&C',
                            style:
                            TextStyle(color: Colors.green, fontSize: 12)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            backgroundColor: kWhiteColor,
                            padding: EdgeInsets.all(10),
                          ),
                          child: const Text(
                            "No,I'm not",
                            style: TextStyle(
                                color: Color(0xffeca53d),
                                fontWeight: FontWeight.w400),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            backgroundColor: kMainColor,
                            padding: EdgeInsets.all(10),
                          ),
                          child: const Text("Yes,I'm above 18"),
                          onPressed: () => {
                            Navigator.pop(context),
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StoresPage(
                                        category_name, vendor_category_id)))
                          },
                        ),
                        Spacer(),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      } else {
        print("Not cigarette");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    StoresPage(category_name, vendor_category_id)));
      }

  }
}
showMyDialog2(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Maximum Vendor Limit Reached',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      });
}

class BackendService {
  static Future<List<ProductWithVarient>> getSuggestions(
      String query, dynamic vendor_id) async {
    if (query.isEmpty && query.length < 2) {
      print('Query needs to be at least 3 chars');
      return Future.value([]);
    }

    var url = storesearch;
    Uri myUri = Uri.parse(url);
    var response = await http.post(myUri,
        body: {'vendor_id': vendor_id.toString(),
          'prod_name': query});

    List<ProductWithVarient> vendors = [];
    List<ProductWithVarient> vendors1 = [];

    if (response.statusCode == 200) {
      Iterable json1 = jsonDecode(response.body)['product'];
      Iterable json2 = jsonDecode(response.body)['cat'];

      if (json1.isNotEmpty) {
        vendors.clear();
        vendors = List<ProductWithVarient>.from(
            json1.map((model) => ProductWithVarient.fromJson(model)));
      }
      if (json2.isNotEmpty) {
        vendors1.clear();
        vendors1 = List<ProductWithVarient>.from(
            json2.map((model) => ProductWithVarient.fromJson(model)));
        vendors.addAll(vendors1);
      }
    }

    return Future.value(vendors);
  }
}

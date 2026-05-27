import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kpUser/BlinkitProduct/product_details_screen.dart';

import '../Pages/oneViewCart.dart';
import '../baseurlp/baseurl.dart';
import '../bean/cartitem.dart';
import '../bean/nearstorebean.dart';
import '../bean/productlistvarient.dart';
import '../bean/resturantbean/restaurantcartitem.dart';
import '../bean/subcategorylist.dart';
import '../bean/venderbean.dart';
import '../databasehelper/dbhelper.dart';

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../HomeOrderAccount/Account/UI/account_page.dart';
import '../HomeOrderAccount/Home/UI/Stores/stores.dart';
import '../HomeOrderAccount/Home/UI/appcategory/appcategory.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Routes/routes.dart';
import '../TextNumber/textfield.dart';
import '../Themes/colors.dart';
import '../Themes/constantfile.dart';
import '../bean/bannerbean.dart';

class ProductsScreen extends StatefulWidget {

  final dynamic pageTitle;
  final dynamic vendor_id;
  final dynamic category_name;
  final dynamic category_id;
  final dynamic distance;
  final int index;
  final dynamic subcat_id;

  ProductsScreen(this.pageTitle, this.vendor_id, this.category_name,
      this.category_id, this.distance, this.index, this.subcat_id);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {

  List<double> subTotals = [];

  late List<NearStores> rest_nearStores = [];
  double totalPrice = 0.0;

  int _selectedItemIndex = -1;
  int _quantity = 1;
  double _totalPrice = 0.0;
  double pricebottom = 0.0;

  var lat = 30.3253;
  var lng = 78.0413;

  Set<int> wishlistProductIds = {};
  bool wishlistLoading = false;


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
  dynamic subcat_Id = '';

  dynamic currency = '₹';

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

  // ✅ LOCAL SEARCH FILTER
  void _filterProducts(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        productVarientList = List.from(productVarientListSearch);
      } else {
        final lowerQuery = query.toLowerCase();
        productVarientList = productVarientListSearch.where((product) {
          final name = product.product_name.toString().toLowerCase();
          return name.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> toggleWishlistApi(int productId) async {
    if (wishlistLoading) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("user_id")?.toString() ??
          prefs.getString("user_id") ??
          "0";

      if (userId == "0") {
        Fluttertoast.showToast(msg: "Please login first");
        return;
      }

      setState(() {
        wishlistLoading = true;
      });

      final Uri myUri = Uri.parse("${baseUrl}toggle-wishlist");

      final response = await http.post(
        myUri,
        body: {
          "user_id": userId,
          "product_id": productId.toString(),
        },
      );

      print("Toggle Wishlist Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"].toString() == "1") {
          final String type = data["type"]?.toString() ?? "";

          setState(() {
            if (type == "added") {
              wishlistProductIds.add(productId);
            } else if (type == "removed") {
              wishlistProductIds.remove(productId);
            }
          });

          Fluttertoast.showToast(
            msg: data["message"]?.toString() ?? "Wishlist updated",
          );
        }
      }
    } catch (e) {
      print("Toggle Wishlist Error: $e");
      Fluttertoast.showToast(msg: "Unable to update wishlist");
    } finally {
      if (mounted) {
        setState(() {
          wishlistLoading = false;
        });
      }
    }
  }

  Future<void> fetchWishlistIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("user_id")?.toString() ??
          prefs.getString("user_id") ??
          "0";

      if (userId == "0") return;

      final Uri myUri = Uri.parse("${baseUrl}wishlist");

      final response = await http.post(
        myUri,
        body: {
          "user_id": userId,
        },
      );

      print("Wishlist IDS Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"].toString() == "1" &&
            jsonData["data"] != null &&
            jsonData["data"] is List) {
          final List list = jsonData["data"];

          setState(() {
            wishlistProductIds = list
                .map((e) => int.tryParse(e["product_id"].toString()) ?? 0)
                .where((id) => id != 0)
                .toSet();
          });
        }
      }
    } catch (e) {
      print("Fetch Wishlist IDs Error: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    ClearCart();
    print("widget items : ${widget.pageTitle}");
    print("widget items : ${widget.vendor_id}");
    print("widget items : ${widget.category_name}");
    print("widget items : ${widget.category_id}");
    print("widget items : ${widget.distance}");

    getCartCount();
    getCartItem2();
    hitServiceBanner(lat.toString(), lng.toString());
    // selectedIndex = subCategoryListApp.indexWhere((subCategory) => subCategory.subcatName == 'Munchies');
    selectedIndex = widget.index.toInt();
    tabController?.animateTo(widget.index.toInt());
    fetchWishlistIds(); // ✅ add this



    hitTabSeriveList(
        widget.category_id);
  }

  int quantity = 1;
  int selectedQuality = 1;
  int selectedIndex = 0;

  @override
  void dispose() {
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

    db.queryAllRows().then((value) {
      double total = 0.0;

      List<CartItem> cartItems =
      value.map((tagJson) => CartItem.fromJson(tagJson)).toList();

      for (final item in cartItems) {
        double price = double.tryParse(item.price.toString()) ?? 0.0;

        double gstPercent = double.tryParse(
          item.gst.toString().replaceAll('%', '').trim(),
        ) ??
            0.0;

        double gstAmount = gstPercent > 0
            ? price * gstPercent / (100 + gstPercent)
            : 0.0;

        double gstOffAmount = gstAmount * 0.5;

        total += price - gstOffAmount;
      }

      setState(() {
        totalAmount = total.toStringAsFixed(2);
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        backgroundColor: white_color,
        leadingWidth: 25,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: black_color),
        title: isSearchOpen
            ? TextField(
          controller: searchController,
          autofocus: true,
          style: TextStyle(color: black_color, fontSize: 15.sp),
          cursorColor: kButtonColor,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle:
            TextStyle(color: Colors.grey, fontSize: 14.sp),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _filterProducts(value);
          },
        )
            : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pageTitle.toString(),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: black_color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  " Total item: ${productVarientList.length}",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )),
        actions: [
          // ✅ SEARCH TOGGLE BUTTON
          IconButton(
            icon: Icon(
              isSearchOpen ? Icons.close : Icons.search,
              color: black_color,
            ),
            onPressed: () {
              setState(() {
                if (isSearchOpen) {
                  // search band karo + list reset
                  isSearchOpen = false;
                  searchController.clear();
                  productVarientList = List.from(productVarientListSearch);
                } else {
                  isSearchOpen = true;
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: IconButton(
              icon: ImageIcon(
                const AssetImage('images/icons/ic_cart blk.png'),
                color: kButtonColor,
              ),
              onPressed: () async {
                Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
                  setList(productVarientList);
                  getCartCount();
                });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!isFetchList && productVarientList.isNotEmpty)
            ListView.builder(
              padding: EdgeInsets.fromLTRB(
                5.w,
                5.h,
                5.w,
                isCartCount ? 85.h : 20.h,
              ),
              itemCount: productVarientList.length,
              itemBuilder: (context, index) {
                final product = productVarientList[index];

                return GestureDetector(
                  onTap: () {

                  },
                  child: _productListCard(index),
                );
              },
            )          else
            _emptyOrLoadingWidget(),

          _bottomCartBar(),
        ],
      ),
    );
  }

  Widget _productListCard(int index) {
    final product = productVarientList[index];
    final bool hasData = product.data.isNotEmpty;
    final item = hasData ? product.data[product.selectPos] : null;

    final int stock =
    item == null ? 0 : int.tryParse(item.stock.toString()) ?? 0;

    final int productId = int.tryParse(product.product_id.toString()) ?? 0;

    final double price =
    item == null ? 0.0 : double.tryParse(item.price.toString()) ?? 0.0;

    final double strikePrice = item == null
        ? 0.0
        : double.tryParse(item.strick_price.toString()) ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(5.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                    productId: item?.product_id,
                  ),
                ),
              );

              if (!mounted) return;

              setState(() {
                // cart qty / button UI refresh
              });

              getCartCount();
              setList(productVarientList); // agar ye method cart qty set karta hai
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: CachedNetworkImage(
                    imageUrl: item == null ||
                        item.varient_image == null ||
                        item.varient_image.toString().trim().isEmpty
                        ? ''
                        : imageBaseUrl + item.varient_image.toString(),

                    height: 110.sp,
                    width: 110.sp,
                    fit: BoxFit.cover,

                    // FAST LOAD
                    memCacheHeight: 300,
                    memCacheWidth: 300,
                    maxHeightDiskCache: 600,
                    maxWidthDiskCache: 600,

                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,

                    // ✅ no progressbar
                    placeholder: (_, __) {
                      return Container(
                        height: 110.sp,
                        width: 110.sp,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.photo,
                          color: Colors.grey,
                          size: 35.sp,
                        ),
                      );
                    },

                    // ✅ default icon if image failed
                    errorWidget: (_, __, ___) {
                      return Container(
                        height: 110.sp,
                        width: 110.sp,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.photo,
                          color: Colors.grey,
                          size: 35.sp,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: InkWell(
                    onTap: () {
                      if (productId != 0) {
                        toggleWishlistApi(productId);
                      }
                    },
                    child: Container(
                      height: 30.sp,
                      width: 30.sp,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        wishlistProductIds.contains(productId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    height: 24.sp,
                    width: 24.sp,
                    padding: EdgeInsets.all(2.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: product.is_veg == 1
                        ? Image.asset('assets/veg.png')
                        : Image.asset('assets/non_veg.png'),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      strikePrice > price
                          ? '${(((strikePrice - price) / strikePrice) * 100).toStringAsFixed(0)}% OFF'
                          : 'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 5.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.product_name.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cabin(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 5.h),

                Row(
                  children: [
                    if (strikePrice > price)
                      Text(
                        '$currency ${item!.strick_price}',
                        style: GoogleFonts.cabin(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (strikePrice > price) SizedBox(width: 6.w),
                    Text(
                      '$currency ${item == null ? 0 : item.price}',
                      style: GoogleFonts.cabin(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8.sp,),
                    if (item != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.h),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'GST Inc. ${item.gst}%',
                          style: GoogleFonts.cabin(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),




                SizedBox(height: 3.h),

                Text(
                  stock > 0 ? 'Available in Stock ($stock)' : 'Out of stock',
                  style: GoogleFonts.cabin(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: stock > 0 ? Colors.green : Colors.red,
                  ),
                ),

                SizedBox(height: 5.h),

                Align(
                  alignment: Alignment.centerRight,
                  child: _addButton(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(int index) {
    final product = productVarientList[index];

    if (product.data.isEmpty) {
      return const SizedBox();
    }

    final item = product.data[product.selectPos];
    final int stock = int.tryParse(item.stock.toString()) ?? 0;

    if (stock <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Text(
          'Out of stock',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      );
    }

    if (product.add_qnty == 0) {
      return InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: () {
            //
            // if (restrocart == 1) {
            //   showMyDialog(context);
            // } else {
            //   _increaseProduct(index);
            // }

          if (product.data.length == 1) {
            if (restrocart == 1) {
              showMyDialog(context);
            } else {
              _increaseProduct(index);
            }
          } else {
            _showVariantSheet(index);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: kButtonColor,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: kButtonColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'ADD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: kButtonColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _decreaseProduct(index),
            child: Icon(Icons.remove, color: kButtonColor, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            product.add_qnty.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12.w),
          InkWell(
            onTap: () => _increaseProduct(index),
            child: Icon(Icons.add, color: kButtonColor, size: 22.sp),
          ),
        ],
      ),
    );
  }

  void _increaseProduct(int index) {
    final product = productVarientList[index];
    final item = product.data[product.selectPos];
    final int stock = int.tryParse(item.stock.toString()) ?? 0;

    setState(() {
      if (product.add_qnty >= 10) {
        Fluttertoast.showToast(msg: "You can add maximum 10 only");
        return;
      }

      if (stock > product.add_qnty) {
        product.add_qnty++;

        addOrMinusProduct(
          product.is_id,
          product.is_pres,
          product.isbasket,
          product.product_name,
          item.unit,
          double.parse('${item.price}'),
          int.parse('${item.quantity}'),
          product.add_qnty,
          item.varient_image,
          item.varient_id,
          product.data[0].vendor_id,
          product.data[0].gst,
        );
      }
    });
  }

  void _decreaseProduct(int index) {
    final product = productVarientList[index];
    final item = product.data[product.selectPos];

    setState(() {
      if (product.add_qnty > 0) {
        product.add_qnty--;
      }

      addOrMinusProduct(
        product.is_id,
        product.is_pres,
        product.isbasket,
        product.product_name,
        item.unit,
        double.parse('${item.price}'),
        int.parse('${item.quantity}'),
        product.add_qnty,
        item.varient_image,
        item.varient_id,
        product.data[0].vendor_id,
        product.data[0].gst,
      );
    });
  }

  void _showVariantSheet(int index) {
    final product = productVarientList[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5.h,
                    width: 45.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    product.product_name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: product.data.length,
                    itemBuilder: (context, i) {
                      final entry = product.data[i];

                      return RadioListTile<VarientList>(
                        value: entry,
                        groupValue: product.data[product.selectPos],
                        activeColor: kButtonColor,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${entry.quantity} ${entry.unit}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        secondary: Text(
                          '$currency ${entry.price}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onChanged: (value) {
                          sheetSetState(() {
                            product.selectPos = i;
                          });

                          setState(() {
                            product.selectPos = i;
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (restrocart == 1) {
                          showMyDialog(context);
                        } else {
                          _increaseProduct(index);
                        }
                      },
                      child: Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
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

  Widget _emptyOrLoadingWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 95.h,
                width: 95.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFetchList ? Colors.white : kButtonColor,
                ),
                child: Center(
                  child: isFetchList
                      ? SizedBox(
                    height: 34.h,
                    width: 34.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: kButtonColor,
                    ),
                  )
                      : Icon(
                    Icons.inventory_2_outlined,
                    size: 42.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                isFetchList ? "Fetching Products..." : "No Products Found",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                isFetchList
                    ? "Please wait while we load products for you."
                    : "No product available for this category right now.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomCartBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Visibility(
        visible: isCartCount,
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () async {
              Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
                if (!context.mounted) return;
                setList(productVarientList);
                getCartCount();
              });
            },
            child: Container(
              height: 60.0,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kButtonColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'images/icons/ic_cart wt.png',
                    height: 22.0,
                    width: 22.0,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$cartCount items | $currency $totalAmount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Go to cart',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void addOrMinusProduct(is_id, is_pres, isBasket, product_name, unit, price,
      quantity, itemCount, varient_image, varient_id, vendor,gst) async {
    DatabaseHelper db = DatabaseHelper.instance;
    Future<int?> existing = db.getcount(int.parse('${varient_id}'));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_name = prefs.getString('store_name');

    existing.then((value) {
      final String safeImage =
      (varient_image == null ||
          varient_image.toString().trim().isEmpty)
          ? 'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900'
          : '${imageBaseUrl}${varient_image.toString()}';

      var vae = {
        DatabaseHelper.productName: product_name,
        DatabaseHelper.storeName: store_name,
        DatabaseHelper.vendor_id: vendor,
        DatabaseHelper.price: (price * itemCount),
        DatabaseHelper.unit: unit,
        DatabaseHelper.quantitiy: quantity,
        DatabaseHelper.addQnty: itemCount,

        // ✅ null nahi jayega
        DatabaseHelper.productImage: safeImage,
        DatabaseHelper.gst: gst,

        DatabaseHelper.is_pres: is_pres,
        DatabaseHelper.is_id: is_id,
        DatabaseHelper.isBasket: isBasket,
        DatabaseHelper.addedBasket: 0,
        DatabaseHelper.varientId: int.parse('${varient_id}')
      };

      bool allow = (prefs.getString("allowmultishop").toString() != "1");

      if (value == 0) {
        db.insert(vae);

        if (allow) {
          db.getVendorcount().then((value) {
            if (value != null && value <= 3) {
              getCartCount();
            } else {
              db.delete(int.parse('${varient_id}'));
              showMyDialog2(context);
              setList(productVarientList);
            }
          });
        } else {
          getCartCount();
        }
      } else {
        if (itemCount == 0) {
          db.delete(int.parse('${varient_id}'));
          getCartCount();
        } else {
          db.updateData(vae, int.parse('${varient_id}')).then((vay) {
            getCartCount();
          });
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  List<dynamic> data = [];

  Future<void> hitBannerUrl() async {
    final response = await http.get(Uri.parse(servicebanner));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('data')) {
        setState(() {
          data = responseData['data'];
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
    await http.post(myUri, body: {'category_id': subCatId.toString()});
    try {
      if (response.statusCode == 200) {
        if (response.body.toString().contains('product_id')) {
          print('Response Body(chicken): - ${response.body}');
          var jsonData = jsonDecode(response.body);
          if (jsonData
              .toString()
              .length > 4) {
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
                  "productvarient list is 1 : ${productVarientList[0].data
                      .length}");
              setList(tagObjs);

              // ✅ Product images ko pehle se cache me load kar do
              for (final p in tagObjs) {
                if (p.data.isNotEmpty) {
                  final img = p.data[p.selectPos].varient_image.toString();

                  if (img.trim().isNotEmpty) {
                    precacheImage(
                      CachedNetworkImageProvider(imageBaseUrl + img),
                      context,
                    );
                  }
                }
              }
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
    }
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      message = prefs.getString("message")!;
      curency = prefs.getString("curency")!;
    });
  }

  // ✅ FIXED: backup hamesha poori list (tagObjs) ka banega
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
    productVarientListSearch = List.from(tagObjs);
  }

  void hitServiceBanner(String lat, String lng) async {
    var endpointUrl = vendorUrl;
    Map<String, String> queryParams = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString = Uri(queryParameters: queryParams).query;
    var requestUrl = endpointUrl + '?' + queryString;
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
        });
      }
    }

    var endpointUrl1 = newvendorUrl;
    Map<String, String> queryParams1 = {
      'lat': lat.toString(),
      'lng': lng.toString()
    };
    String queryString1 = Uri(queryParameters: queryParams1).query;
    var requestUrl1 = endpointUrl1 + '?' + queryString1;
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
          hitService(lat.toString(), lng.toString());
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
              builder: (context) =>
              new AppCategory(detail.vendorCategoryId,
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
                        onPressed: () =>
                        {
                          Navigator.pop(context),
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      StoresPage(
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
  static Future<List<ProductWithVarient>> getSuggestions(String query,
      dynamic vendor_id) async {
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

const subCategory = [
  "Milk",
  "Bread & Pav",
  "Butter & Cheese",
  "Paneer & Curd",
  "Eggs",
  "Oats",
  "Flakes & Cereals",
  "Vermicelli",
  "Peanut Butter",
  "Condensed Milk"
];


const productDetails =
'''Amul Taaza Toned Milk (Polypack) is pasteurized with a great nutritional value. It can be consumed directly or can be used for preparing tea, coffee, sweets, khoya, curd, buttermilk, ghee etc.''';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("Assets/Products/${index + 1}.png"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Amul Milk",
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "300gms",
                    maxLines: 1,
                    style: Theme
                        .of(context)
                        .textTheme
                        .displaySmall,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "₹ 100",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      buildAddToCartButton()
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget buildAddToCartButton() {
  return InkWell(
    splashColor: kButtonColor,
    onTap: () {
      Fluttertoast.showToast(
        msg: 'Product Added To Cart',
        backgroundColor: Colors.white,
        textColor: Colors.black,
        gravity: ToastGravity.BOTTOM,
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
          color: kButtonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            width: 1,
            color: kButtonColor,
          )),
      child: Text(
        "Add",
        style: TextStyle(
          fontSize: 15,
          color: kButtonColor,
        ),
      ),
    ),
  );
}
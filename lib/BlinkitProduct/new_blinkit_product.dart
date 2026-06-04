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

          if (!mounted) return;
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
    searchController.dispose();
    _controller.dispose();
    tabController?.dispose();
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
      if (!mounted) return;
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
        if (!mounted) return;
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

      if (!mounted) return;
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

  // ✅ Tap anywhere on the card (ya image par) -> product details kholo,
  //    aur wapas aane par cart quantity refresh kar do.
  Future<void> _openDetails(ProductWithVarient product) async {
    final item =
    product.data.isNotEmpty ? product.data[product.selectPos] : null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          productId: item?.product_id,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
    getCartCount();
    refreshQuantities();
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
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(PageRoutes.viewCart)
                    .then((value) {
                  if (!context.mounted) return;

                  refreshQuantities();
                  getCartCount();
                });
                // Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
                //   if (!mounted) return;
                //   refreshQuantities();
                //   getCartCount();
                // });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isFetchList)
            _buildShimmerList()
          else if (productVarientList.isNotEmpty)
            ListView.builder(
              padding: EdgeInsets.fromLTRB(
                5.w,
                5.h,
                5.w,
                isCartCount ? 85.h : 20.h,
              ),
              itemCount: productVarientList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openDetails(productVarientList[index]),
                  child: _productListCard(index),
                );
              },
            )
          else
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
            onTap: () => _openDetails(product),
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
                    // fit: BoxFit.contain,

                    // FAST LOAD
                    memCacheHeight: 220,
                    memCacheWidth: 220,
                    maxHeightDiskCache: 220,
                    maxWidthDiskCache: 220,

                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,

                    // ✅ shimmer placeholder
                    placeholder: (_, __) {
                      return _Shimmer(
                        child: Container(
                          height: 110.sp,
                          width: 110.sp,
                          color: Colors.white,
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
                    // SizedBox(width: 8.sp,),
                    // if (item != null)
                    //   Container(
                    //     padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.h),
                    //     decoration: BoxDecoration(
                    //       color: Colors.red.shade50,
                    //       borderRadius: BorderRadius.circular(8.r),
                    //       border: Border.all(color: Colors.red.shade200),
                    //     ),
                    //     child: Text(
                    //       'GST Inc. ${item.gst}%',
                    //       style: GoogleFonts.cabin(
                    //         fontSize: 9.sp,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.red,
                    //       ),
                    //     ),
                    //   ),
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

          if (product.data.length == 1) {
            _increaseProduct(index);

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

    // ✅ guard checks setState ke bahar (toast ab return ke saath theek se kaam karega)
    if (product.add_qnty >= 10) {
      Fluttertoast.showToast(msg: "You can add maximum 10 only");
      return;
    }

    if (stock <= product.add_qnty) {
      Fluttertoast.showToast(msg: "Only $stock in stock");
      return;
    }

    setState(() {
      product.add_qnty++;
    });

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
      product.data[0].size,
      product.data[0].color,
    );
  }

  void _decreaseProduct(int index) {
    final product = productVarientList[index];
    final item = product.data[product.selectPos];

    setState(() {
      if (product.add_qnty > 0) {
        product.add_qnty--;
      }
    });

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
      product.data[0].size,
      product.data[0].color,
    );
  }

  void _showVariantSheet(int index) {
    final product = productVarientList[index];


    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // important
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              padding: EdgeInsets.only(
                left: 10.sp,
                right: 10.sp,
                top: 10.sp,
                // keyboard + safe area ko handle karta hai
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.sp,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 40.w), // balance ke liye
                      Column(
                        children: [
                          Container(
                            height: 5.h,
                            width: 45.w,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          // SizedBox(height: 5.h),
                          // Text(
                          //   product.product_name,
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     fontSize: 16.sp,
                          //     fontWeight: FontWeight.w900,
                          //   ),
                          // ),
                          // SizedBox(height: 5.h),
                        ],
                      ),

                      // ✅ Close Button - Right Side
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.only(right: 8.w),
                          child: Icon(
                            Icons.close,
                            size: 22.sp,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.sp,
                  ),
                  // List ab scroll hogi, overflow nahi karegi
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: product.data.length,
                      itemBuilder: (context, i) {
                        final entry = product.data[i];
                        final isSelected = product.selectPos == i;
                        final bool inStock =
                            (int.tryParse(entry.stock.toString()) ?? 0) > 0;

                        return GestureDetector(
                          onTap: () {
                            sheetSetState(() => product.selectPos = i);
                            setState(() => product.selectPos = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(vertical: 6.h),
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: isSelected ? kButtonColor.withOpacity(0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected ? kButtonColor : Colors.grey.shade200,
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? kButtonColor.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 👈 LEFT: Image thumbnail (✅ ab cached - fast load)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Container(
                                        width: 80.w,
                                        height: 80.w,
                                        color: Colors.grey.shade100,
                                        child: entry.varient_image != null && entry.varient_image.toString().isNotEmpty
                                            ? CachedNetworkImage(
                                          imageUrl: imageBaseUrl + entry.varient_image.toString(),
                                          fit: BoxFit.cover,
                                          width: 80.w,
                                          height: 80.w,
                                          memCacheHeight: 160,
                                          memCacheWidth: 160,
                                          errorWidget: (_, __, ___) => Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 22.sp,
                                            color: Colors.grey.shade400,
                                          ),
                                          placeholder: (_, __) => _Shimmer(
                                            child: Container(
                                              width: 80.w,
                                              height: 80.w,
                                              color: Colors.black,

                                            ),
                                          ),
                                        )
                                            : Icon(
                                          Icons.image_outlined,
                                          size: 22.sp,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5.w),

                                    // 👇 CENTER: Column with Size, Color, Price, Stock
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${entry.product_name}',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w900,
                                              color:  Colors.black,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'Size : ${entry.size}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(width: 5.w),
                                              Text(
                                                'Color :  ${entry.color}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5.h),
                                          Row(
                                            children: [
                                              Text(
                                                '$currency ${entry.strick_price}',
                                                style: GoogleFonts.cabin(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                              SizedBox(width: 5.w),
                                              Text(
                                                '$currency${entry.price}',
                                                style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w900,
                                                    color: kButtonColor
                                                ),
                                              ),
                                            ],
                                          ),


                                          SizedBox(height: 4.h),
                                          Text(
                                            inStock ? 'Available in Stock: ${entry.stock}' : 'Out of Stock',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: inStock ? Colors.green : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.w),

                                    // 👉 RIGHT: Radio button
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 22.w,
                                      height: 22.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? kButtonColor : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                        color: isSelected ? kButtonColor : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

  // ✅ SHIMMER LOADING LIST (loading ke time product card jaisa skeleton dikhega)
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 20.h),
      itemCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerBox({double? w, double? h, double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerCard() {
    return _Shimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(5.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(w: 110.sp, h: 110.sp, radius: 16),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(w: double.infinity, h: 14.h),
                    SizedBox(height: 8.h),
                    _shimmerBox(w: 150.w, h: 14.h),
                    SizedBox(height: 14.h),
                    _shimmerBox(w: 90.w, h: 16.h),
                    SizedBox(height: 12.h),
                    _shimmerBox(w: 120.w, h: 12.h),
                    SizedBox(height: 16.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _shimmerBox(w: 90.w, h: 32.h, radius: 24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            onTap: () {
              Navigator.of(context, rootNavigator: true)
                  .pushNamed(PageRoutes.viewCart)
                  .then((value) {
                if (!context.mounted) return;

                refreshQuantities();
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
      quantity, itemCount, varient_image, varient_id, vendor,gst,selectedSize,selectedColor) async {
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

        DatabaseHelper.size: selectedSize,   // null bhi ho sakta hai
        DatabaseHelper.color: selectedColor, // null bhi ho sakta hai

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
              refreshQuantities();
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

            if (!mounted) return;
            setState(() {
              productVarientList = tagObjs;
              productVarientListSearch = List.from(tagObjs);
            });

            // cart quantity sync
            setList(tagObjs);

            // ✅ Product images ko pehle se cache me load kar do (setState ke bahar)
            for (final p in tagObjs) {
              if (p.data.isNotEmpty) {
                final img = p.data[p.selectPos].varient_image.toString();

                if (img.trim().isNotEmpty && mounted) {
                  precacheImage(
                    CachedNetworkImageProvider(imageBaseUrl + img),
                    context,
                  );
                }
              }
            }
          }
          if (!mounted) return;
          setState(() {
            isFetchList = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            productVarientList.clear();
            productVarientListSearch.clear();
            isFetchList = false;
          });
        }
      }
    } on Exception catch (_) {
      Timer(Duration(seconds: 5), () {
        if (mounted) hitTabSeriveList(subCatId);
      });
    }
  }

  hitViewCart(BuildContext context) {
    if (isCartCount) {
      Navigator.pushNamed(context, PageRoutes.viewCart).then((value) {
        refreshQuantities();
        getCartCount();
      });
    } else {
    }
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      message = prefs.getString("message") ?? "";
      curency = prefs.getString("curency") ?? "";
    });
  }

  // ✅ Sirf cart quantity refresh karta hai – FULL backup list (productVarientListSearch)
  //    par chalta hai, isliye search active hone par bhi backup clobber nahi hota.
  void refreshQuantities() {
    final list = productVarientListSearch.isNotEmpty
        ? productVarientListSearch
        : productVarientList;

    DatabaseHelper db = DatabaseHelper.instance;

    for (int i = 0; i < list.length; i++) {
      if (list[i].data.isEmpty) continue;

      final int varientId = int.tryParse(
          '${list[i].data[list[i].selectPos].varient_id}') ??
          0;

      db.getVarientCount(varientId).then((value) {
        if (!mounted) return;
        setState(() {
          list[i].add_qnty = value ?? 0;
        });
      });
    }
  }

  // initial population ke liye: backup set + quantity sync
  void setList(List<ProductWithVarient> tagObjs) {
    DatabaseHelper db = DatabaseHelper.instance;
    for (int i = 0; i < tagObjs.length; i++) {
      if (tagObjs[i].data.length > 0) {
        print("PRES: " + tagObjs[i].is_pres.toString());
        db
            .getVarientCount(int.parse(
            '${tagObjs[i].data[tagObjs[i].selectPos].varient_id}'))
            .then((value) {
          print('print val $value');
          if (!mounted) return;
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

            if (!mounted) return;
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
            if (!mounted) return;
            setState(() {
              newnearStores.clear();
              newnearStores = tagObjs;
            });
          }
        }
      } on Exception catch (_) {
        // ✅ FIX: pehle yahan undefined `hitService(...)` call thi (compile/runtime bug).
        //    Ab safe retry – same method dobara try karega.
        Timer(Duration(seconds: 5), () {
          if (mounted) hitServiceBanner(lat, lng);
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

// ✅ Reusable shimmer effect (koi extra package nahi chahiye)
class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double slide = (_ctrl.value * 2) - 1; // -1 .. 1
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE7E9EC),
                Color(0xFFF4F6F8),
                Color(0xFFE7E9EC),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlideGradient(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double slide;

  const _SlideGradient(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slide, 0.0, 0.0);
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
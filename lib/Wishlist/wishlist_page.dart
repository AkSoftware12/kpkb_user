import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../BlinkitProduct/product_details_screen.dart';
import '../Pages/oneViewCart.dart';
import '../Routes/routes.dart';
import '../Themes/colors.dart';
import '../baseurlp/baseurl.dart';
import '../bean/cartitem.dart';
import '../bean/productlistvarient.dart';
import '../bean/resturantbean/restaurantcartitem.dart';
import '../databasehelper/dbhelper.dart';

class WishListProductsScreen extends StatefulWidget {
  final dynamic pageTitle;
  final dynamic vendor_id;
  final dynamic category_name;
  final dynamic category_id;
  final dynamic distance;
  final int index;
  final dynamic subcat_id;

  const WishListProductsScreen(
      this.pageTitle,
      this.vendor_id,
      this.category_name,
      this.category_id,
      this.distance,
      this.index,
      this.subcat_id, {
        super.key,
      });

  @override
  State<WishListProductsScreen> createState() => _WishListProductsScreenState();
}

class _WishListProductsScreenState extends State<WishListProductsScreen> {
  List<ProductWithVarient> productVarientList = [];
  List<ProductWithVarient> productVarientListSearch = [];

  bool isFetchList = false;
  bool isCartCount = false;

  int cartCount = 0;
  int restrocart = 0;

  dynamic currency = '';
  dynamic totalAmount = '0.00';

  final String defaultImage =
      'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900';

  @override
  void initState() {
    super.initState();
    ClearCart();
    getCartCount();
    getCartItem2();
    hitWishlistList();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String getSafeImage(dynamic image) {
    if (image == null || image.toString().trim().isEmpty) {
      return defaultImage;
    }

    final img = image.toString().trim();

    if (img.startsWith('http')) {
      return img;
    }

    return imageBaseUrl + img;
  }

  String getProductImage(ProductWithVarient product) {
    if (product.data.isNotEmpty) {
      final img = product.data[product.selectPos].varient_image;
      if (img != null && img.toString().trim().isNotEmpty) {
        return getSafeImage(img);
      }
    }

    return getSafeImage(product.products_image);
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> hitWishlistList() async {
    safeSetState(() {
      isFetchList = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      currency = prefs.getString('curency') ?? '₹';

      final userId = prefs.getInt("user_id")?.toString() ??
          prefs.getString("user_id") ??
          "0";

      final Uri myUri = Uri.parse("${baseUrl}wishlist");

      final response = await http.post(
        myUri,
        body: {
          "user_id": userId,
        },
      );

      print("Wishlist Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"].toString() == "1" &&
            jsonData["data"] != null &&
            jsonData["data"] is List) {
          final List list = jsonData["data"];

          final List<ProductWithVarient> products = list
              .map((e) => ProductWithVarient.fromJson(e))
              .toList();

          safeSetState(() {
            productVarientList.clear();
            productVarientListSearch.clear();

            productVarientList = products;
            productVarientListSearch = List.from(products);
            isFetchList = false;
          });

          setList(productVarientList);
        } else {
          safeSetState(() {
            productVarientList.clear();
            productVarientListSearch.clear();
            isFetchList = false;
          });
        }
      } else {
        safeSetState(() {
          isFetchList = false;
        });
      }
    } catch (e) {
      print("Wishlist Error: $e");
      safeSetState(() {
        isFetchList = false;
      });
    }
  }

  Future<void> removeFromWishlist(int productId, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("user_id")?.toString() ??
          prefs.getString("user_id") ??
          "0";

      final Uri myUri = Uri.parse("${baseUrl}remove-from-wishlist");

      final response = await http.post(
        myUri,
        body: {
          "user_id": userId,
          "product_id": productId.toString(),
        },
      );

      print("Remove Wishlist Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"].toString() == "1") {
          safeSetState(() {
            productVarientList.removeAt(index);
            productVarientListSearch = List.from(productVarientList);
          });

          Fluttertoast.showToast(
            msg: "Product removed from wishlist",
          );
        } else {
          Fluttertoast.showToast(
            msg: jsonData["message"]?.toString() ?? "Something went wrong",
          );
        }
      }
    } catch (e) {
      print("Remove Wishlist Error: $e");
      Fluttertoast.showToast(msg: "Unable to remove product");
    }
  }

  void ClearCart() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.deleteAllRestProdcut();
    getCartItem2();


    safeSetState(() {
      restrocart = 0;
    });
  }

  void getCartItem2() async {
    DatabaseHelper db = DatabaseHelper.instance;

    db.getResturantOrderList().then((value) {
      List<RestaurantCartItem> tagObjs =
      value.map((tagJson) => RestaurantCartItem.fromJson(tagJson)).toList();

      if (tagObjs.isNotEmpty) {
        safeSetState(() {
          restrocart = 1;
        });
      }
    });
  }

  void getCartCount() {
    DatabaseHelper db = DatabaseHelper.instance;

    db.queryRowCount().then((value) {
      safeSetState(() {
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

        double gstAmount =
        gstPercent > 0 ? price * gstPercent / (100 + gstPercent) : 0.0;

        double gstOffAmount = gstAmount * 0.5;

        total += price - gstOffAmount;
      }

      safeSetState(() {
        totalAmount = total.toStringAsFixed(2);
      });
    });
  }

  void setList(List<ProductWithVarient> tagObjs) {
    for (int i = 0; i < tagObjs.length; i++) {
      if (tagObjs[i].data.isNotEmpty) {
        DatabaseHelper db = DatabaseHelper.instance;

        db
            .getVarientCount(
          int.parse('${tagObjs[i].data[tagObjs[i].selectPos].varient_id}'),
        )
            .then((value) {
          safeSetState(() {
            if (value == null) {
              tagObjs[i].add_qnty = 0;
            } else {
              tagObjs[i].add_qnty = value;
              isCartCount = true;
            }
          });
        });
      }
    }

    productVarientListSearch = List.from(productVarientList);
  }

  void showMyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Grocery orders are to be placed separately.\nPlease clear/empty cart to add item.',
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
      },
    );
  }

  void addOrMinusProduct(
      is_id,
      is_pres,
      isBasket,
      product_name,
      unit,
      price,
      quantity,
      itemCount,
      varient_image,
      varient_id,
      vendor,
      gst,
      weight,
      ) async {
    DatabaseHelper db = DatabaseHelper.instance;

    Future<int?> existing = db.getcount(int.parse('$varient_id'));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storeName = prefs.getString('store_name');

    existing.then((value) {
      final String safeImage = getSafeImage(varient_image);

      var data = {
        DatabaseHelper.productName: product_name,
        DatabaseHelper.storeName: storeName,
        DatabaseHelper.vendor_id: vendor,
        DatabaseHelper.price: (toDouble(price) * toInt(itemCount)),
        DatabaseHelper.unit: unit,
        DatabaseHelper.quantitiy: quantity,
        DatabaseHelper.addQnty: itemCount,
        DatabaseHelper.productImage: safeImage,
        DatabaseHelper.gst: gst,
        DatabaseHelper.weight: weight,
        DatabaseHelper.is_pres: is_pres,
        DatabaseHelper.is_id: is_id,
        DatabaseHelper.isBasket: isBasket,
        DatabaseHelper.addedBasket: 0,
        DatabaseHelper.varientId: int.parse('$varient_id'),
      };

      bool allow = (prefs.getString("allowmultishop").toString() != "1");

      if (value == 0) {
        db.insert(data);

        if (allow) {
          db.getVendorcount().then((vendorCount) {
            if (vendorCount != null && vendorCount <= 3) {
              getCartCount();
            } else {
              db.delete(int.parse('$varient_id'));
              showMyDialog2(context);
              setList(productVarientList);
            }
          });
        } else {
          getCartCount();
        }
      } else {
        if (itemCount == 0) {
          db.delete(int.parse('$varient_id'));
          getCartCount();
        } else {
          db.updateData(data, int.parse('$varient_id')).then((vay) {
            getCartCount();
          });
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  void addProduct(int index) {
    final product = productVarientList[index];

    if (product.data.isEmpty) return;

    final variant = product.data[product.selectPos];
    final stock = toInt(variant.stock);

    if (stock > product.add_qnty) {
      safeSetState(() {
        product.add_qnty++;
      });

      addOrMinusProduct(
        product.is_id,
        product.is_pres,
        product.isbasket,
        product.product_name,
        variant.unit,
        toDouble(variant.price),
        toInt(variant.quantity),
        product.add_qnty,
        variant.varient_image,
        variant.varient_id,
        variant.vendor_id,
        variant.gst,
        variant.weight,
      );
    } else {
      Fluttertoast.showToast(msg: "No more stock available");
    }
  }

  void minusProduct(int index) {
    final product = productVarientList[index];

    if (product.data.isEmpty) return;

    final variant = product.data[product.selectPos];

    safeSetState(() {
      if (product.add_qnty > 0) {
        product.add_qnty--;
      }
    });

    addOrMinusProduct(
      product.is_id,
      product.is_pres,
      product.isbasket,
      product.product_name,
      variant.unit,
      toDouble(variant.price),
      toInt(variant.quantity),
      product.add_qnty,
      variant.varient_image,
      variant.varient_id,
      variant.vendor_id,
      variant.gst,
      variant.weight,
    );
  }


  // ============================================================
  // CARD DESIGN — full-width horizontal style (same as screenshot)
  // Only the UI/layout has been changed. All logic stays the same.
  // ============================================================
  Widget productCard(int index) {
    final product = productVarientList[index];

    if (product.data.isEmpty) {
      return const SizedBox();
    }

    final variant = product.data[product.selectPos];

    final double price = toDouble(variant.price);
    final double strikePrice = toDouble(variant.strick_price);
    final int stock = toInt(variant.stock);
    final int weight = int.tryParse(variant.weight?.toString() ?? "0") ?? 0;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      padding:  EdgeInsets.all(5.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT — IMAGE with heart + veg/non-veg icon
              Stack(
                children: [

                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                            productId: product.product_id,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CachedNetworkImage(
                        imageUrl:getProductImage(product),


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
                  ),



                  /// HEART (remove from wishlist)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: InkWell(
                      onTap: () {
                        removeFromWishlist(
                          toInt(product.product_id),
                          index,
                        );
                      },
                      child: Container(
                        height: 25.sp,
                        width: 25
                            .sp,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  /// VEG / NON-VEG icon
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      height: 22,
                      width: 22,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
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

              const SizedBox(width: 5),

              /// RIGHT — DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// PRODUCT NAME
                    Text(
                      product.product_name.toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cabin(
                        textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 2.sp),

                    /// PRICE ROW
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (strikePrice > price)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '$currency ${strikePrice.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cabin(
                                textStyle: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        Flexible(
                          child: Text(
                            '$currency ${price.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cabin(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),


                        // SizedBox(width: 6.w),
                        //
                        // /// GST BADGE
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //     horizontal: 3.w,
                        //     vertical: 0.h,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.red.shade50,
                        //     borderRadius: BorderRadius.circular(20),
                        //     border: Border.all(
                        //       color: Colors.red.shade200,
                        //     ),
                        //   ),
                        //   child: Text(
                        //     'GST Inc. ${variant.gst}%',
                        //     style: GoogleFonts.cabin(
                        //       textStyle: TextStyle(
                        //         color: Colors.red,
                        //         fontSize: 9.sp,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),

                    SizedBox(height: 8.sp),

                    /// STOCK
                    Text(
                      'Available in Stock ($stock)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cabin(
                        textStyle: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    SizedBox(height: 3.sp),

                    /// ADD / QTY / OUT OF STOCK
                    Align(
                      alignment: Alignment.centerRight,
                      child: stock > 0
                          ? product.add_qnty == 0
                          ? InkWell(
                        onTap: () {
                          if (weight >= 21000) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 8,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Icon circle
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child:  Icon(
                                          Icons.store_mall_directory_rounded,
                                          color:kButtonColor,
                                          size: 48,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Title
                                      const Text(
                                        'Store Pickup Only',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Message
                                      const Text(
                                        'This product cannot be ordered online because its weight exceeds the allowed limit.\n\nYou can only collect this product directly from the Store.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // OK button (full width)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kButtonColor,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          addProduct(index);

                        },
                        child: Container(
                          height: 30.sp,
                          width: 80.sp,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kButtonColor,
                            borderRadius:
                            BorderRadius.circular(30),
                          ),
                          child: Text(
                            'ADD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                          : Container(
                        height: 30.sp,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        decoration: BoxDecoration(
                          color: kButtonColor,
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => minusProduct(index),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              product.add_qnty.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () => addProduct(index),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      )
                          : Container(
                        height: 30.sp,
                        width: 120.sp,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Out of stock',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bottomCartBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Visibility(
        visible: isCartCount,
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: (){
              Navigator.of(context, rootNavigator: true)
                  .pushNamed(PageRoutes.viewCart)
                  .then((value) {
                if (!context.mounted) return;

                setList(productVarientList);
                getCartCount();
              });
            },
            child: Container(
              height: 50.sp,
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
                children: [
                  Image.asset(
                    'images/icons/ic_cart wt.png',
                    height: 22,
                    width: 22,
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

  Widget emptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 22.w,
            vertical: 28.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// ICON / LOADER
              Container(
                height: 90.h,
                width: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isFetchList
                        ? [
                      kButtonColor,
                      Colors.deepOrange.shade50,
                    ]
                        : [
                      Colors.red.shade50,
                      Colors.pink.shade50,
                    ],
                  ),
                ),
                child: Center(
                  child: isFetchList
                      ? SizedBox(
                    height: 32.h,
                    width: 32.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: kButtonColor,
                    ),
                  )
                      : Icon(
                    Icons.favorite_border_rounded,
                    size: 42.sp,
                    color: Colors.red.shade400,
                  ),
                ),
              ),

              SizedBox(height: 22.h),

              /// TITLE
              Text(
                isFetchList
                    ? "Fetching Wishlist..."
                    : "Your Wishlist is Empty",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 10.h),

              /// SUBTITLE
              Text(
                isFetchList
                    ? "Please wait while we load your favourite products."
                    : "Looks like you haven't added any products to your wishlist yet.",
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Wishlist",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Your saved products",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: (){
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(PageRoutes.viewCart)
                    .then((value) {
                  if (!context.mounted) return;

                  setList(productVarientList);
                  getCartCount();
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kButtonColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (isCartCount)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            "$cartCount",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          productVarientList.isNotEmpty && !isFetchList
              ? ListView.builder(
            padding: EdgeInsets.fromLTRB(
              0,
              4,
              0,
              isCartCount ? 110.sp : 50.sp,
            ),
            itemCount: productVarientList.length,
            itemBuilder: (context, index) {
              return productCard(index);
            },
          )
              : emptyView(),
          bottomCartBar(),
        ],
      ),
    );
  }
}

void showMyDialog2(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: const Text('Maximum Vendor Limit Reached'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}
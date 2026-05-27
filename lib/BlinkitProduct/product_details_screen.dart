import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kpUser/Themes/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../baseurlp/baseurl.dart';
import '../databasehelper/dbhelper.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int currentIndex = 0;

  bool isLoading = true;
  String? errorMessage;

  dynamic currency = '₹';

  /// API data
  Map<String, dynamic>? product;
  Map<String, dynamic>? variant; // pehla variant
  List<String> images = [];

  /// cart quantity (ProductsScreen ke add_qnty jaisa)
  int addQnty = 0;

  /// grocery vs restaurant cart check (ProductsScreen jaisa)
  int restrocart = 0;

  @override
  void initState() {
    super.initState();
    getCartItem2();
    fetchProductDetails();
  }

  /// relative path ko full url me convert karta hai
  String _fullUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return p;
    if (p.startsWith("http")) return p;
    return "$imageBaseUrl$p";
  }

  /// comma-separated image string ko todta hai aur full urls list me add karta hai.
  void _addImagesFromCommaString(String raw, List<String> target) {
    if (raw.trim().isEmpty) return;

    final parts = raw
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return;

    String folder = "";
    final first = parts.first;
    final slash = first.lastIndexOf("/");
    if (slash != -1) {
      folder = first.substring(0, slash + 1);
    }

    for (final part in parts) {
      final path = part.contains("/") ? part : "$folder$part";
      target.add(_fullUrl(path));
    }
  }

  Future<void> fetchProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      "$appproductdetailOnly${widget.productId}",
    );

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["status"].toString() == "1" && body["data"] != null) {
          final data = body["data"] as Map<String, dynamic>;

          // ---------- VARIANT (pehla) ----------
          // NOTE: API variants array "data" key me aata hai, "variants" me nahi
          Map<String, dynamic>? firstVariant;
          if (data["data"] is List && (data["data"] as List).isNotEmpty) {
            firstVariant =
            Map<String, dynamic>.from((data["data"] as List).first);
          }

          // ---------- IMAGES ----------
          final List<String> imgs = [];
          // variant ke "product_image" me comma-separated multiple images aati hain
          if (firstVariant != null && firstVariant["product_image"] != null) {
            _addImagesFromCommaString(
                firstVariant["product_image"].toString(), imgs);
          }
          // fallback: product level "products_image"
          if (imgs.isEmpty && data["products_image"] != null) {
            _addImagesFromCommaString(
                data["products_image"].toString(), imgs);
          }
          // fallback: variant ka single varient_image
          if (imgs.isEmpty &&
              firstVariant != null &&
              firstVariant["varient_image"] != null) {
            _addImagesFromCommaString(
                firstVariant["varient_image"].toString(), imgs);
          }

          setState(() {
            product = data;
            variant = firstVariant;
            images = imgs;
            isLoading = false;
          });

          // current cart quantity nikaalo (ProductsScreen ke setList jaisa)
          _loadCurrentCartQty();
        } else {
          setState(() {
            errorMessage = body["message"]?.toString() ?? "Product not found";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong: $e";
        isLoading = false;
      });
    }
  }

  /// DB se is variant ka current qty load karo
  void _loadCurrentCartQty() {
    if (variant == null) return;
    final int varientId =
        int.tryParse(variant!["varient_id"].toString()) ?? 0;
    if (varientId == 0) return;

    DatabaseHelper db = DatabaseHelper.instance;
    db.getVarientCount(varientId).then((value) {
      setState(() {
        addQnty = value ?? 0;
      });
    });
  }

  /// restaurant cart check (ProductsScreen jaisa)
  void getCartItem2() {
    DatabaseHelper db = DatabaseHelper.instance;
    db.getResturantOrderList().then((value) {
      if (value.isNotEmpty) {
        setState(() {
          restrocart = 1;
        });
      }
    });
  }

  /// ---------- value getters ----------

  String get _name => product?["product_name"]?.toString() ?? "-";

  String get _gst => (variant?["gst"] ?? product?["gst"])?.toString() ?? "0";

  String get _barcode =>
      (variant?["barcode"] ?? product?["barcode"])?.toString() ?? "-";

  String get _model =>
      (variant?["model_num"] ?? product?["model_num"])?.toString() ?? "-";

  String get _supplier =>
      (variant?["supplier"] ?? product?["supplier"])?.toString() ?? "-";

  String get _sku =>
      (variant?["sku_nomenclature"] ?? product?["sku_nomenclature"])
          ?.toString() ??
          "-";

  double get _price =>
      double.tryParse(variant?["price"]?.toString() ?? "") ??
          double.tryParse(product?["mrp"]?.toString() ?? "0") ??
          0.0;

  double get _strikePrice =>
      double.tryParse(variant?["strick_price"]?.toString() ?? "") ??
          double.tryParse(product?["mrp"]?.toString() ?? "0") ??
          0.0;

  int get _stock => int.tryParse(variant?["stock"]?.toString() ?? "0") ?? 0;

  // ============================================================
  // ADD / MINUS  (ProductsScreen ka exact same flow)
  // ============================================================

  void _increaseProduct() {
    if (variant == null) return;

    if (restrocart == 1) {
      _showMyDialog();
      return;
    }

    setState(() {
      if (addQnty >= 10) {
        Fluttertoast.showToast(msg: "You can add maximum 10 only");
        return;
      }

      if (_stock > addQnty) {
        addQnty++;
        _addOrMinusProduct();
      } else {
        Fluttertoast.showToast(msg: "No more stock available");
      }
    });
  }

  void _decreaseProduct() {
    if (variant == null) return;

    setState(() {
      if (addQnty > 0) {
        addQnty--;
      }
      _addOrMinusProduct();
    });
  }

  /// ProductsScreen ka addOrMinusProduct waise hi, par variant map se values
  void _addOrMinusProduct() async {
    if (variant == null || product == null) return;

    DatabaseHelper db = DatabaseHelper.instance;

    final int varientId =
        int.tryParse(variant!["varient_id"].toString()) ?? 0;
    if (varientId == 0) return;

    final Future<int?> existing = db.getcount(varientId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_name = prefs.getString('store_name');

    final double price =
        double.tryParse(variant!["price"].toString()) ?? 0.0;
    final int quantity =
        int.tryParse(variant!["quantity"].toString()) ?? 1;
    final String unit = variant!["unit"]?.toString() ?? "pcs";
    final dynamic vendor = variant!["vendor_id"];
    final dynamic gst = variant!["gst"] ?? product!["gst"];
    final String varientImage = variant!["varient_image"]?.toString() ?? "";

    final dynamic isId = product!["is_id"] ?? 0;
    final dynamic isPres = product!["is_pres"] ?? 0;
    final dynamic isBasket = product!["isbasket"] ?? 0;

    existing.then((value) {
      final String safeImage = varientImage.trim().isEmpty
          ? 'https://img.freepik.com/premium-vector/default-image-icon-vector-missing-picture-page-website-design-mobile-app-no-photo-available_87543-11093.jpg?w=900'
          : '$imageBaseUrl$varientImage';

      var vae = {
        DatabaseHelper.productName: _name,
        DatabaseHelper.storeName: store_name,
        DatabaseHelper.vendor_id: vendor,
        DatabaseHelper.price: (price * addQnty),
        DatabaseHelper.unit: unit,
        DatabaseHelper.quantitiy: quantity,
        DatabaseHelper.addQnty: addQnty,
        DatabaseHelper.productImage: safeImage,
        DatabaseHelper.gst: gst,
        DatabaseHelper.is_pres: isPres,
        DatabaseHelper.is_id: isId,
        DatabaseHelper.isBasket: isBasket,
        DatabaseHelper.addedBasket: 0,
        DatabaseHelper.varientId: varientId,
      };

      bool allow = (prefs.getString("allowmultishop").toString() != "1");

      if (value == 0) {
        db.insert(vae);

        if (allow) {
          db.getVendorcount().then((vc) {
            if (vc != null && vc <= 3) {
              // ok
            } else {
              db.delete(varientId);
              _showMyDialog2();
              setState(() {
                addQnty = 0;
              });
            }
          });
        }
      } else {
        if (addQnty == 0) {
          db.delete(varientId);
        } else {
          db.updateData(vae, varientId);
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  void _showMyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Grocery orders are to be placed separately.\nPlease clear/empty cart to add item. ',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Clear Cart'),
              onPressed: () {
                DatabaseHelper db = DatabaseHelper.instance;
                db.deleteAllRestProdcut();
                getCartItem2();
                setState(() {
                  restrocart = 0;
                });
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

  void _showMyDialog2() {
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

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Product Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: isLoading || product == null ? null : _bottomBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProductDetails,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE SLIDER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    images.isEmpty
                        ? _placeholderImage()
                        : CarouselSlider.builder(
                      itemCount: images.length,
                      itemBuilder: (_, index, __) {
                        return Container(
                          margin:
                          const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            // color: const Color(0xfff7f8fc),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              images[index],
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 280,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  _placeholderImage(),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 280,
                        viewportFraction: 1,
                        autoPlay: images.length > 1,
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                      ),
                    ),

                    /// GST badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: kButtonColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "GST INC. $_gst% ",
                          style:  TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _strikePrice > _price
                              ? '${(((_strikePrice - _price) / _strikePrice) * 100).toStringAsFixed(0)}% OFF'
                              : 'NEW',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 14),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: currentIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? kButtonColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // const SizedBox(height: 16),

          /// NAME + PRICE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_strikePrice > _price) ...[
                      Text(
                        "$currency${_strikePrice.toStringAsFixed(2)}",
                        style:  TextStyle(
                          color: Colors.grey,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      "$currency${_price.toStringAsFixed(2)}",
                      style:  TextStyle(
                        color: Colors.black,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: (_stock > 0 ? Colors.green : Colors.red)
                            .withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _stock > 0 ? "In Stock ($_stock)" : "Out of stock",
                        style: TextStyle(
                          color: _stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// DESCRIPTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _sku,
                  style:  TextStyle(
                    height: 1.6,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _infoCard(
            title: "Price Details",
            icon: Icons.currency_rupee_rounded,
            children: [
              _row("Price", "$currency${_price.toStringAsFixed(2)}"),
              _row("GST INC.", "$_gst%"),
            ],
          ),

          const SizedBox(height: 14),

          _infoCard(
            title: "Product Information",
            icon: Icons.info_outline_rounded,
            children: [
              _row("Model No", _model),
              _row("Barcode", _barcode),
              _row("Supplier", _supplier),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(
        Icons.photo,
        size: 60,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kButtonColor.withOpacity(.12),
                child: Icon(icon, color: kButtonColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  /// BOTTOM BAR — ProductsScreen wala ADD / stepper pattern
  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            /// price summary left side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$currency${(_price * (addQnty == 0 ? 1 : addQnty)).toStringAsFixed(2)}",
                    style:  TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "GST Inc. $_gst%",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            /// ADD / stepper right side
            _buildAddArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddArea() {
    if (_stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          "Out of stock",
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (addQnty == 0) {
      return ElevatedButton(
        onPressed: _increaseProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          "ADD",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color:kButtonColor, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _decreaseProduct,
            child:  Icon(Icons.remove, color:kButtonColor, size: 24),
          ),
          const SizedBox(width: 18),
          Text(
            addQnty.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: _increaseProduct,
            child:  Icon(Icons.add, color: kButtonColor, size: 24),
          ),
        ],
      ),
    );
  }
}
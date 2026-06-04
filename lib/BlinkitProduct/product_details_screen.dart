import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kpUser/Themes/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Routes/routes.dart';
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

  /// API data — same as original
  Map<String, dynamic>? product;

  /// All variants list — for bottom sheet
  List<Map<String, dynamic>> allVariants = [];

  /// Currently selected variant index (default 0 = pehla variant)
  int selectPos = 0;

  /// Shortcut: currently selected variant
  Map<String, dynamic>? get variant =>
      allVariants.isNotEmpty ? allVariants[selectPos] : null;

  List<String> images = [];

  /// cart quantity — same as original ProductsScreen add_qnty
  int add_qnty = 0;

  /// grocery vs restaurant cart check — same as original
  int restrocart = 0;

  @override
  void initState() {
    super.initState();
    getCartItem2();
    fetchProductDetails();
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS — original se same
  // ─────────────────────────────────────────────────────────

  String _fullUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return p;
    if (p.startsWith("http")) return p;
    return "$imageBaseUrl$p";
  }

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
    if (slash != -1) folder = first.substring(0, slash + 1);
    for (final part in parts) {
      final path = part.contains("/") ? part : "$folder$part";
      target.add(_fullUrl(path));
    }
  }

  // ─────────────────────────────────────────────────────────
  // FETCH — original logic same, bas allVariants bhi fill karo
  // ─────────────────────────────────────────────────────────

  Future<void> fetchProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse("$appproductdetailOnly${widget.productId}");

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["status"].toString() == "1" && body["data"] != null) {
          final data = body["data"] as Map<String, dynamic>;

          // Saare variants collect karo (original mein sirf pehla tha)
          List<Map<String, dynamic>> variants = [];
          if (data["data"] is List) {
            for (final v in (data["data"] as List)) {
              variants.add(Map<String, dynamic>.from(v));
            }
          }

          // Images — original logic same, pehle variant ke liye
          final List<String> imgs = [];
          if (variants.isNotEmpty && variants[0]["product_image"] != null) {
            _addImagesFromCommaString(
                variants[0]["product_image"].toString(), imgs);
          }
          if (imgs.isEmpty && data["products_image"] != null) {
            _addImagesFromCommaString(
                data["products_image"].toString(), imgs);
          }
          if (imgs.isEmpty &&
              variants.isNotEmpty &&
              variants[0]["varient_image"] != null) {
            _addImagesFromCommaString(
                variants[0]["varient_image"].toString(), imgs);
          }

          setState(() {
            product = data;
            allVariants = variants;
            selectPos = 0;
            images = imgs;
            isLoading = false;
          });

          _loadCurrentCartQty();
        } else {
          setState(() {
            errorMessage =
                body["message"]?.toString() ?? "Product not found";
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

  // ─────────────────────────────────────────────────────────
  // CART HELPERS — original se bilkul same
  // ─────────────────────────────────────────────────────────

  /// Original _loadCurrentCartQty — same logic
  void _loadCurrentCartQty() {
    if (variant == null) return;
    final int varientId =
        int.tryParse(variant!["varient_id"].toString()) ?? 0;
    if (varientId == 0) return;

    DatabaseHelper db = DatabaseHelper.instance;
    db.getVarientCount(varientId).then((value) {
      setState(() {
        add_qnty = value ?? 0;
      });
    });
  }

  /// Original getCartItem2 — same
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

  // ─────────────────────────────────────────────────────────
  // VALUE GETTERS — original se same
  // ─────────────────────────────────────────────────────────

  String get _name =>
      product?["product_name"]?.toString() ?? "-";

  String get _gst =>
      (variant?["gst"] ?? product?["gst"])?.toString() ?? "0";

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

  String get _size => variant?["size"]?.toString() ?? "";

  String get _color => variant?["color"]?.toString() ?? "";

  double get _price =>
      double.tryParse(variant?["price"]?.toString() ?? "") ??
          double.tryParse(product?["mrp"]?.toString() ?? "0") ??
          0.0;

  double get _strikePrice =>
      double.tryParse(variant?["strick_price"]?.toString() ?? "") ??
          double.tryParse(product?["mrp"]?.toString() ?? "0") ??
          0.0;

  int get _stock =>
      int.tryParse(variant?["stock"]?.toString() ?? "0") ?? 0;

  // ─────────────────────────────────────────────────────────
  // ADD / MINUS — original ProductsScreen ka exact same flow
  // ─────────────────────────────────────────────────────────

  void _increaseProduct() {
    if (variant == null) return;

    if (restrocart == 1) {
      _showMyDialog();
      return;
    }

    setState(() {
      if (add_qnty >= 10) {
        Fluttertoast.showToast(msg: "You can add maximum 10 only");
        return;
      }

      if (_stock > add_qnty) {
        add_qnty++;
        _addOrMinusProduct();
      } else {
        Fluttertoast.showToast(msg: "No more stock available");
      }
    });
  }

  void _decreaseProduct() {
    if (variant == null) return;

    setState(() {
      if (add_qnty > 0) {
        add_qnty--;
      }
      _addOrMinusProduct();
    });
  }

  /// Original addOrMinusProduct — same logic, variant map se values
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
    final dynamic size = variant!["size"] ?? '';
    final dynamic color = variant!["color"] ?? '';
    final String varientImage =
        variant!["varient_image"]?.toString() ?? "";

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
        DatabaseHelper.price: (price * add_qnty),
        DatabaseHelper.unit: unit,
        DatabaseHelper.quantitiy: quantity,
        DatabaseHelper.addQnty: add_qnty,
        DatabaseHelper.productImage: safeImage,
        DatabaseHelper.gst: gst,
        DatabaseHelper.size: size,
        DatabaseHelper.color: color,
        DatabaseHelper.is_pres: isPres,
        DatabaseHelper.is_id: isId,
        DatabaseHelper.isBasket: isBasket,
        DatabaseHelper.addedBasket: 0,
        DatabaseHelper.varientId: varientId,
      };

      bool allow =
      (prefs.getString("allowmultishop").toString() != "1");

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
                add_qnty = 0;
              });
            }
          });
        }
      } else {
        if (add_qnty == 0) {
          db.delete(varientId);
        } else {
          db.updateData(vae, varientId);
        }
      }
    }).catchError((e) {
      print(e);
    });
  }

  // ─────────────────────────────────────────────────────────
  // VARIANT SHEET — ProductsScreen wali _showVariantSheet same
  // ─────────────────────────────────────────────────────────

  // ── Size/Color helpers ──────────────────────────────────

  /// All unique sizes from allVariants (order preserve)
  List<String> get _allSizes {
    final seen = <String>{};
    final result = <String>[];
    for (final v in allVariants) {
      final s = v["size"]?.toString().trim() ?? "";
      if (s.isNotEmpty && seen.add(s)) result.add(s);
    }
    return result;
  }

  /// Colors available for a given size
  List<String> _colorsForSize(String size) {
    final seen = <String>{};
    final result = <String>[];
    for (final v in allVariants) {
      final s = v["size"]?.toString().trim() ?? "";
      final c = v["color"]?.toString().trim() ?? "";
      if (s == size && c.isNotEmpty && seen.add(c)) result.add(c);
    }
    return result;
  }

  /// Find variant index by size + color
  int _variantIndexFor(String size, String color) {
    for (int i = 0; i < allVariants.length; i++) {
      final s = allVariants[i]["size"]?.toString().trim() ?? "";
      final c = allVariants[i]["color"]?.toString().trim() ?? "";
      if (s == size && c == color) return i;
    }
    // fallback: match only size
    for (int i = 0; i < allVariants.length; i++) {
      final s = allVariants[i]["size"]?.toString().trim() ?? "";
      if (s == size) return i;
    }
    return selectPos;
  }

  /// Parse color name → Flutter Color (best-effort)
  Color _parseColor(String name) {
    const map = {
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'green': Color(0xFF43A047),
      'black': Color(0xFF212121),
      'white': Color(0xFFFAFAFA),
      'yellow': Color(0xFFFDD835),
      'orange': Color(0xFFFB8C00),
      'purple': Color(0xFF8E24AA),
      'pink': Color(0xFFE91E63),
      'grey': Color(0xFF9E9E9E),
      'gray': Color(0xFF9E9E9E),
      'brown': Color(0xFF6D4C41),
      'navy': Color(0xFF1A237E),
      'teal': Color(0xFF00897B),
      'maroon': Color(0xFF880E4F),
      'beige': Color(0xFFF5F5DC),
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'cyan': Color(0xFF00BCD4),
      'lime': Color(0xFFCDDC39),
      'indigo': Color(0xFF3949AB),
    };
    return map[name.toLowerCase().trim()] ?? kButtonColor;
  }

  void _showVariantSheet() {
    // Sheet ke liye local selection state
    String sheetSize =
        allVariants[selectPos]["size"]?.toString().trim() ?? "";
    String sheetColor =
        allVariants[selectPos]["color"]?.toString().trim() ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final sizes = _allSizes;
            final colorsForSelected = _colorsForSize(sheetSize);

            // Current selected variant index in sheet
            final sheetVariantIdx =
            _variantIndexFor(sheetSize, sheetColor);
            final sheetVariant = allVariants[sheetVariantIdx];
            final double sheetPrice =
                double.tryParse(
                    sheetVariant["price"]?.toString() ?? "0") ??
                    0.0;
            final double sheetStrike =
                double.tryParse(
                    sheetVariant["strick_price"]?.toString() ??
                        "0") ??
                    0.0;
            final int sheetStock =
                int.tryParse(
                    sheetVariant["stock"]?.toString() ?? "0") ??
                    0;
            final String sheetImg =
                sheetVariant["varient_image"]?.toString() ?? "";

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.70,
              ),
              padding: EdgeInsets.only(
                left: 16.sp,
                right: 16.sp,
                top: 12.sp,
                bottom:
                MediaQuery.of(context).viewInsets.bottom + 20.sp,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle + close ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 40.w),
                      Container(
                        height: 5.h,
                        width: 45.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.w,
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.close,
                              size: 22.sp, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // ── Selected variant preview card ──
                  Container(
                    padding: EdgeInsets.all(10.sp),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(14.r),
                      border:
                      Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            width: 70.w,
                            height: 70.w,
                            color: Colors.grey.shade100,
                            child: sheetImg.isNotEmpty
                                ? Image.network(
                              imageBaseUrl + sheetImg,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 22.sp,
                                color: Colors.grey.shade400,
                              ),
                            )
                                : Icon(Icons.image_outlined,
                                size: 24.sp,
                                color: Colors.grey.shade400),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              if (sheetSize.isNotEmpty ||
                                  sheetColor.isNotEmpty)
                                Text(
                                  [
                                    if (sheetSize.isNotEmpty)
                                      "Size: $sheetSize",
                                    if (sheetColor.isNotEmpty)
                                      "Color: $sheetColor",
                                  ].join("  •  "),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  if (sheetStrike > sheetPrice)
                                    Text(
                                      '$currency ${sheetStrike.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey,
                                        decoration: TextDecoration
                                            .lineThrough,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (sheetStrike > sheetPrice)
                                    SizedBox(width: 6.w),
                                  Text(
                                    '$currency ${sheetPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: kButtonColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: (sheetStock > 0
                                          ? Colors.green
                                          : Colors.red)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      sheetStock > 0
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: sheetStock > 0
                                            ? Colors.green
                                            : Colors.red,
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
                  ),
                  SizedBox(height: 16.h),

                  // ── SIZE section (sirf tab dikhao jab sizes hoon) ──
                  if (sizes.isNotEmpty) ...[
                    Text(
                      "Select Size",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sizes.map((size) {
                          final isSelected = sheetSize == size;
                          return GestureDetector(
                            onTap: () {
                              sheetSetState(() {
                                sheetSize = size;
                                // Us size ke available colors mein se pehla color auto-select
                                final cols = _colorsForSize(size);
                                sheetColor = cols.isNotEmpty
                                    ? cols.first
                                    : "";
                              });
                              // Main screen update
                              final idx =
                              _variantIndexFor(size, sheetColor);
                              final newImgs =
                              _buildImagesForIndex(idx);
                              setState(() {
                                selectPos = idx;
                                images = newImgs;
                                currentIndex = 0;
                                add_qnty = 0;
                              });
                              _loadCurrentCartQty();
                            },
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 180),
                              margin: EdgeInsets.only(right: 8.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kButtonColor
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(22.r),
                                border: Border.all(
                                  color: isSelected
                                      ? kButtonColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 0 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: kButtonColor
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset:
                                    const Offset(0, 3),
                                  )
                                ]
                                    : [],
                              ),
                              child: Text(
                                size,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // ── COLOR section (sirf tab dikhao jab colors hoon) ──
                  if (colorsForSelected.isNotEmpty) ...[
                    Text(
                      "Select Color",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: colorsForSelected.map((color) {
                          final isSelected = sheetColor == color;
                          final flutterColor = _parseColor(color);
                          final bool isDark =
                              flutterColor.computeLuminance() < 0.4;

                          return GestureDetector(
                            onTap: () {
                              sheetSetState(
                                      () => sheetColor = color);
                              final idx = _variantIndexFor(
                                  sheetSize, color);
                              final newImgs =
                              _buildImagesForIndex(idx);
                              setState(() {
                                selectPos = idx;
                                images = newImgs;
                                currentIndex = 0;
                                add_qnty = 0;
                              });
                              _loadCurrentCartQty();
                            },
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 180),
                              margin: EdgeInsets.only(right: 10.w),
                              child: Column(
                                children: [
                                  // Color circle
                                  Container(
                                    width: 36.w,
                                    height: 36.w,
                                    decoration: BoxDecoration(
                                      color: flutterColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? kButtonColor
                                            : Colors.grey.shade300,
                                        width: isSelected ? 3 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: flutterColor
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset:
                                          const Offset(0, 3),
                                        )
                                      ]
                                          : [],
                                    ),
                                    child: isSelected
                                        ? Icon(
                                      Icons.check,
                                      size: 16.sp,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    )
                                        : null,
                                  ),
                                  SizedBox(height: 4.h),
                                  // Color name
                                  Text(
                                    color,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? kButtonColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // ── Add Item button ──
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sheetStock > 0
                            ? kButtonColor
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: sheetStock <= 0
                          ? null
                          : () {
                        Navigator.pop(context);
                        if (restrocart == 1) {
                          _showMyDialog();
                        } else {
                          _increaseProduct();
                        }
                      },
                      child: Text(
                        sheetStock > 0 ? 'Add Item' : 'Out of Stock',
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

  /// Variant ke liye images list banao aur return karo
  List<String> _buildImagesForIndex(int index) {
    if (index >= allVariants.length) return [];
    final v = allVariants[index];
    final List<String> imgs = [];

    if (v["product_image"] != null &&
        v["product_image"].toString().trim().isNotEmpty) {
      _addImagesFromCommaString(v["product_image"].toString(), imgs);
    }
    if (imgs.isEmpty &&
        v["varient_image"] != null &&
        v["varient_image"].toString().trim().isNotEmpty) {
      _addImagesFromCommaString(v["varient_image"].toString(), imgs);
    }
    if (imgs.isEmpty && product?["products_image"] != null) {
      _addImagesFromCommaString(
          product!["products_image"].toString(), imgs);
    }
    return imgs;
  }

  // ─────────────────────────────────────────────────────────
  // DIALOGS — original same
  // ─────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:  Text(
          "Product Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14.sp
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
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

                  // refreshQuantities();
                  // getCartCount();
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
      bottomNavigationBar:
      isLoading || product == null ? null : _bottomBar(),
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
              const Icon(Icons.error_outline,
                  size: 50, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontWeight: FontWeight.w700),
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
          // ── IMAGE SLIDER — original same ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
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
                      key: ValueKey(selectPos),
                      itemCount: images.length,
                      itemBuilder: (_, index, __) {
                        final imageUrl = images[index].toString().trim();

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.contain,

                            memCacheHeight: 600,
                            memCacheWidth: 600,
                            maxHeightDiskCache: 900,
                            maxWidthDiskCache: 900,

                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,

                            placeholder: (_, __) => _placeholderImage(),
                            errorWidget: (_, __, ___) => _placeholderImage(),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 280,
                        viewportFraction: 1,
                        autoPlay: images.length > 1,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: images.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: kButtonColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "GST INC. $_gst% ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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

                    if (allVariants.length > 1)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _showVariantSheet,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: kButtonColor, width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${allVariants.length} Variants',
                                  style: TextStyle(
                                    color: kButtonColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  color: kButtonColor,
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dots indicator — original same
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (index) => AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          height: 8,
                          width: currentIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? kButtonColor
                                : Colors.grey.shade300,
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── NAME + SIZE + COLOR + PRICE — original + size/color added ──
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
                      fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),

                // Size & Color chips — variant change hone par update honge
                if (_size.isNotEmpty || _color.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (_size.isNotEmpty)
                        _infoChip(Icons.straighten_rounded, "Size", _size),
                      if (_color.isNotEmpty)
                        _infoChip(Icons.palette_outlined, "Color", _color),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Price row — original same
                Row(
                  children: [
                    if (_strikePrice > _price) ...[
                      Text(
                        "$currency${_strikePrice.toStringAsFixed(2)}",
                        style: TextStyle(
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
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: (_stock > 0 ? Colors.green : Colors.red)
                            .withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _stock > 0
                            ? "In Stock ($_stock)"
                            : "Out of stock",
                        style: TextStyle(
                          color:
                          _stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                // Change variant row — sirf multiple variants mein dikhao
                if (allVariants.length > 1) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showVariantSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 11.h),
                      decoration: BoxDecoration(
                        color: kButtonColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: kButtonColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers_outlined,
                              color: kButtonColor, size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Change Variant  •  ${allVariants.length} options',
                              style: TextStyle(
                                color: kButtonColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                              Icons.keyboard_arrow_right_rounded,
                              color: kButtonColor,
                              size: 20.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "note".tr(),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // ── DESCRIPTION — original same ──
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
                      fontSize: 18.sp, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  _sku,
                  style: TextStyle(
                    height: 1.6,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── PRICE DETAILS — original same ──
          _infoCard(
            title: "Price Details",
            icon: Icons.currency_rupee_rounded,
            children: [
              _row("Price", "$currency${_price.toStringAsFixed(2)}"),
              _row("GST INC.", "$_gst%"),
            ],
          ),

          const SizedBox(height: 14),

          // ── PRODUCT INFO — original same ──
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

  // ─────────────────────────────────────────────────────────
  // SMALL WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _placeholderImage() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(Icons.photo, size: 60, color: Colors.grey.shade400),
    );
  }

  /// Size / Color chip — product name section mein
  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: kButtonColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: kButtonColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: kButtonColor),
          SizedBox(width: 5.w),
          Text(
            "$label: $value",
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: kButtonColor,
            ),
          ),
        ],
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
                    fontSize: 17, fontWeight: FontWeight.w900),
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
                  fontWeight: FontWeight.w700),
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

  // ─────────────────────────────────────────────────────────
  // BOTTOM BAR — original same + size/color text
  // ─────────────────────────────────────────────────────────

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
            // Price summary — left side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$currency${(_price * (add_qnty == 0 ? 1 : add_qnty)).toStringAsFixed(2)}",
                    style: TextStyle(
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
                  // Size & Color — live update jab variant badle
                  if (_size.isNotEmpty || _color.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      [
                        if (_size.isNotEmpty) "Size: $_size",
                        if (_color.isNotEmpty) "Color: $_color",
                      ].join("  •  "),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ADD / stepper — right side
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
              color: Colors.grey, fontWeight: FontWeight.w900),
        ),
      );
    }

    if (add_qnty == 0) {
      return ElevatedButton(
        // Multiple variants → sheet kholo; single variant → seedha add karo
        onPressed: allVariants.length > 1
            ? _showVariantSheet
            : _increaseProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 16),
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

    // Stepper — original same
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kButtonColor, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _decreaseProduct,
            child: Icon(Icons.remove, color: kButtonColor, size: 24),
          ),
          const SizedBox(width: 18),
          Text(
            add_qnty.toString(),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: _increaseProduct,
            child: Icon(Icons.add, color: kButtonColor, size: 24),
          ),
        ],
      ),
    );
  }
}
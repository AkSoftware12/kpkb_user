import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../Auth/login_navigator.dart';
import '../../../BlinkitProduct/new_blinkit_product.dart';
import '../../../BlinkitProduct/product_details_screen.dart';
import '../../../Components/custom_appbar.dart';
import '../../../Maps/UI/location_page.dart';
import '../../../Routes/routes.dart';
import '../../../Themes/colors.dart';
import '../../../baseurlp/baseurl.dart';
import '../../../bean/latlng.dart';
import '../../../databasehelper/dbhelper.dart';
import '../../../main.dart';

// ─────────────────────────────────────────────────────────
//  HomePageDemo
// ─────────────────────────────────────────────────────────

class HomePageDemo extends StatefulWidget {
  final int value;
  const HomePageDemo(this.value, {super.key});

  @override
  State<HomePageDemo> createState() => _HomeState();
}

class _HomeState extends State<HomePageDemo>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? cityName;
  double? lat;
  double? lng;

  bool isLoading = true;
  bool isRefreshing = false;

  bool isCartCount = false;
  int cartCount = 0;

  String vendorId = '';
  String blinkitDist = '';

  List<dynamic> categories = [];
  List<dynamic> banners = [];
  List<dynamic> filteredCategories = [];

  final TextEditingController searchController = TextEditingController();
  Timer? _searchTimer;
  String searchText = '';

  int _current = 0;

  // ── PRODUCT SEARCH state ──
  bool _isProductSearching = false;          // true jab API call chal rahi ho
  bool _showProductResults = false;          // true jab search active ho
  List<dynamic> _productResults = [];        // API se aaye products
  int _searchReqId = 0;                       // race-condition guard (stale response ignore)
  http.Client? _searchClient;                 // request cancel karne ke liye
  final Map<String, List<dynamic>> _searchCache = {}; // fast repeat search cache

  @override
  void initState() {
    super.initState();
    _initFast();
  }

  Future<void> _initFast() async {
    await Future.wait([
      _loadCachedCategories(),
      _loadCachedBanners(), // FIX: banners bhi cache se turant load -> instant dikhe
      _loadBasicPrefs(),
      _getCartCountFast(),
    ]);
    await _fetchCategories(refreshOnly: categories.isNotEmpty);
  }

  Future<void> _loadBasicPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId  = prefs.getString('vendor_id')       ?? '';
    cityName  = prefs.getString('city_name')        ?? 'Current Location';
    blinkitDist = prefs.getString('blinkit_distance') ?? '';
    lat = double.tryParse(prefs.getString('lat') ?? '');
    lng = double.tryParse(prefs.getString('lng') ?? '');
    if (mounted) setState(() {});
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString('home_categories_cache');
    if (cache != null && cache.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cache);
        categories       = list;
        filteredCategories = list;
        isLoading = false;
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  // FIX: banner ko bhi category ki tarah cache se instant load karo
  Future<void> _loadCachedBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString('home_banners_cache');
    if (cache != null && cache.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cache);
        banners = list;
        if (mounted) setState(() {});
        // pehle frame ke baad precache -> scroll/show karte hi ready
        WidgetsBinding.instance.addPostFrameCallback((_) => _precacheBanners());
      } catch (_) {}
    }
  }

  Future<void> _fetchCategories({bool refreshOnly = false}) async {
    try {
      if (mounted) {
        setState(() {
          if (!refreshOnly) isLoading = true;
          isRefreshing = refreshOnly;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final vendor = prefs.getString('vendor_id') ?? vendorId;

      await prefs.setString('store_name', 'KPKB Store');

      final response = await http
          .post(
        Uri.parse(categoryList),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // FIX: type consistent rakha (hamesha String) — mixed int/String se bachne ke liye
          'vendor_id': vendor.isNotEmpty ? vendor : '54',
        }),
      )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.body);

        // Categories
        final List<dynamic> newData = res['data'] ?? [];

        // Banners
        final List<dynamic> bannersData = res['banners'] ?? [];

        /// -------------------------------
        /// SAVE CACHE
        /// -------------------------------

        // Category cache
        await prefs.setString(
          'home_categories_cache',
          jsonEncode(newData),
        );

        // Banner cache
        await prefs.setString(
          'home_banners_cache',
          jsonEncode(bannersData),
        );

        if (!mounted) return;

        // Set category data
        categories = newData;

        // Set banner data
        banners = bannersData;

        // FIX: agar refresh ke baad banners kam ho gaye to _current out-of-range na rahe
        if (_current >= banners.length) _current = 0;

        _applySearch(searchText, rebuild: false);

        setState(() {
          isLoading = false;
          isRefreshing = false;
        });

        _precacheFirstCategoryImages();
        _precacheBanners(); // FIX: banner images bhi pehle se precache
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            isRefreshing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Category Error: $e');

      /// -------------------------------
      /// LOAD FROM CACHE IF API FAILS
      /// -------------------------------
      try {
        final prefs = await SharedPreferences.getInstance();

        // Categories cache
        final categoryCache =
        prefs.getString('home_categories_cache');

        // Banner cache
        final bannerCache =
        prefs.getString('home_banners_cache');

        if (categoryCache != null) {
          categories = jsonDecode(categoryCache);
        }

        if (bannerCache != null) {
          banners = jsonDecode(bannerCache);
          if (_current >= banners.length) _current = 0;
        }

        _applySearch(searchText, rebuild: false);
      } catch (cacheError) {
        debugPrint('Cache Error: $cacheError');
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  void _precacheFirstCategoryImages() {
    if (!mounted) return;
    for (final cat in categories.take(8)) {
      if (cat is! Map) continue;
      final img = cat['category_image']?.toString() ?? '';
      if (_isValidImage(img)) {
        precacheImage(CachedNetworkImageProvider('$imageBaseUrl$img'), context);
      }
    }
  }

  // FIX: banner images ko category ki tarah pehle se memory me load karo
  void _precacheBanners() {
    if (!mounted) return;
    for (final b in banners.take(5)) {
      if (b is! Map) continue;
      final url = _bannerUrl(b['banner_img']?.toString() ?? '');
      if (url.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  bool _isValidImage(String v) {
    final s = v.trim().toLowerCase();
    return s.isNotEmpty && s != 'null' && s != 'n/a';
  }

  // FIX: banner_img full URL ho ya relative path, dono handle ho jaye + null safe
  String _bannerUrl(String v) {
    final s = v.trim();
    if (s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'n/a') {
      return '';
    }
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return '$imageBaseUrl$s';
  }

  Future<void> _getCartCountFast() async {
    final value = await DatabaseHelper.instance.queryRowBothCount();
    if (!mounted) return;
    setState(() { cartCount = value; isCartCount = value > 0; });
  }

  // ─────────────────────────────────────────────────────
  //  CLEAR CART  (pura cart khaali karne ke liye)
  // ─────────────────────────────────────────────────────
  Future<void> _clearCart() async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteAll();
      await db.deleteAllRestProdcut();
      await db.deleteAllAddOns();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('service');
      await prefs.remove('res_vendor_id');
      await prefs.remove('vendor_id');
    } catch (e) {
      debugPrint('Clear Cart Error: $e');
    }

    if (!mounted) return;
    setState(() {
      cartCount = 0;
      isCartCount = false;
    });

    Fluttertoast.showToast(msg: 'Cart cleared');
  }

  void callThisMethodOnResume(bool isVisible) {
    if (isVisible && !isLoading) _getCartCountFast();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();

    // turant UI update (clear button etc.)
    searchText = query.toLowerCase();

    _searchTimer?.cancel();

    // Khaali ho gaya -> turant categories wapas, koi API nahi
    if (query.isEmpty) {
      _searchClient?.close();
      _searchClient = null;
      _searchReqId++; // chalti hui purani request ko stale mark kardo
      if (mounted) {
        setState(() {
          _showProductResults = false;
          _isProductSearching = false;
          _productResults = [];
          filteredCategories = categories;
        });
      }
      return;
    }

    // debounce: tezi se type karte waqt har keystroke pe call na ho
    _searchTimer = Timer(
      const Duration(milliseconds: 280),
          () => _searchProducts(query),
    );
  }

  // ─────────────────────────────────────────────────────
  //  PRODUCT SEARCH API  (fast + cached + cancel-able)
  // ─────────────────────────────────────────────────────
  Future<void> _searchProducts(String query) async {
    final key = query.toLowerCase();

    // 1) Cache hit -> instant result, koi network call nahi
    final cached = _searchCache[key];
    if (cached != null) {
      if (mounted) {
        setState(() {
          _productResults = cached;
          _showProductResults = true;
          _isProductSearching = false;
        });
      }
      return;
    }

    // 2) Naya request id -> purani response aane par ignore ho jaye
    final int reqId = ++_searchReqId;

    // purana chalta client band karo
    _searchClient?.close();
    final client = http.Client();
    _searchClient = client;

    if (mounted) {
      setState(() {
        _showProductResults = true;
        _isProductSearching = true;
      });
    }

    try {
      final response = await client
          .post(
        Uri.parse('${baseUrl}appproductsearch'),
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'search': query},
      )
          .timeout(const Duration(seconds: 10));

      // stale response? (user ne aage type kar diya) -> chhod do
      if (reqId != _searchReqId || !mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.body);
        final List<dynamic> data = res['data'] ?? [];

        _searchCache[key] = data; // cache for fast repeat

        setState(() {
          _productResults = data;
          _isProductSearching = false;
        });
      } else {
        setState(() {
          _productResults = [];
          _isProductSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Product Search Error: $e');
      if (reqId != _searchReqId || !mounted) return;
      setState(() {
        _productResults = [];
        _isProductSearching = false;
      });
    }
  }

  void _applySearch(String value, {bool rebuild = true}) {
    searchText = value;
    filteredCategories = value.isEmpty
        ? categories
        : categories.where((cat) {
      // FIX: null-safe category_name
      final name = cat is Map
          ? (cat['category_name']?.toString().toLowerCase() ?? '')
          : '';
      return name.contains(value);
    }).toList();
    if (rebuild && mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchClient?.close();
    searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: const Key('home-page-visibility'),
      onVisibilityChanged: (info) => callThisMethodOnResume(info.visibleFraction > 0),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F5),
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: kButtonColor,
              onRefresh: () => _fetchCategories(refreshOnly: true),
              child: _showProductResults
                  ? _buildProductSearchBody()
                  : (isLoading && categories.isEmpty
                  ? _buildSkeleton()
                  : _buildBody()),
            ),
            if (isCartCount) _buildCartBar(),
            if (isRefreshing)
              Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  color: kButtonColor,
                  backgroundColor: kMainColor.withOpacity(.12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // SafeArea status-bar inset ke liye top padding add karo, warna
    // notch wale devices par content overflow karega.
    final double topInset = MediaQuery.of(context).padding.top;

    return PreferredSize(
      // 116 = top row + search bar ke liye safe height (logical px, NOT .sp).
      preferredSize: Size.fromHeight(116 + topInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── top row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.black, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LocationPage(lat, lng)),
                          );
                          if (result is BackLatLng) {
                            lat = result.lat;
                            lng = result.lng;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('lat', lat.toString());
                            await prefs.setString('lng', lng.toString());
                            cityName = prefs.getString('city_name') ?? 'Current Location';

                            // async gap ke baad widget alive hai ya nahi, confirm karo.
                            if (!mounted) return;
                            setState(() {});
                            await _fetchCategories(refreshOnly: true);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'delivery_to'.tr(),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.black.withOpacity(.7),
                                fontWeight: FontWeight.bold,
                                letterSpacing: .4,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    cityName?.trim().isNotEmpty == true
                                        ? cityName!
                                        : 'tap_to_select_location'.tr(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Account button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamed(PageRoutes.accountPage);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.06),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(.30)),
                        ),
                        child: const Icon(
                          Icons.account_circle_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── search bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  height: 44, // fixed logical px (pehle 40.sp tha → scaling se overflow)
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(width: 1, color: Colors.grey),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'search_product'.tr(),
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: Colors.grey,
                        onPressed: () {
                          searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
  // ─────────────────────────────────────────────────────
  //  BODY
  // ─────────────────────────────────────────────────────

  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildBannerSection()),
        SliverToBoxAdapter(child: _buildSectionHeader()),
        if (filteredCategories.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No category found',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _CategoryTile(
                  category: filteredCategories[index],
                  index: index,
                  blinkitDist: blinkitDist,
                  onReturn: _getCartCountFast,
                ),
                childCount: filteredCategories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .95,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  PRODUCT SEARCH BODY  (search active hone par dikhta hai)
  // ─────────────────────────────────────────────────────
  Widget _buildProductSearchBody() {
    // pehli dafa loading -> shimmer list
    if (_isProductSearching && _productResults.isEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _ShimmerBox(height: 78),
      );
    }

    // koi result nahi
    if (_productResults.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 100.h),
          // FIX: icon ko center kiya (pehle left-align tha)
          Center(
            child: Icon(Icons.search_off_rounded,
                size: 54, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'No products found',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      );
    }

    // result list
    return Column(
      children: [
        // top thin loader jab fresh search chal rahi ho (par purane result dikh rahe)
        if (_isProductSearching)
          LinearProgressIndicator(
            minHeight: 2.5,
            color: kButtonColor,
            backgroundColor: kMainColor.withOpacity(.12),
          ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: _productResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ProductSearchTile(
                  product: _productResults[index],
                  onReturn: _getCartCountFast,
                ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  //  BANNER
  // ─────────────────────────────────────────────────────

  Widget _buildBannerSection() {
    // FIX: banners khaali ho to kuch render mat karo (crash/empty carousel se bacho)
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, _) => _buildBannerSlide(banners[index]),
          options: CarouselOptions(
            height: 200,
            autoPlay: banners.length > 1, // FIX: 1 banner pe autoplay ki zarurat nahi
            enlargeCenterPage: true,
            viewportFraction: 1,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (i, _) {
              if (mounted) setState(() => _current = i);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = _current == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: active ? 20 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? kButtonColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  // FIX: Image.network -> CachedNetworkImage (category jaisa fast + cache + no flicker)
  Widget _buildBannerSlide(dynamic data) {
    final raw = data is Map ? (data['banner_img']?.toString() ?? '') : '';
    final url = _bannerUrl(raw);

    return SizedBox(
      width: double.infinity,
      child: url.isEmpty
          ? Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_rounded,
            color: kMainColor.withOpacity(.3), size: 40),
      )
          : CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.fill,
        // FIX: memory cache + fade off => category ki tarah turant render
        memCacheWidth: 1080,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, __) => Container(color: Colors.grey.shade200),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image_rounded,
              color: kMainColor.withOpacity(.3), size: 40),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SECTION HEADER
  // ─────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0,18, 0, 18),
      child: Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            "all_category".tr(),
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1a2e1a),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  CART BAR
  // ─────────────────────────────────────────────────────

  Widget _buildCartBar() {
    return Positioned(
      left: 12,
      right: 12,
      bottom:10.sp,
      child: Dismissible(
        key: const ValueKey('home-cart-bar'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withOpacity(.10),
                      ),
                      child: const Icon(
                        Icons.remove_shopping_cart_rounded,
                        color: Colors.redAccent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Clear Cart?',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will remove all items from your cart. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade800,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Clear',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          return confirm ?? false;
        },
        onDismissed: (_) => _clearCart(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_sweep_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'Clear Cart',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () async {

            Navigator.of(context, rootNavigator: true)
                .pushNamed(PageRoutes.viewCart)
                .then((value) {
              if (!context.mounted) return;

              _getCartCountFast();
            });
          },

          child: Container(
            height: 50.sp,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(width: 1.sp,color: kButtonColor)
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30.sp,
                      height: 30.sp,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: kButtonColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$cartCount item${cartCount > 1 ? 's' : ''} in cart',
                        style: GoogleFonts.nunito(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        'Tap to review • slide ← to clear',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Cart',
                        style: GoogleFonts.nunito(
                          color: kButtonColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: kButtonColor,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  SKELETON
  // ─────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        _skeletonBox(height: 168),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            3,
                (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _skeletonBox(height: 36, width: 110),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .80,
          ),
          itemBuilder: (_, __) => _skeletonBox(height: 120),
        ),
      ],
    );
  }

  Widget _skeletonBox({required double height, double? width}) {
    return _ShimmerBox(height: height, width: width);
  }
}

// ─────────────────────────────────────────────────────────
//  _ShimmerBox
// ─────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  const _ShimmerBox({required this.height, this.width});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: const [
                Color(0xFFe8e8e8),
                Color(0xFFf5f5f5),
                Color(0xFFe8e8e8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _ProductSearchTile
// ─────────────────────────────────────────────────────────

class _ProductSearchTile extends StatelessWidget {
  final dynamic product;
  final Future<void> Function()? onReturn;
  const _ProductSearchTile({required this.product, this.onReturn});

  bool _isValidImage(String v) {
    final s = v.trim().toLowerCase();
    return s.isNotEmpty && s != 'null' && s != 'n/a';
  }

  @override
  Widget build(BuildContext context) {
    final name = product['product_name']?.toString() ?? '';
    final image = product['product_image']?.toString() ?? '';
    final imageUrl = _isValidImage(image) ? '$imageBaseUrl$image' : '';
    final price = product['price']?.toString() ?? '';
    final stock = product['stock'];
    final inStock = stock == null || (int.tryParse(stock.toString()) ?? 0) > 0;
    // FIX: product_id null ho to crash na ho
    final productId = product['product_id'];

    return GestureDetector(
      onTap: () async {
        if (productId == null) return; // safety
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: productId),
          ),
        );
        if (onReturn != null) await onReturn!();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 58,
                height: 58,
                color: Colors.grey.shade100,
                child: imageUrl.isEmpty
                    ? Icon(Icons.shopping_bag_rounded,
                    color: kMainColor.withOpacity(.4), size: 26)
                    : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheHeight: 160,
                  fadeInDuration: Duration.zero,
                  placeholder: (_, __) => Icon(Icons.image_rounded,
                      color: kMainColor.withOpacity(.28), size: 22),
                  errorWidget: (_, __, ___) => Icon(
                      Icons.shopping_bag_rounded,
                      color: kMainColor.withOpacity(.4),
                      size: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (price.isNotEmpty)
                        Text(
                          '₹$price',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kButtonColor,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          inStock ? 'In stock($stock)' : 'Out of stock',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: inStock
                                ? Colors.green.shade600
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _CategoryTile
// ─────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  final dynamic category;
  final int index;
  final String blinkitDist;
  final Future<void> Function()? onReturn;

  const _CategoryTile({
    required this.category,
    required this.index,
    required this.blinkitDist,
    this.onReturn,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  bool _isValidImage(String v) {
    final s = v.trim().toLowerCase();
    return s.isNotEmpty && s != 'null' && s != 'n/a';
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.category['category_image']?.toString() ?? '';
    final imageUrl = _isValidImage(image) ? '$imageBaseUrl$image' : '';

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () async {
          final subcategories = widget.category['subcategories'];
          final hasSubCat = subcategories != null &&
              subcategories is List &&
              subcategories.isNotEmpty;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductsScreen(
                widget.category['category_name']?.toString() ?? '',
                widget.category['vendor_id']?.toString() ?? '',
                hasSubCat ? subcategories[0]['subcat_name'].toString() : '',
                widget.category['category_id']?.toString() ?? '',
                0,
                0,
                hasSubCat ? subcategories[0]['subcat_id'].toString() : '',
              ),
            ),
          );
          if (widget.onReturn != null) await widget.onReturn!();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:  EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _pressed ? Colors.grey : Colors.grey.withOpacity(.25),
                width: _pressed ? 1.8 : 1.2,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: imageUrl.isEmpty
                          ? _fallbackIcon()
                          : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        memCacheHeight: 220,
                        fadeInDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        placeholder: (_, __) => Center(
                          child: Icon(
                            Icons.image_rounded,
                            color: kMainColor.withOpacity(.28),
                            size: 28,
                          ),
                        ),
                        errorWidget: (_, __, ___) => _fallbackIcon(),
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.category['category_name'].toString(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        Icons.category_rounded,
        color: kMainColor,
        size: 30,
      ),
    );
  }
}
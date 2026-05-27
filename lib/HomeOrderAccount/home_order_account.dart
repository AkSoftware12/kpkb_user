import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Pages/oneViewCart.dart';
import '../SplashScreen/splash_screen.dart';
import '../Themes/colors.dart';
import '../Wishlist/wishlist_page.dart';
import '../baseurlp/baseurl.dart';
import 'Account/UI/account_page.dart';
import 'Home/UI/home_demo.dart';

class HomeStateless extends StatelessWidget {
  final int currentIndex;
  final int value;

  const HomeStateless({
    super.key,
    this.currentIndex = 0,
    this.value = 0,
  });

  @override
  Widget build(BuildContext context) {
    return HomeOrderAccount(currentIndex, value);
  }
}

class HomeOrderAccount extends StatefulWidget {
  final int currentIndex;
  final int value;

  const HomeOrderAccount(this.currentIndex, this.value, {super.key});

  @override
  State<HomeOrderAccount> createState() => _HomeOrderAccountState();
}

class _HomeOrderAccountState extends State<HomeOrderAccount> {
  late int _currentIndex;
  late int _value;

  late final List<Widget> _children;

  double lat = 0.0;
  double lng = 0.0;
  String cityName = 'NO LOCATION SELECTED';

  String currentVersion = '';
  String release = "";
  bool _upgradeDialogShown = false;


  @override
  void initState() {
    super.initState();

    _currentIndex = widget.currentIndex.clamp(0, 2);
    _value = widget.value;

    _children = [
      HomePageDemo(_value),
      WishListProductsScreen(
        '',
        '54',
        '',
        1,
        0,
        0,
        1,

      ),
      AccountPage(),
      oneViewCart(),

    ];

    _requestPermission();
    getData();
    getCurrency();

    checkForVersion(context);

    final newVersion = NewVersionPlus(
      // iOSId: '6760596159',
      iOSId: '',
      iOSAppStoreCountry: 'IN',
      androidId: 'com.kpkb.user',
      androidPlayStoreCountry: "in",
      androidHtmlReleaseNotes: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      advancedStatusCheck(newVersion); // ✅ now context is ready
    });
  }

  Future<void> getData() async {
    try {
      final pref = await SharedPreferences.getInstance();

      cityName = pref.getString("addr") ?? 'NO LOCATION SELECTED';
      lat = double.tryParse(pref.getString("lat") ?? "0.0") ?? 0.0;
      lng = double.tryParse(pref.getString("lng") ?? "0.0") ?? 0.0;

      await pref.setString("lat", lat.toString());
      await pref.setString("lng", lng.toString());
      await pref.setString("addr", cityName);

      debugPrint("HOME_ORDER lat: $lat lng: $lng");
    } catch (e) {
      debugPrint("getData error: $e");
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      debugPrint('Location permission granted');
    } else if (status.isPermanentlyDenied) {
      debugPrint('Location permission permanently denied');
      // openAppSettings();
    }
  }

  Future<void> getCurrency() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final response = await http.get(Uri.parse(currencyuri));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1" &&
            jsonData['data'] != null &&
            jsonData['data'].isNotEmpty) {
          await pref.setString(
            'curency',
            '${jsonData['data'][0]['currency_sign']}',
          );
        }
      }
    } catch (e) {
      debugPrint("getCurrency error: $e");
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    exit(0);
  }

  void onTapped(int index) {
    if (index < 0 || index >= _children.length) return;

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> advancedStatusCheck(NewVersionPlus newVersion) async {
    try {
      final status = await newVersion.getVersionStatus();
      if (status == null) return;

      debugPrint("releaseNotes: ${status.releaseNotes}");
      debugPrint("appStoreLink: ${status.appStoreLink}");
      debugPrint("localVersion: ${status.localVersion}");
      debugPrint("storeVersion: ${status.storeVersion}");
      debugPrint("canUpdate: ${status.canUpdate}");

      if (!status.canUpdate) return;
      if (_upgradeDialogShown) return;
      if (!mounted) return;

      _upgradeDialogShown = true;

      showDialog(
        context: context, // ✅ yahi best hai
        barrierDismissible: false,
        builder: (dialogCtx) {
          return PopScope( // ✅ WillPopScope new replacement (Flutter 3.13+)
            canPop: false,
            onPopInvoked: (didPop) {
              SystemNavigator.pop();
            },
            child: CustomUpgradeDialog(
              currentVersion: status.localVersion,
              newVersion: status.storeVersion,
              releaseNotes: [
                (status.releaseNotes ?? "").trim().isEmpty
                    ? "New update available."
                    : status.releaseNotes!.trim(),
              ],
            ),
          );
        },
      );
    } catch (e, st) {
      debugPrint("advancedStatusCheck error: $e");
      debugPrint("$st");
    }
  }
  Future<void> checkForVersion(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion = packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _children.length - 1);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: KeyedSubtree(
          key: ValueKey(safeIndex),
          child: _children[safeIndex],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [

            _navItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'home'.tr(),
            ),
            _navItem(
              index: 1,
              icon: Icons.favorite,
              label: 'wishlist'.tr(),
            ),

            _navItem(
              index: 2,
              icon: Icons.person_rounded,
              label: 'account'.tr(),
            ),
            _navItem(
              index: 3,
              icon: Icons.shopping_cart_rounded,
              label: 'cart'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: selected ? 30 : 25,
              color: selected ? kButtonColor : Colors.black,
            ),
            // const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? kButtonColor : Colors.black,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
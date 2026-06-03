import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'package:kpUser/DriverApp/Account/UI/ListItems/about_us_page.dart';
import 'package:kpUser/DriverApp/Account/UI/ListItems/insight_page.dart';
import 'package:kpUser/DriverApp/Account/UI/ListItems/support_page.dart';
import 'package:kpUser/DriverApp/Account/UI/ListItems/tnc_page.dart';
import 'package:kpUser/DriverApp/DeliveryPartnerProfile/store_profile.dart';
import 'package:kpUser/DriverApp/OrderMap/UI/accepted.dart';
import 'package:kpUser/DriverApp/OrderMap/UI/new_delivery.dart';
import 'package:kpUser/DriverApp/OrderMap/UI/onway.dart';
import 'package:kpUser/DriverApp/Themes/colors.dart';
import 'package:kpUser/DriverApp/baseurl/baseurl.dart';
import 'package:kpUser/DriverApp/beanmodel/Multistoreorder.dart';
import 'package:kpUser/DriverApp/beanmodel/orderbean.dart';
import 'package:kpUser/DriverApp/beanmodel/dutyonoff.dart';
import 'package:kpUser/DriverApp/orderpage/itemdetailspage.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../Auth/login_navigator.dart';

var scfoldKey = GlobalKey<ScaffoldState>();

// Light background used across the page (Swiggy/Zomato style soft gray).
const Color kPageBg = Color(0xFFF6F7F9);
const Color kCardBorder = Color(0xFFEDEFF2);
const Color kCardFooterBg = Color(0xFFF8F9FB);

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<Tab> tabs = <Tab>[
    Tab(text: 'NEW ORDERS'),
    Tab(text: 'COMPLETED ORDERS'),
  ];
  TabController? tabController;

  Completer<GoogleMapController> _controller = Completer();
  var onOffLine = 'GO OFFLINE';
  var status = 0;
  dynamic lat;
  dynamic lng;
  SharedPreferences? preferences;
  dynamic driverName = '';
  dynamic driverNumber = '';
  dynamic imageUrld = '';
  static const LatLng _center = const LatLng(45.343434, -122.545454);
  CameraPosition kGooglePlex = CameraPosition(target: _center, zoom: 12.151926);
  bool isRun = false;
  bool isRingBell = false;
  Timer? timer;

  // Auto-refresh timer for the NEW ORDERS tab.
  Timer? newOrdersTimer;

  var orderCount = 0;

  List<dynamic> categories = [];
  List<dynamic> categories1 = [];

  List<OrderDetails> todayOrder = [];

  dynamic currency;

  List<OrderDetail> orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getCurrency();
    _checkFirstLaunch();
    // _getLocation();
    getSharedPref();
    hitStatusServiced();
    getAllApi();
    tabController = TabController(length: tabs.length, vsync: this);
    tabController!.addListener(() {
      if (!tabController!.indexIsChanging) {
        setState(() {
          todayOrder = [];
        });
        print(tabController!.index);
        if (tabController!.index == 0) {
          getAllApi();
          // New Orders tab par aaye -> agar list khaali hai to refresh shuru karo.
          startNewOrdersAutoRefresh();
        } else if (tabController!.index == 1) {
          getAllApi2();
          // Completed tab par aaye -> new orders ka refresh band karo.
          stopNewOrdersAutoRefresh();
        }
      }
    });

    // App khulte hi New Orders tab default hai, isliye refresh shuru kar do.
    startNewOrdersAutoRefresh();
  }

  // ----------------------------------------------------------------------
  // AUTO-REFRESH LOGIC (NEW ORDERS TAB)
  //
  // - Timer sirf tab chalta hai jab New Orders tab (index 0) active ho
  //   AUR list khaali ho.
  // - Jaise hi orders aa jaate hain, timer khud cancel ho jata hai
  //   (taaki order aane ke baad list baar-baar refresh na ho).
  // - Detail page se wapas aane par list phir khaali ho to timer
  //   dobara start kar diya jata hai.
  // ----------------------------------------------------------------------

  void startNewOrdersAutoRefresh() {
    // Pehle se chal raha hai ya list bhari hui hai to kuch mat karo.
    if (newOrdersTimer != null && newOrdersTimer!.isActive) {
      return;
    }
    if (todayOrder.isNotEmpty) {
      return;
    }

    newOrdersTimer = Timer.periodic(Duration(seconds: 5), (t) {
      // Agar New Orders tab par nahi hain to refresh band kar do.
      if (!mounted || tabController == null || tabController!.index != 0) {
        stopNewOrdersAutoRefresh();
        return;
      }
      // Agar list bhar gayi hai to refresh band kar do.
      if (todayOrder.isNotEmpty) {
        stopNewOrdersAutoRefresh();
        return;
      }
      // Warna naye orders ke liye dobara try karo.
      getTodayOrders();
    });
  }

  void stopNewOrdersAutoRefresh() {
    if (newOrdersTimer != null) {
      newOrdersTimer!.cancel();
      newOrdersTimer = null;
    }
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (isFirstLaunch) {
      await Future.delayed(Duration(seconds: 2));
      showDisclosureDialog(context);
      prefs.setBool('firstLaunch', false);
    } else {
      // Navigate to your home screen or any other screen as needed.
    }
  }

  void showDisclosureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Location Permission Disclosure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This app requires access to your location to provide certain features. '
                    'By clicking "Allow", you agree to share your device\'s location data.',
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the disclosure dialog
                  _getLocation();
                },
                child: Text('Allow'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        {
          print("APP RESUMED");

          getCurrency();

          getSharedPref();

          hitStatusServiced();

          if (tabController!.index == 0) {
            getAllApi();
            // Resume hone par bhi New Orders tab par auto-refresh resume karo.
            startNewOrdersAutoRefresh();
          } else if (tabController!.index == 1) {
            getAllApi2();
            stopNewOrdersAutoRefresh();
          }
        }
        break;

      case AppLifecycleState.inactive:
        {
          print("APP INACTIVE");
          // App background me jaane par refresh band karo (battery/data bachao).
          stopNewOrdersAutoRefresh();
        }
        break;

      case AppLifecycleState.paused:
        {
          print("APP PAUSED");
          stopNewOrdersAutoRefresh();
        }
        break;

      case AppLifecycleState.detached:
        {
          print("APP DETACHED");
          stopNewOrdersAutoRefresh();
        }
        break;

      case AppLifecycleState.hidden:
        {
          print("APP HIDDEN");
          stopNewOrdersAutoRefresh();
        }
        break;
    }
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    stopNewOrdersAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  getAllApi() {
    setState(() {
      todayOrder = [];
    });
    getTodayOrders();
  }

  getAllApi2() {
    setState(() {
      todayOrder = [];
    });
    getCompleteOrders();
  }

  _launchURL(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }

  Future<void> getCompleteOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    final response = await http.post(
      Uri.parse(completed_orders),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${''}',
      },
      body: jsonEncode({'delivery_boy_id': boyId}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        categories1 = data['data'];
      });
    } else {
      throw Exception('Failed to load categories');
    }
  }

  getTodayOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var todayOrderUrl = ordersfortoday;
    var client = http.Client();
    client
        .post(Uri.parse(todayOrderUrl), body: {'delivery_boy_id': '${boyId}'})
        .then((value) {
      print('g ${value.body}');
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        if (value.body.toString().contains(
          "[{\"order_details\":\"no orders found\"}]",
        ) ||
            value.body.toString().contains(
              "[{\"no_order\":\"no orders found\"}]",
            )) {
          // Koi order nahi mila -> agar New Orders tab par hain to
          // auto-refresh chalu rakho taaki naya order aate hi dikh jaaye.
          if (mounted &&
              tabController != null &&
              tabController!.index == 0) {
            startNewOrdersAutoRefresh();
          }
        } else {
          var jsonList = jsonData as List;
          List<OrderDetails> orderDetails = jsonList
              .map((e) => OrderDetails.fromJson(e))
              .toList();
          print('${orderDetails.toString()}');
          setState(() {
            todayOrder = orderDetails;
          });
          // Orders aa gaye -> ab refresh ki zaroorat nahi, timer band karo.
          if (todayOrder.isNotEmpty) {
            stopNewOrdersAutoRefresh();
          }
        }
      }
    })
        .catchError((e) {
      Fluttertoast.showToast(
        msg: 'No Order Found!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black26,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      print(e);
    });
  }

  void setTimerTask() async {
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (this.timer == null) {
        this.timer = timer;
      }
      hitTestServices();
    });
  }

  _getDirection(url) async {
    try {
      launch(url);
    } catch (error, stack) {
      // log error
    }
  }

  void hitStatusServiced() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    print('${status} - ${preferences!.getInt('delivery_boy_id')}');
    var client = http.Client();
    var statusUrl = driverstatus;
    client
        .post(
      Uri.parse(statusUrl),
      body: {
        'delivery_boy_id': '${preferences!.getInt('delivery_boy_id')}',
      },
    )
        .then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var sat = jsonData['data']['delivery_boy_status'];
          print('${sat}');
          if (sat == "online") {
            preferences!.setInt('duty', 1);
            setState(() {
              status = 1;
            });
          } else {
            preferences!.setInt('duty', 0);
            setState(() {
              status = 0;
            });
          }
        }
      }
    })
        .catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }

  void _getLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      bool isLocationServiceEnableds =
      await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnableds) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        Timer(Duration(seconds: 5), () async {
          double lat = position.latitude;
          double lng = position.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          // setLocation(lat, lng);
        });
        Geolocator.getPositionStream().listen((positionNew) {
          print(
            positionNew == null
                ? 'Unknown'
                : positionNew.latitude.toString() +
                ', ' +
                positionNew.longitude.toString(),
          );
          double lat = positionNew.latitude;
          double lng = positionNew.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          // setLocation(lat, lng);
        });
      } else {
        await Geolocator.openLocationSettings()
            .then((value) {
          if (value) {
            _getLocation();
          } else {
            Fluttertoast.showToast(
              msg: 'Location permission is required!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black26,
              textColor: Colors.white,
              fontSize: 14.0,
            );
          }
        })
            .catchError((e) {
          Fluttertoast.showToast(
            msg: 'Location permission is required!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        });
      }
    } else if (permission == LocationPermission.denied) {
      LocationPermission permissiond = await Geolocator.requestPermission();
      if (permissiond == LocationPermission.whileInUse ||
          permissiond == LocationPermission.always) {
        _getLocation();
      } else {
        Fluttertoast.showToast(
          msg: 'Location permission is required!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black26,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings()
          .then((value) {
        _getLocation();
      })
          .catchError((e) {
        Fluttertoast.showToast(
          msg: 'Location permission is required!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black26,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      });
    }
  }

  void _showPermissionError() {
    Fluttertoast.showToast(
      msg: 'Location permission is required!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black26,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  setLocation(lats, lngs) {
    print('state - ${scfoldKey.currentState}');
    setState(() {
      lat = lats ?? "";
      lng = lngs ?? "";
      kGooglePlex = CameraPosition(target: LatLng(lats, lngs), zoom: 12.151926);
    });
  }

  void getSharedPref() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      driverName = preferences!.getString('delivery_boy_name');
      driverNumber = preferences!.getString('delivery_boy_phone');
      imageUrld = Uri.parse(
        '${imageBaseUrl}${preferences!.getString('delivery_boy_image')}',
      );
      print('${preferences!.getInt('duty')}');
      setState(() {
        status = preferences!.getInt('duty')!;
      });
    });
  }

  void getCurrency() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    var currencyUrl = currencys;
    var client = http.Client();
    client
        .get(Uri.parse(currencyUrl))
        .then((value) {
      var jsonData = jsonDecode(value.body);
      if (value.statusCode == 200 && jsonData['status'] == "1") {
        print('${jsonData['data'][0]['currency_sign']}');
        preferences.setString(
          'curency',
          '${jsonData['data'][0]['currency_sign']}',
        );
        setState(() {
          currency = '${jsonData['data'][0]['currency_sign']}';
        });
      }
    })
        .catchError((e) {
      print(e);
    });
  }

  Future<void> getorders(orderid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic boyId = prefs.getInt('delivery_boy_id');
    var url = ordersfortodaydetails;
    var client = http.Client();

    try {
      final value = await client.post(
        Uri.parse(url),
        body: {
          'order_id': orderid.toString(),
          'delivery_boy_id': boyId.toString(),
        },
      );

      if (value.statusCode == 200) {
        var tagObjsJson = jsonDecode(value.body) as List;
        List<Multistoreorder> tagObjs = tagObjsJson
            .map((tagJson) => Multistoreorder.fromJson(tagJson))
            .toList();

        List<OrderDetail> temp = [];
        for (var element in tagObjs) {
          if (element.orderDetails != null) {
            temp.addAll(element.orderDetails!);
          }
        }

        if (mounted) {
          setState(() {
            orders.clear();
            orders.addAll(temp);
          });
        }
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        key: scfoldKey,
        backgroundColor: kPageBg,
        appBar: _buildAppBar(),
        drawer: Account(driverName, driverNumber, imageUrld),
        body: TabBarView(
          controller: tabController,
          children: [
            NewOrdersTab(
              todayOrder: todayOrder,
              currency: currency,
              lat: lat,
              lng: lng,
              orders: orders,
              getorders: getorders,
              getAllApi: getAllApi,
              getAllApi2: getAllApi2,
              launchURL: _launchURL,
              getDirection: _getDirection,
              onOrderOpened: stopNewOrdersAutoRefresh,
              onReturnedFromOrder: startNewOrdersAutoRefresh,
            ),
            CompletedOrdersTab(categories1: categories1),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Modern app bar: title + online/offline status text on left,
  // pill-shaped Go Online/Offline toggle on right, clean tab bar below.
  // --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(108.0),
      child: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: kMainColor),
        centerTitle: false,
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'My Orders',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 2),
            Text(
              status == 1 ? 'You are online' : 'You are offline',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: status == 1 ? kGreen : const Color(0xff9a9a9a),
              ),
            ),
          ],
        ),
        actions: [
          if (isRun)
            const Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: Center(child: CupertinoActivityIndicator(radius: 12)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0, top: 10, bottom: 10),
            child: Material(
              color: (status == 1)
                  ? kRed.withOpacity(0.10)
                  : kGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  if (!isRun) hitStatusService();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 9, color: status == 1 ? kRed : kGreen),
                      const SizedBox(width: 7),
                      Text(
                        status == 1 ? 'Go Offline' : 'Go Online',
                        style: TextStyle(
                          color: status == 1 ? kRed : kGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: tabController,
              tabs: tabs,
              isScrollable: true,
              labelColor: kMainColor,
              unselectedLabelColor: kLightTextColor,
              indicatorColor: kMainColor,
              indicatorWeight: 2.5,
              labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
        ),
      ),
    );
  }

  void hitTestServices() async {
    preferences = await SharedPreferences.getInstance();
    var client = http.Client();
    var dboy_completed_orderd = today_order_count;
    client
        .post(
      Uri.parse(dboy_completed_orderd),
      body: {
        'delivery_boy_id': '${preferences!.getInt('delivery_boy_id')}',
      },
    )
        .then((value) {
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        print('${jsonData.toString()}');
        if (jsonData['status'] == "1") {
          if (jsonData['data'] > 0) {
            orderCount = jsonData['data'];
          }
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        } else {
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        }
      }
    })
        .catchError((e) {
      if (orderCount > 0) {
        setState(() {
          isRingBell = true;
        });
      } else {
        setState(() {
          isRingBell = false;
        });
      }
      print(e);
    });
  }

  void hitStatusService() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    dynamic statuss = preferences!.getInt('duty');
    var client = http.Client();
    var statusUrl = dboy_status;
    client
        .post(
      Uri.parse(statusUrl),
      body: {
        'delivery_boy_id': '${preferences!.getInt('delivery_boy_id')}',
        'status': '${statuss == 1 ? 0 : 1}',
      },
    )
        .then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        DutyOnOff dutyOnOff = DutyOnOff.fromJson(jsonData);
        switch (dutyOnOff.status.toString().trim()) {
          case '0':
            print('0');
            break;
          case '1':
            print('1');
            preferences!.setInt('duty', 1);
            setState(() {
              status = preferences!.getInt('duty')!;
            });
            break;
          case '2':
            print('2');
            preferences!.setInt('duty', 0);
            setState(() {
              status = preferences!.getInt('duty')!;
            });
            break;
        }
        Fluttertoast.showToast(
          msg: dutyOnOff.message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black26,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    })
        .catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }
}

// =============================================================================
//  STATUS HELPERS — order_status ke hisaab se rang decide karte hain.
// =============================================================================

Color _statusBgColor(String status) {
  final s = status.toLowerCase();
  if (s == 'pending' || s == 'confirm' || s == 'confirmed') {
    return const Color(0xFFFFF3E0);
  } else if (s == 'delivery accepted') {
    return const Color(0xFFE3F2FD);
  } else if (s == 'out for delivery') {
    return const Color(0xFFE1F5EE);
  }
  return const Color(0xFFF0F0F0);
}

Color _statusTextColor(String status) {
  final s = status.toLowerCase();
  if (s == 'pending' || s == 'confirm' || s == 'confirmed') {
    return const Color(0xFF8A5300);
  } else if (s == 'delivery accepted') {
    return const Color(0xFF185FA5);
  } else if (s == 'out for delivery') {
    return const Color(0xFF0F6E56);
  }
  return const Color(0xFF555555);
}

// =============================================================================
//  DRAWER  (Swiggy-style: gradient header + clean menu rows)
// =============================================================================

class Account extends StatefulWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  Account(this.driverName, this.driverNumber, this.imageUrld);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String? number;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kPageBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: <Widget>[
            // ---- Profile header card ----
            UserDetails(
              widget.driverName,
              widget.driverNumber,
              widget.imageUrld,
            ),
            const SizedBox(height: 16),

            // ---- Menu group ----
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kCardBorder, width: 1),
              ),
              child: Column(
                children: [
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    text: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  const _DrawerDivider(),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    text: 'Terms & Conditions',
                    onTap: () {
                      scfoldKey.currentState?.openEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TncPage()),
                      );
                    },
                  ),
                  const _DrawerDivider(),
                  _DrawerTile(
                    icon: Icons.headset_mic_outlined,
                    text: 'Support',
                    onTap: () {
                      scfoldKey.currentState?.openEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SupportPage(number: number?.toString()),
                        ),
                      );
                    },
                  ),
                  const _DrawerDivider(),
                  _DrawerTile(
                    icon: Icons.info_outline,
                    text: 'About us',
                    onTap: () {
                      scfoldKey.currentState?.openEndDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AboutUsPage()),
                      );
                    },
                  ),
                  const _DrawerDivider(),
                  _DrawerTile(
                    icon: Icons.info,
                    text: 'Privacy Policy',
                    onTap: () async {
                      scfoldKey.currentState?.openEndDrawer();
                      final Uri url = Uri.parse(
                        'https://www.termsfeed.com/live/b710c701-5a4c-4746-88eb-77642222bf25',
                      );

                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- Logout ----
            const LogoutTile(),
          ],
        ),
      ),
    );
  }
}

// A single tappable drawer row with a leading icon.
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _DrawerTile({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 21, color: kMainColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff333333),
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: kCardBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}

class LogoutTile extends StatelessWidget {
  const LogoutTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCEBEB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text('Logging out'),
                content: Text('Are you sure?'),
                actions: <Widget>[
                  TextButton(
                    child: Text('No'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: kTransparentColor),
                      ),
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text('Yes'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: kTransparentColor),
                      ),
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      SharedPreferences pref =
                      await SharedPreferences.getInstance();
                      pref.clear().then((value) {
                        if (value) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return LoginNavigator();
                              },
                            ),
                                (Route<dynamic> route) => true,
                          );
                        }
                      });
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 19, color: Color(0xFFA32D2D)),
              const SizedBox(width: 10),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA32D2D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile header card with colored background, avatar, name, number.
class UserDetails extends StatelessWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  UserDetails(this.driverName, this.driverNumber, this.imageUrld);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kMainColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 2),
            ),
            child: CircleAvatar(
              radius: 30.0,
              backgroundColor: Colors.white24,
              backgroundImage: NetworkImage('${imageUrld}'),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: InkWell(
              onTap: () {
                scfoldKey.currentState?.openEndDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(phoneNumber: ''),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${driverName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${driverNumber}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'View profile',
                      style: TextStyle(
                        color: kMainColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  NEW ORDERS TAB  (redesigned)
// =============================================================================

class NewOrdersTab extends StatelessWidget {
  final List<OrderDetails> todayOrder;
  final dynamic currency;
  final dynamic lat;
  final dynamic lng;
  final List<OrderDetail> orders;
  final Future<void> Function(dynamic) getorders;
  final VoidCallback getAllApi;
  final VoidCallback getAllApi2;
  final Function(dynamic) launchURL;
  final Function(dynamic) getDirection;

  final VoidCallback onOrderOpened;
  final VoidCallback onReturnedFromOrder;

  const NewOrdersTab({
    Key? key,
    required this.todayOrder,
    required this.currency,
    required this.lat,
    required this.lng,
    required this.orders,
    required this.getorders,
    required this.getAllApi,
    required this.getAllApi2,
    required this.launchURL,
    required this.getDirection,
    required this.onOrderOpened,
    required this.onReturnedFromOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (todayOrder.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No new orders yet',
        subtitle: 'Naye orders aate hi yahan dikhenge.',
      );
    }

    return Container(
      color: kPageBg,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        itemCount: todayOrder.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = todayOrder[index];
          final statusStr = order.order_status.toString();
          final isOutForDelivery =
              statusStr.toLowerCase() == 'out for delivery';

          return _OrderCard(
            order: order,
            currency: currency,
            isOutForDelivery: isOutForDelivery,
            onTap: () => _handleTap(context, order),
            onItemDetail: () async {
              await getorders(order.order_id);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Itemdetail(
                    cartId: '${order.cart_id}',
                    itemDetails: List<OrderDetail>.from(orders),
                    currency: currency,
                  ),
                ),
              );
            },
            onDirection: () {
              getDirection(
                'https://www.google.com/maps/search/?api=1&query=${order.user_lat},${order.user_lng}',
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, OrderDetails order) {
    final status = order.order_status.toString();

    int? orderPage;
    if (status == "Pending" ||
        status == "pending" ||
        status == "Confirmed" ||
        status == "Confirm") {
      orderPage = 0;
    } else if (status == "Delivery Accepted") {
      orderPage = 1;
    } else if (status == "Out For Delivery") {
      orderPage = 2;
    }

    if (orderPage == null) return;

    onOrderOpened();

    final Future<dynamic> navigation;
    if (orderPage == 0) {
      navigation = Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewDeliveryPage(
            cartId: order.cart_id,
            vendorName: order.vendor_name,
            vendorAddress: order.vendor_address,
            userName: order.user_name,
            userAddress: order.user_address,
            userphone: order.user_phone,
            vendorlat: order.vendor_lat,
            vendorlng: order.vendor_lng,
            dlat: lat,
            dlng: lng,
            userlat: order.user_lat,
            userlng: order.user_lng,
            remprice: order.new_price,
            paymentstatus: order.payment_status,
            paymentMethod: order.payment_method,
            orderId: order.order_id,
            itemDetails: order.order_details,
          ),
        ),
      );
    } else if (orderPage == 1) {
      navigation = Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AcceptedPage(
            cartId: order.cart_id,
            vendorName: order.vendor_name,
            vendorAddress: order.vendor_address,
            userName: order.user_name,
            userAddress: order.user_address,
            userphone: order.user_phone,
            vendorlat: order.vendor_lat,
            vendorlng: order.vendor_lng,
            vendorPhone: order.vendor_phone,
            dlat: lat,
            dlng: lng,
            userlat: order.user_lat,
            userlng: order.user_lng,
            remprice: order.new_price,
            paymentstatus: order.payment_status,
            paymentMethod: order.payment_method,
            orderId: order.order_id,
            itemDetails: order.order_details,
          ),
        ),
      );
    } else {
      navigation = Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnWayPage(
            cartId: order.cart_id,
            vendorName: order.vendor_name,
            vendorAddress: order.vendor_address,
            userName: order.user_name,
            userAddress: order.user_address,
            userphone: order.user_phone,
            vendorlat: order.vendor_lat,
            vendorlng: order.vendor_lng,
            vendorPhone: order.vendor_phone,
            dlat: lat,
            dlng: lng,
            userlat: order.user_lat,
            userlng: order.user_lng,
            remprice: order.new_price,
            paymentstatus: order.payment_status,
            paymentMethod: order.payment_method,
            orderId: order.order_id,
            itemDetails: order.order_details,
          ),
        ),
      );
    }

    navigation.then((value) {
      getAllApi();
      getAllApi2();
      onReturnedFromOrder();
    });
  }
}


// A clean, modern order card.
class _OrderCard extends StatelessWidget {
  final OrderDetails order;
  final dynamic currency;
  final bool isOutForDelivery;
  final VoidCallback onTap;
  final VoidCallback onItemDetail;
  final VoidCallback onDirection;

  const _OrderCard({
    Key? key,
    required this.order,
    required this.currency,
    required this.isOutForDelivery,
    required this.onTap,
    required this.onItemDetail,
    required this.onDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusStr = order.order_status.toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kCardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: kMainColor, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.user_name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff2b2b2b),
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${order.cart_id} . ${order.delivery_date} · ${order.time_slot}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBgColor(statusStr),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusStr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _statusTextColor(statusStr),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: const BoxDecoration(
                  color: kCardFooterBg,
                  border: Border(
                    top: BorderSide(color: kCardBorder, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Text(
                          '${order.total_items} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: order.payment_method.toLowerCase() == "online"
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.payment_method.toLowerCase() == "online"
                            ? "Paid"
                            : "POD",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: order.payment_method.toLowerCase() == "online"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),

                    Text(
                      '$currency ${order.new_price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff2b2b2b),
                      ),
                    ),
                  ],
                ),
              ),
              if (isOutForDelivery)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onItemDetail,
                          icon: const Icon(Icons.list_alt_outlined, size: 17),
                          label: const Text("Item Detail's"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMainColor,
                            side: BorderSide(color: kMainColor),
                            padding:
                            const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDirection,
                          icon: const Icon(Icons.navigation_outlined,
                              size: 17),
                          label: const Text('Get Direction'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                            const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  COMPLETED ORDERS TAB  (redesigned)
// =============================================================================

class CompletedOrdersTab extends StatelessWidget {
  final List<dynamic> categories1;

  const CompletedOrdersTab({Key? key, required this.categories1})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories1.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'No completed orders',
        subtitle: 'Aapke delivered orders yahan dikhenge.',
      );
    }

    return Container(
      color: kPageBg,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        itemCount: categories1.length,
        itemBuilder: (context, index) {
          final category = categories1[index];
          final array = category['array'] as List;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: kMainColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['date'].toString(),
                      style: const TextStyle(
                        color: Color(0xff2b2b2b),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: array.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (context, subIndex) {
                  final subCategory = array[subIndex];
                  final isRazorPay =
                      subCategory['payment_method'].toString() == 'RazorPay';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kCardBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: kMainColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.person_outline,
                                    color: kMainColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subCategory['user_name'].toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff2b2b2b),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subCategory['delivery_date']} · ${subCategory['time_slot']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isRazorPay)
                                Text(
                                  '₹ ${subCategory['remaining_price']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff2b2b2b),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: const BoxDecoration(
                            color: kCardFooterBg,
                            border: Border(
                              top: BorderSide(color: kCardBorder, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '#${subCategory['cart_id']}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Text(
                                '${subCategory['order_details'].length} items',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  subCategory['order_status'].toString(),
                                  style: const TextStyle(
                                    color: Color(0xff8A5300),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          );
        },
      ),
    );
  }
}

// Shared empty-state widget for both tabs.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPageBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: kMainColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff3a3a3a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
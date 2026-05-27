import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../Auth/login_navigator.dart';
import '../HomeOrderAccount/Account/UI/ListItems/about_us_page.dart';
import '../HomeOrderAccount/Account/UI/ListItems/support_page.dart';
import '../HomeOrderAccount/Account/UI/ListItems/tnc_page.dart';
import '../HomeOrderAccount/Account/UI/account_page.dart';
import '../HomeOrderAccount/Home/UI/home2.dart';
import '../HomeOrderAccount/Home/UI/order_placed_map.dart';
import '../HomeOrderAccount/Order/UI/Cancelled/cancel_order_page.dart';
import '../HomeOrderAccount/Order/UI/Completed/completed.dart';
import '../HomeOrderAccount/Order/UI/Ongoing/ongong_order_page.dart';
import '../HomeOrderAccount/Order/UI/order_page.dart' hide CompletedOrders;
import '../HomeOrderAccount/home_order_account.dart';
import '../HomeOrderAccount/offer/ui/offerui.dart';
import '../Maps/UI/location_page.dart';
import '../Pages/instructions.dart';
import '../Pages/oneViewCart.dart';
// import '../parcel/DropMap.dart';
// import '../parcel/ParcelLocation.dart';
// import '../parcel/PickMap.dart';
// import '../settingpack/settings.dart';


class PageRoutes {
  static const String locationPage = 'location_page';
  static const String subscription = 'subscription';
  static const String otpScreen = 'otp_screen';
  static const String livetrack = 'livetrack';
  static const String homeOrderAccountPage = 'home_order_account';
  static const String homeOrderAccountPage3 = 'homeOrderAccountPage3';
  static const String homePage = 'home_page';
  static const String accountPage = 'account_page';
  static const String orderPage = 'order_page';
  static const String ongoingOrderPage = 'ongoing_order_page';
  static const String cancelOrderPage = 'cancel_order_page';
  static const String completedOrderPage = 'completed_order_page';

  static const String tncPage = 'tnc_page';
  static const String aboutUsPage = 'about_us_page';
  static const String settings = 'settings';
  static const String savedAddressesPage = 'saved_addresses_page';
  static const String supportPage = 'support_page';
  static const String loginNavigator = 'login_navigator';
  static const String orderMapPage = 'order_map_page';
  static const String viewCart = 'view_cart';
  static const String restviewCart = 'restviewCart';
  static const String orderPlaced = 'order_placed';
  static const String paymentMethod = 'payment_method';
  static const String wallet = 'wallet';
  static const String reward = 'reward';
  static const String reffernearn = 'reffernearn';
  static const String returanthome = 'returanthome';
  static const String pharmacart = 'pharmacart';
  static const String offers = 'offers';
  static const String dropmap = 'DropMap';
  static const String pickmap = 'pickmap';
  static const String parcellocation = 'parcellocation';
  static const String restro = 'restro';
  static const String instruction = 'instruction';
  static const String blinkit = 'blinkit';

  Map<String, WidgetBuilder> routes() {
    return {

      homeOrderAccountPage: (context) => HomeOrderAccount(0,1),
      homeOrderAccountPage3: (context) => HomeOrderAccount(3,1),
      homePage: (context) => HomePage2(1),
      orderPage: (context) => OrderPage(),
      ongoingOrderPage: (context) => const OngoingOrderPage(),
      cancelOrderPage: (context) =>  CancelledOrderPage(),
      completedOrderPage: (context) =>  CompletedOrders(),
      accountPage: (context) => AccountPage(),
      tncPage: (context) => TncPage(),
      aboutUsPage: (context) => AboutUsPage(),
      supportPage: (context) => SupportPage(),
      loginNavigator: (context) => LoginNavigator(),
      orderMapPage: (context) => OrderMapPage(),
      viewCart: (context) => oneViewCart(),
      restviewCart: (context) => oneViewCart(),
      offers: (context) => OfferScreen(),
      locationPage: (context) => LocationPage(30.3165, 78.0322),
      instruction: (context) => instructions(),
    };
  }
}

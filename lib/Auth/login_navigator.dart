import 'package:flutter/material.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Routes/routes.dart';
import 'MobileNumber/UI/phone_number.dart';
import 'Verification/UI/verification_page.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoginRoutes {
  static const String loginRoot = 'login/';
  static const String registration = 'login/registration';
  static const String verification = 'login/verification';
  static const String homepage = 'login/home_order_account';
}

class LoginNavigator extends StatelessWidget {
  LoginNavigator({super.key});

  final GlobalKey<NavigatorState> _loginNavigatorKey =
  GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var canPop = _loginNavigatorKey.currentState!.canPop();

        if (canPop) {
          _loginNavigatorKey.currentState!.pop();
        }

        return !canPop;
      },
      child: Navigator(
        key: _loginNavigatorKey,
        initialRoute: LoginRoutes.loginRoot,
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;

          switch (settings.name) {
            case LoginRoutes.loginRoot:
              builder = (_) => PhoneNumber_New();
              return MaterialPageRoute(builder: builder, settings: settings);

            case LoginRoutes.verification:
              builder = (_) => VerificationPage(
                    () {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil(
                    PageRoutes.homeOrderAccountPage,
                        (Route<dynamic> route) => false,
                  );
                },
              );
              return MaterialPageRoute(builder: builder, settings: settings);

            case LoginRoutes.homepage:
              builder = (_) => HomeOrderAccount(0, 0);
              return MaterialPageRoute(builder: builder, settings: settings);

            default:
              builder = (_) => PhoneNumber_New();
              return MaterialPageRoute(builder: builder, settings: settings);
          }
        },
      ),
    );
  }
}
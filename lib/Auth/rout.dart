import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../Routes/routes.dart';
import 'MobileNumber/UI/phone_number.dart';
import 'Verification/UI/verification_page.dart';


class RoutePaths {
  static const String loginRoot = 'login/';
  static const String registration = 'login/registration';
  static const String verification = 'login/verification';
  static const String homepage = 'login/home_order_account';
}

// Define the route configuration class
class AppRouter {
  final GoRouter router;

  AppRouter() : router = GoRouter(
    routes: [
      GoRoute(
        path: RoutePaths.loginRoot,
        builder: (context, state) =>  PhoneNumber_New(),
      ),
      GoRoute(
        path: RoutePaths.verification,
        builder: (context, state) =>  VerificationPage(
              () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(PageRoutes.homeOrderAccountPage, (Route<dynamic> route) => false);

          },
        ),
      ),
    ],
  );
}
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?>? pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?>? push<T>(Route<T> route) {
    return navigatorKey.currentState?.push(route);
  }

  static void goBack() {
    navigatorKey.currentState?.pop();
  }

  static void pushReplacementNamed(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pushAndRemoveUntil(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(routeName, (_) => false);
  }
}

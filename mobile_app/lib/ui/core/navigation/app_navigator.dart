import 'package:flutter/material.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static Future<T?>? push<T extends Object?>(Route<T> route) {
    return navigatorKey.currentState?.push(route);
  }

  static void pop<T extends Object?>([T? result]) {
    if (navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop(result);
    }
  }
}


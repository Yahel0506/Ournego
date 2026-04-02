import 'package:flutter/material.dart';

/// Custom navigator observer that tracks the route stack.
///
/// This observer maintains a list of all routes in the navigation stack,
/// which is useful for determining navigation context (e.g., whether the
/// first route is onboarding or the main app).
///
/// Usage:
/// ```dart
/// // Access the route stack from anywhere
/// final routes = AppRouteObserver.instance.routeStack;
/// final firstRoute = routes.isNotEmpty ? routes.first : null;
///
/// // Check if first route is onboarding
/// final isFromOnboarding = firstRoute?.settings.name == '/onboarding';
/// ```
class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  // Singleton instance
  static final AppRouteObserver instance = AppRouteObserver._internal();

  AppRouteObserver._internal();

  // List of current routes in the stack
  final List<Route<dynamic>> _routeStack = [];

  /// Returns a copy of the current route stack.
  List<Route<dynamic>> get routeStack => List.unmodifiable(_routeStack);

  /// Returns the first route in the stack, or null if stack is empty.
  Route<dynamic>? get firstRoute =>
      _routeStack.isNotEmpty ? _routeStack.first : null;

  /// Returns the current (top) route in the stack, or null if stack is empty.
  Route<dynamic>? get currentRoute =>
      _routeStack.isNotEmpty ? _routeStack.last : null;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routeStack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final index = _routeStack.indexOf(oldRoute);
      if (index != -1 && newRoute != null) {
        _routeStack[index] = newRoute;
      }
    }
  }

  /// Clears the route stack (useful for testing or hard resets).
  void clear() {
    _routeStack.clear();
  }
}

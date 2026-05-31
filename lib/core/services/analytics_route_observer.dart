import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// NavigatorObserver for GoRouter that logs screen views to Firebase Analytics.
/// 
/// Automatically tracks all route changes and logs them as screen_view events.
class AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService analytics;

  AnalyticsRouteObserver(this.analytics);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleRouteChange(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _handleRouteChange(previousRoute, 'pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _handleRouteChange(newRoute, 'replace');
    }
  }

  void _handleRouteChange(Route<dynamic> route, String action) {
    // Extract route name from GoRouterState if available
    String screenName = route.settings.name ?? 'unknown';

    // Normalize screen names for consistency
    screenName = _normalizeScreenName(screenName);

    // Log screen view with route info
    analytics.logScreenView(
      screenName: screenName,
      screenClass: 'GoRoute',
    );
  }

  /// Normalize screen names for analytics.
  /// 
  /// Removes leading slashes and converts to snake_case.
  String _normalizeScreenName(String routeName) {
    // Remove leading/trailing slashes
    String normalized = routeName.replaceAll(RegExp(r'^/+|/+$'), '');

    // Replace remaining slashes with underscores
    normalized = normalized.replaceAll('/', '_');

    return normalized;
  }
}

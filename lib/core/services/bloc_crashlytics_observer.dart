import 'package:flutter_bloc/flutter_bloc.dart';

import 'analytics_service.dart';

/// A global BlocObserver that records non-fatal errors and breadcrumbs
/// to Crashlytics via `AnalyticsService`.
class BlocCrashlyticsObserver extends BlocObserver {
  final AnalyticsService analytics;

  BlocCrashlyticsObserver(this.analytics);

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    try {
      analytics.recordBreadcrumb('Bloc event: ${bloc.runtimeType} -> ${event.runtimeType}');
    } catch (_) {}
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    try {
      analytics.recordBreadcrumb(
        'Bloc change: ${bloc.runtimeType} '
        '[${change.currentState.runtimeType} → ${change.nextState.runtimeType}]',
      );
    } catch (_) {}
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    try {
      analytics.recordBreadcrumb(
        'Bloc transition: ${bloc.runtimeType} '
        '[${transition.currentState.runtimeType} '
        '--${transition.event.runtimeType}--> '
        '${transition.nextState.runtimeType}]',
      );
    } catch (_) {}
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    try {
      analytics.recordException(
        error,
        stackTrace,
        reason: 'Bloc error in ${bloc.runtimeType}',
        information: ['bloc: ${bloc.runtimeType}'],
      );
    } catch (_) {}
  }
}

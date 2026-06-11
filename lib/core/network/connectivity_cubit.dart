import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';

enum ConnectivityStatus { online, offline }

/// App-wide network status, exposed as a single root-level cubit.
///
/// Starts optimistic (`online`) so the UI never flashes "offline" on a cold
/// boot; it corrects itself the instant the first reachability check returns.
/// Radio changes are debounced before the (networked) re-check to avoid a burst
/// of pings when, e.g., switching from WiFi to mobile.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit(this._service) : super(ConnectivityStatus.online);

  final ConnectivityService _service;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;

  bool get isOffline => state == ConnectivityStatus.offline;

  /// Begin watching connectivity. Call once at startup.
  void start() {
    _check(); // initial state
    _sub = _service.onChange.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _check);
    });
  }

  /// Force an immediate re-check (e.g. a "retry" button).
  Future<void> recheck() => _check();

  Future<void> _check() async {
    final online = await _service.isOnline();
    final next =
        online ? ConnectivityStatus.online : ConnectivityStatus.offline;
    if (next != state) emit(next);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _sub?.cancel();
    return super.close();
  }
}

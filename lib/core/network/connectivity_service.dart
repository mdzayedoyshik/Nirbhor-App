import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../env/app_env.dart';

/// Wraps `connectivity_plus` with a *real* reachability check.
///
/// `connectivity_plus` only reports whether a network interface (WiFi, mobile…)
/// is up — not whether the internet actually works, nor whether OUR backend is
/// reachable. So after a radio change we confirm by pinging the backend's
/// lightweight `/health` endpoint with a short timeout. "Online" therefore means
/// "the app can actually talk to its server", which is exactly what we care
/// about for showing cached data.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, http.Client? client})
      : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client();

  final Connectivity _connectivity;
  final http.Client _client;

  static const _pingTimeout = Duration(seconds: 4);

  /// Raw interface changes. The cubit debounces these and re-checks reachability.
  Stream<List<ConnectivityResult>> get onChange =>
      _connectivity.onConnectivityChanged;

  /// True only if an interface is up AND the backend answered.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    if (_noInterface(results)) return false;
    return _canReachBackend();
  }

  bool _noInterface(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  Future<bool> _canReachBackend() async {
    final base = AppEnv.baseUrl;
    // If we can't verify (misconfig), assume online rather than blocking the UI.
    if (base.isEmpty) return true;
    try {
      // Any HTTP response means the round-trip worked → we're online.
      // Only socket errors / timeouts (caught below) mean truly offline.
      await _client.get(Uri.parse('$base/health')).timeout(_pingTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../env/app_env.dart';
import '../models/app_config_model.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  AppConfigModel? _config;
  StreamSubscription<RemoteConfigUpdate>? _realtimeSub;

  // Broadcasts whenever config is refreshed at runtime via real-time listener.
  final _updateController = StreamController<AppConfigModel>.broadcast();
  Stream<AppConfigModel> get onUpdate => _updateController.stream;

  AppConfigModel get config => _config ?? AppConfigModel.defaults();

  Future<void> initialize() async {
    try {
      final rc = FirebaseRemoteConfig.instance;

      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            AppEnv.isDev ? Duration.zero : const Duration(hours: 1),
      ));

      await rc.setDefaults({
        'app_config': jsonEncode({
          'maintenance': {'is_enabled': false, 'title': '', 'message': ''},
          'android': {
            'latest_version': '0.0.0',
            'min_version': '0.0.0',
            'is_update_enabled': false,
            'update_url': '',
            'title': '',
            'message': '',
            'changelog': [],
          },
          'ios': {
            'latest_version': '0.0.0',
            'min_version': '0.0.0',
            'is_update_enabled': false,
            'update_url': '',
            'title': '',
            'message': '',
            'changelog': [],
          },
        }),
      });

      // Apply whatever we already have (last fetch from a previous run, or the
      // defaults above) — this is LOCAL and instant, so startup never waits on
      // the network. Critical for offline launches: the app renders immediately
      // instead of stalling on the native splash until the fetch times out.
      await rc.activate();
      _loadConfig(rc);

      // Refresh from the server in the BACKGROUND; updates apply when they land.
      unawaited(_refreshInBackground(rc));

      // Real-time listener: Firebase pushes updates via persistent connection
      // the moment you publish in the console, bypassing CDN cache entirely.
      // This is how changes propagate immediately during testing and in prod
      // for users who have the app open.
      _realtimeSub = rc.onConfigUpdated.listen(
        (event) async {
          await rc.activate();
          _loadConfig(rc);
          log('[RemoteConfig] real-time update received');
          _updateController.add(config);
        },
        onError: (e) => log('[RemoteConfig] real-time error: $e'),
      );
    } catch (e, st) {
      log('[RemoteConfig] init failed, using defaults', error: e, stackTrace: st);
      _config = null;
    }
  }

  // Fetches fresh config off the startup path. Offline / timeout simply leaves
  // the cached-or-default values in place.
  Future<void> _refreshInBackground(FirebaseRemoteConfig rc) async {
    try {
      final changed = await rc.fetchAndActivate();
      if (changed) {
        _loadConfig(rc);
        _updateController.add(config);
      }
    } catch (e) {
      log('[RemoteConfig] background refresh failed (using cached/defaults): $e');
    }
  }

  void _loadConfig(FirebaseRemoteConfig rc) {
    final raw = rc.getString('app_config');
    if (raw.isNotEmpty) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _config = AppConfigModel.fromJson(json);
      log('[RemoteConfig] loaded: android=${_config!.android.latestVersion} '
          'update=${_config!.android.isUpdateEnabled} '
          'maintenance=${_config!.maintenance.isEnabled}');
    }
  }

  void dispose() {
    _realtimeSub?.cancel();
    _updateController.close();
  }
}

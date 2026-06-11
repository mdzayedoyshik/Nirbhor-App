import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A tiny key → JSON cache used for read-through offline caching.
///
/// Each entry stores the payload *and* the moment it was written, so screens
/// can show a "last updated" hint and we can expire stale data later if needed.
/// It lives behind this interface on purpose: the current implementation is
/// SharedPreferences-backed (small per-screen snapshots), but it can be swapped
/// for Hive/sqflite later without touching any repository.
abstract class CacheService {
  /// Cache [value] under [key], stamped with the current time.
  Future<void> putJson(String key, Map<String, dynamic> value);

  /// The last-cached payload for [key], or null if nothing is cached.
  Future<Map<String, dynamic>?> getJson(String key);

  /// When [key] was last written, or null if absent.
  Future<DateTime?> cachedAt(String key);

  /// Drop a single entry.
  Future<void> remove(String key);

  /// Wipe every cache entry (e.g. on logout).
  Future<void> clearAll();
}

class SharedPrefsCacheService implements CacheService {
  SharedPrefsCacheService();

  static const _prefix = 'cache_';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _k(String key) => '$_prefix$key';

  @override
  Future<void> putJson(String key, Map<String, dynamic> value) async {
    final sp = await _sp;
    final envelope = jsonEncode({
      't': DateTime.now().millisecondsSinceEpoch,
      'v': value,
    });
    await sp.setString(_k(key), envelope);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final env = await _readEnvelope(key);
    return env?['v'] as Map<String, dynamic>?;
  }

  @override
  Future<DateTime?> cachedAt(String key) async {
    final env = await _readEnvelope(key);
    final t = env?['t'] as int?;
    return t == null ? null : DateTime.fromMillisecondsSinceEpoch(t);
  }

  Future<Map<String, dynamic>?> _readEnvelope(String key) async {
    final sp = await _sp;
    final raw = sp.getString(_k(key));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupt/legacy entry — drop it so it can be rebuilt cleanly.
      await sp.remove(_k(key));
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    final sp = await _sp;
    await sp.remove(_k(key));
  }

  @override
  Future<void> clearAll() async {
    final sp = await _sp;
    final keys = sp.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await sp.remove(k);
    }
  }
}

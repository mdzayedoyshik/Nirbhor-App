import '../errors/exceptions.dart';
import 'cache_service.dart';

/// Read-through cache wrapper for a single GET.
///
/// Behaviour ("remote-first, fall back to cache"):
///   1. Try the network. On success, cache the raw response and return it parsed.
///   2. On [NetworkException] (no internet / backend unreachable), return the
///      last-cached response parsed the same way — so the user sees their last
///      known data instead of an error.
///   3. If nothing is cached yet, the [NetworkException] propagates (genuine
///      "no data + offline" → the screen shows its normal error/empty state).
///
/// Only [NetworkException] triggers the fallback. A [ServerException] (e.g. 403,
/// 404, validation) is a real answer from the server and must NOT be masked by
/// stale cache, so it propagates untouched.
///
/// We cache the *raw* response Map and re-run the existing `fromJson` on it, so
/// no model needs a `toJson`.
Future<T> cacheable<T>({
  required CacheService cache,
  required String key,
  required Future<Map<String, dynamic>> Function() fetchRaw,
  required T Function(Map<String, dynamic>) parse,
}) async {
  try {
    final response = await fetchRaw();
    await cache.putJson(key, response);
    return parse(response);
  } on NetworkException {
    final cached = await cache.getJson(key);
    if (cached != null) return parse(cached);
    rethrow;
  }
}

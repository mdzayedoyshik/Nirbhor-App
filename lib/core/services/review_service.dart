import 'package:shared_preferences/shared_preferences.dart';

/// Decides *when* to ask the user for an app review, and remembers the outcome.
///
/// Mirrors [OnboardingService]'s singleton + SharedPreferences style. It holds
/// no UI — the presentation layer asks [shouldPrompt] and then drives the
/// pre-prompt dialog.
///
/// Trigger philosophy (industry standard): don't nag on day one mid-task. Only
/// ask once the user has spent real time in the app, opened it a few times,
/// across a few days — and then only occasionally, with a hard cap.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  // ── Tunable thresholds ──────────────────────────────────────────────────────
  /// Minimum cumulative foreground time before we ever ask (~15 minutes).
  static const int _minUsageSeconds = 15 * 60;

  /// Minimum number of app opens.
  static const int _minLaunches = 3;

  /// Minimum age of the install before the first ask.
  static const Duration _minAge = Duration(days: 2);

  /// Quiet period between asks if the user dismissed without acting.
  static const Duration _cooldown = Duration(days: 12);

  /// Hard cap on how many times we ever ask. After this we stop forever.
  static const int _maxPrompts = 3;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kFirstLaunch = 'review_first_launch_ms';
  static const _kLaunchCount = 'review_launch_count';
  static const _kUsageSeconds = 'review_usage_seconds';
  static const _kLastPrompt = 'review_last_prompt_ms';
  static const _kPromptCount = 'review_prompt_count';
  static const _kDone = 'review_done';

  /// Record an app open. Call once per cold start (when authenticated).
  Future<void> recordLaunch() async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_kFirstLaunch)) {
      await p.setInt(_kFirstLaunch, DateTime.now().millisecondsSinceEpoch);
    }
    await p.setInt(_kLaunchCount, (p.getInt(_kLaunchCount) ?? 0) + 1);
  }

  /// Add foreground time. Called when the app is backgrounded.
  Future<void> addUsage(Duration delta) async {
    if (delta.inSeconds <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kUsageSeconds, (p.getInt(_kUsageSeconds) ?? 0) + delta.inSeconds);
  }

  /// Whether the moment is right to show the pre-prompt.
  Future<bool> shouldPrompt() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kDone) ?? false) return false;

    final promptCount = p.getInt(_kPromptCount) ?? 0;
    if (promptCount >= _maxPrompts) return false;

    final usage = p.getInt(_kUsageSeconds) ?? 0;
    if (usage < _minUsageSeconds) return false;

    final launches = p.getInt(_kLaunchCount) ?? 0;
    if (launches < _minLaunches) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final firstLaunch = p.getInt(_kFirstLaunch) ?? now;
    if (now - firstLaunch < _minAge.inMilliseconds) return false;

    final lastPrompt = p.getInt(_kLastPrompt) ?? 0;
    if (lastPrompt != 0 && now - lastPrompt < _cooldown.inMilliseconds) {
      return false;
    }
    return true;
  }

  /// Record that we showed a prompt (starts the cooldown, counts toward the cap).
  Future<void> markPrompted() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastPrompt, DateTime.now().millisecondsSinceEpoch);
    await p.setInt(_kPromptCount, (p.getInt(_kPromptCount) ?? 0) + 1);
  }

  /// Stop asking forever — the user rated, sent feedback, or said "don't ask".
  Future<void> markDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDone, true);
  }
}

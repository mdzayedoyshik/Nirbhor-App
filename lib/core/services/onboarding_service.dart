import 'package:shared_preferences/shared_preferences.dart';

/// Manages first-launch onboarding state and per-flat Getting Started
/// checklist progress — all persisted via SharedPreferences.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _seenKey = 'has_seen_onboarding';

  static String _stepKey(String flatId, String userId, String stepId) =>
      'gs_${flatId}_${userId}_$stepId';

  static String _dismissedKey(String flatId, String userId) =>
      'gs_${flatId}_${userId}_dismissed';

  // ── Onboarding slides ─────────────────────────────────────────────────────

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  // ── Getting Started checklist ─────────────────────────────────────────────

  Future<bool> isStepDone(
      String flatId, String userId, String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stepKey(flatId, userId, stepId)) ?? false;
  }

  Future<void> markStepDone(
      String flatId, String userId, String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stepKey(flatId, userId, stepId), true);
  }

  Future<Set<String>> completedSteps(
      String flatId, String userId, List<String> allIds) async {
    final prefs = await SharedPreferences.getInstance();
    return allIds
        .where((id) => prefs.getBool(_stepKey(flatId, userId, id)) ?? false)
        .toSet();
  }

  Future<bool> isDismissed(String flatId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey(flatId, userId)) ?? false;
  }

  Future<void> dismiss(String flatId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey(flatId, userId), true);
  }
}

import 'package:equatable/equatable.dart';
import 'package:timezone/timezone.dart' as tz;

class MealConfigEntity extends Equatable {
  const MealConfigEntity({
    required this.id,
    required this.flatId,
    required this.breakfastPoints,
    required this.lunchPoints,
    required this.dinnerPoints,
    required this.lockTimeBreakfast,
    required this.lockTimeLunch,
    required this.lockTimeDinner,
    required this.flatTimezone,
  });

  final String id;
  final String flatId;
  final double breakfastPoints;
  final double lunchPoints;
  final double dinnerPoints;
  final String lockTimeBreakfast; // flat-local HH:MM
  final String lockTimeLunch; // flat-local HH:MM
  final String lockTimeDinner; // flat-local HH:MM
  final String flatTimezone; // IANA timezone name for this flat

  /// Returns true if the flat-local lock time for [shift] has passed for today.
  /// Lock times are stored as flat-local "HH:MM" strings on the backend and
  /// compared against the flat's wall-clock time (not UTC, not device local).
  bool isLocked(String shift) {
    final lockTime = _lockTime(shift);
    if (lockTime == null) return false;
    final parts = lockTime.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    try {
      final location = tz.getLocation(flatTimezone);
      final nowLocal = tz.TZDateTime.now(location);
      return nowLocal.hour > h || (nowLocal.hour == h && nowLocal.minute >= m);
    } catch (_) {
      // Fallback: use device local time (wrong timezone but better than UTC)
      final now = DateTime.now();
      return now.hour > h || (now.hour == h && now.minute >= m);
    }
  }

  String? _lockTime(String shift) => switch (shift) {
        'breakfast' => lockTimeBreakfast,
        'lunch' => lockTimeLunch,
        'dinner' => lockTimeDinner,
        _ => null,
      };

  double pointsFor(String shift) => switch (shift) {
        'breakfast' => breakfastPoints,
        'lunch' => lunchPoints,
        'dinner' => dinnerPoints,
        _ => 0,
      };

  @override
  List<Object?> get props => [
        id,
        flatId,
        breakfastPoints,
        lunchPoints,
        dinnerPoints,
        lockTimeBreakfast,
        lockTimeLunch,
        lockTimeDinner,
        flatTimezone,
      ];
}

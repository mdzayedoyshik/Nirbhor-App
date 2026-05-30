import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String flatId;
  final double breakfastPoints;
  final double lunchPoints;
  final double dinnerPoints;
  final String lockTimeBreakfast; // "HH:MM" local time
  final String lockTimeLunch;
  final String lockTimeDinner;

  /// Returns true if the local lock time for [shift] has passed for today.
  bool isLocked(String shift) {
    final lockTime = _lockTime(shift);
    if (lockTime == null) return false;
    final parts = lockTime.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now(); // local time — lock times are set in local time
    return now.hour > h || (now.hour == h && now.minute >= m);
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
      ];
}

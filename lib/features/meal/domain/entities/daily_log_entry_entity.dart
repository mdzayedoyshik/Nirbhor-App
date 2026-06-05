import 'package:equatable/equatable.dart';

class ShiftCountEntity extends Equatable {
  const ShiftCountEntity({
    required this.members,
    required this.guests,
    required this.totalServings,
  });

  final int members;
  final int guests;
  final int totalServings;

  @override
  List<Object?> get props => [members, guests, totalServings];
}

class ShiftTotalsEntity extends Equatable {
  const ShiftTotalsEntity({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final ShiftCountEntity breakfast;
  final ShiftCountEntity lunch;
  final ShiftCountEntity dinner;

  ShiftCountEntity forShift(String shift) => switch (shift) {
        'breakfast' => breakfast,
        'lunch' => lunch,
        'dinner' => dinner,
        _ => const ShiftCountEntity(members: 0, guests: 0, totalServings: 0),
      };

  @override
  List<Object?> get props => [breakfast, lunch, dinner];
}

class DailyLogEntryEntity extends Equatable {
  const DailyLogEntryEntity({
    this.id,
    required this.flatMemberId,
    required this.memberName,
    this.photoUrl,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.breakfastGuests,
    required this.lunchGuests,
    required this.dinnerGuests,
    required this.totalPoints,
    required this.isPreferenceBased,
  });

  final String? id; // null if preference-based (no real log yet)
  final String flatMemberId;
  final String memberName;
  final String? photoUrl;
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final int breakfastGuests;
  final int lunchGuests;
  final int dinnerGuests;
  final double totalPoints;
  final bool isPreferenceBased;

  bool shiftEnabled(String shift) => switch (shift) {
        'breakfast' => breakfast,
        'lunch' => lunch,
        'dinner' => dinner,
        _ => false,
      };

  int guestsFor(String shift) => switch (shift) {
        'breakfast' => breakfastGuests,
        'lunch' => lunchGuests,
        'dinner' => dinnerGuests,
        _ => 0,
      };

  @override
  List<Object?> get props => [
        id,
        flatMemberId,
        memberName,
        photoUrl,
        breakfast,
        lunch,
        dinner,
        breakfastGuests,
        lunchGuests,
        dinnerGuests,
        totalPoints,
        isPreferenceBased,
      ];
}

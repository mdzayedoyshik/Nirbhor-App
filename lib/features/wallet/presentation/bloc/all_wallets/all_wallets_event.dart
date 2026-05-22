import 'package:equatable/equatable.dart';

abstract class AllWalletsEvent extends Equatable {
  const AllWalletsEvent();
}

class AllWalletsLoadRequested extends AllWalletsEvent {
  const AllWalletsLoadRequested(this.flatId);
  final String flatId;
  @override
  List<Object?> get props => [flatId];
}

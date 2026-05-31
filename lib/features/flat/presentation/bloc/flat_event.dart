part of 'flat_bloc.dart';

abstract class FlatEvent extends Equatable {
  const FlatEvent();
  @override
  List<Object?> get props => [];
}

class FlatCheckRequested extends FlatEvent {
  final String? userId;
  const FlatCheckRequested({this.userId});
  @override
  List<Object?> get props => [userId];
}

class FlatRefreshRequested extends FlatEvent {
  final String flatId;
  const FlatRefreshRequested(this.flatId);
  @override
  List<Object?> get props => [flatId];
}

class FlatCreateRequested extends FlatEvent {
  final String name;
  final String? address;
  final String? photoUrl;

  const FlatCreateRequested({required this.name, this.address, this.photoUrl});

  @override
  List<Object?> get props => [name, address, photoUrl];
}

class FlatUpdateRequested extends FlatEvent {
  final String flatId;
  final String? name;
  final String? address;
  final String? photoUrl;

  const FlatUpdateRequested({
    required this.flatId,
    this.name,
    this.address,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [flatId, name, address, photoUrl];
}

class FlatDeleteRequested extends FlatEvent {
  final String flatId;
  const FlatDeleteRequested(this.flatId);
  @override
  List<Object?> get props => [flatId];
}

class FlatJoinRequested extends FlatEvent {
  final String joinCode;
  const FlatJoinRequested(this.joinCode);
  @override
  List<Object?> get props => [joinCode];
}

class FlatCancelRequestRequested extends FlatEvent {
  final String requestId;
  const FlatCancelRequestRequested(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

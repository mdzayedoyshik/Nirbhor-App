import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileFetchRequested extends ProfileEvent {
  const ProfileFetchRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  final String name;
  final String? avatarUrl;

  const ProfileUpdateRequested({required this.name, this.avatarUrl});

  @override
  List<Object?> get props => [name, avatarUrl];
}

class ProfilePasswordChangeRequested extends ProfileEvent {
  final String oldPassword;
  final String newPassword;

  const ProfilePasswordChangeRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

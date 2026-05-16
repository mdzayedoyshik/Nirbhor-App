part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileUpdated extends ProfileState {
  final UserEntity user;
  const ProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

class PasswordChanged extends ProfileState {
  const PasswordChanged();
}

class ProfileFailure extends ProfileState {
  final String message;
  const ProfileFailure(this.message);
  @override
  List<Object?> get props => [message];
}

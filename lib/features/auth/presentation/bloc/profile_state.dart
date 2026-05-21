import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

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

/// Profile data loaded — stable view state.
class ProfileLoaded extends ProfileState {
  final UserEntity user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

/// An action (update/changePassword) is in progress; user data stays visible.
class ProfileActionLoading extends ProfileState {
  final UserEntity user;

  const ProfileActionLoading(this.user);

  @override
  List<Object?> get props => [user];
}

/// Profile update succeeded — listener shows snackbar, then bloc emits ProfileLoaded.
class ProfileUpdateSuccess extends ProfileState {
  final UserEntity user;

  const ProfileUpdateSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// Password changed — listener pops page, then bloc emits ProfileLoaded.
class ProfilePasswordChangeSuccess extends ProfileState {
  const ProfilePasswordChangeSuccess();
}

/// Initial profile load failed — show error screen with retry.
class ProfileLoadError extends ProfileState {
  final String message;

  const ProfileLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Action failed — listener shows snackbar; user data retained for display.
class ProfileActionError extends ProfileState {
  final UserEntity user;
  final String message;

  const ProfileActionError({required this.user, required this.message});

  @override
  List<Object?> get props => [user, message];
}

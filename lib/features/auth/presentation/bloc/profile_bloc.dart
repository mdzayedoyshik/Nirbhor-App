import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

export 'profile_event.dart';
export 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final ChangePasswordUseCase _changePassword;

  ProfileBloc({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required ChangePasswordUseCase changePassword,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _changePassword = changePassword,
        super(const ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetch);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfilePasswordChangeRequested>(_onChangePassword);
  }

  Future<void> _onFetch(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await _getProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileLoadError(_message(e)));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final user = _currentUser;
    if (user == null) return;
    emit(ProfileActionLoading(user));
    try {
      final updated = await _updateProfile(
        name: event.name,
        avatarUrl: event.avatarUrl,
      );
      emit(ProfileUpdateSuccess(updated));
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileActionError(user: user, message: _message(e)));
      emit(ProfileLoaded(user));
    }
  }

  Future<void> _onChangePassword(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final user = _currentUser;
    if (user == null) return;
    emit(ProfileActionLoading(user));
    try {
      await _changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(const ProfilePasswordChangeSuccess());
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileActionError(user: user, message: _message(e)));
      emit(ProfileLoaded(user));
    }
  }

  UserEntity? get _currentUser {
    final s = state;
    if (s is ProfileLoaded) return s.user;
    if (s is ProfileActionLoading) return s.user;
    if (s is ProfileUpdateSuccess) return s.user;
    if (s is ProfileActionError) return s.user;
    return null;
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}

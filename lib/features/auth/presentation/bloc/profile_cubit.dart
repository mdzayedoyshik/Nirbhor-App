import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final ChangePasswordUseCase _changePassword;

  ProfileCubit({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required ChangePasswordUseCase changePassword,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        _changePassword = changePassword,
        super(const ProfileInitial());

  Future<void> fetchProfile() async {
    emit(const ProfileLoading());
    try {
      final user = await _getProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileFailure(_message(e)));
    }
  }

  Future<void> updateProfile({required String name, String? avatarUrl}) async {
    emit(const ProfileLoading());
    try {
      final user = await _updateProfile(name: name, avatarUrl: avatarUrl);
      emit(ProfileUpdated(user));
    } catch (e) {
      emit(ProfileFailure(_message(e)));
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    emit(const ProfileLoading());
    try {
      await _changePassword(oldPassword: oldPassword, newPassword: newPassword);
      emit(const PasswordChanged());
    } catch (e) {
      emit(ProfileFailure(_message(e)));
    }
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}

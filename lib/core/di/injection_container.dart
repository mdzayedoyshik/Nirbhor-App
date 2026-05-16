import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../services/device_token_service.dart';
import '../services/token_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/check_email_usecase.dart';
import '../../features/auth/domain/usecases/complete_setup_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/google_auth_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/send_device_token_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/profile_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Core
  sl.registerLazySingleton(() => TokenService(storage: sl()));
  sl.registerLazySingleton(() => ApiClient(client: sl(), tokenService: sl()));
  sl.registerLazySingleton(() => DeviceTokenService());

  // Data
  sl.registerLazySingleton(
    () => AuthRemoteDataSource(apiClient: sl(), tokenService: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CheckEmailUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => CompleteSetupUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GoogleAuthUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => SendDeviceTokenUseCase(sl()));

  // Blocs (singletons — app-global state, live for the entire app lifetime)
  sl.registerLazySingleton(
    () => AuthBloc(
      checkEmail: sl(),
      verifyOtp: sl(),
      login: sl(),
      completeSetup: sl(),
      forgotPassword: sl(),
      resetPassword: sl(),
      googleAuth: sl(),
      logout: sl(),
      getProfile: sl(),
      sendDeviceToken: sl(),
      deviceTokenService: sl(),
      tokenService: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => ProfileCubit(
      getProfile: sl(),
      updateProfile: sl(),
      changePassword: sl(),
    ),
  );
}

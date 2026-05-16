import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

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
import '../../features/flat/data/datasources/flat_remote_datasource.dart';
import '../../features/flat/data/repositories/flat_repository_impl.dart';
import '../../features/flat/domain/repositories/flat_repository.dart';
import '../../features/flat/domain/usecases/add_fixed_expense_usecase.dart';
import '../../features/flat/domain/usecases/approve_join_request_usecase.dart';
import '../../features/flat/domain/usecases/cancel_join_request_usecase.dart';
import '../../features/flat/domain/usecases/create_flat_usecase.dart';
import '../../features/flat/domain/usecases/decline_join_request_usecase.dart';
import '../../features/flat/domain/usecases/delete_fixed_expense_usecase.dart';
import '../../features/flat/domain/usecases/delete_flat_usecase.dart';
import '../../features/flat/domain/usecases/get_fixed_expenses_usecase.dart';
import '../../features/flat/domain/usecases/get_join_requests_usecase.dart';
import '../../features/flat/domain/usecases/get_my_flat_usecase.dart';
import '../../features/flat/domain/usecases/get_my_requests_usecase.dart';
import '../../features/flat/domain/usecases/preview_flat_usecase.dart';
import '../../features/flat/domain/usecases/redistribute_usecase.dart';
import '../../features/flat/domain/usecases/send_join_request_usecase.dart';
import '../../features/flat/domain/usecases/update_fixed_expense_usecase.dart';
import '../../features/flat/domain/usecases/update_flat_usecase.dart';
import '../../features/flat/presentation/bloc/flat_bloc.dart';
import '../../features/flat/presentation/cubit/fixed_expenses_cubit.dart';
import '../../features/flat/presentation/cubit/flat_preview_cubit.dart';
import '../../features/flat/presentation/cubit/join_requests_cubit.dart';
import '../network/api_client.dart';
import '../services/device_token_service.dart';
import '../services/image_upload_service.dart';
import '../services/token_service.dart';

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
  sl.registerLazySingleton(() => ImageUploadService(apiClient: sl()));

  // ── Auth ──────────────────────────────────────────────
  sl.registerLazySingleton(
    () => AuthRemoteDataSource(apiClient: sl(), tokenService: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );
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

  // ── Flat ──────────────────────────────────────────────
  sl.registerLazySingleton(() => FlatRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<FlatRepository>(
    () => FlatRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetMyFlatUseCase(sl()));
  sl.registerLazySingleton(() => CreateFlatUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFlatUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFlatUseCase(sl()));
  sl.registerLazySingleton(() => PreviewFlatUseCase(sl()));
  sl.registerLazySingleton(() => SendJoinRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetMyRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CancelJoinRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetJoinRequestsUseCase(sl()));
  sl.registerLazySingleton(() => ApproveJoinRequestUseCase(sl()));
  sl.registerLazySingleton(() => DeclineJoinRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetFixedExpensesUseCase(sl()));
  sl.registerLazySingleton(() => AddFixedExpenseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFixedExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFixedExpenseUseCase(sl()));
  sl.registerLazySingleton(() => RedistributeUseCase(sl()));

  // Flat blocs — global singletons
  sl.registerLazySingleton(
    () => FlatBloc(
      getMyFlat: sl(),
      createFlat: sl(),
      updateFlat: sl(),
      deleteFlat: sl(),
      sendJoinRequest: sl(),
      getMyRequests: sl(),
      cancelJoinRequest: sl(),
    ),
  );

  // Flat cubits — factories (new instance per usage)
  sl.registerFactory(() => FlatPreviewCubit(preview: sl()));
  sl.registerFactory(
    () =>
        JoinRequestsCubit(getJoinRequests: sl(), approve: sl(), decline: sl()),
  );
  sl.registerFactory(
    () => FixedExpensesCubit(
      getExpenses: sl(),
      addExpense: sl(),
      updateExpense: sl(),
      deleteExpense: sl(),
      redistribute: sl(),
    ),
  );
}

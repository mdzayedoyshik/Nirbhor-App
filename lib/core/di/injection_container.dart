import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/set_password_usecase.dart';
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
import '../../features/auth/presentation/bloc/profile_bloc.dart';
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
import '../../features/flat/presentation/bloc/fixed_expenses_bloc.dart';
import '../../features/flat/presentation/bloc/flat_bloc.dart';
import '../../features/flat/presentation/bloc/flat_preview_bloc.dart';
import '../../features/flat/presentation/bloc/join_requests_bloc.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/cancel_payment_request_usecase.dart';
import '../../features/wallet/domain/usecases/create_payment_request_usecase.dart';
import '../../features/wallet/domain/usecases/get_all_wallets_usecase.dart';
import '../../features/wallet/domain/usecases/get_flat_wallet_usecase.dart';
import '../../features/wallet/domain/usecases/get_payment_hints_usecase.dart';
import '../../features/wallet/domain/usecases/get_payment_requests_usecase.dart';
import '../../features/wallet/domain/usecases/get_payments_usecase.dart';
import '../../features/wallet/domain/usecases/get_transactions_usecase.dart';
import '../../features/wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../features/wallet/domain/usecases/reject_payment_usecase.dart';
import '../../features/wallet/domain/usecases/submit_payment_usecase.dart';
import '../../features/wallet/domain/usecases/update_payment_hints_usecase.dart';
import '../../features/wallet/domain/usecases/verify_payment_usecase.dart';
import '../../features/wallet/presentation/bloc/all_wallets/all_wallets_bloc.dart';
import '../../features/wallet/presentation/bloc/payment_hints/payment_hints_bloc.dart';
import '../../features/wallet/presentation/bloc/payment_requests/payment_requests_bloc.dart';
import '../../features/wallet/presentation/bloc/payments/payments_bloc.dart';
import '../../features/wallet/presentation/bloc/transactions/transactions_bloc.dart';
import '../../features/wallet/presentation/bloc/wallet/wallet_bloc.dart';
import '../../features/member/data/datasources/member_remote_datasource.dart';
import '../../features/member/data/repositories/member_repository_impl.dart';
import '../../features/member/domain/repositories/member_repository.dart';
import '../../features/member/domain/usecases/acknowledge_exit_usecase.dart';
import '../../features/member/domain/usecases/cancel_exit_usecase.dart';
import '../../features/member/domain/usecases/change_role_usecase.dart';
import '../../features/member/domain/usecases/finalize_exit_usecase.dart';
import '../../features/member/domain/usecases/get_exit_status_usecase.dart';
import '../../features/member/domain/usecases/get_members_usecase.dart';
import '../../features/member/domain/usecases/get_pending_exits_usecase.dart';
import '../../features/member/domain/usecases/get_settlement_usecase.dart';
import '../../features/member/domain/usecases/initiate_exit_usecase.dart';
import '../../features/member/domain/usecases/transfer_manager_usecase.dart';
import '../../features/member/presentation/bloc/member_bloc.dart';
import '../../features/expense/data/datasources/expense_remote_datasource.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/domain/usecases/approve_expense_usecase.dart';
import '../../features/expense/domain/usecases/delete_expense_usecase.dart';
import '../../features/expense/domain/usecases/get_expense_detail_usecase.dart';
import '../../features/expense/domain/usecases/get_expense_summary_usecase.dart';
import '../../features/expense/domain/usecases/get_expenses_usecase.dart';
import '../../features/expense/domain/usecases/record_expense_usecase.dart';
import '../../features/expense/domain/usecases/update_expense_usecase.dart';
import '../../features/expense/presentation/bloc/expense_bloc.dart';
import '../../features/meal/data/datasources/meal_remote_datasource.dart';
import '../../features/meal/data/repositories/meal_repository_impl.dart';
import '../../features/meal/domain/repositories/meal_repository.dart';
import '../../features/meal/domain/usecases/get_daily_meal_logs_usecase.dart';
import '../../features/meal/domain/usecases/get_meal_config_usecase.dart';
import '../../features/meal/domain/usecases/get_meal_pool_usecase.dart';
import '../../features/meal/domain/usecases/get_meal_preferences_usecase.dart';
import '../../features/meal/domain/usecases/get_meal_toggle_usecase.dart';
import '../../features/meal/domain/usecases/manager_edit_meal_log_usecase.dart';
import '../../features/meal/domain/usecases/set_meal_toggle_usecase.dart';
import '../../features/meal/domain/usecases/update_meal_config_usecase.dart';
import '../../features/meal/domain/usecases/update_meal_preferences_usecase.dart';
import '../../features/meal/domain/usecases/update_own_meal_log_usecase.dart';
import '../../features/meal/presentation/bloc/meal_bloc.dart';
import '../../features/meal/presentation/bloc/meal_pool_bloc.dart';
import '../../features/meal/presentation/bloc/meal_prefs_bloc.dart';
import '../../features/summary/data/datasources/summary_remote_datasource.dart';
import '../../features/summary/data/repositories/summary_repository_impl.dart';
import '../../features/summary/domain/repositories/summary_repository.dart';
import '../../features/summary/domain/usecases/close_month_usecase.dart';
import '../../features/summary/domain/usecases/get_close_preview_usecase.dart';
import '../../features/summary/domain/usecases/get_closed_months_usecase.dart';
import '../../features/summary/domain/usecases/get_monthly_summary_usecase.dart';
import '../../features/summary/presentation/bloc/summary_bloc.dart';
import '../../features/complaint/data/datasources/complaint_remote_datasource.dart';
import '../../features/complaint/data/repositories/complaint_repository_impl.dart';
import '../../features/complaint/domain/repositories/complaint_repository.dart';
import '../../features/complaint/domain/usecases/delete_complaint_usecase.dart';
import '../../features/complaint/domain/usecases/edit_complaint_usecase.dart';
import '../../features/complaint/domain/usecases/get_complaint_usecase.dart';
import '../../features/complaint/domain/usecases/get_complaints_usecase.dart';
import '../../features/complaint/domain/usecases/raise_complaint_usecase.dart';
import '../../features/complaint/domain/usecases/update_complaint_status_usecase.dart';
import '../../features/complaint/presentation/bloc/complaint_bloc.dart';
import '../../features/task/data/datasources/task_remote_datasource.dart';
import '../../features/task/data/repositories/task_repository_impl.dart';
import '../../features/task/domain/repositories/task_repository.dart';
import '../../features/task/domain/usecases/add_sub_task_usecase.dart';
import '../../features/task/domain/usecases/create_task_usecase.dart';
import '../../features/task/domain/usecases/delete_sub_task_usecase.dart';
import '../../features/task/domain/usecases/delete_task_usecase.dart';
import '../../features/task/domain/usecases/get_task_usecase.dart';
import '../../features/task/domain/usecases/get_tasks_usecase.dart';
import '../../features/task/domain/usecases/update_sub_task_usecase.dart';
import '../../features/task/domain/usecases/update_task_usecase.dart';
import '../../features/task/presentation/bloc/task_bloc.dart';
import '../../features/audit_log/data/datasources/audit_log_remote_datasource.dart';
import '../../features/audit_log/data/repositories/audit_log_repository_impl.dart';
import '../../features/audit_log/domain/repositories/audit_log_repository.dart';
import '../../features/audit_log/domain/usecases/get_audit_log_usecase.dart';
import '../../features/audit_log/domain/usecases/get_audit_logs_usecase.dart';
import '../../features/audit_log/presentation/bloc/audit_log_bloc.dart';
import '../../features/notification/data/datasources/notification_remote_datasource.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/domain/usecases/delete_notification_usecase.dart';
import '../../features/notification/domain/usecases/get_notifications_usecase.dart';
import '../../features/notification/domain/usecases/get_unread_count_usecase.dart';
import '../../features/notification/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notification/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
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
  sl.registerLazySingleton(() => SetPasswordUseCase(sl()));
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
    () => ProfileBloc(
      getProfile: sl(),
      updateProfile: sl(),
      changePassword: sl(),
      setPassword: sl(),
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
      getExitStatus: sl(),
    ),
  );

  // Flat blocs — factories (new instance per page visit)
  sl.registerFactory(() => FlatPreviewBloc(preview: sl()));
  // Singleton so badge + pending-section on home always reflects live state;
  // use BlocProvider.value everywhere to avoid closing the shared instance.
  sl.registerLazySingleton(
    () => JoinRequestsBloc(
      getJoinRequests: sl(),
      approve: sl(),
      decline: sl(),
    ),
  );
  sl.registerFactory(
    () => FixedExpensesBloc(
      getExpenses: sl(),
      addExpense: sl(),
      updateExpense: sl(),
      deleteExpense: sl(),
      redistribute: sl(),
    ),
  );

  // ── Wallet ────────────────────────────────────────────
  sl.registerLazySingleton(() => WalletRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetWalletSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetAllWalletsUseCase(sl()));
  sl.registerLazySingleton(() => GetFlatWalletUseCase(sl()));
  sl.registerLazySingleton(() => SubmitPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePaymentRequestUseCase(sl()));
  sl.registerLazySingleton(() => CancelPaymentRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentsUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPaymentUseCase(sl()));
  sl.registerLazySingleton(() => RejectPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentHintsUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePaymentHintsUseCase(sl()));

  // Wallet bloc — global singleton
  sl.registerLazySingleton(
    () => WalletBloc(
      getWalletSummary: sl(),
      getFlatWallet: sl(),
      submitPayment: sl(),
    ),
  );

  // Wallet blocs — factories (new instance per page)
  sl.registerFactory(() => AllWalletsBloc(getAllWallets: sl()));
  sl.registerFactory(
    () => PaymentsBloc(
      getPayments: sl(),
      verifyPayment: sl(),
      rejectPayment: sl(),
    ),
  );
  sl.registerFactory(
    () => PaymentRequestsBloc(
      getPaymentRequests: sl(),
      createPaymentRequest: sl(),
      cancelPaymentRequest: sl(),
    ),
  );
  sl.registerFactory(() => TransactionsBloc(getTransactions: sl()));
  sl.registerFactory(
    () => PaymentHintsBloc(
      getPaymentHints: sl(),
      updatePaymentHints: sl(),
    ),
  );

  // ── Expense ───────────────────────────────────────────
  sl.registerLazySingleton(
      () => ExpenseRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetExpenseDetailUseCase(sl()));
  sl.registerLazySingleton(() => RecordExpenseUseCase(sl()));
  sl.registerLazySingleton(() => ApproveExpenseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));

  // Expense bloc — factory (new instance per page visit)
  sl.registerFactory(
    () => ExpenseBloc(
      getExpenses: sl(),
      getExpenseSummary: sl(),
      getExpenseDetail: sl(),
      recordExpense: sl(),
      approveExpense: sl(),
      updateExpense: sl(),
      deleteExpense: sl(),
    ),
  );

  // ── Member ────────────────────────────────────────────
  sl.registerLazySingleton(() => MemberRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<MemberRepository>(
    () => MemberRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetMembersUseCase(sl()));
  sl.registerLazySingleton(() => ChangeRoleUseCase(sl()));
  sl.registerLazySingleton(() => TransferManagerUseCase(sl()));
  sl.registerLazySingleton(() => InitiateExitUseCase(sl()));
  sl.registerLazySingleton(() => GetSettlementUseCase(sl()));
  sl.registerLazySingleton(() => FinalizeExitUseCase(sl()));
  sl.registerLazySingleton(() => CancelExitUseCase(sl()));
  sl.registerLazySingleton(() => GetExitStatusUseCase(sl()));
  sl.registerLazySingleton(() => AcknowledgeExitUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingExitsUseCase(sl()));

  // Member bloc — factory (new instance per page visit)
  sl.registerFactory(
    () => MemberBloc(
      getMembers: sl(),
      changeRole: sl(),
      transferManager: sl(),
      initiateExit: sl(),
      getSettlement: sl(),
    ),
  );

  // ── Meal ──────────────────────────────────────────────
  sl.registerLazySingleton(() => MealRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetMealConfigUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMealConfigUseCase(sl()));
  sl.registerLazySingleton(() => GetMealToggleUseCase(sl()));
  sl.registerLazySingleton(() => SetMealToggleUseCase(sl()));
  sl.registerLazySingleton(() => GetMealPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMealPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => GetDailyMealLogsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOwnMealLogUseCase(sl()));
  sl.registerLazySingleton(() => ManagerEditMealLogUseCase(sl()));
  sl.registerLazySingleton(() => GetMealPoolUseCase(sl()));

  // Meal blocs — factories (new instance per page visit)
  sl.registerFactory(
    () => MealBloc(
      getConfig: sl(),
      updateConfig: sl(),
      getDailyLogs: sl(),
      updateOwnLog: sl(),
      managerEdit: sl(),
      setToggle: sl(),
    ),
  );
  sl.registerFactory(() => MealPoolBloc(getPool: sl()));
  sl.registerFactory(
    () => MealPrefsBloc(getPrefs: sl(), updatePrefs: sl()),
  );

  // ── Summary ───────────────────────────────────────────
  sl.registerLazySingleton(() => SummaryRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<SummaryRepository>(
    () => SummaryRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetMonthlySummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetClosePreviewUseCase(sl()));
  sl.registerLazySingleton(() => CloseMonthUseCase(sl()));
  sl.registerLazySingleton(() => GetClosedMonthsUseCase(sl()));

  // ── Task ──────────────────────────────────────────────
  sl.registerLazySingleton(() => TaskRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => GetTaskUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => AddSubTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSubTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSubTaskUseCase(sl()));

  sl.registerFactory(
    () => TaskBloc(
      getTasks: sl(),
      getTask: sl(),
      createTask: sl(),
      updateTask: sl(),
      deleteTask: sl(),
      addSubTask: sl(),
      updateSubTask: sl(),
      deleteSubTask: sl(),
    ),
  );

  // ── Complaint ─────────────────────────────────────────
  sl.registerLazySingleton(
      () => ComplaintRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<ComplaintRepository>(
    () => ComplaintRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetComplaintsUseCase(sl()));
  sl.registerLazySingleton(() => GetComplaintUseCase(sl()));
  sl.registerLazySingleton(() => RaiseComplaintUseCase(sl()));
  sl.registerLazySingleton(() => UpdateComplaintStatusUseCase(sl()));
  sl.registerLazySingleton(() => EditComplaintUseCase(sl()));
  sl.registerLazySingleton(() => DeleteComplaintUseCase(sl()));

  sl.registerFactory(
    () => ComplaintBloc(
      getComplaints: sl(),
      getComplaint: sl(),
      raiseComplaint: sl(),
      updateStatus: sl(),
      editComplaint: sl(),
      deleteComplaint: sl(),
    ),
  );

  sl.registerFactory(
    () => SummaryBloc(
      getMonthlySummary: sl(),
      getClosePreview: sl(),
      closeMonth: sl(),
      getClosedMonths: sl(),
    ),
  );

  // ── Notification ──────────────────────────────────────────
  sl.registerLazySingleton(
      () => NotificationRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));

  // Singleton so the bell badge is globally consistent
  sl.registerLazySingleton(
    () => NotificationBloc(
      getNotifications: sl(),
      getUnreadCount: sl(),
      markRead: sl(),
      markAllRead: sl(),
      deleteNotification: sl(),
    ),
  );

  // ── Audit Log ─────────────────────────────────────────────
  sl.registerLazySingleton(() => AuditLogRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<AuditLogRepository>(
    () => AuditLogRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAuditLogsUseCase(sl()));
  sl.registerLazySingleton(() => GetAuditLogUseCase(sl()));

  sl.registerFactory(
    () => AuditLogBloc(
      getAuditLogs: sl(),
      getAuditLog: sl(),
    ),
  );
}

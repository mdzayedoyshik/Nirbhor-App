import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized analytics service for Firebase Analytics integration.
/// 
/// Provides type-safe event logging, user property tracking, and error reporting.
/// Used as the single source of truth for all analytics instrumentation.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  static AnalyticsService get instance => _instance;

  /// Log a custom event with optional parameters.
  /// 
  /// [eventName] must be alphanumeric, max 40 characters
  /// [parameters] are optional key-value pairs (max 100 parameters)
  Future<void> logEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _firebaseAnalytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      _recordError('Analytics event logging error', e);
    }
  }

  /// Set user ID for analytics (call after authentication).
  /// 
  /// Important: Only set after user is authenticated (GDPR compliance).
  Future<void> setUserId(String userId) async {
    try {
      // Firebase Analytics v12+ uses logEvent for user identification
      // Set as a custom parameter or property
      await _firebaseAnalytics.setUserProperty(
        name: 'user_id',
        value: userId,
      );
    } catch (e) {
      _recordError('Failed to set user ID', e);
    }
  }

  /// Clear user ID (call on logout).
  Future<void> clearUserId() async {
    try {
      await _firebaseAnalytics.setUserProperty(
        name: 'user_id',
        value: '',
      );
    } catch (e) {
      _recordError('Failed to clear user ID', e);
    }
  }

  /// Set a user property for audience segmentation.
  /// 
  /// Examples: user_type, apartment_count, is_premium, experience_level
  /// Property names must be alphanumeric (max 24 characters)
  /// Property values must be strings (max 36 characters)
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _firebaseAnalytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      _recordError('Failed to set user property: $name', e);
    }
  }

  /// Set multiple user properties in one call.
  Future<void> setUserProperties(
    Map<String, String> properties,
  ) async {
    for (final entry in properties.entries) {
      await setUserProperty(name: entry.key, value: entry.value);
    }
  }

  /// Log a screen view event.
  /// Typically called during navigation.
  /// 
  /// [screenName] is the name of the screen/page
  /// [screenClass] is optional, can be used for categorization
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _firebaseAnalytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      _recordError('Failed to log screen view', e);
    }
  }

  /// Log an error event (non-fatal).
  Future<void> logError({
    required String errorCode,
    String? errorMessage,
    Map<String, Object>? additionalParameters,
  }) async {
    try {
      final params = <String, Object>{
        'error_code': errorCode,
        'error_message': ?errorMessage,
        ...?additionalParameters,
      };
      await logEvent(eventName: 'app_error', parameters: params);
      await _crashlytics.recordError(
        Exception(errorCode),
        StackTrace.current,
        reason: errorMessage,
        information: params.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
      );
    } catch (e) {
      _recordError('Failed to log error event', e);
    }
  }

  /// Record an exception to Crashlytics.
  void recordException(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
  }) {
    try {
      _crashlytics.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: reason,
        information: information ?? const [],
      );
    } catch (e) {
      _recordError('Failed to record exception', e);
    }
  }

  /// Add a custom breadcrumb for Crashlytics (useful for debugging).
  void recordBreadcrumb(String message) {
    try {
      _crashlytics.log(message);
    } catch (e) {
      _recordError('Failed to record breadcrumb', e);
    }
  }

  /// Reset analytics data (call on logout).
  Future<void> resetAnalytics() async {
    try {
      await _firebaseAnalytics.resetAnalyticsData();
    } catch (e) {
      _recordError('Failed to reset analytics', e);
    }
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Auth & Onboarding
  // ─────────────────────────────────────────────────────

  /// Log auth signup started event.
  /// Parameters: platform (ios/android/web)
  Future<void> logSignupStarted({String? platform}) async {
    await logEvent(
      eventName: 'auth_signup_started',
      parameters: {'platform': ?platform},
    );
  }

  /// Log auth signup completed successfully.
  /// Parameters: signup_method (email/google), account_type (owner/member)
  Future<void> logSignupCompleted({
    required String signupMethod,
    String? accountType,
  }) async {
    await logEvent(
      eventName: 'auth_signup_completed',
      parameters: {
        'signup_method': signupMethod,
        'account_type': ?accountType,
      },
    );
  }

  /// Log auth signup failed.
  /// Parameters: error_code (invalid_email, weak_password, etc.), step (email_check, otp_verify, setup)
  Future<void> logSignupFailed({
    required String errorCode,
    String? step,
  }) async {
    await logEvent(
      eventName: 'auth_signup_failed',
      parameters: {
        'error_code': errorCode,
        'step': ?step,
      },
    );
  }

  /// Log auth login completed.
  /// Parameters: login_method (email/google)
  Future<void> logLoginCompleted({required String loginMethod}) async {
    await logEvent(
      eventName: 'auth_login_completed',
      parameters: {'login_method': loginMethod},
    );
  }

  /// Log auth login failed.
  /// Parameters: error_code, reason
  Future<void> logLoginFailed({
    required String errorCode,
    String? reason,
  }) async {
    await logEvent(
      eventName: 'auth_login_failed',
      parameters: {
        'error_code': errorCode,
        'reason': ?reason,
      },
    );
  }

  /// Log first flat joined event (onboarding funnel).
  Future<void> logFirstFlatJoined({
    required String flatId,
    required String userRole,
  }) async {
    await logEvent(
      eventName: 'first_flat_joined',
      parameters: {
        'flat_id': flatId,
        'user_role': userRole,
      },
    );
  }

  /// Log first flat created event (onboarding funnel).
  Future<void> logFirstFlatCreated({
    required String flatId,
    String? numberOfMembers,
  }) async {
    await logEvent(
      eventName: 'first_flat_created',
      parameters: {
        'flat_id': flatId,
        'initial_members': ?numberOfMembers,
      },
    );
  }

  /// Log first wallet setup event (onboarding funnel).
  Future<void> logFirstWalletSetup({
    required String flatId,
    required String walletType,
  }) async {
    await logEvent(
      eventName: 'first_wallet_setup',
      parameters: {
        'flat_id': flatId,
        'wallet_type': walletType,
      },
    );
  }

  /// Log first expense added event (onboarding funnel).
  Future<void> logFirstExpenseAdded({
    required String flatId,
    required String category,
    required double amount,
  }) async {
    await logEvent(
      eventName: 'first_expense_added',
      parameters: {
        'flat_id': flatId,
        'category': category,
        'amount': amount,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Flat Feature
  // ─────────────────────────────────────────────────────

  /// Log flat list viewed.
  Future<void> logFlatListViewed() async {
    await logEvent(eventName: 'flat_list_viewed');
  }

  /// Log flat detail viewed.
  Future<void> logFlatDetailViewed(String flatId) async {
    await logEvent(
      eventName: 'flat_detail_viewed',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log flat created.
  Future<void> logFlatCreated({
    required String flatId,
    String? numberOfMembers,
  }) async {
    await logEvent(
      eventName: 'flat_created',
      parameters: {
        'flat_id': flatId,
        'initial_members': ?numberOfMembers,
      },
    );
  }

  /// Log flat joined.
  Future<void> logFlatJoined({
    required String flatId,
    required String userRole,
  }) async {
    await logEvent(
      eventName: 'flat_joined',
      parameters: {
        'flat_id': flatId,
        'user_role': userRole,
      },
    );
  }

  /// Log member invited to flat.
  Future<void> logMemberInvited({
    required String flatId,
    required String inviteMethod,
  }) async {
    await logEvent(
      eventName: 'member_invited',
      parameters: {
        'flat_id': flatId,
        'invite_method': inviteMethod, // email, phone, link
      },
    );
  }

  /// Log member removed from flat.
  Future<void> logMemberRemoved({
    required String flatId,
    required String memberId,
  }) async {
    await logEvent(
      eventName: 'member_removed',
      parameters: {
        'flat_id': flatId,
        'member_id': memberId,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Wallet Feature
  // ─────────────────────────────────────────────────────

  /// Log wallet viewed.
  Future<void> logWalletViewed({required String flatId}) async {
    await logEvent(
      eventName: 'wallet_viewed',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log wallet transaction added.
  Future<void> logWalletTransactionAdded({
    required String flatId,
    required String transactionType, // recharge, settlement, etc.
    required double amount,
    String? paymentMethod,
  }) async {
    await logEvent(
      eventName: 'wallet_transaction_added',
      parameters: {
        'flat_id': flatId,
        'transaction_type': transactionType,
        'amount': amount,
        'payment_method': ?paymentMethod,
      },
    );
  }

  /// Log wallet balance checked.
  Future<void> logWalletBalanceChecked({required String flatId}) async {
    await logEvent(
      eventName: 'wallet_balance_checked',
      parameters: {'flat_id': flatId},
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Expense Feature
  // ─────────────────────────────────────────────────────

  /// Log expense added.
  Future<void> logExpenseAdded({
    required String flatId,
    required String category,
    required double amount,
    required String splitType, // individual, equal, custom
    required int memberCount,
  }) async {
    await logEvent(
      eventName: 'expense_added',
      parameters: {
        'flat_id': flatId,
        'category': category,
        'amount': amount,
        'split_type': splitType,
        'member_count': memberCount,
      },
    );
  }

  /// Log expense edited.
  Future<void> logExpenseEdited({required String flatId, required String expenseId}) async {
    await logEvent(
      eventName: 'expense_edited',
      parameters: {
        'flat_id': flatId,
        'expense_id': expenseId,
      },
    );
  }

  /// Log expense deleted.
  Future<void> logExpenseDeleted({required String flatId, required String expenseId}) async {
    await logEvent(
      eventName: 'expense_deleted',
      parameters: {
        'flat_id': flatId,
        'expense_id': expenseId,
      },
    );
  }

  /// Log expense split view opened.
  Future<void> logExpenseSplitView({required String flatId}) async {
    await logEvent(
      eventName: 'expense_split_view',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log expense settled.
  Future<void> logExpenseSettled({
    required String flatId,
    required String settlementId,
    required double totalAmount,
  }) async {
    await logEvent(
      eventName: 'expense_settled',
      parameters: {
        'flat_id': flatId,
        'settlement_id': settlementId,
        'total_amount': totalAmount,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Meal Feature
  // ─────────────────────────────────────────────────────

  /// Log meal list viewed.
  Future<void> logMealListViewed({required String flatId}) async {
    await logEvent(
      eventName: 'meal_list_viewed',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log meal added.
  Future<void> logMealAdded({
    required String flatId,
    required String mealType, // breakfast, lunch, dinner
  }) async {
    await logEvent(
      eventName: 'meal_added',
      parameters: {
        'flat_id': flatId,
        'meal_type': mealType,
      },
    );
  }

  /// Log meal deleted.
  Future<void> logMealDeleted({required String flatId}) async {
    await logEvent(
      eventName: 'meal_deleted',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log meal toggle changed.
  Future<void> logMealToggleChanged({
    required String flatId,
    required String mealType,
    required bool toggled,
  }) async {
    await logEvent(
      eventName: 'meal_toggle_changed',
      parameters: {
        'flat_id': flatId,
        'meal_type': mealType,
        'toggled': toggled,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Task Feature
  // ─────────────────────────────────────────────────────

  /// Log task created.
  Future<void> logTaskCreated({
    required String flatId,
    required String taskId,
    String? assignedTo,
  }) async {
    await logEvent(
      eventName: 'task_created',
      parameters: {
        'flat_id': flatId,
        'task_id': taskId,
        'assigned_to': ?assignedTo,
      },
    );
  }

  /// Log task completed.
  Future<void> logTaskCompleted({required String flatId, required String taskId}) async {
    await logEvent(
      eventName: 'task_completed',
      parameters: {
        'flat_id': flatId,
        'task_id': taskId,
      },
    );
  }

  /// Log task assigned.
  Future<void> logTaskAssigned({
    required String flatId,
    required String taskId,
    required String assignedTo,
  }) async {
    await logEvent(
      eventName: 'task_assigned',
      parameters: {
        'flat_id': flatId,
        'task_id': taskId,
        'assigned_to': assignedTo,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Member Feature
  // ─────────────────────────────────────────────────────

  /// Log member list viewed.
  Future<void> logMemberListViewed({required String flatId}) async {
    await logEvent(
      eventName: 'member_list_viewed',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log member profile viewed.
  Future<void> logMemberProfileViewed({
    required String flatId,
    required String memberId,
  }) async {
    await logEvent(
      eventName: 'member_profile_viewed',
      parameters: {
        'flat_id': flatId,
        'member_id': memberId,
      },
    );
  }

  /// Log member role changed.
  Future<void> logMemberRoleChanged({
    required String flatId,
    required String memberId,
    required String newRole,
  }) async {
    await logEvent(
      eventName: 'member_role_changed',
      parameters: {
        'flat_id': flatId,
        'member_id': memberId,
        'new_role': newRole,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Complaint Feature
  // ─────────────────────────────────────────────────────

  /// Log complaint filed.
  Future<void> logComplaintFiled({
    required String flatId,
    required String complaintId,
    required String category,
  }) async {
    await logEvent(
      eventName: 'complaint_filed',
      parameters: {
        'flat_id': flatId,
        'complaint_id': complaintId,
        'category': category,
      },
    );
  }

  /// Log complaint viewed.
  Future<void> logComplaintViewed({
    required String flatId,
    required String complaintId,
  }) async {
    await logEvent(
      eventName: 'complaint_viewed',
      parameters: {
        'flat_id': flatId,
        'complaint_id': complaintId,
      },
    );
  }

  /// Log complaint status changed.
  Future<void> logComplaintStatusChanged({
    required String flatId,
    required String complaintId,
    required String newStatus,
  }) async {
    await logEvent(
      eventName: 'complaint_status_changed',
      parameters: {
        'flat_id': flatId,
        'complaint_id': complaintId,
        'new_status': newStatus,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Analytics Event Constants - Audit Log Feature
  // ─────────────────────────────────────────────────────

  /// Log audit log viewed.
  Future<void> logAuditLogViewed({required String flatId}) async {
    await logEvent(
      eventName: 'audit_log_viewed',
      parameters: {'flat_id': flatId},
    );
  }

  /// Log audit log filtered.
  Future<void> logAuditLogFiltered({
    required String flatId,
    required String filterType,
  }) async {
    await logEvent(
      eventName: 'audit_log_filtered',
      parameters: {
        'flat_id': flatId,
        'filter_type': filterType,
      },
    );
  }

  // ─────────────────────────────────────────────────────
  // Private Helper Methods
  // ─────────────────────────────────────────────────────

  void _recordError(String message, Object error) {
    try {
      _crashlytics.recordError(
        error,
        StackTrace.current,
        reason: message,
      );
    } catch (e) {
      // Silently fail if Crashlytics recording fails
    }
  }
}

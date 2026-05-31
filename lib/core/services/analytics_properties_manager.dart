import 'package:firebase_analytics/firebase_analytics.dart';

/// Manages user segmentation properties for Firebase Analytics.
/// 
/// Updates user properties based on:
/// - Authentication state (user_type, is_new_user)
/// - Apartment data (apartment_count, is_manager)
/// - Wallet setup (is_wallet_setup, total_balance)
/// - Experience level (based on account age & activity)
class AnalyticsPropertiesManager {
  static final AnalyticsPropertiesManager _instance =
      AnalyticsPropertiesManager._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  AnalyticsPropertiesManager._internal();

  factory AnalyticsPropertiesManager() {
    return _instance;
  }

  static AnalyticsPropertiesManager get instance => _instance;

  /// Set user properties after authentication.
  /// 
  /// Call this after login/signup to populate user segmentation data.
  /// 
  /// [userType] - 'owner' or 'member'
  /// [isNewUser] - true if account created within last 24 hours
  /// [apartmentCount] - number of apartments user is member of
  /// [isManager] - true if user manages any apartment
  /// [isPremium] - true if user has premium features (if applicable)
  Future<void> setAuthProperties({
    required String userType,
    required bool isNewUser,
    required int apartmentCount,
    required bool isManager,
    required bool isPremium,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: 'user_type',
        value: userType,
      );
      await _analytics.setUserProperty(
        name: 'is_new_user',
        value: isNewUser ? 'true' : 'false',
      );
      await _analytics.setUserProperty(
        name: 'apartment_count',
        value: apartmentCount.toString(),
      );
      await _analytics.setUserProperty(
        name: 'is_manager',
        value: isManager ? 'true' : 'false',
      );
      await _analytics.setUserProperty(
        name: 'is_premium',
        value: isPremium ? 'true' : 'false',
      );
    } catch (e) {
      _logPropertyError('auth properties', e);
    }
  }

  /// Update apartment-related user properties.
  /// 
  /// Call this when:
  /// - User joins or creates a new apartment
  /// - User is promoted/demoted to manager
  /// 
  /// [apartmentCount] - updated count of apartments
  /// [isManager] - updated manager status
  /// [currentApartmentId] - ID of the currently active apartment (for context)
  Future<void> updateApartmentProperties({
    required int apartmentCount,
    required bool isManager,
    String? currentApartmentId,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: 'apartment_count',
        value: apartmentCount.toString(),
      );
      await _analytics.setUserProperty(
        name: 'is_manager',
        value: isManager ? 'true' : 'false',
      );
      if (currentApartmentId != null) {
        await _analytics.setUserProperty(
          name: 'current_apartment_id',
          value: currentApartmentId,
        );
      }
    } catch (e) {
      _logPropertyError('apartment properties', e);
    }
  }

  /// Update wallet-related user properties.
  /// 
  /// Call this when:
  /// - Wallet is first set up
  /// - Wallet balance changes significantly
  /// - New payment method is added
  /// 
  /// [isWalletSetup] - true if wallet is configured
  /// [primaryWalletType] - type of primary wallet (savings, checking, etc.)
  /// [hasPaymentMethod] - true if payment method is configured
  Future<void> updateWalletProperties({
    required bool isWalletSetup,
    String? primaryWalletType,
    bool? hasPaymentMethod,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: 'is_wallet_setup',
        value: isWalletSetup ? 'true' : 'false',
      );
      if (primaryWalletType != null) {
        await _analytics.setUserProperty(
          name: 'primary_wallet_type',
          value: primaryWalletType,
        );
      }
      if (hasPaymentMethod != null) {
        await _analytics.setUserProperty(
          name: 'has_payment_method',
          value: hasPaymentMethod ? 'true' : 'false',
        );
      }
    } catch (e) {
      _logPropertyError('wallet properties', e);
    }
  }

  /// Update experience level based on user activity.
  /// 
  /// Call this periodically to update user engagement level.
  /// 
  /// Levels:
  /// - 'new' (< 7 days)
  /// - 'active' (7-30 days, regular activity)
  /// - 'engaged' (> 30 days, high activity)
  /// - 'dormant' (> 30 days, no recent activity)
  Future<void> updateExperienceLevel(String level) async {
    try {
      await _analytics.setUserProperty(
        name: 'experience_level',
        value: level,
      );
    } catch (e) {
      _logPropertyError('experience_level', e);
    }
  }

  /// Update account age property.
  /// 
  /// [daysOld] - number of days since account creation
  Future<void> updateAccountAge(int daysOld) async {
    try {
      final ageCategory = _getAgeCategory(daysOld);
      await _analytics.setUserProperty(
        name: 'account_age_category',
        value: ageCategory,
      );
    } catch (e) {
      _logPropertyError('account_age_category', e);
    }
  }

  /// Set feature usage tier based on user activity.
  /// 
  /// Helps analyze which features drive engagement.
  /// 
  /// [featureName] - name of the feature (expenses, meals, tasks, etc.)
  /// [usageLevel] - 'never', 'light', 'moderate', 'heavy'
  Future<void> setFeatureUsageTier(
    String featureName,
    String usageLevel,
  ) async {
    try {
      await _analytics.setUserProperty(
        name: 'feature_usage_$featureName',
        value: usageLevel,
      );
    } catch (e) {
      _logPropertyError('feature_usage_$featureName', e);
    }
  }

  /// Set multiple feature usage tiers at once.
  /// 
  /// Example:
  /// ```dart
  /// await manager.setMultipleFeatureUsageTiers({
  ///   'expenses': 'heavy',
  ///   'meals': 'light',
  ///   'tasks': 'never',
  ///   'wallet': 'moderate',
  /// });
  /// ```
  Future<void> setMultipleFeatureUsageTiers(
    Map<String, String> featureUsageTiers,
  ) async {
    for (final entry in featureUsageTiers.entries) {
      await setFeatureUsageTier(entry.key, entry.value);
    }
  }

  /// Clear all user properties on logout.
  /// 
  /// Called from AuthBloc when user logs out.
  Future<void> clearUserProperties() async {
    try {
      // Reset all custom user properties to default values
      final defaultProperties = <String, String>{
        'user_type': 'unknown',
        'is_new_user': 'false',
        'apartment_count': '0',
        'is_manager': 'false',
        'is_premium': 'false',
        'is_wallet_setup': 'false',
        'experience_level': 'unknown',
      };

      for (final entry in defaultProperties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value,
        );
      }
    } catch (e) {
      _logPropertyError('clear all properties', e);
    }
  }

  /// Get account age category from days old.
  String _getAgeCategory(int daysOld) {
    if (daysOld < 1) {
      return 'brand_new'; // Less than 1 day
    } else if (daysOld < 7) {
      return 'very_new'; // Less than 1 week
    } else if (daysOld < 30) {
      return 'new'; // Less than 1 month
    } else if (daysOld < 90) {
      return 'established'; // 1-3 months
    } else if (daysOld < 365) {
      return 'regular'; // 3-12 months
    } else {
      return 'veteran'; // 1+ year
    }
  }

  void _logPropertyError(String propertyName, Object error) {
    // Silently fail - property setting is not critical
  }
}

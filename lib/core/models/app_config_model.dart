class AppConfigModel {
  final MaintenanceConfig maintenance;
  final PlatformConfig android;
  final PlatformConfig ios;

  const AppConfigModel({
    required this.maintenance,
    required this.android,
    required this.ios,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      maintenance: MaintenanceConfig.fromJson(
        json['maintenance'] as Map<String, dynamic>? ?? {},
      ),
      android: PlatformConfig.fromJson(
        json['android'] as Map<String, dynamic>? ?? {},
      ),
      ios: PlatformConfig.fromJson(
        json['ios'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  factory AppConfigModel.defaults() {
    return AppConfigModel(
      maintenance: MaintenanceConfig.defaults(),
      android: PlatformConfig.defaults(),
      ios: PlatformConfig.defaults(),
    );
  }
}

class MaintenanceConfig {
  final bool isEnabled;
  final String title;
  final String message;

  const MaintenanceConfig({
    required this.isEnabled,
    required this.title,
    required this.message,
  });

  factory MaintenanceConfig.fromJson(Map<String, dynamic> json) {
    return MaintenanceConfig(
      isEnabled: json['is_enabled'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  factory MaintenanceConfig.defaults() {
    return const MaintenanceConfig(
      isEnabled: false,
      title: '',
      message: '',
    );
  }
}

class PlatformConfig {
  final String latestVersion;
  final String minVersion;
  final bool isUpdateEnabled;
  final String updateUrl;
  final String title;
  final String message;
  final List<String> changelog;

  const PlatformConfig({
    required this.latestVersion,
    required this.minVersion,
    required this.isUpdateEnabled,
    required this.updateUrl,
    required this.title,
    required this.message,
    required this.changelog,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    final rawChangelog = json['changelog'];
    final changelog = rawChangelog is List
        ? rawChangelog.whereType<String>().toList()
        : <String>[];

    return PlatformConfig(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      minVersion: json['min_version'] as String? ?? '0.0.0',
      isUpdateEnabled: json['is_update_enabled'] as bool? ?? false,
      updateUrl: json['update_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      changelog: changelog,
    );
  }

  factory PlatformConfig.defaults() {
    return const PlatformConfig(
      latestVersion: '0.0.0',
      minVersion: '0.0.0',
      isUpdateEnabled: false,
      updateUrl: '',
      title: '',
      message: '',
      changelog: [],
    );
  }
}

/// Central environment configuration.
///
/// Inject at build time via --dart-define:
///   flutter run --dart-define=APP_ENV=production
class AppConfig {
  AppConfig._();

  static const String env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const bool isProduction = env == 'production';
  static const bool isStaging = env == 'staging';
  static const bool isDevelopment = env == 'development';

  static const String appName = 'Home Vault';
  static const String packageName = 'com.viyalabs.home_vault';

  /// Free plan item limit per the PRD monetization spec.
  static const int freeItemLimit = 50;
}

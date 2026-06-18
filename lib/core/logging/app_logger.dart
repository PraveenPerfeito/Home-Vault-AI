import 'package:home_vault/core/config/app_config.dart';
import 'package:logger/logger.dart';

/// Application-wide structured logger.
///
/// In development: colorized PrettyPrinter with method context.
/// In production: SimplePrinter (warnings and above only).
class AppLogger {
  AppLogger._();

  static late final Logger _logger;

  static void init() {
    _logger = Logger(
      printer: AppConfig.isProduction
          ? SimplePrinter(printTime: true, colors: false)
          : PrettyPrinter(
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            ),
      level: AppConfig.isProduction ? Level.warning : Level.debug,
    );
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  static void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  static void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  static void fatal(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

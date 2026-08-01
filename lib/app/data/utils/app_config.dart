/// Centralized application configuration constants.
///
/// Use [AppConfig.baseUrl] for all API requests instead of
/// hardcoding the server URL in individual services.
class AppConfig {
  AppConfig._();

  /// Laravel Backend Server URL.
  ///
  /// - Web / Desktop: `http://127.0.0.1:8000/api`
  /// - Android Emulator: `http://10.0.2.2:8000/api`
  /// - Production (Render): `https://crust-and-crumb-server-n0wv.onrender.com/api`
  static const String baseUrl = 'https://crust-and-crumb-server-n0wv.onrender.com/api';
}

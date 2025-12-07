class AppConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  // Toggle to use static mock data throughout the app (no backend calls)
  static const bool USE_MOCK = false;

  // Base URL for Firebase Functions API (e.g. https://your-project.cloudfunctions.net/api)
  static const String firebaseFunctionsBaseUrl = 'https://your-firebase-project.cloudfunctions.net/api';
}

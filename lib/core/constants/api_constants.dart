class ApiConstants {
  static const String baseUrl = 'https://api.example.com/v1';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String products = '/products';
  static const String cart = '/cart';
  static const String orders = '/orders';

  static const Duration timeoutDuration = Duration(seconds: 30);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
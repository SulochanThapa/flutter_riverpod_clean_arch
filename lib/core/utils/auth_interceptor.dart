import 'package:dio/dio.dart';
import '../utils/token_service.dart';

class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;
  bool _isRefreshing = false;

  AuthInterceptor(this._tokenService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _tokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the failed request
          final response = await _retryRequest(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (e) {
        _isRefreshing = false;
        _tokenService.clearTokens();
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      // Implement refresh token logic here
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = _tokenService.getAccessToken();
    requestOptions.headers['Authorization'] = 'Bearer $token';
    
    return await Dio().fetch(requestOptions);
  }
}
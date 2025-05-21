import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../exceptions/network_exception.dart';

class ConnectivityInterceptor extends Interceptor {
  final InternetConnectionChecker _connectionChecker;

  ConnectivityInterceptor(this._connectionChecker);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (await _connectionChecker.hasConnection) {
      return handler.next(options);
    }

    return handler.reject(
      DioError(
        requestOptions: options,
        type: DioErrorType.unknown,
        error: NetworkException(
          message: 'No internet connection',
          statusCode: null,
        ),
      ),
    );
  }
}
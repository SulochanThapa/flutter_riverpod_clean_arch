import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../exceptions/network_exception.dart';
import '../services/token_service.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final TokenService _tokenService;

  DioClient(this._tokenService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.timeoutDuration,
        receiveTimeout: ApiConstants.timeoutDuration,
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      ConnectivityInterceptor(InternetConnectionChecker()),
      AuthInterceptor(_tokenService),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) {
          debugPrint(object.toString());
        },
      ),
    ]);
  }

 Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioError catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioError catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioError catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioError catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
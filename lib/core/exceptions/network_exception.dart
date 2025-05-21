import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({
    required this.message,
    this.statusCode,
  });

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        return NetworkException(
          message: error.response?.data['message'] ?? 'Server error occurred.',
          statusCode: error.response?.statusCode,
        );
      default:
        return const NetworkException(
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  @override
  String toString() => 'NetworkException: $message (Status Code: $statusCode)';
}
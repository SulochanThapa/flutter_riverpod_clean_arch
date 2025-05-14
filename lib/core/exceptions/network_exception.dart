class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({
    required this.message,
    this.statusCode,
  });

  factory NetworkException.fromDioError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectionTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioErrorType.badResponse:
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
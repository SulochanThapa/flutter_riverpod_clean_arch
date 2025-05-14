import 'package:either_dart/either.dart';
import '../../../../core/exceptions/network_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_model.dart';

class AuthRepository implements IAuthRepository {
  final DioClient _dioClient;
  final TokenService _tokenService;

  AuthRepository(this._dioClient, this._tokenService);

  @override
  Future<Either<NetworkException, User?>> getCurrentUser() async {
    try {
      final token = _tokenService.getAccessToken();
      if (token == null) return const Right(null);

      final response = await _dioClient.get('/auth/me');
      final user = UserModel.fromJson(response.data);
      return Right(user);
    } on NetworkException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<NetworkException, User>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final user = UserModel.fromJson(response.data['user']);
      await _tokenService.saveTokens(
        accessToken: response.data['token'],
        refreshToken: response.data['refreshToken'],
        expiresIn: response.data['expiresIn'],
      );

      return Right(user);
    } on NetworkException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<NetworkException, void>> logout() async {
    try {
      await _dioClient.post('/auth/logout');
      await _tokenService.clearTokens();
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(e);
    }
  }
}
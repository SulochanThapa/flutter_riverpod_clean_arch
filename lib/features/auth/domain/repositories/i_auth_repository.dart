import 'package:either_dart/either.dart';
import '../../../../core/exceptions/network_exception.dart';
import '../entities/user.dart';

abstract class IAuthRepository {
  Future<Either<NetworkException, User?>> getCurrentUser();
  Future<Either<NetworkException, User>> login(String email, String password);
  Future<Either<NetworkException, void>> logout();
}
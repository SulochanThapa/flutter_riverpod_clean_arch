import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_arch/core/providers/storage_providers.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../network/dio_client.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(tokenServiceProvider),
  );
});
final internetCheckerProvider = Provider<InternetConnectionChecker>((ref) {
  return InternetConnectionChecker();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(tokenServiceProvider));
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(internetCheckerProvider).onStatusChange.map(
    (status) => status == InternetConnectionStatus.connected,
  );
});
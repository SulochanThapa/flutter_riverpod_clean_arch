import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../network/dio_client.dart';

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
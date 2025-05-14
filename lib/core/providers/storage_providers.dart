import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences.dart';
import '../services/token_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart');
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(ref.watch(sharedPreferencesProvider));
});
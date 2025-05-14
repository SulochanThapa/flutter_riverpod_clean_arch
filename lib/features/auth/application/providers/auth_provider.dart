import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    checkAuth();
  }

  Future<bool> checkAuth() async {
    final result = await _repository.getCurrentUser();
    
    return result.fold(
      (error) {
        state = const AuthUnauthenticated();
        return false;
      },
      (user) {
        if (user != null) {
          state = AuthAuthenticated(user);
          return true;
        }
        state = const AuthUnauthenticated();
        return false;
      },
    );
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    
    final result = await _repository.login(email, password);
    
    state = result.fold(
      (error) => AuthError(error.message),
      (user) => AuthAuthenticated(user),
    );
  }

  Future<void> logout() async {
    state = const AuthLoading();
    
    final result = await _repository.logout();
    
    state = result.fold(
      (error) => AuthError(error.message),
      (_) => const AuthUnauthenticated(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: router,
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: router._redirect,
    errorBuilder: NavigationErrorHandler.errorScreen,
    observers: [
      NavigationObserver(),
    ],
  );
});
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navigation: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navigation: Popped ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navigation: Removed ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
      'Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    debugPrint('Navigation: Started gesture on ${route.settings.name}');
  }
}
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuth = false;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, state) {
      if (state is AuthAuthenticated != _isAuth) {
        _isAuth = state is AuthAuthenticated;
        notifyListeners();
      }
    });
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    try {
      final path = state.location;

      if (path == '/splash') {
        return null;
      }

      if (!_isAuth && !_isPublicRoute(path)) {
        return '/login';
      }

      if (_isAuth && _isAuthRoute(path)) {
        return '/home';
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('Navigation error: $e\n$stackTrace');
      return '/error';
    }
  }

  bool _isPublicRoute(String path) {
    return ['/login', '/register', '/forgot-password'].contains(path);
  }

  bool _isAuthRoute(String path) {
    return ['/login', '/register'].contains(path);
  }
}
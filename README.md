#Roadmap Flutter Riverpod Clean Architecture

## Roadmap Overview

This roadmap demonstrates best practices for:
- State Management with Riverpod
- Clean Architecture Implementation
- Feature-Based Folder Structure
- Performance Optimization
- Testing & Quality Assurance

## Project Structure

```
lib/
├── core/                    → Shared utilities
│   ├── constants/          → App-wide constants
│   ├── exceptions/         → Custom exceptions
│   ├── network/           → Network utilities
│   └── utils/             → Common utilities
└── features/              → Feature modules
    ├── auth/             → Authentication feature
    │   ├── data/         → Data layer
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories/
    │   ├── domain/       → Business logic
    │   │   ├── entities/
    │   │   ├── repositories/
    │   ├── presentation/ → UI components
    │   │   ├── screens/
    │   │   └── widgets/
    │   └── application/  → State management
    │       ├── providers/
    │       └── states/
    └── register/         → Registration feature
        └── // Similar structure as auth
```

## Key Features

### 1. State Management
- Riverpod for dependency injection and state management
- AsyncNotifier for handling API calls
- Proper state separation and immutability

### 2. Clean Architecture
- Separation of concerns with layered architecture
- Domain-driven design principles
- Independent business logic layer
- Repository pattern implementation

### 3. Network & Data Handling
- Dio for API communication
- Local storage with SharedPreferences/Hive
- Proper error handling

### 4. UI/UX Implementation
- Responsive design patterns
- Performance-optimized widgets
- Material Design 3 components
- Dark/Light theme support

## Development Guidelines

### State Management
- Use Riverpod providers for dependency injection
- Implement AsyncNotifier for API calls
- Keep UI and business logic separate

### Code Organization
- Feature-first folder structure
- Clean Architecture layers
- Separate routing configuration
- Centralized theme management

## Features Implementation

### Authentication
- User login/logout functionality
- Token management
- Session handling
- Secure storage for credentials

### Registration
- User registration flow
- Form validation
- Error handling
- Success/failure states

## Performance Considerations

- Use const constructors
- Implement proper widget rebuilding
- Handle memory leaks
- Profile app performance





## Table of Contents
1. Project Setup
2. Core Layer
3. Auth Feature Implementation
4. Registration Feature Implementation
5. Examples

## 1. Project Setup
First, create a new Flutter project and set up dependencies:
name: flutter_riverpod_app
description: Clean architecture Flutter app with Riverpod

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  dio: ^5.3.2
  shared_preferences: ^2.2.0
  flutter_screenutil: ^5.9.0
  go_router: ^10.1.0
  either_dart: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6

## 2. Core Layer Implementation
2.1 Constants
class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const Duration timeoutDuration = Duration(seconds: 15);
}
class StorageConstants {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
}
2.2 Network
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../exceptions/network_exceptions.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.timeoutDuration,
        receiveTimeout: ApiConstants.timeoutDuration,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioError catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // Similar implementations for get, put, delete
}
2.3 Exceptions
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({
    required this.message,
    this.statusCode,
  });

  factory NetworkException.fromDioError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectionTimeout:
        return NetworkException(
          message: 'Connection timeout',
          statusCode: error.response?.statusCode,
        );
      case DioErrorType.badResponse:
        return NetworkException(
          message: error.response?.data['message'] ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      default:
        return NetworkException(
          message: 'Network error occurred',
          statusCode: error.response?.statusCode,
        );
    }
  }
}
## 3. Auth Feature Implementation
  ### 3.1 Domain Layer
   #### //Entities
class User {
  final String id;
  final String email;
  final String? name;
  final String token;

  const User({
    required this.id,
    required this.email,
    this.name,
    required this.token,
  });
}
   #### //Repository
import 'package:either_dart/either.dart';
import '../../../../core/exceptions/network_exceptions.dart';
import '../entities/user.dart';

abstract class IAuthRepository {
  Future<Either<NetworkException, User>> login(String email, String password);
  Future<Either<NetworkException, void>> logout();
  Future<Either<NetworkException, User?>> getCurrentUser();
}
### 3.2 Data Layer
   #### //Model
class UserModel extends User {
  UserModel({
    required String id,
    required String email,
    String? name,
    required String token,
  }) : super(
          id: id,
          email: email,
          name: name,
          token: token,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
    };
  }
}
#### //Repository
class AuthRepository implements IAuthRepository {
  final DioClient _dioClient;
  final SharedPreferences _prefs;

  AuthRepository(this._dioClient, this._prefs);

  @override
  Future<Either<NetworkException, User>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final user = UserModel.fromJson(response.data);
      await _saveUserData(user);
      
      return Right(user);
    } on NetworkException catch (e) {
      return Left(e);
    }
  }

  Future<void> _saveUserData(UserModel user) async {
    await _prefs.setString(StorageConstants.authToken, user.token);
    await _prefs.setString(StorageConstants.userId, user.id);
    await _prefs.setString(StorageConstants.userEmail, user.email);
  }
}
### 3.3 Application Layer (State Management)
 #### //States
First, let's create the auth state:
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
#### //Providers
Next, let's create the providers:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../states/auth_state.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main');
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
//Now, let's implement the state notifier:
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final result = await _repository.getCurrentUser();
    
    state = result.fold(
      (error) => const AuthInitial(),
      (user) => user != null ? AuthAuthenticated(user) : const AuthInitial(),
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
      (_) => const AuthInitial(),
    );
  }
}
### //Let's also create some utility providers:
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

final authTokenProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.token;
});
//Finally, let's add an auth interceptor:
class AuthInterceptor extends Interceptor {
  final Reader read;

  AuthInterceptor(this.read);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = read(authTokenProvider);
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      read(authStateProvider.notifier).logout();
    }
    handler.next(err);
  }
}
//Update the DioClient to use the auth interceptor:
class DioClient {
  late final Dio _dio;

  DioClient(Reader read) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.timeoutDuration,
        receiveTimeout: ApiConstants.timeoutDuration,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(read),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }
  // ...existing code...
}

### 3.4 Presentation Layer Implementation
#### //UI Components
#### //Custom Widgets
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
#### Login Form Widget
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!value!.contains('@')) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password is required';
              }
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final authState = ref.watch(authStateProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: authState is AuthLoading
            ? null
            : _handleLogin,
        child: authState is AuthLoading
            ? const CircularProgressIndicator()
            : const Text('Login'),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
      );
    }
  }
}
#### Login Screen
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authStateProvider, (previous, current) {
      if (current is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(current.message)),
        );
      } else if (current is AuthAuthenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  const LoginForm(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
#### Home Screen Implementation
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome ${user?.name ?? user?.email ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              const UserProfileCard(),
            ],
          ),
        ),
      ),
    );
  }
}
#### UserProfileCard
class UserProfileCard extends ConsumerWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', user.email),
            if (user.name != null) _buildInfoRow('Name', user.name!),
            _buildInfoRow('ID', user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
#### Now, let's implement protected routes with GoRouter:
_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isAuthRoute = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
#### Finally, update the main app:
/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Flutter Riverpod App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}
## 4. Registration Feature Implementation
### Domain Layer
class RegistrationData {
  final String email;
  final String password;
  final String name;

  const RegistrationData({
    required this.email,
    required this.password,
    required this.name,
  });
}
abstract class IRegisterRepository {
  Future<Either<NetworkException, User>> register(RegistrationData data);
}
### Data Layer
   #### Model
class RegistrationModel {
  final String email;
  final String password;
  final String name;

  const RegistrationModel({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }
}
   #### Repositories
      class RegisterRepository implements IRegisterRepository {
     final DioClient _dioClient;
     final SharedPreferences _prefs;
   
     RegisterRepository(this._dioClient, this._prefs);
   
     @override
     Future<Either<NetworkException, User>> register(RegistrationData data) async {
       try {
         final model = RegistrationModel(
           email: data.email,
           password: data.password,
           name: data.name,
         );
   
         final response = await _dioClient.post(
           ApiConstants.register,
           data: model.toJson(),
         );
   
         final user = UserModel.fromJson(response.data);
         await _saveUserData(user);
         
         return Right(user);
       } on NetworkException catch (e) {
         return Left(e);
       }
     }
   
     Future<void> _saveUserData(UserModel user) async {
       await _prefs.setString(StorageConstants.authToken, user.token);
       await _prefs.setString(StorageConstants.userId, user.id);
       await _prefs.setString(StorageConstants.userEmail, user.email);
     }
   }
 ### Application Layer
  #### states
  abstract class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final User user;
  const RegisterSuccess(this.user);
}

class RegisterError extends RegisterState {
  final String message;
  const RegisterError(this.message);
}
   #### Providers
      final registerRepositoryProvider = Provider<IRegisterRepository>((ref) {
     return RegisterRepository(
       ref.watch(dioClientProvider),
       ref.watch(sharedPreferencesProvider),
     );
   });
   
   final registerStateProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
     return RegisterNotifier(ref.watch(registerRepositoryProvider));
   });
   
   class RegisterNotifier extends StateNotifier<RegisterState> {
     final IRegisterRepository _repository;
   
     RegisterNotifier(this._repository) : super(const RegisterInitial());
   
     Future<void> register(RegistrationData data) async {
       state = const RegisterLoading();
       
       final result = await _repository.register(data);
       
       state = result.fold(
         (error) => RegisterError(error.message),
         (user) => RegisterSuccess(user),
       );
     }
   }
   ### Presentation Layer
       class RegisterForm extends ConsumerStatefulWidget {
     const RegisterForm({super.key});
   
     @override
     ConsumerState<RegisterForm> createState() => _RegisterFormState();
   }
   
   class _RegisterFormState extends ConsumerState<RegisterForm> {
     final _formKey = GlobalKey<FormState>();
     final _nameController = TextEditingController();
     final _emailController = TextEditingController();
     final _passwordController = TextEditingController();
     final _confirmPasswordController = TextEditingController();
   
     @override
     void dispose() {
       _nameController.dispose();
       _emailController.dispose();
       _passwordController.dispose();
       _confirmPasswordController.dispose();
       super.dispose();
     }
   
     @override
     Widget build(BuildContext context) {
       return Form(
         key: _formKey,
         child: Column(
           children: [
             CustomTextField(
               controller: _nameController,
               label: 'Full Name',
               validator: (value) {
                 if (value?.isEmpty ?? true) {
                   return 'Name is required';
                 }
                 return null;
               },
             ),
             const SizedBox(height: 16),
             CustomTextField(
               controller: _emailController,
               label: 'Email',
               validator: _validateEmail,
             ),
             const SizedBox(height: 16),
             CustomTextField(
               controller: _passwordController,
               label: 'Password',
               obscureText: true,
               validator: _validatePassword,
             ),
             const SizedBox(height: 16),
             CustomTextField(
               controller: _confirmPasswordController,
               label: 'Confirm Password',
               obscureText: true,
               validator: _validateConfirmPassword,
             ),
             const SizedBox(height: 24),
             _buildRegisterButton(),
           ],
         ),
       );
     }
   
     String? _validateEmail(String? value) {
       if (value?.isEmpty ?? true) {
         return 'Email is required';
       }
       if (!value!.contains('@')) {
         return 'Invalid email format';
       }
       return null;
     }
   
     String? _validatePassword(String? value) {
       if (value?.isEmpty ?? true) {
         return 'Password is required';
       }
       if (value!.length < 8) {
         return 'Password must be at least 8 characters';
       }
       return null;
     }
   
     String? _validateConfirmPassword(String? value) {
       if (value != _passwordController.text) {
         return 'Passwords do not match';
       }
       return null;
     }
   
     Widget _buildRegisterButton() {
       final registerState = ref.watch(registerStateProvider);
   
       return SizedBox(
         width: double.infinity,
         child: ElevatedButton(
           onPressed: registerState is RegisterLoading ? null : _handleRegister,
           child: registerState is RegisterLoading
               ? const CircularProgressIndicator()
               : const Text('Create Account'),
         ),
       );
     }
   
     void _handleRegister() {
       if (_formKey.currentState?.validate() ?? false) {
         final data = RegistrationData(
           email: _emailController.text,
           password: _passwordController.text,
           name: _nameController.text,
         );
   
         ref.read(registerStateProvider.notifier).register(data);
       }
     }
   }
   #### Register Screen
      class RegisterScreen extends ConsumerWidget {
     const RegisterScreen({super.key});
   
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       ref.listen<RegisterState>(registerStateProvider, (previous, current) {
         if (current is RegisterError) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(current.message)),
           );
         } else if (current is RegisterSuccess) {
           context.go('/home');
         }
       });
   
       return Scaffold(
         appBar: AppBar(
           title: const Text('Create Account'),
         ),
         body: SafeArea(
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Join Us',
                   style: Theme.of(context).textTheme.headlineMedium,
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'Create an account to get started',
                   style: Theme.of(context).textTheme.bodyLarge,
                 ),
                 const SizedBox(height: 32),
                 const RegisterForm(),
                 const SizedBox(height: 16),
                 Center(
                   child: TextButton(
                     onPressed: () => context.go('/login'),
                     child: const Text('Already have an account? Login'),
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
     }
   }

   ## Core Layer other Utilities
   ### internect connection checker
      import 'package:internet_connection_checker/internet_connection_checker.dart';
   
   class NetworkInfo {
     final InternetConnectionChecker connectionChecker;
   
     NetworkInfo(this.connectionChecker);
   
     Future<bool> get isConnected => connectionChecker.hasConnection;
     
     Stream<bool> get onConnectionChange => 
       connectionChecker.onStatusChange
         .map((status) => status == InternetConnectionStatus.connected);
   }
   ### Token Manager
      class TokenManager {
     final SharedPreferences _prefs;
     final Duration _refreshThreshold = const Duration(minutes: 5);
   
     TokenManager(this._prefs);
   
     bool get hasValidToken {
       final expiry = _getTokenExpiry();
       if (expiry == null) return false;
       
       return DateTime.now().isBefore(expiry.subtract(_refreshThreshold));
     }
   
     bool get needsRefresh {
       final expiry = _getTokenExpiry();
       if (expiry == null) return false;
       
       return DateTime.now().isAfter(expiry.subtract(_refreshThreshold)) &&
              DateTime.now().isBefore(expiry);
     }
   
     Future<void> saveTokens({
       required String accessToken,
       required String refreshToken,
       required Duration expiresIn,
     }) async {
       await Future.wait([
         _prefs.setString('access_token', accessToken),
         _prefs.setString('refresh_token', refreshToken),
         _prefs.setInt('token_expiry', 
           DateTime.now().add(expiresIn).millisecondsSinceEpoch),
       ]);
     }
   
     String? getAccessToken() => _prefs.getString('access_token');
     String? getRefreshToken() => _prefs.getString('refresh_token');
     
     DateTime? _getTokenExpiry() {
       final expiryMs = _prefs.getInt('token_expiry');
       if (expiryMs == null) return null;
       return DateTime.fromMillisecondsSinceEpoch(expiryMs);
     }
   
     Future<void> clearTokens() async {
       await Future.wait([
         _prefs.remove('access_token'),
         _prefs.remove('refresh_token'),
         _prefs.remove('token_expiry'),
       ]);
     }
   }
   ### Update the DioClient to handle token refresh:
      class DioClient {
     final Dio _dio;
     final TokenManager _tokenManager;
     final NetworkInfo _networkInfo;
     bool _isRefreshing = false;
     
     DioClient({
       required TokenManager tokenManager,
       required NetworkInfo networkInfo,
     }) : _tokenManager = tokenManager,
          _networkInfo = networkInfo {
       _dio = Dio(
         BaseOptions(
           baseUrl: ApiConstants.baseUrl,
           connectTimeout: ApiConstants.timeoutDuration,
           receiveTimeout: ApiConstants.timeoutDuration,
         ),
       );
   
       _dio.interceptors.addAll([
         _AuthInterceptor(this),
         _ConnectivityInterceptor(_networkInfo),
         LogInterceptor(
           requestBody: true,
           responseBody: true,
         ),
       ]);
     }
   
     Future<Response<T>> request<T>(...) async {
       if (!await _networkInfo.isConnected) {
         throw const NetworkException(message: 'No internet connection');
       }
   
       try {
         return await _dio.request(...);
       } on DioError catch (e) {
         throw _handleError(e);
       }
     }
   
     Future<bool> refreshToken() async {
       if (_isRefreshing) return true;
       
       try {
         _isRefreshing = true;
         final refreshToken = _tokenManager.getRefreshToken();
         
         if (refreshToken == null) return false;
   
         final response = await _dio.post(
           ApiConstants.refreshToken,
           data: {'refresh_token': refreshToken},
         );
   
         await _tokenManager.saveTokens(
           accessToken: response.data['access_token'],
           refreshToken: response.data['refresh_token'],
           expiresIn: Duration(seconds: response.data['expires_in']),
         );
   
         return true;
       } catch (_) {
         return false;
       } finally {
         _isRefreshing = false;
       }
     }
   }
   ### Add interceptors for auth and connectivity:
      class _AuthInterceptor extends Interceptor {
     final DioClient _client;
   
     _AuthInterceptor(this._client);
   
     @override
     void onRequest(
       RequestOptions options,
       RequestInterceptorHandler handler,
     ) async {
       final token = _client._tokenManager.getAccessToken();
       
       if (token != null) {
         options.headers['Authorization'] = 'Bearer $token';
       }
       
       if (_client._tokenManager.needsRefresh) {
         final refreshed = await _client.refreshToken();
         if (refreshed) {
           options.headers['Authorization'] = 
             'Bearer ${_client._tokenManager.getAccessToken()}';
         }
       }
       
       handler.next(options);
     }
   
     @override
     void onError(DioError err, ErrorInterceptorHandler handler) async {
       if (err.response?.statusCode == 401) {
         final refreshed = await _client.refreshToken();
         if (refreshed) {
           // Retry the original request
           final opts = err.requestOptions;
           opts.headers['Authorization'] = 
             'Bearer ${_client._tokenManager.getAccessToken()}';
           
           try {
             final response = await _client._dio.fetch(opts);
             return handler.resolve(response);
           } catch (e) {
             return handler.next(err);
           }
         }
         
         await _client._tokenManager.clearTokens();
       }
       handler.next(err);
     }
   }
      class _ConnectivityInterceptor extends Interceptor {
     final NetworkInfo _networkInfo;
   
     _ConnectivityInterceptor(this._networkInfo);
   
     @override
     void onRequest(
       RequestOptions options,
       RequestInterceptorHandler handler,
     ) async {
       if (!await _networkInfo.isConnected) {
         return handler.reject(
           DioError(
             requestOptions: options,
             error: 'No internet connection',
           ),
         );
       }
       return handler.next(options);
     }
   }
   ## Add providers for the new utilities:
      final networkInfoProvider = Provider<NetworkInfo>((ref) {
     return NetworkInfo(InternetConnectionChecker());
   });
   
   final tokenManagerProvider = Provider<TokenManager>((ref) {
     return TokenManager(ref.watch(sharedPreferencesProvider));
   });
   
   final dioClientProvider = Provider<DioClient>((ref) {
     return DioClient(
       tokenManager: ref.watch(tokenManagerProvider),
       networkInfo: ref.watch(networkInfoProvider),
     );
   });
   
   final connectivityStreamProvider = StreamProvider<bool>((ref) {
     return ref.watch(networkInfoProvider).onConnectionChange;
   });
   //How to use these utilities in the features
      class AuthNotifier extends StateNotifier<AuthState> {
     final IAuthRepository _repository;
     final TokenManager _tokenManager;
     final NetworkInfo _networkInfo;
   
     AuthNotifier({
       required IAuthRepository repository,
       required TokenManager tokenManager,
       required NetworkInfo networkInfo,
     }) : _repository = repository,
          _tokenManager = tokenManager,
          _networkInfo = networkInfo,
          super(const AuthInitial()) {
       _initialize();
     }
   
     Future<void> _initialize() async {
       if (!_tokenManager.hasValidToken) {
         state = const AuthInitial();
         return;
       }
   
       state = const AuthLoading();
       final result = await _repository.getCurrentUser();
       state = result.fold(
         (error) => AuthError(error.message),
         (user) => user != null ? AuthAuthenticated(user) : const AuthInitial(),
       );
     }
   
     Future<void> login(String email, String password) async {
       if (!await _networkInfo.isConnected) {
         state = const AuthError('No internet connection');
         return;
       }
   
       state = const AuthLoading();
       final result = await _repository.login(email, password);
       state = result.fold(
         (error) => AuthError(error.message),
         (user) => AuthAuthenticated(user),
       );
     }
   }
   ### Login Screen-updated
      class LoginScreen extends ConsumerWidget {
     const LoginScreen({super.key});
   
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       // Listen to connectivity changes
       ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (previous, current) {
         current.whenData((hasConnection) {
           if (!hasConnection) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No internet connection')),
             );
           }
         });
       });
   
       return Scaffold(
         body: SafeArea(
           child: Column(
             children: [
               // Show offline banner when no connection
               Consumer(
                 builder: (context, ref, child) {
                   final connectivity = ref.watch(connectivityStreamProvider);
                   return connectivity.whenData((hasConnection) {
                     if (!hasConnection) {
                       return Container(
                         color: Colors.red,
                         padding: const EdgeInsets.all(8),
                         child: const Text(
                           'You are offline',
                           style: TextStyle(color: Colors.white),
                         ),
                       );
                     }
                     return const SizedBox.shrink();
                   }).value ?? const SizedBox.shrink();
                 },
               ),
               Expanded(child: LoginForm()),
             ],
           ),
         ),
       );
     }
   }
   ### Profile Screen -  Updated
      class ProfileScreen extends ConsumerWidget {
     const ProfileScreen({super.key});
   
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       // Auto-refresh token if needed
       ref.listen<bool>(tokenNeedsRefreshProvider, (previous, needsRefresh) {
         if (needsRefresh) {
           ref.read(dioClientProvider).refreshToken();
         }
       });
   
       return Scaffold(
         appBar: AppBar(
           title: const Text('Profile'),
           actions: [
             IconButton(
               icon: const Icon(Icons.logout),
               onPressed: () {
                 ref.read(tokenManagerProvider).clearTokens();
                 ref.read(authStateProvider.notifier).logout();
               },
             ),
           ],
         ),
         body: const ProfileContent(),
       );
     }
   }
   ### NetworkAware Widget
      class NetworkAwareWidget extends ConsumerWidget {
     final Widget onlineWidget;
     final Widget offlineWidget;
   
     const NetworkAwareWidget({
       super.key,
       required this.onlineWidget,
       required this.offlineWidget,
     });
   
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final connectivity = ref.watch(connectivityStreamProvider);
       
       return connectivity.when(
         data: (isOnline) => isOnline ? onlineWidget : offlineWidget,
         loading: () => onlineWidget,
         error: (_, __) => offlineWidget,
       );
     }
   }

   ### UsageExample:
   #### HomeScreen: 
      class HomeScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       return Scaffold(
         body: NetworkAwareWidget(
           onlineWidget: HomeContent(),
           offlineWidget: OfflineWidget(),
         ),
       );
     }
   }
   
   class HomeContent extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       // Auto logout on token expiration
       ref.listen<AuthState>(authStateProvider, (previous, current) {
         if (current is AuthInitial && previous is AuthAuthenticated) {
           context.go('/login');
         }
       });
   
       return ListView(
         children: [
           // Your content here
         ],
       );
     }
   }

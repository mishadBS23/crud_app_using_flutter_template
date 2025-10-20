# Flutter Template - Complete Architecture Deep Dive

**Last Updated:** October 20, 2025  
**Architecture Pattern:** Clean Architecture with Layered Design  
**State Management:** Riverpod with Code Generation  
**Language:** Dart 3.8.0+ | Flutter 3.32.7+

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Core Layer](#core-layer)
4. [Domain Layer](#domain-layer)
5. [Data Layer](#data-layer)
6. [Presentation Layer](#presentation-layer)
7. [Dependency Injection System](#dependency-injection-system)
8. [Application Startup Flow](#application-startup-flow)
9. [Authentication Flow](#authentication-flow)
10. [Routing & Navigation](#routing--navigation)
11. [State Management](#state-management)
12. [Error Handling](#error-handling)
13. [Theme System](#theme-system)
14. [Localization](#localization)
15. [Best Practices](#best-practices)

---

## Architecture Overview

This Flutter template implements **Clean Architecture** with a **Layered Design Pattern**. The architecture enforces strict separation of concerns, making the codebase:

- **Testable**: Each layer can be tested independently
- **Maintainable**: Changes in one layer don't affect others
- **Scalable**: Easy to add new features without breaking existing code
- **Readable**: Clear structure and naming conventions

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (UI, Widgets, Pages, State Management - Riverpod)          │
│  Depends on: Domain Layer                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ Calls Use Cases
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  (Entities, Use Cases, Repository Interfaces)                │
│  Pure Business Logic - No Dependencies                       │
└──────────────────────┬──────────────────────────────────────┘
                       │ Defines Contracts
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  (Repository Implementations, Models, Services)              │
│  Depends on: Domain Layer                                    │
│  Communicates with: Network, Local Storage, etc.             │
└──────────────────────┬──────────────────────────────────────┘
                       │ Uses
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                       CORE LAYER                             │
│  (Base Classes, DI, Extensions, Utilities)                   │
│  Shared across all layers                                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Dependency Rule**: Dependencies only point inward (Presentation → Domain ← Data)
2. **Single Responsibility**: Each class has one reason to change
3. **Interface Segregation**: Repository interfaces define contracts
4. **Dependency Inversion**: High-level modules don't depend on low-level modules

---

## Project Structure

```
lib/
├── main.dart                          # Application entry point
└── src/
    ├── core/                          # Shared utilities and base classes
    │   ├── base/                      # Base classes (Repository, Result, Failure, etc.)
    │   ├── di/                        # Dependency Injection configuration
    │   ├── extensions/                # Extension methods
    │   ├── gen/                       # Generated localization files
    │   ├── localization/              # Localization setup
    │   ├── logger/                    # Logging configuration
    │   └── utiliity/                  # Utility classes (validation, etc.)
    │
    ├── domain/                        # Business logic layer
    │   ├── entities/                  # Business entities
    │   ├── repositories/              # Repository interfaces (contracts)
    │   └── use_cases/                 # Business use cases
    │
    ├── data/                          # Data layer
    │   ├── models/                    # Data models with serialization
    │   ├── repositories/              # Repository implementations
    │   └── services/                  # External services
    │       ├── cache/                 # Local storage service
    │       └── network/               # API client and interceptors
    │
    └── presentation/                  # UI layer
        ├── core/                      # Shared UI components
        │   ├── application_state/     # Global app state (startup, locale)
        │   ├── base/                  # Base UI classes
        │   ├── gen/                   # Generated assets
        │   ├── router/                # Navigation configuration
        │   ├── theme/                 # Theme configuration
        │   └── widgets/               # Reusable widgets
        │
        └── features/                  # Feature modules
            ├── authentication/        # Login, registration, forgot password
            ├── home/                  # Home screen
            ├── onboarding/            # Onboarding screens
            ├── profile/               # User profile
            └── splash/                # Splash screen
```

---

## Core Layer

The Core layer contains fundamental components used across all layers.

### 1. Base Classes

#### **Result<T, E>** - Type-Safe Error Handling

```dart
// Location: lib/src/core/base/result.dart

// A sealed union type for handling success and error states
@freezed
class Result<T, E> with _$Result<T, E> {
  const factory Result.success(T data) = Success;
  const factory Result.error(E error) = Error;
}

// Usage Example:
Future<Result<LoginResponseEntity, String>> login() async {
  return switch (result) {
    Success(:final data) => Success(data),
    Error(:final error) => Error(error.message),
    _ => const Error('Something went wrong'),
  };
}
```

**Why Freezed?**
- Immutable data classes
- Pattern matching support
- Copy-with functionality
- Code generation reduces boilerplate

#### **Failure** - Structured Error Handling

```dart
// Location: lib/src/core/base/failure.dart

// Enum for categorizing failure types
enum FailureType {
  timeout,           // Network timeout
  badResponse,       // HTTP error responses
  badCertificate,    // SSL/TLS issues
  network,           // Connection problems
  parsing,           // JSON parsing errors
  validation,        // Validation errors
  illegalOperation,  // Illegal operations
  notFound,          // Resource not found
  unauthorized,      // Auth failures
  typeError,         // Type mismatches
  unknown,           // Unknown errors
}

// Failure class encapsulates error information
@freezed
abstract class Failure with _$Failure {
  const factory Failure({
    required FailureType type,     // Type of failure
    required String message,        // Human-readable message
    String? code,                   // Optional error code
    StackTrace? stackTrace,         // Stack trace for debugging
  }) = _Failure;
  
  // Factory to convert exceptions to Failures
  factory Failure.mapExceptionToFailure(Object e) {
    // Maps DioException, CustomException to appropriate Failure
    // Provides user-friendly error messages
  }
}
```

**Key Features:**
- Maps network exceptions (DioException) to user-friendly messages
- Categorizes errors for proper handling
- Preserves stack traces for debugging

#### **Repository Base Class** - Safe Operation Execution

```dart
// Location: lib/src/core/base/repository.dart

abstract base class Repository<T> {
  // Wraps async operations with error handling
  // Converts exceptions to Result<T, Failure>
  Future<Result<T, Failure>> asyncGuard<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Success(result);
    } on Exception catch (e) {
      return Error(Failure.mapExceptionToFailure(e));
    }
  }

  // Wraps sync operations with error handling
  Result<T, Failure> guard(T Function() operation) {
    try {
      final result = operation();
      return Success(result);
    } on Exception catch (e) {
      return Error(Failure.mapExceptionToFailure(e));
    }
  }
}
```

**Purpose:**
- Provides a consistent way to handle errors across repositories
- Automatically catches and converts exceptions to Failures
- Eliminates try-catch blocks in repository implementations

#### **CustomException** - Typed Exceptions

```dart
// Location: lib/src/core/base/exceptions.dart

@freezed
sealed class CustomException with _$CustomException {
  // Parsing errors (JSON, XML, etc.)
  const factory CustomException.parsing({
    required String message,
    String? field,
    Object? originalError,
    StackTrace? stackTrace,
  }) = ParsingException;

  // Validation errors
  const factory CustomException.validation({
    required String message,
    required String field,
    Map<String, dynamic>? errors,
    StackTrace? stackTrace,
  }) = ValidationException;

  // Other exception types: illegalOperation, notFound, unauthorized, unknown
}
```

**Benefits:**
- Type-safe exception handling
- Rich error context
- Pattern matching support

### 2. Dependency Injection

The DI system uses **Riverpod** with code generation for type-safe, compile-time dependency management.

#### **Structure**

```dart
// Location: lib/src/core/di/dependency_injection.dart

// Main DI file that imports all provider parts
part 'dependency_injection.g.dart';      // Generated code
part 'parts/externals.dart';              // External dependencies
part 'parts/services.dart';               // Service providers
part 'parts/repository.dart';             // Repository providers
part 'parts/use_cases.dart';              // Use case providers
```

#### **Externals** - Third-Party Dependencies

```dart
// Location: lib/src/core/di/parts/externals.dart

// SharedPreferences - Persistent local storage
// keepAlive: true ensures it lives for the entire app lifecycle
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

// Dio - HTTP client with interceptors
@riverpod
Dio dio(Ref ref) {
  final dio = Dio();
  
  // Add interceptors for token management and logging
  dio.interceptors.addAll([
    TokenManager(
      baseUrl: Endpoints.base,
      refreshTokenEndpoint: Endpoints.refreshToken,
      cacheService: ref.read(cacheServiceProvider),
      navigatorKey: ref.read(goRouterProvider).routerDelegate.navigatorKey,
      dio: Dio(...),  // Separate Dio instance for token refresh
    ),
    // Only log in debug mode
    if (kDebugMode) PrettyDioLogger(requestHeader: true, requestBody: true),
  ]);
  
  dio.options.headers['Content-Type'] = 'application/json';
  return dio;
}
```

**Key Points:**
- `keepAlive: true` → Provider never disposes
- `@riverpod` (without keepAlive) → Auto-dispose when not watched
- Interceptors added in order: TokenManager → Logger
- TokenManager uses a separate Dio instance to avoid recursion

#### **Services** - Business Services

```dart
// Location: lib/src/core/di/parts/services.dart

// CacheService - Wrapper around SharedPreferences
@Riverpod(keepAlive: true)
CacheService cacheService(Ref ref) {
  return SharedPreferencesService(
    ref.read(sharedPreferencesProvider).requireValue,
  );
}

// RestClient - API client generated by Retrofit
@riverpod
RestClient restClientService(Ref ref) {
  return RestClient(ref.read(dioProvider));
}
```

**Pattern:**
- Services depend on externals
- Use `ref.read()` to get dependencies
- Services are injected into repositories

#### **Repositories** - Data Access Layer

```dart
// Location: lib/src/core/di/parts/repository.dart

@riverpod
AuthenticationRepositoryImpl authenticationRepository(Ref ref) {
  return AuthenticationRepositoryImpl(
    remote: ref.read(restClientServiceProvider),  // Network service
    local: ref.read(cacheServiceProvider),        // Local storage
  );
}

@riverpod
LocaleRepository localeRepository(Ref ref) {
  return LocaleRepositoryImpl(ref.read(cacheServiceProvider));
}
```

**Dependency Flow:**
```
Externals (Dio, SharedPreferences)
    ↓
Services (RestClient, CacheService)
    ↓
Repositories (AuthenticationRepository)
    ↓
Use Cases (LoginUseCase)
    ↓
Presentation (LoginProvider)
```

#### **Use Cases** - Business Logic

```dart
// Location: lib/src/core/di/parts/use_cases.dart

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
LogoutUseCase logoutUseCase(Ref ref) {
  return LogoutUseCase(ref.read(authenticationRepositoryProvider));
}

// Locale use cases
@riverpod
GetCurrentLocaleUseCase getCurrentLocaleUseCase(Ref ref) {
  return GetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}

@riverpod
SetCurrentLocaleUseCase setCurrentLocaleUseCase(Ref ref) {
  return SetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}
```

**Key Concepts:**
- Each use case has a single responsibility
- Use cases depend only on repository interfaces
- Riverpod auto-generates provider code

### 3. Extensions

#### **Riverpod Extensions** - Converting Providers to Listenable

```dart
// Location: lib/src/core/extensions/riverpod_extensions.dart

// Converts a Riverpod provider to ValueListenable
// Useful for GoRouter's refreshListenable parameter
extension RefAsListenable on Ref {
  ValueListenable<T> asListenable<T>(ProviderBase<T> provider) {
    final valueNotifier = ValueNotifier(read(provider));
    
    // Listen to provider changes
    final providerSubscription = listen<T>(provider, (_, next) {
      if (valueNotifier.value != next) {
        valueNotifier.value = next;
      }
    });
    
    // Clean up on dispose
    onDispose(() {
      providerSubscription.close();
      valueNotifier.dispose();
    });
    
    return valueNotifier;
  }
}
```

**Use Case:**
- GoRouter's `refreshListenable` expects a `Listenable`
- Riverpod providers aren't `Listenable` by default
- This extension bridges the gap

### 4. Logging

```dart
// Location: lib/src/core/logger/log.dart

class Log {
  static void info(String message) => _singleton._logger.i(message);
  static void debug(String message) => _singleton._logger.d(message);
  static void error(String message) => _singleton._logger.e(message);
  static void warning(String message) => _singleton._logger.w(message);
  static void fatal({required Object error, required StackTrace stackTrace});
}
```

#### **Riverpod Observer** - Provider Lifecycle Logging

```dart
// Location: lib/src/core/logger/riverpod_log.dart

class RiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value, ...) {
    Log.info('Provider $provider was initialized with $value');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ...) {
    Log.warning('Provider $provider was disposed');
  }

  @override
  void didUpdateProvider(ProviderBase provider, ...) {
    Log.info('Provider $provider updated from $previousValue to $newValue');
  }

  @override
  void providerDidFail(ProviderBase provider, Object error, ...) {
    Log.error('Provider $provider threw $error');
  }
}

// Usage in main.dart:
void main() {
  runApp(
    ProviderScope(
      observers: [RiverpodObserver()],  // Logs all provider changes
      child: const MyApp(),
    ),
  );
}
```

---

## Domain Layer

The Domain layer contains **pure business logic** with no external dependencies.

### 1. Entities

Entities represent core business objects. They're simple, immutable data classes.

#### **Login Entity**

```dart
// Location: lib/src/domain/entities/login_entity.dart

// Interface marker (not used directly)
interface class LoginEntity {}

// Request entity for login
class LoginRequestEntity extends LoginEntity {
  LoginRequestEntity({
    required this.username,
    required this.password,
    this.shouldRemeber = false,
  });

  final String username;
  final String password;
  final bool? shouldRemeber;
}

// Response entity after successful login
class LoginResponseEntity extends LoginEntity {
  LoginResponseEntity({required this.accessToken});

  final String accessToken;
}
```

**Design Decision:**
- Entities contain only business-relevant fields
- No JSON serialization logic (that's in Models)
- Immutable by convention

### 2. Repository Interfaces

Repositories define contracts for data operations without implementation details.

```dart
// Location: lib/src/domain/repositories/authentication_repository.dart

abstract base class AuthenticationRepository extends Repository {
  // Registration
  Future<SignUpResponseEntity> register(SignUpRequestEntity data);

  // Login - Returns Result for type-safe error handling
  Future<Result<LoginResponseEntity, Failure>> login(LoginRequestEntity data);

  // Remember me functionality
  Future<bool> rememberMe({bool? rememberMe});

  // Password recovery
  Future<String> forgotPassword(Map<String, dynamic> data);
  Future<String> resetPassword(Map<String, dynamic> data);
  Future<String> verifyOTP(Map<String, dynamic> data);
  Future<String> resendOTP(Map<String, dynamic> data);

  // Logout
  Future<void> logout();
}
```

**Why Abstract?**
- Defines what operations are needed
- Data layer provides implementation
- Easy to mock for testing

### 3. Use Cases

Use cases encapsulate single business operations.

#### **Login Use Case**

```dart
// Location: lib/src/domain/use_cases/authentication_use_case.dart

final class LoginUseCase {
  LoginUseCase(this.repository);

  final AuthenticationRepository repository;

  // Call method executes the use case
  Future<Result<LoginResponseEntity, String>> call({
    required String email,
    required String password,
    bool? shouldRemember,
  }) async {
    // Create request entity
    final request = LoginRequestEntity(
      username: email,
      password: password,
      shouldRemeber: shouldRemember,
    );

    // Call repository
    final result = await repository.login(request);

    // Transform Result<..., Failure> to Result<..., String>
    return switch (result) {
      Success(:final data) => Success(data),
      Error(:final error) => Error(error.message),  // Extract message
      _ => const Error('Something went wrong'),
    };
  }
}
```

**Key Points:**
- Single responsibility: Login logic only
- Depends on repository interface, not implementation
- Transforms complex Failure to simple String for UI
- Uses pattern matching for clean Result handling

#### **Other Use Cases**

```dart
// Check if "Remember Me" is enabled
final class CheckRememberMeUseCase {
  CheckRememberMeUseCase(this.repository);
  final AuthenticationRepository repository;

  Future<bool> call() async {
    return repository.rememberMe();
  }
}

// Save "Remember Me" preference
final class SaveRememberMeUseCase {
  SaveRememberMeUseCase(this.repository);
  final AuthenticationRepository repository;

  Future<bool> call(bool rememberMe) async {
    return repository.rememberMe(rememberMe: rememberMe);
  }
}

// Logout
final class LogoutUseCase {
  LogoutUseCase(this.repository);
  final AuthenticationRepository repository;

  Future<void> call() async {
    return repository.logout();
  }
}
```

**Pattern:**
- Constructor takes dependencies
- `call()` method executes the use case
- Can be invoked like a function: `useCase(params)`

---

## Data Layer

The Data layer handles data operations and external communication.

### 1. Models

Models are DTOs (Data Transfer Objects) with JSON serialization.

```dart
// Location: lib/src/data/models/login_model.dart

// Response model from API
@MappableClass(generateMethods: GenerateMethods.decode)
class LoginResponseModel extends LoginResponseEntity
    with LoginResponseModelMappable {
  LoginResponseModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
    required super.accessToken,  // Passed to parent Entity
    required this.gender,
    required this.refreshToken,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String refreshToken;
}

// Request model for API
@MappableClass(generateMethods: GenerateMethods.copy | GenerateMethods.encode)
class LoginRequestModel extends LoginRequestEntity
    with LoginRequestModelMappable {
  LoginRequestModel({required super.username, required super.password});

  // Factory to convert Entity to Model
  factory LoginRequestModel.fromEntity(LoginRequestEntity entity) {
    return LoginRequestModel(
      username: entity.username,
      password: entity.password,
    );
  }
}
```

**dart_mappable Benefits:**
- Generates `fromJson`, `toJson`, `copyWith`
- Type-safe serialization
- Supports nested objects
- Better performance than json_serializable

**Model vs Entity:**
- **Model**: Has all fields from API (id, email, firstName, etc.)
- **Entity**: Has only business-relevant fields (accessToken)
- Model extends Entity to maintain compatibility

### 2. Repository Implementation

```dart
// Location: lib/src/data/repositories/authentication_repository_impl.dart

final class AuthenticationRepositoryImpl extends AuthenticationRepository {
  AuthenticationRepositoryImpl({
    required this.remote,  // Network service
    required this.local,   // Local storage
  });

  final RestClient remote;
  final CacheService local;

  @override
  Future<Result<LoginResponseEntity, Failure>> login(
    LoginRequestEntity data,
  ) async {
    // asyncGuard wraps the operation in try-catch
    return asyncGuard(() async {
      // Convert Entity to Model
      final model = LoginRequestModel.fromEntity(data);
      
      // Make API call
      final response = await remote.login(model);

      // Save session if "Remember Me" is checked
      if (data.shouldRemeber ?? false) await _saveSession();

      // Parse response and return Entity
      return LoginResponseModelMapper.fromJson(response.data);
    });
  }

  Future<void> _saveSession() async {
    await local.save(CacheKey.isLoggedIn, true);
  }

  @override
  Future<bool> rememberMe({bool? rememberMe}) async {
    try {
      // If null, retrieve current value
      if (rememberMe == null) {
        return local.get<bool>(CacheKey.rememberMe) ?? false;
      }

      // Otherwise, save new value
      await local.save(CacheKey.rememberMe, rememberMe);
      return rememberMe;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    // Remove session tokens
    await local.remove([CacheKey.isLoggedIn, CacheKey.rememberMe]);
  }
}
```

**Responsibilities:**
- Implements repository interface
- Converts Entities ↔ Models
- Handles both network and local storage
- Uses `asyncGuard` for error handling

### 3. Services

#### **REST Client** - API Communication

```dart
// Location: lib/src/data/services/network/rest_client.dart

@RestApi(baseUrl: Endpoints.base)
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST(Endpoints.login)
  Future<HttpResponse> login(@Body() LoginRequestModel request);
  
  // More endpoints...
}
```

**Retrofit Benefits:**
- Generates API client code
- Type-safe API calls
- Automatic serialization
- Works with Dio interceptors

#### **Endpoints**

```dart
// Location: lib/src/data/services/network/endpoints.dart

class Endpoints {
  static const base = 'https://dummyjson.com';

  // Authentication endpoints
  static const String register = '/auth/register/';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot_password/';
  static const String resetPassword = '/auth/reset_password/';
  static const String refreshToken = '/auth/refresh_token/';

  // OTP endpoints
  static const String verifyOtp = '/otp/verify_otp/';
  static const String resendOtp = '/otp/resend_otp/';
}
```

#### **Cache Service** - Local Storage

```dart
// Location: lib/src/data/services/cache/cache_service.dart

// Enum for type-safe cache keys
enum CacheKey {
  accessToken,
  refreshToken,
  isOnBoardingCompleted,
  isLoggedIn,
  rememberMe,
  language,
}

// Abstract interface
abstract class CacheService {
  Future<void> save<T>(CacheKey key, T value);
  T? get<T>(CacheKey key);
  Future<void> remove(List<CacheKey> keys);
  Future<void> clear();
}

// Implementation using SharedPreferences
class SharedPreferencesService implements CacheService {
  SharedPreferencesService(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<void> save<T>(CacheKey key, T value) async {
    switch (T) {
      case String:
        await _prefs.setString(key.name, value as String);
      case int:
        await _prefs.setInt(key.name, value as int);
      case bool:
        await _prefs.setBool(key.name, value as bool);
      case double:
        await _prefs.setDouble(key.name, value as double);
      default:
        throw Exception('Unsupported type');
    }
  }

  @override
  T? get<T>(CacheKey key) {
    return _prefs.get(key.name) as T?;
  }

  @override
  Future<void> remove(List<CacheKey> keys) async {
    for (final key in keys) {
      await _prefs.remove(key.name);
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

**Design:**
- Type-safe keys prevent typos
- Generic methods for any type
- Can swap implementation (Hive, SecureStorage, etc.)

#### **Token Manager** - Automatic Token Refresh

```dart
// Location: lib/src/data/services/network/interceptor/token_manager.dart

class TokenManager extends Interceptor {
  TokenManager({
    required this.baseUrl,
    required this.refreshTokenEndpoint,
    required this.cacheService,
    required this.navigatorKey,
    required this.dio,  // Separate Dio for refresh requests
  });

  bool _isRefreshing = false;
  final List<_QueuedRequest> _queue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add access token to every request
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    
    // Handle 401 Unauthorized
    if (statusCode == 401 && err.requestOptions.extra['retry'] != true) {
      await _handleUnauthorizedError(err, handler);
      return;
    }
    
    handler.next(err);
  }

  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If already refreshing, queue the request
    if (_isRefreshing) {
      _queue.add(_QueuedRequest(options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      // Refresh the access token
      final newToken = await _refreshAccessToken();
      
      // Retry the failed request
      await _retryFailedRequest(err.requestOptions, handler, newToken);
      
      // Retry all queued requests
      await _retryQueuedRequests(newToken);
    } catch (e) {
      // If refresh fails, logout and redirect to login
      await _handleRefreshFailure(err, handler);
    } finally {
      _isRefreshing = false;
      _queue.clear();
    }
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    // Use separate Dio instance to avoid recursion
    final refreshResp = await dio.fetch(
      RequestOptions(
        baseUrl: baseUrl,
        path: refreshTokenEndpoint,
        method: 'GET',
        headers: {'Authorization': 'Bearer $refreshToken'},
      ),
    );

    if (refreshResp.statusCode != 200) {
      throw Exception('Refresh failed');
    }

    final newToken = refreshResp.data['data']['accessToken'] as String;
    await saveToken(CacheKey.accessToken, newToken);

    return newToken;
  }

  Future<void> _retryFailedRequest(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    String newToken,
  ) async {
    options.headers['Authorization'] = 'Bearer $newToken';
    options.extra['retry'] = true;  // Prevent infinite loop

    final retryResponse = await dio.fetch(options);
    handler.resolve(retryResponse);
  }

  Future<void> _handleRefreshFailure(...) async {
    await _removeTokens();
    _navigateToLoginScreen();
    handler.reject(originalError);
  }
}
```

**Key Features:**
- Automatically adds tokens to requests
- Refreshes expired tokens transparently
- Queues requests during refresh
- Redirects to login on refresh failure
- Prevents infinite loops with retry flag

---

## Presentation Layer

The Presentation layer handles UI and user interactions.

### 1. Application Entry Point

```dart
// Location: lib/main.dart

void main() {
  runApp(
    ProviderScope(
      observers: [RiverpodObserver()],  // Logs provider lifecycle
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,  // Limit text scaling for accessibility
      child: MaterialApp.router(
        // Localization
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: ref.watch(localizationProvider),  // Current locale
        
        // Theme
        theme: context.lightTheme,
        darkTheme: context.darkTheme,
        themeMode: ThemeMode.system,  // Follow system theme
        
        // Routing
        routerConfig: ref.read(goRouterProvider),
      ),
    );
  }
}
```

**Key Points:**
- `ProviderScope` required for Riverpod
- `ConsumerWidget` to watch providers
- Text scaling clamped for better UX
- System theme mode by default

### 2. State Management with Riverpod

#### **Status Enum** - UI State

```dart
// Location: lib/src/presentation/core/base/status.dart

enum Status { initial, loading, success, error }

extension StatusExtension on Status {
  bool get isInitial => this == Status.initial;
  bool get isLoading => this == Status.loading;
  bool get isSuccess => this == Status.success;
  bool get isError => this == Status.error;
}
```

#### **Login State**

```dart
// Location: lib/src/presentation/features/authentication/login/riverpod/login_state.dart

@MappableClass(
  generateMethods: GenerateMethods.copy | GenerateMethods.stringify,
)
class LoginState<T> with LoginStateMappable<T> {
  const LoginState({
    this.rememberMe = false,
    this.type = Status.initial,
    this.error,
  });

  final bool rememberMe;
  final Status type;
  final String? error;

  // Convenience getters
  bool get isInitial => type.isInitial;
  bool get isLoading => type.isLoading;
  bool get isSuccess => type.isSuccess;
  bool get isError => type.isError;
}
```

**Design:**
- Immutable state class
- `copyWith` for updates
- Status enum for UI states
- Optional error message

#### **Login Provider** - State Notifier

```dart
// Location: lib/src/presentation/features/authentication/login/riverpod/login_provider.dart

@riverpod
class Login extends _$Login {
  late LoginUseCase _loginUseCase;
  late CheckRememberMeUseCase _checkRememberMeUseCase;
  late SaveRememberMeUseCase _saveRememberMeUseCase;

  @override
  LoginState build() {
    // Initialize use cases
    _loginUseCase = ref.read(loginUseCaseProvider);
    _checkRememberMeUseCase = ref.read(checkRememberMeUseCaseProvider);
    _saveRememberMeUseCase = ref.read(saveRememberMeUseCaseProvider);

    return const LoginState();  // Initial state
  }

  Future<void> checkRememberMe() async {
    final rememberMe = await _checkRememberMeUseCase.call();
    state = state.copyWith(rememberMe: rememberMe);
  }

  void updateRememberMe(bool rememberMe) {
    state = state.copyWith(rememberMe: rememberMe);
  }

  Future<void> saveRememberMe(bool rememberMe) async {
    await _saveRememberMeUseCase.call(rememberMe);
  }

  void login({
    required String email,
    required String password,
    bool? shouldRemember,
  }) async {
    // Set loading state
    state = state.copyWith(type: Status.loading);

    // Call use case
    final result = await _loginUseCase.call(
      email: email,
      password: password,
      shouldRemember: shouldRemember,
    );

    // Update state based on result
    state = switch (result) {
      Success() => state.copyWith(type: Status.success),
      Error(:final error) => state.copyWith(type: Status.error, error: error),
      _ => state.copyWith(type: Status.error),
    };
  }
}
```

**Pattern:**
- `@riverpod` generates provider code
- `build()` initializes state
- Methods update state immutably
- Use cases handle business logic

### 3. UI - Login Page

```dart
// Location: lib/src/presentation/features/authentication/login/view/login_page.dart

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final shouldRemember = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    final notifier = ref.read(loginProvider.notifier);
    
    // Check if user previously enabled "Remember Me"
    notifier.checkRememberMe();

    // Sync checkbox with state
    shouldRemember.addListener(() {
      notifier.updateRememberMe(shouldRemember.value);
    });

    // Listen to login state changes
    ref.listenManual(loginProvider, (previous, next) {
      if (next.isSuccess) {
        // Save preference and navigate to home
        notifier.saveRememberMe(shouldRemember.value);
        context.pushReplacementNamed(Routes.home);
      } else {
        shouldRemember.value = next.rememberMe;
      }

      if (next.isError) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(loginProvider.notifier).login(
            email: emailController.text,
            password: passwordController.text,
            shouldRemember: shouldRemember.value,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Language switcher
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LanguageSwitcherWidget(),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Login form
                      _LoginForm(
                        formKey: _formKey,
                        emailController: emailController,
                        passwordController: passwordController,
                        shouldRemember: shouldRemember,
                        onLogin: _onLogin,
                        isLoading: state.isLoading,
                      ),
                      
                      // Footer with sign-up link
                      _LoginFormFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key Points:**
- `ConsumerStatefulWidget` for state + lifecycle
- `ref.listenManual()` for side effects
- `ref.watch()` rebuilds on state changes
- `ref.read()` for one-time access

---

## Application Startup Flow

The application startup is a carefully orchestrated sequence that ensures all dependencies are initialized before the user sees the main interface. Let's break down every step in detail.

### Complete Startup Sequence Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: main() - Application Entry Point                            │
│ • Create ProviderScope (Riverpod container)                         │
│ • Attach RiverpodObserver for logging                               │
│ • Launch MyApp widget                                               │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: MyApp.build() - Root Widget                                 │
│ • Setup MaterialApp.router                                          │
│ • Configure localization delegates                                  │
│ • Watch localizationProvider for current locale                     │
│ • Read goRouterProvider for navigation                              │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: GoRouter Initialization                                     │
│ • goRouterProvider is created (keepAlive: true)                     │
│ • Sets up refreshListenable with routerStateProvider                │
│ • Configures redirect logic                                         │
│ • Defines route tree                                                │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 4: Navigate to Routes.initial ('/')                            │
│ • GoRouter navigates to initial route                               │
│ • Renders AppStartupWidget                                          │
│ • AppStartupWidget watches appStartupProvider                       │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 5: appStartupProvider Executes (FutureProvider)                │
│ • Registers onDispose callback                                      │
│ • Waits for sharedPreferencesProvider to complete                   │
│ • Initializes SharedPreferences instance                            │
│ • Loads saved locale from cache                                     │
│ • Sets localizationProvider state                                   │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 6: appStartupProvider Completes                                │
│ • AppStartupWidget.when() receives data state                       │
│ • Renders 'loaded' widget (SplashPage)                              │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 7: RouterState Listener Triggered                              │
│ • routerStateProvider listens to appStartupProvider                 │
│ • Detects completion (not loading, no error)                        │
│ • Calls decideNextRoute()                                           │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 8: decideNextRoute() Logic                                     │
│ • Checks current state (Routes.initial)                             │
│ • Changes to Routes.splash                                          │
│ • Sets 500ms timer                                                  │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 9: GoRouter Redirect Triggered                                 │
│ • routerStateProvider value changed                                 │
│ • refreshListenable notifies GoRouter                               │
│ • redirect() callback executes                                      │
│ • Returns Routes.splash                                             │
│ • User sees splash screen                                           │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 10: Timer Expires (500ms later)                                │
│ • decideNextRoute() called again                                    │
│ • Checks isOnboarded from cache                                     │
│ • Checks isLoggedIn from cache                                      │
└────────────────────────────┬────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Step 11: Final Route Decision                                       │
│ • If not onboarded → Routes.onboarding                              │
│ • If onboarded && logged in → Routes.home                           │
│ • If onboarded && not logged in → Routes.login                      │
│ • GoRouter navigates to final destination                           │
└─────────────────────────────────────────────────────────────────────┘
```

### 1. App Startup Provider - Detailed Breakdown

```dart
// Location: lib/src/presentation/core/application_state/startup_provider/app_startup_provider.dart

@Riverpod(keepAlive: true)  // ← This provider NEVER disposes
Future<void> appStartup(Ref ref) async {
  // STEP 1: Register cleanup callback
  // This runs when the app is about to close
  ref.onDispose(() {
    ref.invalidate(sharedPreferencesProvider);  // Clean up SharedPreferences
  });

  // STEP 2: Initialize SharedPreferences
  // This is a FutureProvider, so we wait for it to complete
  // If SharedPreferences fails to initialize, the app won't proceed
  await ref.watch(sharedPreferencesProvider.future);
  
  // At this point, SharedPreferences is ready and cached

  // STEP 3: Load user's saved language preference
  // This reads from SharedPreferences and updates the locale
  await ref.read(localizationProvider.notifier).setCurrentLocal();
  
  // The provider completes successfully
  // AppStartupWidget receives "data" state and shows the loaded UI
}
```

**Why FutureProvider?**
- Returns `AsyncValue<void>` with three states: loading, data, error
- `AppStartupWidget.when()` can handle all three states
- If any step fails, error state is returned with the exception

**What Happens During Initialization?**

1. **SharedPreferences Initialization**
   ```dart
   @Riverpod(keepAlive: true)
   Future<SharedPreferences> sharedPreferences(Ref ref) =>
       SharedPreferences.getInstance();
   ```
   - Native platform call (iOS/Android)
   - Reads persistent storage file
   - Creates SharedPreferences instance
   - Cached for entire app lifetime (keepAlive: true)

2. **Locale Loading**
   ```dart
   Future<void> setCurrentLocal() async {
     // Calls use case
     final useCase = ref.read(getCurrentLocaleUseCaseProvider);
     final language = await useCase();  // Reads from SharedPreferences
     
     // Updates provider state
     state = Locale(language);  // Triggers rebuild of MaterialApp
   }
   ```
   - Reads saved language code (e.g., "en", "ar")
   - Defaults to "en" if not found
   - Updates `localizationProvider`
   - MaterialApp rebuilds with correct locale

**Purpose:**
- Ensures all critical dependencies are ready
- Loads user preferences before showing UI
- Provides error handling if initialization fails
- Happens only once per app launch

### 2. Startup Widget - Loading States Handler

```dart
// Location: lib/src/presentation/core/widgets/app_startup/startup_widget.dart

class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({
    required this.loading,  // Widget to show while initializing
    required this.loaded,   // Widget to show when initialization completes
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch appStartupProvider - rebuilds on state changes
    final appStartupState = ref.watch(appStartupProvider);

    // AsyncValue.when() handles all three states
    return appStartupState.when(
      // STATE 1: LOADING
      // Called while Future is executing
      // SharedPreferences is initializing, locale is loading
      loading: () => loading,  // Shows splash screen with loading indicator
      
      // STATE 2: ERROR
      // Called if any exception occurs during initialization
      // Provides error object and stack trace for debugging
      error: (error, stackTrace) {
        return AppStartupErrorWidget(
          errorMessage: error.toString(),  // Show user-friendly message
          onRetry: () => ref.invalidate(appStartupProvider),  // Retry button
        );
      },
      
      // STATE 3: SUCCESS (DATA)
      // Called when Future completes successfully
      // All dependencies are initialized and ready
      data: (_) => loaded,  // Show main app (triggers navigation)
    );
  }
}
```

**State Transition Timeline:**

```
Time: 0ms
├─ appStartupProvider starts executing
├─ AppStartupWidget.build() called
├─ appStartupState = AsyncValue.loading()
└─ Shows 'loading' widget (SplashPage with progress indicator)

Time: 50-200ms (typical)
├─ SharedPreferences.getInstance() completes
├─ Locale loaded from cache
├─ appStartupProvider completes
├─ appStartupState = AsyncValue.data(void)
└─ Shows 'loaded' widget (SplashPage without indicator)

Immediately after data state:
├─ RouterState listener triggered
├─ decideNextRoute() called
├─ GoRouter redirect happens
└─ Navigate to splash → onboarding/login/home
```

**Error Handling Example:**

If SharedPreferences fails to initialize:
```dart
// Exception occurs in appStartupProvider
// appStartupState = AsyncValue.error(exception, stackTrace)
// AppStartupWidget shows:

AppStartupErrorWidget(
  errorMessage: "Failed to initialize storage",
  onRetry: () {
    // Invalidate forces the provider to re-execute
    ref.invalidate(appStartupProvider);
    // User can tap button to retry initialization
  },
)
```

**Usage in Router:**

```dart
GoRoute(
  path: Routes.initial,  // '/'
  pageBuilder: (context, state) {
    return const NoTransitionPage(
      child: AppStartupWidget(
        loading: SplashPage(),  // During appStartupProvider execution
        loaded: SplashPage(),   // After appStartupProvider completes
      ),
    );
  },
),
```

**Why Same Widget for Both States?**
- SplashPage internally checks if it should show loading indicator
- Provides smooth transition without widget replacement
- Can show different UI if needed (e.g., loading: LoadingScreen(), loaded: SplashPage())

### 3. Router State Provider - Navigation Controller

This provider acts as the brain of your navigation system, deciding where users should go based on app state.

```dart
// Location: lib/src/presentation/core/router/router_state/router_state_provider.dart

@Riverpod(keepAlive: true)  // Lives forever - maintains navigation state
class RouterState extends _$RouterState {
  RouterRepository? _routerRepository;

  @override
  String? build() {
    // INITIALIZATION: Set up listener for app startup completion
    // This is called ONCE when the provider is first created
    
    ref.listen(
      appStartupProvider,  // Watch the startup provider
      (previous, next) {   // previous = old state, next = new state
        
        // Check if startup completed successfully
        if (!(next.isLoading || next.hasError)) {
          // Startup is done! Initialize repository
          _routerRepository = ref.read(routerRepositoryProvider);
          
          // Start navigation decision tree
          decideNextRoute();
        }
      },
    );
    
    // Initial state: Return '/' route
    return Routes.initial;
  }

  void decideNextRoute() {
    // STEP 1: Read user state from cache (via repository)
    final isOnboarded = _routerRepository?.isOnboardingCompleted() ?? false;
    final isLoggedIn = _routerRepository?.isUserLoggedIn() ?? false;

    // DECISION TREE:
    
    // BRANCH 1: Initial state → Show splash briefly
    if (state == Routes.initial) {
      state = Routes.splash;  // Update state (triggers redirect)
      
      // Wait 500ms for branding/logo display
      Timer(const Duration(milliseconds: 500), () {
        decideNextRoute();  // Call again after timer
      });
      return;  // Exit, wait for timer
    }

    // BRANCH 2: First time user → Show onboarding
    if (!isOnboarded) {
      state = Routes.onboarding;
      
      // Mark as completed so they don't see it again
      _routerRepository?.saveOnboardingAsCompleted();
      return;  // Exit, user stays on onboarding
    }

    // BRANCH 3: Returning user → Check authentication
    // If logged in → home, else → login
    state = isLoggedIn ? Routes.home : Routes.login;
  }
}
```

**How Router State Works with GoRouter:**

```
┌─────────────────────────────────────────────────────────────┐
│ RouterState Provider (State Machine)                         │
│ Current State: Routes.initial                                │
└────────────────────┬────────────────────────────────────────┘
                     │ State changes to Routes.splash
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ ValueNotifier (from asListenable extension)                  │
│ Notifies listeners: "Value changed from / to /splash"        │
└────────────────────┬────────────────────────────────────────┘
                     │ notifyListeners() called
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ GoRouter (refreshListenable parameter)                       │
│ Detects change, calls redirect() callback                    │
└────────────────────┬────────────────────────────────────────┘
                     │ redirect() returns new route
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ GoRouter.redirect() Method                                   │
│ • Checks if current path is in [/, /onboarding, /splash]    │
│ • If yes: returns routerStateProvider.value (/splash)        │
│ • If no: returns null (no redirect needed)                   │
└────────────────────┬────────────────────────────────────────┘
                     │ Navigation happens
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ User sees SplashPage                                         │
│ (Timer starts for 500ms)                                     │
└─────────────────────────────────────────────────────────────┘
```

**Detailed Flow for Each Scenario:**

**Scenario 1: First Time User**
```
App Launch
  ↓
Routes.initial → Shows startup loading
  ↓
appStartupProvider completes
  ↓
RouterState.decideNextRoute() called
  ↓
state = Routes.splash (500ms timer starts)
  ↓
GoRouter redirects to /splash
  ↓
Timer expires → decideNextRoute() again
  ↓
isOnboarded = false
  ↓
state = Routes.onboarding
  ↓
GoRouter redirects to /onboarding
  ↓
User completes onboarding → manually navigate to login
```

**Scenario 2: Returning User (Not Logged In)**
```
App Launch
  ↓
Routes.initial → Shows startup loading
  ↓
appStartupProvider completes
  ↓
RouterState.decideNextRoute() called
  ↓
state = Routes.splash (500ms timer starts)
  ↓
Timer expires → decideNextRoute() again
  ↓
isOnboarded = true (from cache)
isLoggedIn = false (no session token)
  ↓
state = Routes.login
  ↓
GoRouter redirects to /login
  ↓
User sees login page
```

**Scenario 3: Returning User (Logged In)**
```
App Launch
  ↓
Routes.initial → Shows startup loading
  ↓
appStartupProvider completes
  ↓
RouterState.decideNextRoute() called
  ↓
state = Routes.splash (500ms timer starts)
  ↓
Timer expires → decideNextRoute() again
  ↓
isOnboarded = true (from cache)
isLoggedIn = true (session token exists)
  ↓
state = Routes.home
  ↓
GoRouter redirects to /home
  ↓
User sees home page
```

**Why This Design?**

1. **Centralized Logic**: All navigation decisions in one place
2. **Cache-Based**: Fast - no API calls during startup
3. **Flexible**: Easy to add new conditions (e.g., check if profile completed)
4. **Observable**: GoRouter automatically reacts to state changes
5. **Testable**: Mock RouterRepository to test all scenarios

---

## Routing & Navigation - Deep Dive

### Understanding GoRouter Architecture

GoRouter is a declarative routing solution that handles all navigation in the app. Let's break down every component.

### 1. Router Configuration - Complete Breakdown

```dart
// Location: lib/src/presentation/core/router/router.dart

@Riverpod(keepAlive: true)  // Router lives for entire app lifetime
GoRouter goRouter(Ref ref) {
  return GoRouter(
    // NAVIGATOR KEY: Global key for accessing navigator state
    // Used by TokenManager to navigate programmatically (e.g., to login on token failure)
    navigatorKey: _rootNavigatorKey,
    
    // DEBUG LOGGING: Prints navigation events in debug console
    // Shows route changes, redirects, parameters, etc.
    debugLogDiagnostics: true,
    
    // REFRESH LISTENABLE: The heart of reactive navigation
    // When this notifies, GoRouter checks if redirect is needed
    refreshListenable: ref.asListenable(routerStateProvider),
    // How it works:
    // 1. routerStateProvider state changes (e.g., Routes.splash → Routes.login)
    // 2. ValueNotifier from asListenable() calls notifyListeners()
    // 3. GoRouter hears the notification
    // 4. Calls redirect() callback for current route
    // 5. If redirect returns non-null, navigates to new route
    
    // INITIAL LOCATION: Where app starts when launched
    initialLocation: Routes.initial,  // '/'
    
    // REDIRECT LOGIC: Guard that decides if navigation should change
    redirect: (context, state) {
      // Log every redirect attempt
      Log.info('Redirecting to ${state.uri}');
      
      // CONDITIONAL REDIRECT:
      // Only redirect if user is on startup/transition routes
      if ([Routes.initial, Routes.onboarding, Routes.splash]
          .contains(state.uri.path)) {
        
        // Return the value from routerStateProvider
        // This is the "desired" route based on app state
        return ref.asListenable(routerStateProvider).value;
        
        // Example flow:
        // 1. User on Routes.initial ('/')
        // 2. routerStateProvider.value = Routes.splash ('/splash')
        // 3. redirect() returns '/splash'
        // 4. GoRouter navigates to /splash
      }
      
      // DON'T REDIRECT: User is on authenticated routes
      // Let them navigate freely
      return null;
    },
    
    // ROUTE TREE: Defines all possible routes
    routes: [
      // Root route: App startup and initialization
      GoRoute(
        path: Routes.initial,  // '/'
        pageBuilder: (context, state) {
          return const NoTransitionPage(
            child: AppStartupWidget(
              loading: SplashPage(),
              loaded: SplashPage(),
            ),
          );
        },
      ),
      
      // Spread operator: Expands list of onboarding routes
      ..._onboardingRoutes(ref),
      
      // Authentication routes: login, register, forgot password
      ..._authenticationRoutes(ref),
      
      // Shell routes: Main app with bottom navigation
      _shellRoutes(ref),
    ],
  );
}
```

**Key Concepts Explained:**

#### **refreshListenable - The Magic Behind Reactive Navigation**

```dart
// This is what happens under the hood:

// 1. Provider state changes
routerStateProvider.state = Routes.login;

// 2. asListenable extension creates/updates ValueNotifier
valueNotifier.value = Routes.login;  // Triggers notifyListeners()

// 3. GoRouter registered as listener
goRouter.addListener(() {
  // Called whenever ValueNotifier notifies
  // GoRouter checks if redirect is needed
  final shouldRedirect = redirect(context, currentState);
  if (shouldRedirect != null) {
    // Navigate to new route
    go(shouldRedirect);
  }
});
```

#### **redirect() Callback - Navigation Guard**

The redirect callback is called in these situations:
1. **Initial Navigation**: When app first launches
2. **Manual Navigation**: When user taps link or button
3. **Refresh Notification**: When refreshListenable notifies
4. **Deep Link**: When app opened via URL

```dart
// Example scenarios:

// SCENARIO 1: User manually tries to access /home while not logged in
redirect: (context, state) {
  if (state.uri.path == '/home' && !isLoggedIn) {
    return '/login';  // Redirect to login
  }
  return null;  // Allow navigation
}

// SCENARIO 2: Current implementation
redirect: (context, state) {
  // Only control startup routes
  if ([Routes.initial, Routes.onboarding, Routes.splash].contains(state.uri.path)) {
    // Let RouterState provider decide where to go
    return ref.asListenable(routerStateProvider).value;
  }
  // All other routes: no redirect (free navigation)
  return null;
}
```

**Why This Design?**

1. **Separation of Concerns**:
   - RouterState provider = Business logic (where should user go?)
   - GoRouter redirect = Navigation mechanism (how to get there?)

2. **Reactive**:
   - Change provider state → Navigation happens automatically
   - No manual `context.go()` calls needed

3. **Testable**:
   - Test RouterState logic without UI
   - Mock routerStateProvider for router tests

4. **Centralized**:
   - All navigation rules in one place
   - Easy to audit and modify

### 2. Routes

```dart
// Location: lib/src/presentation/core/router/routes.dart

class Routes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Authentication
  static const String login = '/login';
  static const String resetPassword = 'reset-password';
  static const String emailVerification = 'email-verification';
  static const String createNewPassword = 'create-new-password';
  static const String resetPasswordSuccess = 'reset-password-success';
  static const String registration = 'registration';

  // Main app
  static const String home = '/home';
  static const String profile = '/profile';
}
```

### 3. Shell Routes - Bottom Navigation with Nested Navigation

Shell routes enable nested navigation - the bottom bar stays visible while content changes above it.

```dart
// Nested navigation with bottom bar
_shellRoutes(Ref ref) {
  return ShellRoute(
    // SEPARATE NAVIGATOR: Shell has its own navigation stack
    // This allows home/profile to navigate independently
    // Root navigator (login, onboarding) and shell navigator are separate
    navigatorKey: _shellNavigatorKey,
    
    // BUILDER: Wraps child routes with persistent UI
    // 'child' = The current route's page (HomePage or ProfilePage)
    builder: (context, state, child) {
      // NavigationShell = Bottom navigation bar wrapper
      // child is rendered above the bottom bar
      return NavigationShell(child: child);
    },
    
    // CHILD ROUTES: All routes under this shell
    routes: [
      GoRoute(
        path: Routes.home,  // '/home'
        pageBuilder: (context, state) {
          // NoTransitionPage = No animation between tabs
          return const NoTransitionPage(child: HomePage());
        },
      ),
      GoRoute(
        path: Routes.profile,  // '/profile'
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: ProfilePage());
        },
      ),
    ],
  );
}
```

**How Shell Navigation Works:**

```
┌─────────────────────────────────────────────────────┐
│ Root Navigator (Full Screen)                        │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │ Login Page                                  │    │
│  │ (No bottom bar)                            │    │
│  │                                             │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘

User logs in → Navigate to /home

┌─────────────────────────────────────────────────────┐
│ Root Navigator                                       │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │ Shell Navigator                             │    │
│  │                                             │    │
│  │  ┌──────────────────────────────────┐      │    │
│  │  │ HomePage                          │      │    │
│  │  │                                   │      │    │
│  │  │ (Content area)                    │      │    │
│  │  │                                   │      │    │
│  │  └──────────────────────────────────┘      │    │
│  │                                             │    │
│  │  [Home] [Profile]  ← Bottom Navigation     │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘

Tap Profile Tab → Navigate to /profile

┌─────────────────────────────────────────────────────┐
│ Root Navigator                                       │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │ Shell Navigator                             │    │
│  │                                             │    │
│  │  ┌──────────────────────────────────┐      │    │
│  │  │ ProfilePage                       │      │    │
│  │  │                                   │      │    │
│  │  │ (Content changed, bar stays)      │      │    │
│  │  │                                   │      │    │
│  │  └──────────────────────────────────┘      │    │
│  │                                             │    │
│  │  [Home] [Profile]  ← Same Bottom Nav       │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Navigator Stack Visualization:**

```
// BEFORE SHELL (Login, Onboarding)
Root Navigator Stack:
  [LoginPage]

// AFTER SHELL (Home, Profile)
Root Navigator Stack:
  [ShellRoute]
    Shell Navigator Stack:
      [HomePage]  ← Current route

// Tap Profile Tab
Root Navigator Stack:
  [ShellRoute]
    Shell Navigator Stack:
      [HomePage]
      [ProfilePage]  ← Current route

// Tap Home Tab (Already in Stack)
Root Navigator Stack:
  [ShellRoute]
    Shell Navigator Stack:
      [HomePage]  ← Current route
      // ProfilePage removed or inactive
```

**Benefits of ShellRoute:**

1. **Persistent UI**: Bottom bar doesn't rebuild when switching tabs
2. **Independent Navigation**: Shell routes can have their own navigation logic
3. **State Preservation**: Tab states can be preserved when switching
4. **Performance**: Only content area rebuilds, not entire screen

---

## Error Handling

### 1. Network Error Handling

```dart
// TokenManager intercepts 401 errors
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401) {
    // Try to refresh token
    await _handleUnauthorizedError(err, handler);
    return;
  }
  
  handler.next(err);  // Pass error to next interceptor
}
```

### 2. Repository Error Handling

```dart
// asyncGuard wraps operations in try-catch
return asyncGuard(() async {
  final response = await remote.login(model);
  return LoginResponseModelMapper.fromJson(response.data);
});

// Returns Result<LoginResponseEntity, Failure>
// Success or Error - no exceptions thrown
```

### 3. Use Case Error Transformation

```dart
// Transform Failure to String for UI
return switch (result) {
  Success(:final data) => Success(data),
  Error(:final error) => Error(error.message),  // Extract message
  _ => const Error('Something went wrong'),
};
```

### 4. UI Error Display

```dart
ref.listenManual(loginProvider, (previous, next) {
  if (next.isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error!)),
    );
  }
});
```

---

## Theme System

### 1. Theme Extensions

```dart
// Location: lib/src/presentation/core/theme/theme.dart

extension ThemeHelpers on BuildContext {
  ThemeData get lightTheme => $LightThemeData()();
  ThemeData get darkTheme => $DarkThemeData()();

  ColorExtension get color =>
      _theme.brightness == Brightness.light ? _lightColor : _darkColor;

  TextStyleExtension get textStyle => _theme.extension<TextStyleExtension>()!;
}

// Usage in widgets:
Text('Hello', style: context.textStyle.heading1);
Container(color: context.color.primary);
```

### 2. Text Style Extensions

```dart
extension TextStyleExtensions on TextStyle {
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle size(double size) => copyWith(fontSize: size);
}

// Usage:
Text('Title', style: context.textStyle.heading1.bold);
Text('Subtitle', style: context.textStyle.body.italic.withColor(Colors.grey));
```

---

## Localization

### 1. Localization Provider

```dart
// Location: lib/src/presentation/core/application_state/localization_provider/localization_provider.dart

@Riverpod(keepAlive: true)
class Localization extends _$Localization {
  @override
  Locale build() {
    return const Locale('en');  // Default locale
  }

  Future<void> changeLocale(Locale locale) async {
    // Save to cache
    final useCase = ref.read(setCurrentLocaleUseCaseProvider);
    await useCase(locale.languageCode);

    // Update state
    state = locale;
  }

  Future<void> setCurrentLocal() async {
    // Load from cache
    final useCase = ref.read(getCurrentLocaleUseCaseProvider);
    final language = await useCase();

    state = Locale(language);
  }
}
```

### 2. Usage in App

```dart
MaterialApp.router(
  locale: ref.watch(localizationProvider),  // Current locale
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  ...
)
```

### 3. Language Switcher

```dart
class LanguageSwitcherWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<Locale>(
      value: ref.watch(localizationProvider),
      items: [
        DropdownMenuItem(value: Locale('en'), child: Text('English')),
        DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
      ],
      onChanged: (locale) {
        if (locale != null) {
          ref.read(localizationProvider.notifier).changeLocale(locale);
        }
      },
    );
  }
}
```

---

## Best Practices

### 1. Dependency Injection

✅ **DO:**
- Use `@Riverpod(keepAlive: true)` for singletons
- Use `@riverpod` for auto-dispose providers
- Inject dependencies through constructors
- Use `ref.read()` for one-time access
- Use `ref.watch()` for reactive updates

❌ **DON'T:**
- Create instances with `new` or constructors directly
- Use service locator pattern
- Pass Ref down the widget tree

### 2. State Management

✅ **DO:**
- Use immutable state classes
- Generate `copyWith` for state updates
- Use Status enum for UI states
- Handle loading, success, error states

❌ **DON'T:**
- Mutate state directly
- Use mutable collections in state
- Forget error handling

### 3. Repository Pattern

✅ **DO:**
- Use `asyncGuard` for error handling
- Return `Result<T, Failure>` for type safety
- Convert Models ↔ Entities at repository boundary
- Keep repositories thin (delegate to services)

❌ **DON'T:**
- Throw exceptions from repositories
- Put business logic in repositories
- Expose Models to domain layer

### 4. Use Cases

✅ **DO:**
- One use case per business operation
- Keep use cases focused and small
- Transform domain results for UI needs

❌ **DON'T:**
- Put UI logic in use cases
- Make use cases depend on other use cases
- Return complex domain types to UI

### 5. Error Handling

✅ **DO:**
- Use Result type for explicit error handling
- Provide user-friendly error messages
- Log errors for debugging
- Handle network errors gracefully

❌ **DON'T:**
- Swallow errors silently
- Show technical error messages to users
- Use exceptions for control flow

### 6. Code Generation

✅ **DO:**
- Run `flutter pub run build_runner watch` during development
- Commit generated files to version control
- Use `--delete-conflicting-outputs` flag

❌ **DON'T:**
- Edit generated files manually
- Ignore build_runner errors

---

## Summary

This Flutter template provides a **production-ready** architecture with:

1. **Clean Architecture**: Separation of concerns across layers
2. **Type-Safe DI**: Riverpod with code generation
3. **Error Handling**: Result type and Failure system
4. **State Management**: Riverpod providers and notifiers
5. **Routing**: GoRouter with declarative navigation
6. **Networking**: Retrofit + Dio with token refresh
7. **Local Storage**: SharedPreferences with type-safe keys
8. **Theming**: Light/dark mode with extensions
9. **Localization**: Multi-language support
10. **Logging**: Comprehensive logging system

### Key Takeaways

- **Entities** = Business objects (domain)
- **Models** = DTOs with serialization (data)
- **Repositories** = Data access contracts (domain) + implementations (data)
- **Use Cases** = Single business operations (domain)
- **Providers** = State management + DI (presentation)
- **Result** = Type-safe success/error handling
- **Failure** = Structured error information

### Next Steps

1. Run code generation: `flutter pub run build_runner watch`
2. Explore feature modules in `lib/src/presentation/features/`
3. Add new features following the established patterns
4. Write tests for each layer independently
5. Customize theme and colors in `lib/src/presentation/core/theme/`

---

**Happy Coding! 🚀**

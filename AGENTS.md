# AGENTS.md - Developer Guide for Ournego

This guide provides essential information for AI coding agents and developers working on the Ournego Flutter project.

## Project Overview

**Tech Stack:** Flutter 3.41.4 (Dart SDK ^3.10.0)  
**State Management:** flutter_riverpod ^3.0.3  
**Backend:** Supabase (Firebase Auth + Cloud Firestore)  
**Architecture:** Clean Architecture with feature-based organization

## Build, Test & Run Commands

### Running the App
```bash
# Run on web (development)
flutter run -d chrome --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Run on mobile (uses .env file)
flutter run

# Build for web
flutter build web

# Build for Android
flutter build apk
flutter build appbundle
```

### Testing
```bash
# Run all tests (when test directory exists)
flutter test

# Run specific test file
flutter test test/path/to/test_file_test.dart

# Run tests with coverage
flutter test --coverage
```

### Linting & Analysis
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Format specific file
flutter format lib/path/to/file.dart
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean && flutter pub get
```

## Project Architecture

### Clean Architecture Pattern

```
lib/
├── core/                          # Shared utilities, themes, failures
│   ├── failures.dart             # Domain failure classes
│   ├── ournego_colors.dart       # Theme definitions
│   ├── ournego_text_styles.dart  # Text styles
│   └── routing/                  # Centralized routing
│       ├── app_router.dart       # GoRouter configuration
│       └── route_names.dart      # Route constants
│
├── features/                      # Feature modules
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/      # External data sources (API, local DB)
│       │   ├── models/           # Data models with serialization
│       │   └── repositories/     # Repository implementations
│       ├── domain/
│       │   ├── entities/         # Business entities (pure Dart classes)
│       │   ├── repositories/     # Repository interfaces
│       │   └── usecases/         # Business logic
│       └── presentation/
│           ├── pages/            # Screen widgets
│           ├── providers/        # Riverpod providers
│           │   └── notifiers/    # StateNotifiers for complex state
│           └── widgets/          # Reusable UI components
│
└── shared/                        # Cross-feature shared code
    └── widgets/                   # Shared widgets
```

### Dependency Flow
**Presentation → Domain ← Data**

- Presentation depends on Domain (uses usecases)
- Data depends on Domain (implements repositories)
- Domain is independent (pure business logic)

## Code Style Guidelines

### Import Organization
Order imports in the following sequence:
1. Dart core libraries (`dart:*`)
2. Flutter packages (`package:flutter/*`)
3. External packages (alphabetically)
4. Internal app imports (`package:ournego/*`)
5. Relative imports (avoid when possible)

Separate each group with a blank line.

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
```

### Naming Conventions

- **Files:** snake_case (e.g., `auth_repository_impl.dart`)
- **Classes:** PascalCase (e.g., `AuthRepository`)
- **Variables/Functions:** camelCase (e.g., `getCurrentLocation`)
- **Constants:** camelCase with `const` or `final` (e.g., `const maxRetries = 3`)
- **Private members:** prefix with underscore (e.g., `_loadCurrentLocation`)

### File Naming Patterns

- Repositories: `[name]_repository.dart` (interface), `[name]_repository_impl.dart` (implementation)
- Datasources: `[source]_[name]_datasource.dart` (e.g., `supabase_auth_datasource.dart`)
- Usecases: `[action]_[entity]_usecase.dart` (e.g., `log_in_with_email_usecase.dart`)
- Providers: `[feature]_providers.dart`
- Notifiers: `[name]_notifier.dart`
- Screens: `[name]_screen.dart`
- Widgets: `[name]_widget.dart`

### Type Annotations

Always use explicit types for public APIs:
```dart
// Good
Future<Either<Failure, AppUser>> signUpWithEmail(String email, String password);

// Avoid
signUpWithEmail(email, password) async { ... }
```

### Error Handling

#### Domain Layer - Use Either from dartz
```dart
Future<Either<Failure, AppUser>> logInWithEmail(String email, String password) async {
  try {
    final user = await authDatasource.logInWithEmail(email, password);
    return Right(user);
  } on AuthException catch (e) {
    if (e.message.contains('Invalid login credentials')) {
      return Left(InvalidCredentialsFailure());
    }
    return Left(ServerFailure());
  } catch (_) {
    return Left(ServerFailure());
  }
}
```

#### Data Layer - Throw Specific Exceptions
```dart
class LocationServiceDisabledException implements Exception {}

Future<Position> getCurrentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw LocationServiceDisabledException();
  }
  // ...
}
```

#### Presentation Layer - Use AsyncValue
```dart
class MapNotifier extends AsyncNotifier<AppPosition> {
  Future<void> refreshLocation() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCurrentLocation());
  }
}
```

### Riverpod Best Practices

- Use `Provider` for immutable dependencies
- Use `StreamProvider` for reactive data
- Use `AsyncNotifier` for complex async state
- Use `StateNotifier` for synchronous state mutations
- Always use `ref.watch()` in build methods, `ref.read()` in callbacks

```dart
// Provider declaration
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = SupabaseAuthDatasource();
  return AuthRepositoryImpl(authDatasource: datasource);
});

// Using in widgets
final authState = ref.watch(authSessionProvider);
```

### Logging & Debugging

Use `debugPrint` for logging (not `print`):
```dart
debugPrint('Login exitoso para usuario: ${user.email}');
```

### Comments & Documentation

- Add TODO comments with perspective notes for improvements
- Document repository methods with expected behavior
- Use Spanish for UI-facing strings, English for code comments

```dart
// TODO: Document expected errors and whether email/password are trimmed.
// Perspective: Add parameter validation or use value objects for email
```

## Common Patterns

### Usecase Structure
```dart
class LogInWithEmailUsecase {
  final AuthRepository repository;

  LogInWithEmailUsecase({required this.repository});

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) async {
    return repository.logInWithEmail(email, password);
  }
}
```

### Entity Structure
```dart
class Business {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Business({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
```

## Environment Configuration

The app uses environment variables for configuration:

- **Web:** Variables loaded from `web/config.js` via `window.ENV`
- **Mobile:** Variables loaded from `.env` file or `--dart-define` flags

Required environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Key Dependencies

- **State Management:** flutter_riverpod
- **Functional Programming:** dartz (Either, Option)
- **Logging:** logger
- **Maps:** flutter_map, latlong2, geolocator
- **Backend:** supabase_flutter
- **Auth:** firebase_auth, google_sign_in
- **Local Storage:** shared_preferences, sembast

## Analysis Rules

Configured in `analysis_options.yaml`:
- Uses `package:flutter_lints/flutter.yaml`
- Ignores `empty_constructor_bodies` warnings

## Git Workflow

- Keep commits focused and atomic
- Write clear commit messages in English
- Don't commit `.env` files or secrets

## Navigation with GoRouter

The app uses GoRouter for declarative routing. All routes are defined in `lib/core/routing/`.

### Adding a New Route

1. **Define route constant** in `route_names.dart`:
```dart
class MyFeatureRoutes {
  MyFeatureRoutes._();
  
  static const myScreen = '/my-screen';
  static const myDetailScreen = '/my-detail/:id';
}
```

2. **Add route to router** in `app_router.dart`:
```dart
GoRoute(
  path: MyFeatureRoutes.myScreen,
  name: 'my-screen',
  builder: (context, state) => const MyScreen(),
),
```

### Navigation Patterns

```dart
// Navigate to a route
context.go(MapRoutes.map);

// Push a route (adds to stack)
context.push(BusinessRoutes.register);

// Navigate with parameters
context.go('/business/${businessId}');

// Navigate with extra data
context.go(
  AuthRoutes.createPassword,
  extra: email,  // Pass data to next screen
);

// Pop back
context.pop();
```

### DO NOT directly import screens from other features for navigation
```dart
// ❌ BAD - Don't do this
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
Navigator.push(context, MaterialPageRoute(builder: (_) => AuthSelectionScreen()));

// ✅ GOOD - Use routes instead
import 'package:ournego/core/routing/route_names.dart';
context.go(AuthRoutes.authSelection);
```

## Models vs Entities

### Entities (Domain Layer)
- Pure business objects with no serialization
- Located in `lib/features/[feature]/domain/entities/`
- Contain only business logic and validation
- No knowledge of JSON, databases, or APIs

```dart
class Business {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  Business({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
```

### Models (Data Layer)
- Extend entities and add serialization
- Located in `lib/features/[feature]/data/models/`
- Handle JSON conversion and data transformation
- Know about specific data source formats

```dart
class BusinessModel extends Business {
  BusinessModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };
}
```

### When to Create Models

**Always create models** for:
- Entities that are serialized (API, database)
- Entities with data transformation logic
- Entities from external data sources

**Skip models** for:
- Pure in-memory entities
- Simple configuration objects
- Entities that never leave the app

See `MODELS_TEMPLATE.md` for detailed model creation guidelines.

# Models Structure Template

This document provides a template for creating data models in the Ournego project.

## Purpose of Models

In Clean Architecture, **models** live in the data layer and are responsible for:
- Serialization/deserialization (toJson/fromJson)
- Data transformation from external sources (API, database)
- Mapping between external data formats and domain entities

**Entities** live in the domain layer and represent pure business concepts with no knowledge of serialization or data sources.

## When to Create a Model

Create a model when:
1. You need to serialize/deserialize data
2. External data structure differs from your domain entity
3. You have transformation logic specific to a data source

You can skip creating a model if:
- The entity is purely in-memory and never serialized
- The data structure is identical to the entity with no transformation

## Model Template

```dart
import 'package:ournego/features/[feature]/domain/entities/[entity_name].dart';

/// Data model for [EntityName].
/// 
/// Extends the domain entity and adds serialization capabilities.
/// Used in the data layer for API communication and local storage.
class [EntityName]Model extends [EntityName] {
  [EntityName]Model({
    required super.field1,
    required super.field2,
    // ... all fields from entity
  });

  /// Create model from JSON (e.g., from API response)
  factory [EntityName]Model.fromJson(Map<String, dynamic> json) {
    return [EntityName]Model(
      field1: json['field_1'] as String,
      field2: json['field_2'] as int,
      // Handle nullable fields
      field3: json['field_3'] as String?,
      // Handle nested objects
      field4: json['field_4'] != null 
        ? NestedModel.fromJson(json['field_4'])
        : null,
      // Handle lists
      field5: (json['field_5'] as List<dynamic>?)
        ?.map((item) => ItemModel.fromJson(item))
        .toList() 
        ?? [],
    );
  }

  /// Convert model to JSON (e.g., for API requests)
  Map<String, dynamic> toJson() {
    return {
      'field_1': field1,
      'field_2': field2,
      'field_3': field3,
      'field_4': field4?.toJson(),
      'field_5': field5?.map((item) => item.toJson()).toList(),
    };
  }

  /// Create model from domain entity
  /// Useful when you need to serialize an entity
  factory [EntityName]Model.fromEntity([EntityName] entity) {
    return [EntityName]Model(
      field1: entity.field1,
      field2: entity.field2,
      // ... all fields
    );
  }

  /// Create model from specific data source (if needed)
  /// Example: Supabase, Firebase, etc.
  factory [EntityName]Model.fromSupabase(Map<String, dynamic> data) {
    return [EntityName]Model(
      // Map Supabase-specific field names to entity fields
      field1: data['supabase_field_1'] as String,
      field2: data['supabase_field_2'] as int,
    );
  }
}
```

## Real Example: UserModel

```dart
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel extends AppUser {
  UserModel({
    required super.uid,
    super.email,
    super.name,
    super.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      profilePicture: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'email': email,
      'name': name,
      'avatar_url': profilePicture,
    };
  }

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      uid: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] as String?,
      profilePicture: user.userMetadata?['avatar_url'] as String?,
    );
  }
}
```

## File Naming Convention

Models should be placed in:
```
lib/features/[feature]/data/models/[entity_name]_model.dart
```

Examples:
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/map/data/models/business_model.dart`
- `lib/features/business/data/models/app_schedule_model.dart`

## Usage in Datasources

Datasources should return models:

```dart
class SupabaseAuthDatasource {
  Future<UserModel> signUpWithEmail(String email, String password) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    return UserModel.fromSupabaseUser(response.user!);
  }
}
```

## Usage in Repositories

Repositories receive models from datasources and return entities to the domain layer:

```dart
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDatasource datasource;

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userModel = await datasource.signUpWithEmail(email, password);
      // Model extends Entity, so can be returned directly
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

## Best Practices

1. **Models extend entities**: Use inheritance to ensure models ARE entities
2. **Null safety**: Handle nullable fields properly in fromJson
3. **Type casting**: Always cast JSON values to expected types
4. **Default values**: Provide defaults for lists/collections
5. **Multiple factories**: Create different factories for different data sources
6. **Immutability**: Models and entities should be immutable (use final fields)
7. **Documentation**: Document any field transformations or special handling

## Migration Checklist

When adding models to an existing feature:

1. [ ] Create `data/models/` directory if it doesn't exist
2. [ ] Create model file extending the entity
3. [ ] Add `fromJson` factory method
4. [ ] Add `toJson` method
5. [ ] Add source-specific factories (e.g., `fromSupabase`)
6. [ ] Update datasource to return models
7. [ ] Update repository to handle models
8. [ ] Update tests to use models
9. [ ] Run `flutter analyze` to check for issues

## Common Patterns

### Handling Enums
```dart
// In entity
enum Status { active, inactive }

// In model
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    status: Status.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => Status.inactive,
    ),
  );
}

Map<String, dynamic> toJson() {
  return {
    'status': status.name,
  };
}
```

### Handling Dates
```dart
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> toJson() {
  return {
    'created_at': createdAt.toIso8601String(),
  };
}
```

### Handling Nested Objects
```dart
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    address: json['address'] != null
      ? AddressModel.fromJson(json['address'])
      : null,
  );
}
```

This template should be used as a starting point for all new models in the project.

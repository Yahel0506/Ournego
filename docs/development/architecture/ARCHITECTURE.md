# Ournego Architecture

This document describes the current architecture and dependency rules used in Ournego.

## Architectural Style

Ournego uses Clean Architecture with feature-based modules.

Dependency direction:

`Presentation -> Domain <- Data`

- Presentation depends on domain contracts and usecases.
- Data implements domain repository interfaces.
- Domain is framework-agnostic and contains business rules.

## Folder Structure

```text
lib/
  core/
    routing/
      app_router.dart
      route_names.dart
    failures.dart
    ...
  features/
    <feature>/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        providers/
        widgets/
  shared/
```

## Models vs Entities

- Entities (`domain/entities`) define business data and rules.
- Models (`data/models`) represent external formats and serialization.
- Models may extend entities when that improves mapping clarity.
- Repositories expose entities to domain/usecases, never raw external DTOs.

## Routing Strategy

Routes are centralized in `lib/core/routing/app_router.dart` and constants in `lib/core/routing/route_names.dart`.

- Shell routes host main tabs and bottom navigation.
- Standalone routes host onboarding, auth, and forms.
- Navigation between features must use route constants and `context.go`/`context.push`.
- Features must not directly import screens from other features for navigation.

## Auth/Profile Guards

Router-level guards enforce:

- Logged out users are redirected from protected routes to auth selection.
- Logged in users without profile are redirected to complete profile.
- Logged in users with profile are redirected away from auth/onboarding routes to map.

## Provider Layering

Every `*_providers.dart` should be ordered as:

1. Datasources
2. Repositories
3. Usecases
4. State providers (StreamProvider/FutureProvider/Notifiers)

This keeps dependency flow explicit and easy to review.

## Feature Boundaries

- A feature owns its UI, state providers, domain contracts, and data mapping.
- Cross-feature communication should happen through:
  - shared route constants and navigation
  - repository/usecase abstractions
  - shared/core utilities
- If multiple features need the same business capability, move it to a dedicated feature or shared domain contract instead of duplicating logic.

## When to Create a New Feature

Create a new feature when at least one applies:

- Distinct business capability with its own entities/usecases
- Independent evolution cadence
- Clear presentation flows/screens

Extend an existing feature when changes are tightly coupled to that feature's existing entities and usecases.

## SOLID in Practice

- **Single Responsibility:** each class has one primary concern.
- **Open/Closed:** add behavior via new usecases/services, avoid editing stable core contracts.
- **Liskov Substitution:** repository implementations remain interchangeable.
- **Interface Segregation:** small feature-specific repository interfaces.
- **Dependency Inversion:** presentation/domain depend on abstractions, not data-layer concretions.

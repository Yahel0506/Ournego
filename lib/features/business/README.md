# Business Feature

## Responsibility
Manages business registration, ownership checks, panel view, business form flow, and schedule-related business data.

## Dependencies
- `features/auth` for current user/session context
- Supabase business tables and storage
- Geocoding datasource for address suggestions

## Key Entities / Usecases / Providers
- **Entities:** `AppBusiness`, `AppSchedule`, `BusinessType`
- **Usecases:** `RegisterBusinessUsecase`, `CheckIfOwnerUsecase`, `GetAddressesSuggestionsUsecase`
- **Providers:** `businessRepositoryProvider`, `registerBusinessUsecaseProvider`, `isOwnerProvider`

## Routes
- `BusinessRoutes.panel`
- `BusinessRoutes.register`
- `BusinessRoutes.form`

## Notes / Extension Points
- Keep owner checks in business usecases fed by auth state, avoid duplicating auth logic.
- Route to auth via route constants when auth is required.

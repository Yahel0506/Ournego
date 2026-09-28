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

## UI Refactor Notes
- Business form and information dialogs are partially migrated to shared presets.
- Prefer `OurnegoInputField`/`OurnegoInputDecorations.filled(...)` and shared snackbar/dialog widgets in new UI changes.
- Use spacing/radius tokens when touching reusable components like schedulers, cards, and form sections.

# Feedback Feature

## Responsibility
Captures in-app feedback with optional attachment metadata and sends it to Supabase storage/table.

## Dependencies
- Supabase storage and database (`feedback_attachments`, `feedback`)
- Device/context metadata from presentation layer

## Key Entities / Usecases / Providers
- **Entities:** `FeedbackReport`
- **Usecases:** `SendFeedbackUsecase`
- **Providers:** `feedbackDatasourceProvider`, `feedbackRepositoryProvider`, `sendFeedbackUsecaseProvider`

## Routes
- No dedicated route currently (modal-driven feature).

## Notes / Extension Points
- If a full feedback screen is added, define a route constant and register route in `app_router.dart`.
- Keep mapping logic in model layer (`FeedbackReportModel`).

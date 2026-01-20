// TODO: Consider making Failure classes carry messages/metadata and
// implement Equatable for easier testing and comparison.
// Perspective: Introduce a base Failure with `message`, `code`, and
// optional `underlyingException` fields. This allows mapping failures to
// user-friendly UI messages and for analytics.
abstract class Failure {}

// Si el servidor falló en el proceso
class ServerFailure extends Failure {}

// Si hay un fallo en un proceso local
class LocalFailure extends Failure {}

// |---------------------------------| \\
// |------- FAILURES DE AUTH --------| \\
// |---------------------------------| \\

// Si alguna de las credenciales no es correcta
class InvalidCredentialsFailure extends Failure {}

// Si el email ya está en uso
class EmailAlreadyInUseFailure extends Failure {}

// Si el nombre ya está en uso
class UsernameAlreadyInUseFailure extends Failure {}

// Si no se encontró el perfil del usuario
class UserProfileNotFound extends Failure {}

// |---------------------------------| \\
// |------- FAILURES DE MAP ---------| \\
// |---------------------------------| \\

// Si no se pudo obtener la ubicación actual
class LocationPermissionDeniedFailure extends Failure {}

class LocationPermissionDeniedForeverFailure extends Failure {}

// Si la operación requiere autenticación pero no hay usuario loggeado
class AuthenticationRequiredFailure extends Failure {}

// TODO: Add mapping helpers (e.g. `Failure.fromException`) to centralize
// translation from platform / third-party errors to domain failures.

import 'package:ournego/core/failures.dart';

class LocalErrorMessagesDatasource {
  String getErrorMessage(Failure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'El correo o la contraseña son incorrectos.';
    } else if (failure is EmailAlreadyInUseFailure) {
      return 'El correo ya está en uso.';
    } else if (failure is EmailNotVerifiedFailure) {
      return 'Tu correo aún no está verificado. Revisa tu bandeja de entrada.';
    } else if (failure is NetworkFailure) {
      return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    } else if (failure is SessionExpiredFailure) {
      return 'Tu sesión venció. Vuelve a iniciar sesión.';
    } else {
      return 'Ha habido un error. Por favor, inténtalo de nuevo.';
    }
  }

  /// Message for a failed or cancelled Google sign-in. Always invites to retry
  /// and never exposes the raw error.
  String getGoogleSignInErrorMessage(Failure failure) {
    if (failure is GoogleSignInCancelledFailure) {
      return 'Cancelaste el inicio de sesión con Google. Puedes volver a intentarlo.';
    } else if (failure is GoogleSignInUnavailableFailure) {
      return 'No pudimos abrir el inicio de sesión de Google en este dispositivo. Inténtalo de nuevo.';
    } else if (failure is NetworkFailure) {
      return getErrorMessage(failure);
    } else {
      return 'No pudimos iniciar sesión con Google. Inténtalo de nuevo.';
    }
  }
}

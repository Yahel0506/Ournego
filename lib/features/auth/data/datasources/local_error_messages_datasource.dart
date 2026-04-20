import 'package:ournego/core/failures.dart';

class LocalErrorMessagesDatasource {
  String getErrorMessage(Failure failure) {
    if (failure is InvalidCredentialsFailure) {
      return 'El correo o la contraseña son incorrectos.';
    } else if (failure is EmailAlreadyInUseFailure) {
      return 'El correo ya está en uso.';
    } else if (failure is EmailNotVerifiedFailure) {
      return 'Tu correo aún no está verificado. Revisa tu bandeja de entrada.';
    } else {
      return 'Ha habido un error. Por favor, inténtalo de nuevo.';
    }
  }
}

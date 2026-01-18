import 'package:ournego/features/auth/domain/entities/auth_selection.dart';

class LocalAuthSelectionDatasource {
  AuthSelection getHardcodedAuthSelection() {
    return AuthSelection(
      title: 'Empieza a crecer.',
      imagePath: 'assets/images/ournego.png',
      darkImagePath: 'assets/images/ournego_white.png',
      googleLogin: 'Continuar con Google',
      emailLogin: 'Continuar con correo electrónico',
      phoneLogin: 'Continuar con número telefónico',
      guestAccess: 'Continuar como invitado',
      termsText1: 'Al continuar, aceptas nuestros ',
      termsText2: 'Términos y Condiciones',
      termsText3: ' y ',
      termsText4: 'Política de Privacidad.',
    );
  }
}

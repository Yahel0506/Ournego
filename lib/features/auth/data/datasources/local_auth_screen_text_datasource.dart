import 'package:ournego/features/auth/domain/entities/auth_screen_text.dart';

class LocalAuthScreenTextDatasource {
  final String primaryButton = 'Siguiente';

  AuthScreenText signupEmail() {
    return AuthScreenText(
      title: 'Regístrate para iniciar a descubrir.',
      primaryButton: primaryButton,
      primaryInstruction: 'Introduce tu correo electrónico:',
      primaryHint: 'nombre@dominio.com',
    );
  }

  AuthScreenText loginEmail() {
    return AuthScreenText(
      title: '¡Hola de nuevo!',
      primaryButton: primaryButton,
      primaryInstruction: 'Introduce tu correo electrónico:',
      primaryHint: 'nombre@dominio.com',
      secondaryInstruction: 'Introduce tu contraseña:',
      secondaryHint: 'Contraseña',
      forgotPassword: '¿Olvidaste tu contraseña?',
      signUp: '¿No tienes cuenta?',
    );
  }

  AuthScreenText createPassword() {
    return AuthScreenText(
      title: '¡Crea una contraseña segura!',
      primaryButton: primaryButton,
      primaryInstruction: 'Crea una contraseña:',
      primaryHint: 'Contraseña',
      secondaryInstruction: 'Confirma tu contraseña:',
      secondaryHint: 'Confirmar contraseña',
      passwordRules: [
        '1 letra mayúscula',
        '1 número o carácter especial',
        '8 caracteres',
      ],
    );
  }

  AuthScreenText completeProfile() {
    return AuthScreenText(
      title: '¡Completa tu perfil para continuar!',
      primaryButton: 'Finalizar',
      primaryInstruction: 'Crea un nombre de usuario',
      primaryHint: '',
    );
  }
}

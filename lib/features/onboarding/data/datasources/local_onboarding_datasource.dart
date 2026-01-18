import 'package:ournego/features/onboarding/domain/entities/slide.dart';

class LocalOnboardingDatasource {
  List<Slide> getHardcodedSlides() {
    return [
      Slide(
        title: 'Tu colonia, conectada.',
        description:
            'Descubre negocios locales, ofertas exclusivas y conecta con tu comunidad vecinal en un solo lugar.',
        imagePath: 'assets/images/welcome.png',
      ),
      Slide(
        title: 'Explora antes de ir.',
        description:
            'Visita locales en Realidad Virtual, revisa inventarios y contacta al dueño directamente desde el mapa.',
        imagePath: 'assets/images/second_top_features.png',
      ),
      Slide(
        title: 'Encuentra lo que te queda cerca.',
        description:
            'Para mostrarte los mejores negocios en tu zona, necesitamos acceso a tu ubicación. Solo la usaremos mientras usas la app.',
        imagePath: 'assets/images/location_permission.png',
        buttonText: 'ACTIVAR UBICACIÓN',
      ),
      /*Slide(
        title: 'Empieza a crecer.',
        imagePath: 'assets/images/ournego.png',
        darkImagePath: 'assets/images/ournego_white.png',
        googleLogin: 'Acceder con Google',
        emailLogin: 'Acceder con correo electrónico',
        phoneLogin: 'Acceder con número telefónico',
        guestAccess: 'Acceder como invitado',
        termsText1: 'Al continuar, aceptas nuestros ',
        termsText2: 'Términos y Condiciones',
        termsText3: ' y ',
        termsText4: 'Política de Privacidad.',
      ),*/
    ];
  }
}

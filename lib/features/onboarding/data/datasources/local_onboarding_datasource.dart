import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/onboarding/data/models/slide_model.dart';

class LocalOnboardingDatasource {
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';

  // Legacy slide data from the previous generic onboarding flow.
  List<SlideModel> getHardcodedSlides() {
    return [
      const SlideModel(
        title: 'Tu colonia, conectada.',
        description:
            'Descubre negocios locales, ofertas exclusivas y conecta con tu comunidad vecinal en un solo lugar.',
        imagePath: 'assets/images/welcome.png',
      ),
      const SlideModel(
        title: 'Explora antes de ir.',
        description:
            'Visita locales en Realidad Virtual, revisa inventarios y contacta al dueño directamente desde el mapa.',
        imagePath: 'assets/images/second_top_features.png',
      ),
      const SlideModel(
        title: 'Encuentra lo que te queda cerca.',
        description:
            'Para mostrarte los mejores negocios en tu zona, necesitamos acceso a tu ubicación. Solo la usaremos mientras usas la app.',
        imagePath: 'assets/images/location_permission.png',
        buttonText: 'ACTIVAR UBICACIÓN',
      ),
    ];
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
}

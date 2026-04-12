import 'package:ournego/features/onboarding/domain/entities/slide.dart';
import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({
    required bool hasSeen,
    this.persistInStorage = true,
  }) : _hasSeen = hasSeen;

  bool _hasSeen;
  final bool persistInStorage;

  @override
  List<Slide> getSlides() {
    return const [
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
    ];
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    if (!persistInStorage) {
      return _hasSeen;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getBool('hasSeenOnboarding');
    return storedValue ?? _hasSeen;
  }

  @override
  Future<void> setHasSeenOnboarding() async {
    _hasSeen = true;

    if (!persistInStorage) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }
}

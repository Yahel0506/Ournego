import 'package:ournego/features/onboarding/domain/entities/slide.dart';

abstract class OnboardingRepository {
  List<Slide> getSlides();
}

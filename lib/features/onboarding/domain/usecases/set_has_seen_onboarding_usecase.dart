import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';

class SetHasSeenOnboardingUsecase {
  final OnboardingRepository repository;

  SetHasSeenOnboardingUsecase({required this.repository});

  Future<void> call() {
    return repository.setHasSeenOnboarding();
  }
}

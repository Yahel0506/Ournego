import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetHasSeenOnboardingUsecase {
  final OnboardingRepository repository;

  GetHasSeenOnboardingUsecase({required this.repository});

  Future<bool> call() {
    return repository.hasSeenOnboarding();
  }
}

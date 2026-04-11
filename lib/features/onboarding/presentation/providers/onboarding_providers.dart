import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/onboarding/data/datasources/local_onboarding_datasource.dart';
import 'package:ournego/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:ournego/features/onboarding/domain/entities/slide.dart';
import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:ournego/features/onboarding/domain/usecases/get_has_seen_onboarding_usecase.dart';
import 'package:ournego/features/onboarding/domain/usecases/set_has_seen_onboarding_usecase.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDataSource = LocalOnboardingDatasource();
  return OnboardingRepositoryImpl(localDataSource);
});

final slidesListProvider = Provider<List<Slide>>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getSlides();
});

final getHasSeenOnboardingUsecaseProvider =
    Provider<GetHasSeenOnboardingUsecase>((ref) {
      final repository = ref.watch(onboardingRepositoryProvider);
      return GetHasSeenOnboardingUsecase(repository: repository);
    });

final setHasSeenOnboardingUsecaseProvider =
    Provider<SetHasSeenOnboardingUsecase>((ref) {
      final repository = ref.watch(onboardingRepositoryProvider);
      return SetHasSeenOnboardingUsecase(repository: repository);
    });

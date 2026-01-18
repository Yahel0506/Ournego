import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/onboarding/data/datasources/local_onboarding_datasource.dart';
import 'package:ournego/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:ournego/features/onboarding/domain/entities/slide.dart';
import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDataSource = LocalOnboardingDatasource();
  return OnboardingRepositoryImpl(localDataSource);
});

final slidesListProvider = Provider<List<Slide>>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getSlides();
});

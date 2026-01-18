import 'package:ournego/features/onboarding/data/datasources/local_onboarding_datasource.dart';
import 'package:ournego/features/onboarding/domain/entities/slide.dart';
import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final LocalOnboardingDatasource localDataSource;

  OnboardingRepositoryImpl(this.localDataSource);

  @override
  List<Slide> getSlides() {
    return localDataSource.getHardcodedSlides();
  }
}

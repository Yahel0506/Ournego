import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart'
    show BusinessRepository;
import 'package:ournego/features/business/domain/usecases/register_business_usecase.dart';
import 'package:riverpod/src/framework.dart';

import '../../data/repositories/business_repository_impl.dart';
import '../../domain/usecases/check_if_logged_usecase.dart';
import '../../domain/usecases/check_if_owner_usecase.dart';
import '../../domain/usecases/get_addresses_suggestions_usecase.dart';

final businessSupabaseDatasourceProvider = Provider<BusinessSupabaseDatasource>(
  (ref) {
    return BusinessSupabaseDatasource();
  },
);

final businessGeocodingDatasourceProvider =
    Provider<BusinessGeocodingDatasource>((ref) {
      return BusinessGeocodingDatasource();
    });

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final businessDatasource = ref.watch(businessSupabaseDatasourceProvider);
  final geocodingDatasource = ref.watch(businessGeocodingDatasourceProvider);
  return BusinessRepositoryImpl(
    businessDatasource: businessDatasource,
    geocodingDatasource: geocodingDatasource,
  );
});

final checkIfLoggedUsecaseProvider = Provider<CheckIfLoggedUsecase>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return CheckIfLoggedUsecase(repository);
});

final isLoggedProvider = StreamProvider<bool>((ref) {
  final usecase = ref.watch(checkIfLoggedUsecaseProvider);
  final result = usecase();
  return result;
});

final getAdressesSuggestionsUsecaseProvider =
    Provider<GetAddressesSuggestionsUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return GetAddressesSuggestionsUsecase(repository: repository);
    });

final registerBusinessUsecaseProvider = Provider<RegisterBusinessUsecase>((
  ref,
) {
  final repository = ref.watch(businessRepositoryProvider);
  return RegisterBusinessUsecase(repository: repository);
});

final checkIfOwnerUsecaseProvider = Provider<CheckIfOwnerUsecase>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return CheckIfOwnerUsecase(repository: repository);
});

final isOwnerProvider = FutureProvider<bool>((ref) async {
  final usecase = ref.watch(checkIfOwnerUsecaseProvider);
  final result = await usecase();
  return result.fold((failure) => false, (isOwner) => isOwner);
});
